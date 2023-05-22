# Rand Hasan
# rsh44

# preserves a0, v0
.macro print_str %str
	.data
	print_str_message: .asciiz %str
	.text
	push a0
	push v0
	la a0, print_str_message
	li v0, 4
	syscall
	pop v0
	pop a0
.end_macro

# -------------------------------------------
.eqv ARR_LENGTH 5
.data
	arr: .word 100, 200, 300, 400, 500
	message: .asciiz "testing!"
.text
# -------------------------------------------
input_arr:
push ra # remember that push ra and pop ra are like { }. all code goes between them
	li t0, 0 # t0 = 0 initially
	li t1, 0
	_loop:
		print_str "enter value: "
		li v0, 5
		syscall # get user input for an int
		
		sw v0, arr(t1)
	add t0, t0, 1 # increment index by 1
	add t1, t1, 4
	blt t0, ARR_LENGTH, _loop  # run while t0 < ARR_LENGTH
pop ra
jr ra
# -------------------------------------------
print_arr:
push ra
	# all code goes here
	li t0, 0 # t0 = 0 initially
	li t1, 0
	_loop:
		#body
		print_str "arr["
		move a0, t0
		li v0, 1
		syscall
		print_str "] = "
		
		lw a0, arr(t1) # prints the next value of the array
		li v0, 1
		syscall
		print_str "\n"
	add t0, t0, 1 # increment loop counter
	add t1, t1, 4 # move to next element of the array
	blt t0, ARR_LENGTH, _loop  # run while t0 < ARR_LENGTH
pop ra
jr ra
# -------------------------------------------
print_chars:
push ra
	li t0, 0 # t0 = 0 initially
	_loop:
		lb t1, message(t0) # load byte
		beq t1, 0, _break # if byte == 0, break (loop exits before printing char, not after)
		li v0, 11 # prints char
		move a0, t1 # char we are printing
		syscall
		print_str "\n"
		add t0, t0, 1
		j _loop # jump back to the beginning of the loop
	_break:
pop ra
jr ra
# -------------------------------------------
.globl main
main:
	jal input_arr
	jal print_arr
	jal print_chars

	# exit()
	li v0, 10
	syscall
# -------------------------------------------