# RAND HASAN
# RSH44

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
	
.data
	display: .word 0 #declaring a global var (display)
.text

.global main
main:
	 print_str "Hello! Welcome!\n"
	 _loop:
	 	lw a0, display
	 	li v0, 1
	 	syscall
	 	
	 	print_str "\nOperation (=,+,-,*,/,c,q): "
	 	li v0, 12  # syscall 12 to read a single char
	 	syscall
	 	print_str "\n"
	 	
	 	# switch(operation)
		beq v0, 'q', _quit # this means "if they typed 'q', go to the _quit case."
		beq v0, 'c', _clear
		beq v0, '=', _equals #adds a new case to the switch case
		beq v0, '+', _add
		beq v0, '-', _sub
		beq v0, '*', _mul
		beq v0, '/', _div
		j _default
	
		# case 'q':
		_quit:
			li v0, 10
			syscall
			j _break 
	
		# case 'c'
		_clear:
			sw zero, display #sets display variable variable to 0 like a clear key
			j _break #needed bc otherwise it'll go thru all of the cases until the end or it hits a j_break
		
		#case '='
		_equals:
			print_str "Value: "
			li v0, 5 #syscall 5 to get a new value
			syscall
			sw v0, display #store return value into display
	     		j _break # don't forget this...
	     		
	     	#case '+'
		_add:
			print_str "Value: "
			li v0, 5
			syscall
			
			lw t0, display #first, get display into register
			add t0, t0, v0 #t0 = t0 + v0 add v0 onto that register
			sw t0, display #set display to what we computed
	     		j _break
	     		
	     	#case '-'
		_sub:
			print_str "Value: "
			li v0, 5
			syscall
			
			lw t0, display
			sub t0, t0, v0
			sw t0, display
	     		j _break 
	     		
	     	#case '*'
		_mul:
			print_str "Value: "
			li v0, 5
			syscall
			
			lw t0, display
			mul t0, t0, v0
			sw t0, display
	     		j _break
	     		
	     	#case '/'
		_div:
			print_str "Value: "
			li v0, 5 
			syscall
			
			bne v0, 0, _else
				print_str "Attempting to divide by 0!\n"
			j _endif
			_else:
				lw t0, display
				div t0, t0, v0
				sw t0, display
				j _break
			_endif:
	     			j _break
	     		
		# default:
		_default:
			print_str "Huh?\n"
			# no j _break needed cause it's the next line.
		_break:
         
         j _loop 
