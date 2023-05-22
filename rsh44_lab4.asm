# Rand Hasan
# rsh44

.include "lab4_include.asm"

.eqv NUM_DOTS 3

.data
	dotX: .word 10, 30, 50
	dotY: .word 20, 30, 40
	curDot: .word 0
.text
.globl main
main:
	# when done at the beginning of the program, clears the display
	# because the display RAM is all 0s (black) right now.
	jal display_update_and_clear

	_loop:
		# code goes here!
		jal check_input
		jal wrap_dot_position
		jal draw_dots

		jal display_update_and_clear
		jal sleep
	j _loop

	li v0, 10
	syscall

#-----------------------------------------

# new functions go here!
draw_dots:
push ra
	li s0, 0
	_loop:
		#code
		sll t0, s0, 2 #Don’t forget you have to multiply the loop index by the size of one value (4)
			      #shift left logication instruction which multiplies the loop index register (s0) by the size of one value(4)
		lw a0, dotX(t0)
		lw a1, dotY(t0)
		
		#li a2, COLOR_WHITE
		lw s1, curDot #loads the value from curDot
		bne s0, s1, _else #if s0==curDot
			#then
			li a2, COLOR_ORANGE
			j _endif
		_else:
			#else
			li a2, COLOR_WHITE
		_endif:
		jal display_set_pixel #calls display_set_pixel(dotX[i],dotY[i],COLOR_WHITE) all are in the arguments a0-a2
		add s0, s0, 1
		blt s0, NUM_DOTS, _loop #Don’t write li a2, 7. Use the names of constants. li a2, COLOR_WHITE makes much more sense.
pop ra
jr ra

check_input:
push ra
	jal input_get_keys_held
	# if((v0 & KEY_Z) != 0) curDot = 0
	and t0, v0, KEY_Z #bitwise AND; not a substitute for &&
	beq t0, 0, _endif_z
		li t0, 0
		sw t0, curDot
	_endif_z:
	
	and t0, v0, KEY_X #bitwise AND; not a substitute for &&
	beq t0, 0, _endif_x
		li t0, 1
		sw t0, curDot
	_endif_x:
	
	and t0, v0, KEY_C #bitwise AND; not a substitute for &&
	beq t0, 0, _endif_c
		li t0, 2
		sw t0, curDot
	_endif_c:
	
	
	lw t9, curDot
	sll t9, t9, 2
	and t0, v0, KEY_R
	beq t0, 0, _endif_r
		lw t0, dotX(t9)
		add t0, t0, 1
		sw t0, dotX(t9)
	_endif_r:
	
	lw t9, curDot
	sll t9, t9, 2
	and t0, v0, KEY_L
	beq t0, 0, _endif_l
		lw t0, dotX(t9)
		sub t0, t0, 1
		sw t0, dotX(t9)
	_endif_l:
	
	lw t9, curDot
	sll t9, t9, 2
	and t0, v0, KEY_D
	beq t0, 0, _endif_d
		lw t0, dotY(t9)
		add t0, t0, 1
		sw t0, dotY(t9)
	_endif_d:
	
	lw t9, curDot
	sll t9, t9, 2
	and t0, v0, KEY_U
	beq t0, 0, _endif_u
		lw t0, dotY(t9)
		sub t0, t0, 1
		sw t0, dotY(t9)
	_endif_u:
pop ra
jr ra

wrap_dot_position:
push ra
	
	lw t8, curDot
	sll t8, t8, 2
	lw t0, dotX(t8)
	and t0, t0, 63 #t0 = t & 63
	sw t0, dotX(t8)
	lw t0, dotY(t8)
	and t0, t0, 63
	sw t0, dotY(t8)
pop ra
jr ra