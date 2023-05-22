# Rand Hasan
# rsh44

# need this early included so we have constants for declaring arrays in data seg
.include "game_constants.asm"
.data

# set to 1 to make it impossible to get a game over!
.eqv GRADER_MODE 0

# player's score and number of lives
score: .word 0
lives: .word 3

# boolean (1 means the game is over)
game_over: .word 0

# how many active objects there are. this many slots of the below arrays represent
# active objects.
cur_num_objs: .word 0

# Object arrays. These are parallel arrays. The player object is in slot 0,
# so the "player_x", "player_y", "player_timer" etc. labels are pointing to the
# same place as slot 0 of those arrays.

object_type: .byte 0:MAX_NUM_OBJECTS
player_x:
object_x: .byte 0:MAX_NUM_OBJECTS
player_y:
object_y: .byte 0:MAX_NUM_OBJECTS
player_timer:
object_timer: .byte 0:MAX_NUM_OBJECTS
player_delay:
object_delay: .byte 0: MAX_NUM_OBJECTS
player_vel:
object_vel: .byte 0:MAX_NUM_OBJECTS

# this is the 2d array for our map
tilemap: .byte 0:MAP_SIZE

.text

#-------------------------------------------------------------------------------------------------
# include AFTER our initial data segment stuff for easier memory debugging

.include "display_2227_0611.asm"
.include "map.asm"
.include "textures.asm"
.include "obj.asm"

#-------------------------------------------------------------------------------------------------

.globl main
main:
	# this populates the tilemap array and the object arrays
	jal load_map

	# do...
	_game_loop:
		jal check_input
		jal update_all
		jal draw_all
		jal display_update_and_clear
		jal wait_for_next_frame
	# ...while(!game_over)
	lw t0, game_over
	beq t0, 0, _game_loop

	# show the game over screen and exit
	jal show_game_over
syscall_exit

#-------------------------------------------------------------------------------------------------
check_input:
enter
	jal input_get_keys_pressed
	beq v0, KEY_L, _left_case
	beq v0, KEY_R, _right_case
	beq v0, KEY_U, _up_case
	beq v0, KEY_D, _down_case
	j _break
	
	_left_case: # player clicks left arrow key
		lb t0, player_x
		bgt t0, PLAYER_MIN_X, _move_left
		j _done_moving
		
		_move_left:
			sub t0, t0, PLAYER_VELOCITY
			sb t0, player_x
			j _done_moving
			
	_right_case: # player clicks right arrow key
		lb t0, player_x
		blt t0, PLAYER_MAX_X, _move_right
		j _done_moving
		
		_move_right:
			add t0, t0, PLAYER_VELOCITY
			sb t0, player_x
			j _done_moving
	
	_up_case: # player clicks up arrow key
		lb t0, player_y
		bgt t0, PLAYER_MIN_Y, _move_up
		j _done_moving
		
		_move_up:
			sub t0, t0, PLAYER_VELOCITY
			sb t0, player_y
			j _done_moving
	
	_down_case: # player clicks down arrow key
		lb t0, player_y
		blt t0, PLAYER_MAX_Y, _move_down
		j _done_moving
		
		_move_down:
			add t0, t0, PLAYER_VELOCITY
			sb t0, player_y
			j _done_moving
	
	_done_moving: # needed for riding on logs and crocs
		sb zero, player_delay
		sb zero, player_vel
		sb zero, player_timer
		j _break
	_break:
leave

#-------------------------------------------------------------------------------------------------
show_game_over:
enter
	jal display_update_and_clear

	li   a0, 5
	li   a1, 10
	lstr a2, "GAME OVER"
	li   a3, COLOR_YELLOW
	jal  display_draw_colored_text

	li   a0, 5
	li   a1, 30
	lstr a2, "SCORE: "
	jal  display_draw_text

	li   a0, 41
	li   a1, 30
	lw   a2, score
	jal  display_draw_int

	jal display_update
leave

#-------------------------------------------------------------------------------------------------
update_all:
enter
	jal obj_move_all
	jal maybe_spawn_object
	jal player_collision
	jal offscreen_obj_removal
leave

#-------------------------------------------------------------------------------------------------
obj_move_all:
enter s0
	li s0, 0
	lw t4, cur_num_objs
	_loop: # for int i = 0; i < cur_num_objs; i++
		lb t0, object_timer(s0) 
		sub t0, t0, 1 # decrementing the value of object_timer[i]
		sb t0, object_timer(s0) # don't forget to store!
		
		bgt t0, 0, _endif # if that value is <= 0
			lb t1, object_vel(s0)
			lb t2, object_x(s0)
			add t2, t2, t1 # object_x[i] += object_vel[i]
			sb t2, object_x(s0) # store
			
			lb t3, object_delay(s0)
			sb t3, object_timer(s0) # object_timer[i] = object_delay[i]
		_endif:
			
	add s0, s0, 1
	blt s0, t4, _loop
leave s0

#-------------------------------------------------------------------------------------------------
draw_all:
enter
	jal draw_tilemap
	jal obj_draw_all
	jal draw_hud
leave

#-------------------------------------------------------------------------------------------------
player_collision:
enter s0, s1
	mul t1, s0, MAP_WIDTH
	add t1, t1, s1
	lb t0, tilemap(t1)
	
	lb t0, player_y 
	div t0, t0, 5 # row is player_y / 5
	
	lb t1, player_x
	div t1, t1, 5
	add t1, t1, 1 # col is (player_x / 5) + 1
	
	mul t2, t0, MAP_WIDTH
	add t2, t2, t1
	lb s0, tilemap(t2) # getting a tile out of tile map
	
	
	bne s0, TILE_OUCH, _continue # if said tile == TILE_OUCH, then kill_player
		jal kill_player
		j _return
	_continue: # otherwise continue to the loop 
	
	li s1, 0
	_loop: # for int i = 0; i < cur_num_objs; i++
		lb a0, player_x
		lb a1, player_y
		lb a2, object_x(s1)
		lb a3, object_y(s1)
		jal bounds_check # call bounds_check with the following arguments (player_x, player_y, object_x[i], object_y[i])
		move t3, v0
		
		bne t3, 1, _increment # if bounds_check returned 1 then do the following, otherwise continue with the loop
		
		lb t5, object_type(s1) # getting the type of the object from object_type[i]
		beq t5, OBJ_CAR_FAST, _kill # 3 cases
		beq t5, OBJ_CAR_SLOW, _kill
		beq t5, OBJ_LOG, _ride
		beq t5, OBJ_CROC, _ride
		beq t5, OBJ_GOAL, _goal
		
		_increment: # just continue the loop if bounds_check != 1
			add s1, s1, 1
			lw t4, cur_num_objs
			blt s1, t4, _loop
			j _continue2
			
		_kill: # frog collides with a car
			jal kill_player
			j _return
			
		_goal: # frong collides with a goal frog at the top of the screen
			move a0, s1
			jal player_get_goal
			j _return
					
		_ride: # frog collides with a moving object (log or croc)
			move a0, s1
			jal player_move_with_object
			j _return
	
	_continue2: # final step! makes water hazardous. frog can only be on water if it's touching a log or crocodile
		bne s0, TILE_WATER, _return
			jal kill_player
			j _return
		
	_return:
leave s0, s1

#-------------------------------------------------------------------------------------------------
kill_player:
enter
	lw t0, lives
	ble t0, 0, _game_over # can have 0 lives at the least
		sub t0, t0, 1 # decrement lives but don't go below 0
		sw t0, lives
		
		beq t0, 0, _game_over # lives == 0, go to _game_over
	
		li t2, PLAYER_START_X # lives > 0
		li t3, PLAYER_START_Y 
		sb t2, player_x # so set player_x = PLAYER_START_X
		sb t3, player_y # set player_y = PLAYER_START_Y
		sb zero, player_delay # set player_delay, player_vel, and player_time = 0
		sb zero, player_vel
		sb zero, player_timer
		j _exit
		
	_game_over:
		bne zero, GRADER_MODE, _exit # since lives == 0 AND GRADER_MODE == 0, then the game is over
		li t4, 1
		sw t4, game_over # set game_over = 1
		j _exit
		
	_exit:
leave

#-------------------------------------------------------------------------------------------------
player_get_goal:
enter
	jal remove_obj # deletes goal object with a0 from player_collision
	
	lw t0, score
	add t0, t0, GOAL_SCORE
	sw t0, score # score += GOAL_SCORE
	
	bne t0, MAX_SCORE, _reset_game # if score == MAXSCORE, set game_over = 1
		li t1, 1
		sw t1, game_over
		j _end
	
	_reset_game: # otherwise game continues
		li t2, PLAYER_START_X # move frog back to it's starting position
		li t3, PLAYER_START_Y
		sb t2, player_x
		sb t3, player_y
		sb zero, player_delay
		sb zero, player_vel
		sb zero, player_timer
	_end:
leave

#-------------------------------------------------------------------------------------------------
obj_draw_all:
enter s0
	lw s0, cur_num_objs
	sub s0, s0, 1
	_loop: # for int s0 = cur_num_objs - 1; s0 >= 0, s0--
		
		lb a0, object_x(s0) # x argument is object_x[s0]
		lb a1, object_y(s0) # y argument is object_y[s0]
		lb a2, object_type(s0) # pattern argument is obj_textures[object_type[s0] * 4
		mul a2, a2, 4
		lw a2, obj_textures(a2)
			
		jal display_blit_5x5_trans # call display_blit_5x5_trans with the three arguments
	sub s0, s0, 1 # s0--
	bge s0, zero, _loop # s0 >= 0
leave s0

#-------------------------------------------------------------------------------------------------
draw_hud:
enter s0
	li a0, 0
	li a1, 4
	lw a2, score
	jal display_draw_int # displays value of score variable at (0,4)
	
	lw s0, lives
	li s1, 0
	_loop: # for int i = 0; i < lives; i++
		mul a0, s1, 5 # x coordinate is the loop counter times 5
		li a1, 59 # y coordinate is the loop counter tiem 59
		la a2, tex_heart # pattern
		jal display_blit_5x5_trans # call display_blit_5x5_trans to draw the hearts
	add s1, s1, 1
	blt s1, s0, _loop
leave s0

#-------------------------------------------------------------------------------------------------
draw_tilemap:
enter s0, s1
	li s0, 0 # s0 is the row
	_loop_outer: # for int row = 0; row < MAP_HEIGHT; row++
		li s1, 0 # s1 is the col
		_loop_inner: # for int col = 0; col < MAP_WIDTH; col++
			mul a0, s1, 5
			sub a0, a0, 3 # a0 = (col * 5) - 3
			
			mul a1, s0, 5
			add a1, a1, 4 # a1 = (row * 5) + 4
			
			mul t1, s0, MAP_WIDTH
			add t1, t1, s1
			lb t0, tilemap(t1) # t0 = tilemap[(row * MAP_WIDTH) + col]
			
			mul t2, t0, 4
			lw a2, texture_atlas(t2) # a2 = texture_atlas[t0 * 4]
			
			jal display_blit_5x5_trans # display_blit_5x5_trans()
		add s1, s1, 1
		blt s1, MAP_WIDTH, _loop_inner
	add s0, s0, 1
	blt s0, MAP_HEIGHT, _loop_outer
leave s0, s1