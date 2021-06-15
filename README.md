# ImageBlendingMIPS
Simple bmp image blending done in MIPS assembly language.

When there are images two bmp files named 'input1.bmp' and 'input2.bmp' 
in a folder with the project, the app blends 'input2.bmp' into 
'input1.bmp'. Blending is done by mixing pixel color in propotions 
50:50. The blending starts in the upper left corner of both images. The 
outcome has the size of 'input1.bmp'. Works for files with size less 
than 65KB.

Sample bmp files are included to repo. 

# TODO

- fix memory leakage caused by bad memory allocation 
- make taking file names from user possible
