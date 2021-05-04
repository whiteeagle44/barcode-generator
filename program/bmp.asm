.include "macros.asm"

#only 24-bits 600x50 pixels BMP files are supported
.eqv 	BMP_FILE_SIZE 90122 	# max num of characters to read
.eqv 	BYTES_PER_ROW 1800
.eqv 	STARTING_Y 15	 	# starting y cordinate of the bar
.eqv 	BLACK 0x00000000 	# black color

	.data
#space for the 600x50px 24-bits bmp image
.align 	4
res:	.space 	2
image:	.space 	BMP_FILE_SIZE

infile:	.asciiz "white.bmp"  #input file name
oufile: .asciiz "output.bmp" #output file name

error1: .asciiz  "Failed to open the white.bmp image file. \nRemember to place MARS.jar in the same location as the white.bmp image."
error2: .asciiz  "Width inputted out of range. Give integer 1, 2 or 3.\n"
error3: .asciiz "Character given is unsupported"
msg1: 	.asciiz  "Input the width in pixels of narrowest bar (1, 2 or 3):"
msg2: 	.asciiz  "Input the text to be encoded (1 to 9 characters):"
text: 	.space   10  # buffer where encoded text will be (max 9 chars)
arr1: 	.byte	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '-', '.',' ',
  '$', '/', '+', '%', '*' 
arr2: 	.half 	0x34, 0x121, 0x61, 0x160, 0x31, 0x130, 0x70, 0x25,  0x124,
0x64, 0x109, 0x49, 0x148, 0x19, 0x118, 0x58, 0xD, 0x10C, 0x4C, 
0x1C, 0x103, 0x43, 0x142, 0x13, 0x112, 0x52, 0x7, 0x106, 0x46, 
0x16, 0x181, 0xC1, 0x1C0, 0x91, 0x190, 0xD0, 0x85, 0x184, 0xC4,
0xA8, 0xA2, 0x8A, 0x2A, 0x94
	.text
main:
	jal	read_bmp
	
grab1: # grab first value from input (the width in pixels of narrowest bar)
	print(msg1)
	read_int()
	bgt 	$v0, 3, err2
	bge 	$v0, 1, grab2
err2:
	print(error2) 
	j  	grab1
grab2: # grab second value from input (text to be encoded)
	move	$s0, $v0
	print(msg2)
	read_string(text)
	# 'text' label now points to text to encode
	
	#start symbol
	li 	$a0, 10 		#x
	move 	$a1, $s0 	#width of the bar
	li 	$a2, '*'
	jal	put_char
	move 	$a0, $v0
	  
	#characters
	la 	$s1, text
	lbu	$a2, ($s1)
loop:	move	$a1, $s0
	jal 	put_char
	addu	$s2, $s2, $v1		#checksum additions
	move 	$a0, $v0

	addiu 	$s1, $s1, 1
	lbu 	$a2, ($s1)
	bge 	$a2, 32,  loop
	
	#checksum remainder calculation
	li	$t0, 43
	divu	$s2, $t0
	mfhi	$a2
	
	move 	$a0, $v0
	move 	$a1, $s0
	jal 	put_char_of_index
	move 	$a0, $v0

stop:	#stop symbol
	move 	$a1, $s0
	li 	$a2, '*'
	jal	put_char
		
	jal	save_bmp

exit:	li 	$v0,10		#Terminate the program
	syscall

# ============================================================================
read_bmp:
#description: 
#	reads the contents of a bmp file into memory
#arguments:
#	none
#return value: none
	sub 	$sp, $sp, 4		#push $ra to the stack
	sw 	$ra,($sp)
	sub 	$sp, $sp, 4		#push $s1
	sw 	$s1, ($sp)
#open file
	li 	$v0, 13
        la 	$a0, infile		#file name 
        li 	$a1, 0		#flags: 0-read file
        li 	$a2, 0		#mode: ignored
        syscall
	move 	$s1, $v0      # save the file descriptor
	
#check if file opened successfully
	bge 	$v0, $zero, read
	print(error1) 
	j  	exit

read:
#read file
	li 	$v0, 14
	move 	$a0, $s1
	la 	$a1, image
	li 	$a2, BMP_FILE_SIZE
	syscall

#close file
	li 	$v0, 16
	move 	$a0, $s1
        syscall
	
	lw	$s1, ($sp)		#restore (pop) $s1
	add 	$sp, $sp, 4
	lw 	$ra, ($sp)		#restore (pop) $ra
	add 	$sp, $sp, 4
	jr 	$ra

# ============================================================================
save_bmp:
#description: 
#	saves bmp file stored in memory to a file
#arguments:
#	none
#return value: none
	sub	$sp, $sp, 4		#push $ra to the stack
	sw	$ra,($sp)
	sub 	$sp, $sp, 4		#push $s1
	sw 	$s1, ($sp)
#open file
	li 	$v0, 13
        la 	$a0, oufile		#file name 
        li 	$a1, 1		#flags: 1-write file
        li 	$a2, 0		#mode: ignored
        syscall
	move 	$s1, $v0      # save the file descriptor
	
#check for errors - if the file was opened
#...

#save file
	li 	$v0, 15
	move 	$a0, $s1
	la	$a1, image
	li 	$a2, BMP_FILE_SIZE
	syscall

#close file
	li 	$v0, 16
	move	 $a0, $s1
        syscall
	
	lw 	$s1, ($sp)		#restore (pop) $s1
	add 	$sp, $sp, 4
	lw 	$ra, ($sp)		#restore (pop) $ra
	add 	$sp, $sp, 4
	jr 	$ra


# ============================================================================
put_pixel:
#description: 
#	sets the color of specified pixel to black
#arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate - (0,0) - bottom left corner
#return value: none

	sub	 $sp, $sp, 4		#push $ra to the stack
	sw 	$ra,($sp)

	la 	$t1, image + 10	#adress of file offset to pixel array
	lw 	$t2, ($t1)		#file offset to pixel array in $t2
	la 	$t1, image		#adress of bitmap
	add 	$t2, $t1, $t2	#adress of pixel array in $t2
	
	#pixel address calculation
	mul 	$t1, $a1, BYTES_PER_ROW #t1= y*BYTES_PER_ROW
	move	$t3, $a0		
	sll 	$a0, $a0, 1 
	add	$t3, $t3, $a0	#$t3= 3*x
	add 	$t1, $t1, $t3	#$t1 = 3x + y*BYTES_PER_ROW
	add 	$t2, $t2, $t1	#pixel address 
	
	li 	$t4, BLACK
	#set new color
	sb 	$t4,($t2)		#store B
	#srl 	$a2,$a2,8
	sb	$t4,1($t2)		#store G
	#srl	$a2,$a2,8
	sb 	$t4,2($t2)		#store R

	lw 	$ra, ($sp)		#restore (pop) $ra
	add 	$sp, $sp, 4
	jr	$ra
# ============================================================================
get_pixel:
#description: 
#	returns color of specified pixel
#arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate - (0,0) - bottom left corner
#return value:
#	$v0 - 0RGB - pixel color

	sub 	$sp, $sp, 4		#push $ra to the stack
	sw 	$ra,($sp)

	la 	$t1, image + 10	#adress of file offset to pixel array
	lw	$t2, ($t1)		#file offset to pixel array in $t2
	la 	$t1, image		#adress of bitmap
	add	$t2, $t1, $t2	#adress of pixel array in $t2
	
	#pixel address calculation
	mul	$t1, $a1, BYTES_PER_ROW #t1= y*BYTES_PER_ROW
	move	$t3, $a0		
	sll	$a0, $a0, 1  
	add	$t3, $t3, $a0	#$t3= 3*x
	add	$t1, $t1, $t3	#$t1 = 3x + y*BYTES_PER_ROW
	add	$t2, $t2, $t1	#pixel address 
	
	#get color
	lbu	$v0,($t2)		#load B
	lbu 	$t1,1($t2)		#load G
	sll	$t1,$t1,8
	or	$v0, $v0, $t1
	lbu	$t1,2($t2)		#load R
        sll	$t1,$t1,16
	or	$v0, $v0, $t1
					
	lw 	$ra, ($sp)		#restore (pop) $ra
	add	$sp, $sp, 4
	jr 	$ra

# ============================================================================
put_thin_bar:
#description: 
#	puts thin bar 
#arguments:
#	$a0 - x cordinate
#	$a1 - the width in pixels of narrowest bar 
#return value:
#	$v0 - x cordinate of the next character

	sub 	$sp, $sp, 4		#push $ra to the stack
	sw	$ra,($sp)
	sub 	$sp, $sp, 4		#push $s0
	sw 	$s0, ($sp)
	sub 	$sp, $sp, 4		#push $s1
	sw 	$s1, ($sp)
	sub 	$sp, $sp, 4		#push $s2
	sw 	$s2, ($sp)

	move 	$s0, $a0 # s0 - x cordinate
	move 	$s1, $a1 # s1 - width of bar
	li	$a1, STARTING_Y # starting y of the bar
	move 	$s2, $a1 # s2 - y cordinate
	
put_bar:
	jal 	put_pixel
	addiu 	$s2, $s2, 1
	move 	$a1, $s2
	move 	$a0, $s0
	ble 	$s2, 35, put_bar
	
next_x: 
	addiu 	$s0, $s0, 1
	move 	$a0, $s0
	subiu 	$s1, $s1, 1
	beqz 	$s1, exit_put_thin_bar
	li 	$s2, STARTING_Y 
	move 	$a1, $s2
	j 	put_bar

exit_put_thin_bar:
	move 	$v0, $a0
	
	lw 	$s2, ($sp)		#restore (pop) $s2
	add 	$sp, $sp, 4
	lw 	$s1, ($sp)		#restore (pop) $s1
	add 	$sp, $sp, 4
	lw 	$s0, ($sp)		#restore (pop) $s0
	add 	$sp, $sp, 4
	lw 	$ra, ($sp)		#restore (pop) $ra
	add	$sp, $sp, 4
	jr	$ra

# ============================================================================

put_thick_bar:
#description: 
#	puts thick bar 
#arguments:
#	$a0 - x cordinate
#	$a1 - the width in pixels of narrowest bar 
#return value:
#	$v0 - x cordinate of the next character

	sub 	$sp, $sp, 4		#push $ra to the stack
	sw	$ra,($sp)
	sub 	$sp, $sp, 4		#push $s0
	sw 	$s0, ($sp)
	sub 	$sp, $sp, 4		#push $s1
	sw 	$s1, ($sp)

	move 	$s0, $a0 # s0 - x cordinate
	move 	$s1, $a1 # s1 - width of bar
	
put_thin:
	jal 	put_thin_bar
	move	$a0, $v0
	move 	$a1, $s1
	jal 	put_thin_bar

exit_put_thick_bar:
	lw 	$s1, ($sp)		#restore (pop) $s1
	add 	$sp, $sp, 4
	lw 	$s0, ($sp)		#restore (pop) $s0
	add 	$sp, $sp, 4
	lw 	$ra, ($sp)		#restore (pop) $ra
	add	$sp, $sp, 4
	jr	$ra

# ============================================================================
put_char:
#description: 
#	puts bars and spaces unique to a given character
#arguments:
#	$a0 - x cordinate
# 	$a1 - the width in pixels of narrowest bar 
#	$a2 - character to put
#return value:
#	$v0 - x cordinate of the next character
#	$v1 - index of char searched in arr1 (for chechsum calc)

	sub 	$sp, $sp, 4		#push $ra to the stack
	sw 	$ra,($sp)
	sub 	$sp, $sp, 4		#push $s0
	sw 	$s0, ($sp)
	sub 	$sp, $sp, 4		#push $s1
	sw 	$s1, ($sp)
	sub 	$sp, $sp, 4		#push $s2
	sw 	$s2, ($sp)
	sub 	$sp, $sp, 4		#push $s3
	sw 	$s3, ($sp)
	sub 	$sp, $sp, 4		#push $s4
	sw 	$s4, ($sp)
	sub 	$sp, $sp, 4		#push $s5
	sw 	$s5, ($sp)
	sub 	$sp, $sp, 4		#push $s6
	sw 	$s6, ($sp)
	sub 	$sp, $sp, 4		#push $s7
	sw 	$s7, ($sp) 
	
	move	$s7, $a1

	la 	$s1, arr1 		# $s1 - address of arr1
	la 	$s3, arr2		# $s3 - address of arr2
	li	$t9, -1			# $t9 - to find $v1
ch_look: # look for char in 1st array
	addiu	$t9, $t9, 1
	lbu	$s2, ($s1)
	beq	$s2, $a2, ch_found
	addiu	$s1, $s1, 1
	addiu	$s3, $s3, 2
	bne	$s2, '*', ch_look
# character not found
	print(error3)
	li	$t9, 0
	j exit_put_char
	
ch_found: #character found, pointers s1 and s3 set to the character and sequence of bits respectively
	li	$s5, 0x100 # binary 100000000 (9-bit)
	lhu	$s4, ($s3)
ch_found2: 
	and	$s6, $s5, $s4
 	beq	$s6, $s5, draw_thick_bar
 	jal 	put_thin_bar	
 	move 	$a0, $v0
 	move 	$a1, $s7
 	j space
 	
draw_thick_bar:
	jal put_thick_bar
	move 	$a0, $v0
 	move 	$a1, $s7
	
space:
 	srl	$s5, $s5, 1
 	beqz	$s5, exit_put_char
	and	$s6, $s5, $s4
	beq	$s6, $s5, draw_thick_space
	srl	$s5, $s5, 1
	addu 	$a0, $a0, $s7
	j	 ch_found2
	
draw_thick_space:
 	srl	$s5, $s5, 1
 	li 	$t1, 0
	mul 	$t1, $s7, 2
	addu	$a0, $a0, $t1
	j 	ch_found2 

exit_put_char:
	li 	$t0, 0
	addu 	$t0, $a0, $a1
	move	$v0, $t0
	move	$v1, $t9

	lw 	$s7, ($sp)		#restore (pop) $s7
	add 	$sp, $sp, 4
	lw 	$s6, ($sp)		#restore (pop) $s6
	add 	$sp, $sp, 4
	lw 	$s5, ($sp)		#restore (pop) $s5
	add 	$sp, $sp, 4
	lw 	$s4, ($sp)		#restore (pop) $s4
	add 	$sp, $sp, 4
	lw 	$s3, ($sp)		#restore (pop) $s3
	add 	$sp, $sp, 4
	lw 	$s2, ($sp)		#restore (pop) $s2
	add 	$sp, $sp, 4
	lw 	$s1, ($sp)		#restore (pop) $s1
	add 	$sp, $sp, 4
	lw 	$s0, ($sp)		#restore (pop) $s0
	add 	$sp, $sp, 4
	lw 	$ra, ($sp)		#restore (pop) $ra
	add	$sp, $sp, 4
	jr	$ra
# ============================================================================

put_char_of_index:
#description: 
#	puts bars and spaces unique to a character of given index
#arguments:
#	$a0 - x cordinate
# 	$a1 - the width in pixels of narrowest bar 
#	$a2 - index of character to put
#return value:
#	$v0 - x cordinate of the next character
#	$v1 - index of char searched in arr1 (for chechsum calc)

	sub 	$sp, $sp, 4		#push $ra to the stack
	sw 	$ra,($sp)
	sub 	$sp, $sp, 4		#push $s0
	sw 	$s0, ($sp)
	sub 	$sp, $sp, 4		#push $s1
	sw 	$s1, ($sp)
	sub 	$sp, $sp, 4		#push $s2
	sw 	$s2, ($sp)
	sub 	$sp, $sp, 4		#push $s3
	sw 	$s3, ($sp)
	sub 	$sp, $sp, 4		#push $s4
	sw 	$s4, ($sp)
	sub 	$sp, $sp, 4		#push $s5
	sw 	$s5, ($sp)
	sub 	$sp, $sp, 4		#push $s6
	sw 	$s6, ($sp)
	sub 	$sp, $sp, 4		#push $s7
	sw 	$s7, ($sp) 
	
	move	$s7, $a1

	la 	$s1, arr1 		# $s1 - address of arr1
	la 	$s3, arr2		# $s3 - address of arr2
	li	$t9, -1			# $t9 - to find $v1
_ch_look: # look for char in 1st array
	addiu	$t9, $t9, 1
	beq	$t9, $a2, _ch_found
	addiu	$s1, $s1, 1
	addiu	$s3, $s3, 2
	bne	$a2, 43,  _ch_look
# character not found
	print(error3)
	li	$t9, 0
	j exit_put_char
	
_ch_found: #character found, pointers s1 and s3 set to the character and sequence of bits respectively
	li	$s5, 0x100 # binary 100000000 (9-bit)
	lhu	$s4, ($s3)
_ch_found2: 
	and	$s6, $s5, $s4
 	beq	$s6, $s5, _draw_thick_bar
 	jal 	put_thin_bar	
 	move 	$a0, $v0
 	move 	$a1, $s7
 	j space
 	
_draw_thick_bar:
	jal 	put_thick_bar
	move 	$a0, $v0
 	move 	$a1, $s7
	
_space:
 	srl	$s5, $s5, 1
 	beqz	$s5, _exit_put_char
	and	$s6, $s5, $s4
	beq	$s6, $s5, _draw_thick_space
	srl	$s5, $s5, 1
	addu 	$a0, $a0, $s7
	j	_ch_found2
	
_draw_thick_space:
 	srl	$s5, $s5, 1
 	li 	$t1, 0
	mul 	$t1, $s7, 2
	addu	$a0, $a0, $t1
	j 	_ch_found2 

_exit_put_char:
	li 	$t0, 0
	addu 	$t0, $a0, $a1
	move	$v0, $t0
	move	$v1, $t9

	lw 	$s7, ($sp)		#restore (pop) $s7
	add 	$sp, $sp, 4
	lw 	$s6, ($sp)		#restore (pop) $s6
	add 	$sp, $sp, 4
	lw 	$s5, ($sp)		#restore (pop) $s5
	add 	$sp, $sp, 4
	lw 	$s4, ($sp)		#restore (pop) $s4
	add 	$sp, $sp, 4
	lw 	$s3, ($sp)		#restore (pop) $s3
	add 	$sp, $sp, 4
	lw 	$s2, ($sp)		#restore (pop) $s2
	add 	$sp, $sp, 4
	lw 	$s1, ($sp)		#restore (pop) $s1
	add 	$sp, $sp, 4
	lw 	$s0, ($sp)		#restore (pop) $s0
	add 	$sp, $sp, 4
	lw 	$ra, ($sp)		#restore (pop) $ra
	add	$sp, $sp, 4
	jr	$ra
# ============================================================================

