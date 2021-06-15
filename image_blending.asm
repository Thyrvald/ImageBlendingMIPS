#========================================================
# Pawe³ Gosk
# Image blending
# Image size cannot be bigger than 65 KB
# 22.05.2021
#========================================================

	.data
fname1: 		.asciiz "input1.bmp"
fname2:			.asciiz "input2.bmp"
outfname:		.asciiz "blended_image.bmp"
filenotfoundmsg:	.asciiz "File not found\n"
image1:			.space 6
image2:			.space 6

	.text
	
main:	 
	
        la $a0, fname1		#file name 
	la $a3, image1
	jal read_bmp
	
	la $a0, fname2		#file name
	#lhu $t0, image1 + 2	# get size of image one
	#la $a3, image1		# load address of image one
	#add $a3, $a3, $t0	# get address for image two by offsetting image on address by image one size
	jal read_bmp
	
	li $t4, 0		# beginning x for image1
	lhu $t5, image1 + 22
	subi $t5, $t5, 1	# beginning y for image1
	
	li $t6, 0		# beginning x for image2
	lhu $t0, image1 + 2
	la $t1, image1
	add $t1, $t1, $t0
	
	lhu $t7, 22($t1)
	subi $t7, $t7, 1	# beginning y for image2
	
blend_loop:
	bltz $t7, change_x

	la $a0, ($t4)		#x
	la $a1, ($t5)		#y
	la $a2, image1
	jal get_pixel

	# store BGR values of pixel color from image one multiplied by 0,5 in $s1, $s2, $s3 for blending
	srl $s1, $s5, 1		# B
	srl $s2, $s6, 1		# G
	srl $s3, $s7, 1		# R
	
	la $a0, ($t6)		#x
	la $a1, ($t7)		#y
	lhu $t0, image1 + 2	# get size of image one
	la $a2, image1		# load address of image one
	add $a2, $a2, $t0	# get address for image two by offsetting image on address by image one size
	jal get_pixel
	
	# store BGR values of pixel color from image two multiplied by 0,5 in $s5, $s6, $s7 for blending
	srl $s5, $s5, 1		# B
	srl $s6, $s6, 1		# G
	srl $s7, $s7, 1		# R
	
	# add $s1 to $5, $s2 to $s6, $s3 to $s7 to create blended BGR values
	add $s1, $s1, $s5
	add $s2, $s2, $s6
	add $s3, $s3, $s7
	
	#create hex value of the color from rgb
	la $a2,($s1)		#load B
	la $t1,($s2)		#load G
	sll $t1,$t1,8
	or $a2, $a2, $t1
	la $t1,($s3)		#load R
        sll $t1,$t1,16
	or $a2, $a2, $t1	#color - 00RRGGBB
	
	la $a0, ($t4)		#x
	la $a1, ($t5)		#y
	la $a3, image1
	
set_pixel:
#arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate - (0,0) - bottom left corner
#	$a2 - 0RGB - pixel color
	lb $t2, 10($a3)		# adress of file offset to pixel array
	la $t1, ($a3)		# adress of bitmap
	add $t2, $t1, $t2	# adress of pixel array in $t2
	
	lhu $t1, 18($a3)	# image width
	mul $t1, $t1, 3 	# save amount of bytes per row in $t1
	mul $t1, $a1, $t1 	# t1= y*BYTES_PER_ROW
	move $t3, $a0		
	sll $a0, $a0, 1
	add $t3, $t3, $a0	# $t3= 3*x
	add $t1, $t1, $t3	# $t1 = 3x + y*BYTES_PER_ROW
	add $t2, $t2, $t1	# pixel address 
	
	#set new color
	sb $a2,($t2)		# store B
	srl $a2,$a2,8
	sb $a2,1($t2)		# store G
	srl $a2,$a2,8
	sb $a2,2($t2)		# store R
	
	subi $t5, $t5, 1
	subi $t7, $t7, 1
	
	bgez $t5, blend_loop
	
change_x:
	addi $t4, $t4, 1	# increase x
	la $t8, image1 + 18	# get image one width
	lhu $t8, ($t8)
	beq $t4, $t8, save_bmp
	
	lhu $t5, image1 + 22	# get image one hight
	subi $t5, $t5, 1	# reset y to the start value
	
	addi $t6, $t6, 1
	lhu $t0, image1 + 2	# get size of image one
	la $t8, image1		# load address of image one
	add $t8, $t8, $t0	# get address for image two by offsetting image on address by image one size
	lhu $t8, 18($t8)	# get image two width
	beq $t6, $t8, save_bmp
	
	lhu $t0, image1 + 2	# get size of image one
	la $t7, image1		# load address of image one
	add $t7, $t7, $t0	# get address for image two by offsetting image on address by image one size
	lhu $t7, 22($t7)	# get image two hight
	subi $t7, $t7, 1	# reset y to the start value
	
	j blend_loop
	
# save bmp ====================================================================================================
        
save_bmp:
#arguments:
#	$a0 - out file name
#	$a1, $a2 - flags

#open file
        la $a0, outfname	# out file name 
	li $v0, 13
        li $a1, 1		# flags: 1-write file
        li $a2, 0		# mode: ignored
        syscall
	move $s1, $v0      	# save the file descriptor

#save file
	li $v0, 15
	move $a0, $s1
	la $a1, image1		# address of pixel array
	lhu $a2, 2($a1)		# size of image
	syscall

#close file
	li $v0, 16
	move $a0, $s1
        syscall

end:
	#call for end of program
	li $v0, 10
	syscall
	
# read bmp ====================================================================================================
	
read_bmp:	
#arguments:
#	$a0 - name of file to read
#	$a1, $a2 - flags
#	$a3 - address to which file will be read

#open file to get file size
	li $v0, 13
        li $a1, 0		# flags: 0-read file
        li $a2, 0		# mode: ignored
        syscall
	move $s1, $v0      	# save the file descriptor
	bltz $v0, file_not_found 	# if there's no file with name stated in fname
	move $t0, $a0

#read file to get file size
	li $v0, 14
	move $a0, $s1
	la $a1, ($a3)
	li $a2, 6		# allocate memory for descriptor fragment to get the file size
	syscall

#close file
	li $v0, 16
	move $a0, $s1
        syscall

#allocate memory for file   
	lhu $a0, 2($a3)	# full size
	li $v0, 9
	syscall		# sbrk
	move $t4, $a0	# save file size
	move $t3, $v0	# save memory address
	sw $t3, image1
	la $a3, image1
        
#open file
	move $a0, $t0
	li $v0, 13
        li $a1, 0		# flags: 0-read file
        li $a2, 0		# mode: ignored
        syscall

#read file
	li $v0, 14
	move $a0, $s1
	la $a1, ($a3)
        lhu $a2, 2($a3)		# file size
	syscall

#close file
	li $v0, 16
	move $a0, $s1
        syscall
        
	jr $ra
	
# get pixel ====================================================================================================
	
get_pixel:
#	$a0 - x coordinate
#	$a1 - y coordinate - (0,0) - bottom left corner
#	$a2 - image descriptor
# return value:
#	$v0 - 0RGB - pixel color


	lb $t2, 10($a2)		# file offset to pixel array
	la $t1, ($a2)		# adress of bitmapp
	add $t2, $t1, $t2	# adress of pixel array in $t2
	
	lhu $t1, 18($a2) 	# save img width in $t1
	mul $t1, $t1, 3 	# save amount of bytes per row in $t1
	mul $t1, $a1, $t1 	# t1= y*(bytes per row)
	move $t3, $a0		
	sll $a0, $a0, 1
	add $t3, $t3, $a0	# $t3= 3*x
	add $t1, $t1, $t3	# $t1 = 3x + y*BYTES_PER_ROW
	add $t2, $t2, $t1	# pixel address 
	
	#get color
	lbu $v0,($t2)		# load B
	lbu $s5,($t2)		# save B
	lbu $t1,1($t2)		# load G
	lbu $s6,1($t2)		# save G
	sll $t1,$t1,8
	or $v0, $v0, $t1
	lbu $t1,2($t2)		# load R
	lbu $s7,2($t2)		# save R
        sll $t1,$t1,16
	or $v0, $v0, $t1
	
	jr $ra

file_not_found:
	li $v0, 4
	la $a0, filenotfoundmsg
	syscall
	
	# call for end of program
	li $v0, 10
	syscall
