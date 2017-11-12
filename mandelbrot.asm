#mandelbrot set - Robert Piwowarek Wtorek 12:00
.eqv	BG_COLOR	255
.eqv 	SHIFT		10
.eqv    DX              32      # 1/32 * 2^16
.eqv    DY              32      # 1/32 * 2^16
.eqv    TWO           2048      # 2*2^16
.eqv    BEGX         -2560      # -2.5 * 2^16
.eqv    BEGY         -1024      # -1 * 2^16
.eqv    MAX_ITER        200     # max number of iterations per point

.data
bitmap:	  .space	4
filename: .asciiz "mandelbrot.bmp"
width:    .word 233
height:   .word 233
size:     .word 0
newline:  .asciiz "\n"

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
	move $s4, $s0 #saving for later
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
	# t5 - saved t0
	# t6 - saved t1
	# s0 - row iter
	# s1 - column iter
	# s2 - iteration iter
	# s3 - bitmap pointer
	# s5 - row size
	# s6 - column size
	li $t0, BEGX 
	li $t1, BEGY 
	lw $s3, bitmap
	lw $s5, width
	lw $s6, height
	li $s1, 0
	li $s0, 0
start:
	li $s2, 0
	move $t5, $t0
	move $t6, $t1
calcABS:
	# calculating absolute value of complex number
	# t2 - re(z) * re(z)
	# t3 - im(z) * im(z)
	# t4 - Abs(z) = t2 + t3
	mul $t2, $t5, $t5
	sra $t2, $t2, SHIFT
	mul $t3, $t6, $t6
	sra $t3, $t3, SHIFT
	add $t4, $t2, $t3
cond:
	bge $t4, 4096, next
	beq $s2, MAX_ITER, color
nextIter:
	# calculating next element of the series
	# t7 - x*x - y*y + x0
	# s7 - 2*x*y + y0
	sub $t7, $t2, $t3
	add $t7, $t7, $t0
	
	mul $s7, $t5, $t6
	sra $s7, $s7, SHIFT
	sll $s7, $s7, 1
	add $t6, $s7, $t1
	
	move $t5, $t7
	
	addi $s2, $s2, 1
	j calcABS
color: 	
	# setting RGB values of pixel
	# t7 - temp value for BG_COLOR
	li $t7, BG_COLOR
	sb $t7, ($s3)
	sb $t7, 1($s3)
	sb $t7, 2($s3)
next:
	addi $s1, $s1, 1
	bge  $s1, $s5, incRow
	addi $t0, $t0, DX
	addi $s3, $s3, 3
	j start
incRow: 
	# one row up
	# add DY to y-coordinate
	# increment bitmap pointer by 3 bytes
	# x = baseX
	# column iter = 0
	addi $s0, $s0, 1 
	bge  $s0, $s6, end
	li $s1, 0	
	addi $t1, $t1, DY
	li $t0, BEGX
	addi $s3, $s3, 3
padding1:
	bne $s4, 1, padding2
	sb $t7, ($s3)
	sb $t7, 1($s3)
	sb $t7, 2($s3)
	addi $s3, $s3, 3
padding2:
	bne $s4, 2, padding3
	sb $t7, ($s3)
	sb $t7, 1($s3)
	addi $s3, $s3, 2
padding3:
	bne $s4, 3, start
	sb $t7, ($s3)
	addi $s3, $s3, 1
	j start
end:
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
	
	# print number of written characters
	move $a0, $v0
	li $v0, 1
	syscall
	
	# close file
	li	$v0, 16
	move 	$a0, $t9
	syscall
	
	# end it all
	li  $v0,10
    	syscall