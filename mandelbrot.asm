#mandelbrot set - Robert Piwowarek Wtorek 12:00
# Swap two registers                     
# $t9 - temp                              
.macro	swap (%a, %b)
	move	$t9, %a
	move 	%a, %b
	move	%b, $t9
.end_macro

# Print string                                                
# $a0 - for address                       
# $v0 - syscall number                    
.macro	print_str(%str)
	li	$v0, 4
	la	$a0, %str
	syscall
.end_macro

.eqv	BG_COLOR	255

.data
bitmap:	  .space	4
filename: .asciiz "mandelbrot.bmp"
width:    .word 13
height:   .word 27
size:     .word 0

head:
#           B     M     size                    RSV   RSV   RSV   RSV   off    
    .byte   0x42, 0x4D, 0x7A, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7A, 0x00, 0x00, 0x00
#           Header size             Width                   Height
    .byte   0x6C, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00
#           plane       bpp         compression             size
    .byte   0x01, 0x00, 0x20, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00
#           h_dpm                   v_dpm                   colors_palette
    .byte   0x13, 0x0B, 0x00, 0x00, 0x13, 0x0B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
#           important colors        red_mask                green_mask
    .byte   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0xFF, 0x00, 0x00
#           blue_mask               alpha_mask      windows_space
    .byte   0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x20, 0x6E, 0x69, 0x57
#           unused
    .byte   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
#           unused
    .byte   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
#           red_gamma               green_gamma             blue_gamma
    .byte   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    
.text
	lw $t0, width
	lw $t1, height
	li $t2, 108
	mul $t0, $t0, 3
	
	and $s0, $t0, 0x3 #div mod 4
	add $t0, $t0, $s0 #padding
    	mul $t0, $t0 ,$t1 #height * width * 3 = size
    	sw  $t0, size
	
	move $a0,$t0      #copy file size to $a0
  	li  $v0,9
   	syscall           #heap memory allocation for bitmap
   	
	sw   $v0, bitmap  #pointer to start of allocated memory
	move $t0, $v0     #saving for later
	
	#edditing header to fit different size of bitmap
	la $s7, head
	add $s7, $s7, 2
	
	#storing size + headersize(108) in appriopriate place in bmp header
	#stored as halfwords because of natural padding
	lw $t0, size
	addi $t0, $t0, 108
 	sh $t0, ($s7)
 	addi $s7, $s7, 2
 	srl $t0, $t0, 16
 	sh $t0, ($s7)
 	###################################################################
 	
 	#storing header size in appriopriate place in bmp header
 	add $s7, $s7, 10
 	sh $t2, ($s7)
 	add $s7, $s7, 2
 	srl $t2, $t2, 16
 	sh $t2, ($s7)
 	add $s7, $s7, 2
  	###################################################################	
 
	#storing file width
 	lw $s0, width
 	
 	sh $s0, ($s7)
 	add $s7, $s7, 2
 	srl $s0, $s0, 16
 	sh $s0, ($s7)
 	
 	add $s7, $s7, 2
 	
 	#storing file height
 	lw $s0, height
 	
 	sh $s0, ($s7)
 	add $s7, $s7, 2
 	srl $s0, $s0, 16
 	sh $s0, ($s7)
 	
 	li $s0, 24
 	add $s7, $s7, 4
 	sh $s0, ($s7)

	#start of algorithm
	# t0 - re(z)
	# t1 - im(z)
	# s0 - row iter
	# s1 - column iter
	# s5 - row size
	# s6 - column size
	# s7 - max number of iterations

		





	#end of algorithm

	# open
	la $a0, filename
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall

	move $t9, $v0

	lw  $s0,size
    	lw  $s1,bitmap

	# write header
	li $v0, 15
	move $a0, $t9
	la $a1, head
	li $a2, 122
	syscall

	# write bmp data
	li $v0, 15
	move $a0, $t9
	la $a1, ($s1)
	la $a2, ($s0)
	syscall
	
	#print number of written characters
	move $a0, $v0
	li $v0, 1
	syscall
	
	# close file
	li	$v0, 16
	move 	$a0, $t9
	syscall
	
	#end it all
	li  $v0,10
    	syscall