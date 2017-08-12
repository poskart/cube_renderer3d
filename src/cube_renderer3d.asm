.globl   main 
        .data 
intro:  .ascii   "Renderer 3D\n" 
        .ascii   "Piotr Poskart\n" 
        .asciiz  "wersja 0.001\n" 
str1:	.ascii	"Podaj kat obrotu wokol osi x:\n"
	.asciiz	"Kat (Ox) : \n"
str2:	.ascii	"Podaj kat obrotu wokol osi y:\n"
	.asciiz	"Kat (Oy) : \n"
str3:	.ascii	"Podaj kat obrotu wokol osi z:\n"
	.asciiz	"Kat (Oz) : \n"
str4:	.ascii	"Podaj przemieszczenie wzdluz osi x:\n"
	.asciiz	"Dx : \n"
str5:	.ascii	"Podaj przemieszczenie wzdluz osi y:\n"
	.asciiz	"Dy : \n"
str6:	.ascii	"Podaj przemieszczenie wzdluz osi z:\n"
	.asciiz	"Dz : \n"
endl:	.asciiz	"\n"
coma:	.asciiz	", "

inputFile:	.asciiz	"wej.bmp"
outputFile:	.asciiz	"wyj.bmp"
opened:		.asciiz "Plik zostal pomyslnie otwarty\n"
err1:		.asciiz "Blad odczytu pliku zrodlowego\n"
err2:		.asciiz "Blad tworzenia pliku docelowego\n"

header:		.space 138
map:		.space 1240000		#1228800

xScreenSize:	.word	640
yScreenSize:	.word	480
xHalfScreenSize:	.word	320
yHalfScreenSize:	.word	240

accuracy:	.float	1.0e-6 
Rx:	.space	64
Ry:	.space	64
Rz:	.space	64
Tr:	.space	64
Scale:	.space	64
TrScreen: .space	64
LookMtx:.space	64
ProjMtx:.space	64	
Mtx1:	.space	64	#matrix for saving outcome of comuting 1
Mtx2:	.space	64	#matrix for saving outcome of comuting 2
Nodes:	.space	128	#addresses of cube nodes
# nodes are vectors 4x1 stored linear in the memory, one after another
NewNodes: .space	128	# auxiliary space for nodes 
points:	.space	240000	# space for points coordinates (x, y ), each 4 bytes
one:	.float	1.0
pi_2:	.float	1.5708
minus1:	.float	-1.0
zero:	.float	0.0
Look3_4:.float	-10.0

# scale coefficient
ScaleCoefficient:	.float	5.0

#___Nonzero projection matrix coefficients___# :	
PM_11:	.float	200.0
PM_22:	.float	200.0
PM_33:	.float	-1.2
PM_34:	.float	-2.2
PM_43:	.float	-1.0

#___Nonzero coefficients of the transformation (to the screen 640 x 480) matrix ___#
TScM_14:	.float	320.0
TScM_24:	.float	240.0
	
	
debug:	.asciiz	"\n\n_______________Debug line _________ :\n\n"
	
	
# 
#       void main ( void ) 
# 
        .text 
main:   la       $v0,4                          # print_str 
la       $a0,intro                     		# a0 text address 
	syscall
	
 ########### fill coordinates of each node (x, y, z) #########
 	
	l.s	$f1, one
	l.s	$f2, minus1
	la	$t0, Nodes
	
	swc1	$f2, 0($t0)			# node 1 x 
	swc1	$f2, 4($t0)			# node 1 y 
	swc1	$f2, 8($t0)			# node 1 z 
	swc1	$f1, 12($t0)			# w coefficient
	
	swc1	$f1, 16($t0)			# node 2 x 
	swc1	$f2, 20($t0)			# node 2 y 
	swc1	$f2, 24($t0)			# node 2 z ....etc
	swc1	$f1, 28($t0)
	
	swc1	$f1, 32($t0)			 
	swc1	$f1, 36($t0)			
	swc1	$f2, 40($t0)	
	swc1	$f1, 44($t0)
	
	swc1	$f2, 48($t0)			 
	swc1	$f1, 52($t0)			
	swc1	$f2, 56($t0)
	swc1	$f1, 60($t0)	
	
	swc1	$f2, 64($t0)			# 5	 
	swc1	$f2, 68($t0)			
	swc1	$f1, 72($t0)
	swc1	$f1, 76($t0)
	
	swc1	$f1, 80($t0)			 
	swc1	$f2, 84($t0)			
	swc1	$f1, 88($t0)
	swc1	$f1, 92($t0)
	
	swc1	$f1, 96($t0)			 
	swc1	$f1, 100($t0)			
	swc1	$f1, 104($t0)
	swc1	$f1, 108($t0)
	
	swc1	$f2, 112($t0)			 
	swc1	$f1, 116($t0)			
	swc1	$f1, 120($t0)			# node 8 
	swc1	$f1, 124($t0)
	
########### read Rx angle value #########
	la       $v0,4                       
        la       $a0,str1                     
	syscall

	la	$v0, 6
	syscall
     

anglesX:
	mov.s	$f6, $f0		# store input angle Ox value in $f6
	jal	sinus			# compute sine
	mov.s	$f5, $f12		# save sin(x) in $f5

	mov.s	$f0, $f6
	jal	cosinus	
	mov.s	$f6, $f12

fillRx:	
	la	$t0, Rx			# load start address of the Rx matrix
	l.s	$f1, one		
	swc1	$f1, Rx			# Rx(1,1) = 1
	#sw	$0, 4($t0)
	#sw	$0, 8($t0)
	#sw	$0, 12($t0)
	
	#sw	$0, 16($t0)
	swc1	$f6, 20($t0)		# cos	
		
	mov.s	$f0, $f5
	jal	minus
	mov.s	$f7, $f0
	swc1	$f7, 24($t0)		# -sin	
	#sw	$0, 28($t0)
	
	#sw	$0, 32($t0)
	swc1	$f5, 36($t0)		# sin
	swc1	$f6, 40($t0)		# cos
	#sw	$0, 44($t0)
	
	#sw	$0, 48($t0)
	#sw	$0, 52($t0)
	#sw	$0, 56($t0)
	swc1	$f1, 60($t0)		# 1

 ########### read Ry angle value #########
	la       $v0,4                        # print_str 
        la       $a0,str2                     # a0 text address 
	syscall

	la	$v0, 6
	syscall

anglesY:
	mov.s	$f6, $f0		# store input angle Oy value in $f6
	jal	sinus			# compute sine
	mov.s	$f5, $f12		# save sin in $f5

	mov.s	$f0, $f6
	jal	cosinus	
	mov.s	$f6, $f12		#save cos in $f6

fillRy:	
	la	$t0, Ry			# load start address of the Rx matrix
	
	swc1	$f6, 0($t0)		# cos
	sw	$0, 4($t0)
	mov.s	$f0, $f5
	jal	minus
	mov.s	$f7, $f0
	swc1	$f7, 8($t0)		# -sin	
	sw	$0, 12($t0)
	
	sw	$0, 16($t0)
	l.s	$f1, one		
	swc1	$f1, 20($t0)		# Rx(2,2) = 1
	sw	$0, 24($t0)
	sw	$0, 28($t0)
	
	swc1	$f5, 32($t0)
	sw	$0, 36($t0)
	swc1	$f6, 40($t0)
	sw	$0, 44($t0)
	
	sw	$0, 48($t0)
	sw	$0, 52($t0)
	sw	$0, 56($t0)
	swc1	$f1, 60($t0)		# 1


 ########### read Rz angle value #########
	la       $v0,4                        # print_str 
        la       $a0,str3                     # a0 text address
	syscall

	la	$v0, 6
	syscall

anglesZ:
	mov.s	$f6, $f0		# store input angle Oz value in $f6
	jal	sinus			# compute sine
	mov.s	$f5, $f12		# save sin in $f5

	mov.s	$f0, $f6
	jal	cosinus	
	mov.s	$f6, $f12		#save cos in $f6

fillRz:	
	la	$t0, Rz			# load start address of the Rz matrix
	
	swc1	$f6, 0($t0)		# cos
	mov.s	$f0, $f5
	jal	minus
	mov.s	$f7, $f0
	swc1	$f7, 4($t0)		# -sin	
	sw	$0, 8($t0)
	sw	$0, 12($t0)

	swc1	$f5, 16($t0)
	swc1	$f6, 20($t0)
	sw	$0, 24($t0)
	sw	$0, 28($t0)	
	
	sw	$0, 32($t0)
	sw	$0, 36($t0)
	l.s	$f1, one		
	swc1	$f1, 40($t0)		# Rx(3,3) = 1
	sw	$0, 44($t0)
	
	sw	$0, 48($t0)
	sw	$0, 52($t0)
	sw	$0, 56($t0)
	swc1	$f1, 60($t0)		# 1

########### read Translation dx, dy, dz values #########
translations:				  # gets data about cube position:	x, y, z

la       $v0,4                      	      # print_str 
        la       $a0,str4                     # a0 text address
	syscall
	la	$v0, 6
	syscall	
	mov.s	$f4, $f0			#save dx in $f4
	
	la       $v0,4                        # print_str 
        la       $a0,str5                     # a0 text address
	syscall
	la	$v0, 6
	syscall	
	mov.s	$f5, $f0			#save dy in $f5
	
	la       $v0,4                        # print_str 
        la       $a0,str6                     # a0 text address 
	syscall
	la	$v0, 6
	syscall	
	mov.s	$f6, $f0			#save dz in $f6
		
fillTr:					# fill transformation matrix
	la	$t0, Tr			# load start address of the Tr matrix
	l.s	$f1, one		
	swc1	$f1, Tr			# Tr(1,1) = 1
	sw	$0, 4($t0)
	sw	$0, 8($t0)
	swc1	$f4, 12($t0)		# dx

	sw	$0, 16($t0)
	swc1	$f1, 20($t0)	
	sw	$0, 24($t0)
	swc1	$f5, 28($t0)		# dy
	
	sw	$0, 32($t0)
	sw	$0, 36($t0)
	swc1	$f1, 40($t0)
	swc1	$f6, 44($t0)		# dz

	sw	$0, 48($t0)
	sw	$0, 52($t0)
	sw	$0, 56($t0)
	swc1	$f1, 60($t0)		# 1

####_______Fill scale matrix_____####
	la	$t0, Scale			# load start address of the Scale matrix
	
	l.s	$f0, zero
	l.s	$f1, ScaleCoefficient
	l.s	$f3, one
		
	swc1	$f1, ($t0)
	swc1	$f0, 4($t0)
	swc1	$f0, 8($t0)	
	swc1	$f0, 12($t0)		

	swc1	$f0, 16($t0)
	swc1	$f1, 20($t0)
	swc1	$f0, 24($t0)	
	swc1	$f0, 28($t0)

	swc1	$f0, 32($t0)
	swc1	$f0, 36($t0)
	swc1	$f1, 40($t0)	
	swc1	$f0, 44($t0)

	swc1	$f0, 48($t0)
	swc1	$f0, 52($t0)
	swc1	$f0, 56($t0)	
	swc1	$f3, 60($t0)

####_______Fill view matrix_____####
	la	$t0, LookMtx			# load start address of the LookMtx matrix
	
	l.s	$f0, zero
	l.s	$f1, Look3_4
	l.s	$f3, one
		
	swc1	$f3, ($t0)
	swc1	$f0, 4($t0)
	swc1	$f0, 8($t0)	
	swc1	$f0, 12($t0)		

	swc1	$f0, 16($t0)
	swc1	$f3, 20($t0)
	swc1	$f0, 24($t0)	
	swc1	$f0, 28($t0)

	swc1	$f0, 32($t0)
	swc1	$f0, 36($t0)
	swc1	$f3, 40($t0)	
	swc1	$f1, 44($t0)

	swc1	$f0, 48($t0)
	swc1	$f0, 52($t0)
	swc1	$f0, 56($t0)	
	swc1	$f3, 60($t0)


####_______Fill projection matrix_____####
	la	$t0, ProjMtx			# load start address of the ProjMtx matrix
	
	l.s	$f0, zero
	l.s	$f1, PM_11
	l.s	$f2, PM_22
	l.s	$f3, PM_33
	l.s	$f4, PM_34
	l.s	$f5, PM_43
		
	swc1	$f1, ($t0)
	swc1	$f0, 4($t0)
	swc1	$f0, 8($t0)	
	swc1	$f0, 12($t0)		

	swc1	$f0, 16($t0)
	swc1	$f2, 20($t0)
	swc1	$f0, 24($t0)	
	swc1	$f0, 28($t0)

	swc1	$f0, 32($t0)
	swc1	$f0, 36($t0)
	swc1	$f3, 40($t0)	
	swc1	$f4, 44($t0)

	swc1	$f0, 48($t0)
	swc1	$f0, 52($t0)
	swc1	$f5, 56($t0)	
	swc1	$f0, 60($t0)
	
####_______Fill on the screen projection matrix (640 x 480) _____####
	la	$t0, TrScreen			# load start address of the TrScreen matrix
	
	l.s	$f4, TScM_14
	l.s	$f5, TScM_24
	
	l.s	$f1, one		
	swc1	$f1, 0($t0)			# TrScreen(1,1) = 1
	sw	$0, 4($t0)
	sw	$0, 8($t0)
	swc1	$f4, 12($t0)		# dx

	sw	$0, 16($t0)
	swc1	$f1, 20($t0)	
	sw	$0, 24($t0)
	swc1	$f5, 28($t0)		# dy
	
	sw	$0, 32($t0)
	sw	$0, 36($t0)
	swc1	$f1, 40($t0)
	sw	$0, 44($t0)		# dz

	sw	$0, 48($t0)
	sw	$0, 52($t0)
	sw	$0, 56($t0)
	swc1	$f1, 60($t0)		# 1

####_______Matrices multiplication: Proj * LookMtx * Rx * Ry * Rz * Tr_____####
	
	la	$s0, Ry
	la	$s1, Scale
	la	$s2, Mtx1
	jal	AxB			# Ry * Scale
	
	la	$s0, Rx
	la	$s1, Mtx1
	la	$s2, Mtx2
	jal	AxB			# Rx * Ry * Scale
	
	la	$s0, Rz
	la	$s1, Mtx2
	la	$s2, Mtx1
	jal	AxB			# Rz * Rx * Ry * Scale
	
	la	$s0, Tr
	la	$s1, Mtx1
	la	$s2, Mtx2
	jal	AxB			# Tr * Rz * Rx * Ry * Scale
	
	la	$s0, LookMtx
	la	$s1, Mtx2
	la	$s2, Mtx1
	jal	AxB			# View * Tr * Rz * Rx * Ry * Scale
	
	la	$s0, ProjMtx
	la	$s1, Mtx1
	la	$s2, Mtx2
	jal	AxB			# Proj * View * Tr * Rz * Rx * Ry * Scale
	
####_______Multiply cube nodes coordinates vectors by resultant transformation matrix Mtx1_____####

	la	$s0, Mtx2
	la	$s1, Nodes
	la	$s2, NewNodes
	li	$a3, 0			#counter
	
mainLoop:
	beq	$a3, 8, koniecMnozeniaProjMtx
	
	jal	Axv

	addiu	$a3, $a3, 1
	addiu	$s1, $s1, 16
	addiu	$s2, $s2, 16
	
	j	mainLoop
	
koniecMnozeniaProjMtx:


####_______Multiplication of cube nodes coordinates vectors by projection on the screen matrix (640 x 480) - translation in (320, 240) _____####
	la	$s0, TrScreen
	la	$s1, NewNodes
	la	$s2, Nodes
	li	$a3, 0			#counter
	
TrScreenLoop:
	beq	$a3, 8, koniecMnozeniaTrScreen
	
	jal	Axv

	addiu	$a3, $a3, 1
	addiu	$s1, $s1, 16
	addiu	$s2, $s2, 16
	
	j	TrScreenLoop
	
koniecMnozeniaTrScreen:

####_______Divide coordinates Vx and Vy of the cube nodes by perspective (distance) coefficient W_____####

	la	$s2, Nodes
	li	$a3	0

dzieleniePrzezW:
	beq	$a3, 8, koniecDzielenia
	
	l.s	$f1, 0($s2)		# load Vx
	l.s	$f2, 4($s2)		# load Vy
	l.s	$f3, 12($s2)		# load W
	div.s	$f4, $f1, $f3		# f4 = f1/f3	(Vx/W)
	div.s	$f5, $f2, $f3		# f5 = f2/f3	(Vy/W)
	
	swc1	$f4, 0($s2)	
	swc1	$f5, 4($s2)	
	
	addiu	$a3, $a3, 1
	addiu	$s2, $s2, 16
	
	j	dzieleniePrzezW
koniecDzielenia:


#__________ Transform nodes coordinates to 2D (x, y)
	la	$s1, Nodes
	la	$s2, Nodes
	addiu	$s2, $s2, 128
	la	$s3, points
	jal	ConvertPointsTo2D	# $s3 indicates first free bytes after last 2D point
	
#__________ Normalize coordinates to bitmap size x, y _____________#
	la	$s2, ($s3)	# take first empty byte after 2D points into s2
	la	$s1, points	
	jal	NormalizeToBitmapSize
	
####_______ Searching for intermediate points between cube nodes - creating the lines ______####
	
	la	$a3, 0($s3)
	
	lw	$a1, points		# pointt 1 x
	lw	$s1, points+4($0)	# point 1 y
	lw	$a2, points+8($0)	# pointt 2 x
	lw	$s2, points+12($0)	# point 2 y
	jal	DzielPkt
	
	lw	$a1, points		# pointt 1 x
	lw	$s1, points+4($0)	# point 1 y
	lw	$a2, points+24($0)	# pointt 4 x
	lw	$s2, points+28($0)	# point 4 y
	jal	DzielPkt
	
	lw	$a1, points		# pointt 1 x
	lw	$s1, points+4($0)	# point 1 y
	lw	$a2, points+32($0)	# pointt 5 x
	lw	$s2, points+36($0)	# point 5 y
	jal	DzielPkt
	
	lw	$a1, points+16($0)	# 3 & 4
	lw	$s1, points+20($0)	
	lw	$a2, points+24($0)		
	lw	$s2, points+28($0)	
	jal	DzielPkt

	lw	$a1, points+16($0)	# 3 & 7
	lw	$s1, points+20($0)	
	lw	$a2, points+48($0)		
	lw	$s2, points+52($0)	
	jal	DzielPkt
	
	lw	$a1, points+16($0)	# 3 & 2
	lw	$s1, points+20($0)	
	lw	$a2, points+8($0)		
	lw	$s2, points+12($0)	
	jal	DzielPkt
	
	lw	$a1, points+56($0)	# 8 & 7
	lw	$s1, points+60($0)	
	lw	$a2, points+48($0)		
	lw	$s2, points+52($0)	
	jal	DzielPkt
	
	lw	$a1, points+56($0)	# 8 & 4
	lw	$s1, points+60($0)	
	lw	$a2, points+24($0)		
	lw	$s2, points+28($0)	
	jal	DzielPkt
	
	lw	$a1, points+56($0)	# 8 & 5
	lw	$s1, points+60($0)	
	lw	$a2, points+32($0)		
	lw	$s2, points+36($0)	
	jal	DzielPkt
	
	lw	$a1, points+40($0)	# 6 & 2
	lw	$s1, points+44($0)	
	lw	$a2, points+8($0)		
	lw	$s2, points+12($0)	
	jal	DzielPkt
	
	lw	$a1, points+40($0)	# 6 & 5
	lw	$s1, points+44($0)	
	lw	$a2, points+32($0)		
	lw	$s2, points+36($0)	
	jal	DzielPkt
	
	lw	$a1, points+40($0)	# 6 & 7
	lw	$s1, points+44($0)	
	lw	$a2, points+48($0)		
	lw	$s2, points+52($0)	
	jal	DzielPkt

# Print x vectors 2x1
	la	$s1, points
	la	$s2, ($s3)
		
ShiftVector2DLoop:
	beq	$s1, $s2, koniecSprawdzania2DWektorow
	
	lw	$a0, 0($s1)
	la	$v0, 1
	syscall
	la	$a0, coma
	la	$v0, 4
	syscall
	lw	$a0, 4($s1)
	la	$v0, 1
	syscall
	la	$a0, endl
	la	$v0, 4
	syscall
	
	addiu	$s1, $s1, 8	
	j	ShiftVector2DLoop
	
koniecSprawdzania2DWektorow:
# Print 8 vectors 2x1 ______END______

### ________________________________  BMP FILE HANDLING ________________________________________###


		
		la 	$a0, inputFile	# (input.bmp)
    		li 	$a1, 0		# set flag
    		li 	$a2, 0		# set mode
    		li 	$v0, 13		# open input file
    		syscall
    		
    		move 	$s0, $v0	# s0 = file descriptor(input.bmp)
    		
		move 	$a0, $s0
		la 	$a1, header
		li 	$a2, 138
		li	$v0, 14		# read header from input.bmp file
		syscall
		
		li	$v0, 14		# read the rest(map) from input.bmp file
		move 	$a0, $s0
		la 	$a1, map
		li 	$a2, 1228800
		syscall
		
		li 	$v0, 16		# close input.bmp file
		move 	$a0, $0
		syscall
		
# _____________________________________ INSERTING NEW POINTS TO BITMAP ___________________________________________#
		
		la	$s1, points
		la	$s2, 0($a3)
		jal	storeVertex
		
		
# ________________ SAVING RESULT FILE _________________________#
				
		la 	$a0, outputFile	# .
		li	$a1, 1		# set flag: 1 for write-only with create
		li 	$a2, 0		# set mode
		li 	$v0, 13		# open output.bmp file
		syscall
		
		move 	$s0, $v0	# s0 = file descriptor(output.bmp)
		
		li 	$v0, 15		# write header to output.bmp file
		move	$a0, $s0
		la 	$a1, header
		li	$a2, 138
		syscall

		li	$v0, 15		# write map to output.bmp file
		move	$a0, $s0
		la	$a1, map
		li	$a2, 1228800
		syscall
	
		li	$v0, 16		# close output.bmp file
		move	$a0, $s0
		syscall

j	theend

#####________________________________________________________________________  THE   END  ________________________________________________________________________##### 

###########################################################################
sinus:					#input x in $f0, output in $f12
	li	 $t0,3 			 # Initilize N
	l.s	 $f4,accuracy		 # Set Accuracey
	
	mul.s	 $f2,$f0,$f0		 # x^2
	mov.s	 $f12,$f0		 # Answer
	forsin:
	abs.s 	 $f1,$f0		 # compares to the non-negative value of the series
	c.lt.s	 $f1,$f4		 # is number < 1.0e-6?
	bc1t endsin
	subu 	 $t1,$t0,1		 # (n-1)
	mul 	 $t1,$t1,$t0		 # n(n-1)
	mtc1	 $t1, $f3		 # move n(n-1) to a floating register
	cvt.s.w	 $f3, $f3 		 # converts n(n-1) to a float
	div.s	 $f3,$f2,$f3 		 # (x^2)/(n(n-1))
	neg.s 	 $f3,$f3		 # -(x^2)/(n(n-1))
	mul.s	 $f0,$f0,$f3 		 # (Series*x^2)/(n(n-1))
	
	add.s  	 $f12,$f12,$f0		 # Puts answer into $f12
	
	addu 	 $t0,$t0,2			 # Increment n
	b forsin				 # Goes to the beggining of the loop
	endsin:
	jr	$ra			#output in $f12
###########################################################################
cosinus:				#input x in $f0, output in $f12
	l.s	$f20, pi_2
	add.s 	$f0,$f0,$f20	
	
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	sinus	
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	jr	$ra
###########################################################################
theend:
	la	$v0, 10
	syscall

minus:		#input in $f0, used registers: $f31 , output: $f0
	l.s	$f31, minus1
	mul.s	$f0, $f0, $f31
	jr	$ra

####_____Matrix multiplication____####
AxB:	# procedura do mnozenia macierzy A i B o rozmiarach 4x4, adresy macierzy w pamieci: $s0 - A, $s1 - B, $s2 - W
	li	$t3, 0		# licznik do 16	
	li	$t4, 0		#licznik do 4 (licznik dodawan w mno?eniu wiersz A * kolumna B)
	li	$t5, 0		#licznik do 4 (zmiana kolumny i zmiana wiersza) - bedzie 4 razy liczyl do 4
	la	$t0, ($s0)
	la	$t1, ($s1)
	la	$t2, ($s2)
	la	$t7, ($s1)	#wskaznik aktualnej kolumny macierzy B
	la	$t6, ($s0)	#wskaznik aktywnego wiersza macierzy A
	l.s	$f3, zero	#set $f3 to zero - auxiliary variable
		loopAxB:	
		lwc1	$f0, 0($t0)
		lwc1	$f1, 0($t1)
		mul.s	$f2, $f1, $f0
		add.s	$f3, $f3, $f2
		addiu	$t0, $t0, 4
		addiu	$t1, $t1, 16
		addiu	$t4, $t4, 1
		bne	$t4, 4, loopAxB
	nextValue:
	swc1	$f3, 0($t2)	#zapisz wartosc
	addiu	$t2, $t2, 4	# inkrementuj miejsce docelowe w pamieci
	l.s	$f3, zero	# wyzeruj $f3
	beq	$t3, 15, endAxB	#jelezi 15 to koniec
	li	$t4, 0		# zerowanie licznika najglebszej petli
	addiu	$t3, $t3, 1	# licznik ogólny
	addiu	$t5, $t5, 1	# licznik czwórek (4x4)
	beq	$t5, 4, changeColAndRow		#co 4 zmien kolumne (powrot do pierwszej) oraz inkrementuj wiersz
	la	$t0, ($t6)	#zeruj wskaznik wiersza po dodawaniu
	addiu	$t7, $t7, 4	#zwieksz wskaznik kolumny (kolejna kolumna)
	la	$t1, ($t7)	
	ifChanged:
	j	loopAxB	
	
	changeColAndRow:
	addiu	$t6, $t6, 16	#change row
	la	$t7, ($s1)
	la	$t1, ($t7)
	li	$t5, 0		#zerowanie licznika czwórek
	j	ifChanged
	
endAxB:
jr	$ra
	
	
####_____Matrix by vector multiplication____####
Axv:	#procedura do mnozenia Macierzy A przez wektor v,  adresy macierzy w pamieci: $s0 - A, $s1 - v, $s2 - W
li	$t3, 0		# licznik do 16	
	li	$t4, 0		#licznik do 4 (licznik dodawan w mno?eniu wiersz A * kolumna B)
	la	$t0, ($s0)
	la	$t1, ($s1)
	la	$t2, ($s2)
	la	$t7, ($s0)	#wskaznik aktualnego wiersza
	l.s	$f3, zero	#set $f3 to zero - auxiliary variable
		loopAxv:	
		lwc1	$f0, 0($t0)
		lwc1	$f1, 0($t1)
		mul.s	$f2, $f1, $f0
		add.s	$f3, $f3, $f2
		addiu	$t0, $t0, 4
		addiu	$t1, $t1, 4
		addiu	$t4, $t4, 1
		beq	$t4, 4, nextValueV
		j	loopAxv
	nextValueV:
	swc1	$f3, 0($t2)	#zapisz wartosc
	addiu	$t2, $t2, 4	# inkrementuj miejsce docelowe w pamieci
	l.s	$f3, zero	# wyzeruj $f3
	beq	$t3, 3, endAxv	#jelezi 15 to koniec
	li	$t4, 0		# zerowanie licznika najglebszej petli
	addiu	$t3, $t3, 1	# licznik ogólny
	addiu	$t7, $t7, 16
	la	$t0, ($t7)
	la	$t1, ($s1)
	j	loopAxv	
	
endAxv:
jr	$ra	


#____________________ STORE POINTS (VECTORS) INTO BITMAP _____________________#

# input $s1 - start address of vertex'es
# 	$s2 - address of the end of the vertex'es
storeVertex:
	li	$s5, 0		# $s5 is used as the only color byte in RGB
	la	$s3, map
	li	$t3, 4		# x direction pixel shift
	li	$t4, 2560	# y direction pixel shift	640*4 (bytes)
	
storeVloop:
	beq	$s1, $s2, VloopEnd
	lw	$t0, 0($s1)
	lw	$t1, 4($s1)
	
	mult	$t0, $t3
	mfhi	$t5
	bgt	$t5, 0, nextPixel		#if coordinates out of range, jump to end
	mflo	$t5
	
	mult	$t1, $t4
	mfhi	$t6
	bgt	$t6, 0, nextPixel		#if coordinates out of range, jump to end
	mflo	$t6
	
	add	$t7, $t5, $t6
	bge	$t7, 1228800, nextPixel
	
	sb	$s5, map+0($t7)
	sb	$s5, map+1($t7)
	sb	$s5, map+2($t7)
nextPixel:	
	addiu	$s1, $s1, 8
	j	storeVloop
VloopEnd:	
	jr	$ra


# Function which changes float 4x1 vectors to int 2x1 vectors (x, y)
# input $s1 - start address of float vertex'es
# 	$s2 - address of the end of float vertex'es
#	#s3 - the initial address of the place in memory to store 2D points
ConvertPointsTo2D:
Store2DLoop:
	beq	$s1, $s2, Store2DEnd
	lwc1	$f2, 0($s1)
	lwc1	$f3, 4($s1)
	round.w.s	$f0, $f2
	round.w.s	$f1, $f3
	mfc1	$t0, $f0
	mfc1	$t1, $f1
	
	sw	$t0, 0($s3)
	sw	$t1, 4($s3)
	addiu	$s3, $s3, 8
	addiu	$s1, $s1, 16
	j	Store2DLoop
Store2DEnd:
	jr	$ra

# Normalize coordinates (x, y) of the nodes, which are out of the bitmap and project it onto bitmap borders
# $s1 - adres pierwszego punktu
# $s2 - adres za ostatnim punktem
NormalizeToBitmapSize:
NormalizeLoop:	
	beq	$s1, $s2, NormalizeEnd
	lw	$t1, 0($s1)
	lw	$t2, 4($s1)
	lw	$t3, xHalfScreenSize
	lw	$t4, yHalfScreenSize
	
	sub	$t5, $t1, $t3	
	abs	$t5, $t5
	bgt	$t5, $t3, NormToX
dalejY:
	sub	$t6, $t2, $t4	
	abs	$t6, $t6
	bgt	$t6, $t4, NormToY
dalejNorm:
	sw	$t1, 0($s1)
	sw	$t2, 4($s1)
	
	addiu	$s1, $s1, 8
	j	NormalizeLoop	
NormalizeEnd:
	jr 	$ra

NormToX:
	mtc1	$t1, $f11 
	mtc1	$t2, $f12
	mtc1	$t3, $f13
	mtc1	$t4, $f14
	cvt.s.w	$f1, $f11
	cvt.s.w	$f2, $f12
	cvt.s.w	$f3, $f13		# ScX in f3
	cvt.s.w	$f4, $f14		# ScY in f4
	sub.s	$f5, $f1, $f3
	mov.s	$f11, $f5		# store x_sr in f11
	sub.s	$f6, $f2, $f4
	mov.s	$f12, $f6		# store y_sr in f12
	
	abs.s	$f5, $f5		
	div.s	$f5, $f5, $f3		# $f5 - coefficient
	
	div.s	$f7, $f11, $f5
	add.s	$f7, $f7, $f3		# x_rz = x_sr/Coeff + ScX
	div.s	$f8, $f12, $f5
	add.s	$f8, $f8, $f4		# y_rz = y_sr/Coeff + ScY
	round.w.s	$f1, $f7
	round.w.s	$f2, $f8
	mfc1	$t1, $f1
	mfc1	$t2, $f2	
	j	dalejY

NormToY:
	mtc1	$t1, $f11 
	mtc1	$t2, $f12
	mtc1	$t3, $f13
	mtc1	$t4, $f14
	cvt.s.w	$f1, $f11
	cvt.s.w	$f2, $f12
	cvt.s.w	$f3, $f13		# ScX in f3
	cvt.s.w	$f4, $f14		# ScY in f4
	sub.s	$f5, $f1, $f3
	mov.s	$f11, $f5		# store x_sr in f11
	sub.s	$f6, $f2, $f4
	mov.s	$f12, $f6		# store y_sr in f12
	
	abs.s	$f6, $f6		
	div.s	$f6, $f6, $f4		# $f5 - coefficient
	
	div.s	$f7, $f11, $f6
	add.s	$f7, $f7, $f3		# x_rz = x_sr/Coeff + ScX
	div.s	$f8, $f12, $f6
	add.s	$f8, $f8, $f4		# y_rz = y_sr/Coeff + ScY
	round.w.s	$f1, $f7
	round.w.s	$f2, $f8
	mfc1	$t1, $f1
	mfc1	$t2, $f2	
	j	dalejNorm

# Creates points between points ($a1, $s1) i ($a2, $s2) and saves to memory space pointed by $a3 (next point every 8 bytes)
# after execution a3 if the first free byte behind these points 
DzielPkt:			
	subu	$t4, $a2, $a1
	abs	$t6, $t4
	ble	$t6, 1, SprawdzY
dalejDziel:	
	subu	$sp, $sp, 20
	sw	$ra, 20($sp)
	sw	$a1, 16($sp)
	sw	$a2, 12($sp)
	sw	$s1, 8($sp)
	sw	$s2, 4($sp)
	jal	Dzielenie
	nop										
	
	subu	$sp, $sp, 8
	sw	$t5, 8($sp)
	sw	$t8, 4($sp)
	lw	$a1, 24($sp)
	lw	$s1, 16($sp)
	addi	$a2, $t5, 0
	addi	$s2, $t8, 0
	jal	DzielPkt
	nop

	lw	$t3, 8($sp)
	addi	$a1, $t3, 0
	lw	$t3, 4($sp)
	addi	$s1, $t3, 0
	lw	$a2, 20($sp)
	lw	$s2, 12($sp)
	jal	DzielPkt
	nop
	
	addu	$sp, $sp, 28
	lw	$ra, 0($sp)
	nop
koniecDzielPkt:
	jr	$ra

SprawdzY:
	subu	$t4, $s2, $s1
	abs	$t6, $t4
	ble	$t6, 1, koniecDzielPkt
	j	dalejDziel				# if |y1 - y2| > 1 divide further

Dzielenie:
	add	$t5, $a1, $a2
	div	$t5, $t5, 2
	
	add	$t8, $s1, $s2
	div	$t8, $t8, 2
	
	sw	$t5, ($a3)
	sw	$t8, 4($a3)
	addiu	$a3, $a3, 8
	
	la	$a0, ($t9)
	jr	$ra



		

