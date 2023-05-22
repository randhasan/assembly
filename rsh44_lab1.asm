#rand hasan rsh44
.data
	x: .word 0 #initializes 2 32-bit ints to 0
	y: .word 0
.text

.global main
main:
	#li t0, 1 #t0 = 1
	#li t1, 2
	#li t2, 3
	#li t3, 0xF00D
	#li zero, 10 #value of zero register is still 0

	#move a0, t0 #data is never moved but copied to these other registers
	#move v0, t1 #v0 = t1 (copy)
	#move t2, zero
	
	#print 123
	li a0, 123
	li v0, 1 #choosing a system call to run which asks the operating system to produce output
	syscall #no code between lines 16-17
	
	#new line
	li a0, '\n'
	li v0, 11 #look at MARS help
	syscall
	
	#print 456
	li a0, 456
	li v0, 1
	syscall #we need to print new line ourselves
	
	#new line
	li a0, '\n'
	li v0, 11 #look at MARS help
	syscall
	
	li v0, 5 #look at MARS help
	syscall
	
	#remember sw is the only backwards acception
	sw v0, x #set x to return val from syscall
	
	li v0, 5 #look at MARS help
	syscall
	
	#remember sw is the only backwards acception
	sw v0, y #set x to return val from syscall\
	
	lw a0, x
	lw t0, y
	add a0, a0, t0
	sw a0, x
	li v0, 1
	syscall
	
	li v0, 10 #exit program
	syscall
