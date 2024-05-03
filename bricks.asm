;Work by: Andrew Wei (260988349) and Mingze Wang (260986639)

.286
.model small
.stack 100h
.data
	studentID db "2609888349$" ; change the content of the string to your studentID (do not remove the $ at the end)
	ball_x dw 160	 ; Default value: 160
	ball_y dw 144	 ; Default value: 144
	ball_x_vel dw 0	 ; Default value: 0
	ball_y_vel dw -1 ; Default value: -1 
	paddle_x dw 144  ; Default value: 144
	paddle_length dw 32 ; Default value: 32

    ; New variables for power-ups
    powerup_active dw 0
    powerup_counter dw 0
    last_powerup_score dw 0

    laser_active dw 0
    laser_x dw 0
    laser_y dw 183
    laser_x_vel dw 0
    laser_y_vel dw -1

.code

; get the functions from the util_br.obj file (needs to be linked)
EXTRN setupGame:PROC, drawBricks:PROC, checkBrickCollision:PROC, sleep:PROC, decreaseLives:PROC, getScore:PROC, clearPaddleZone:PROC

; Checks for wall collisions
checkWallCollision:
    push bp
    mov bp, sp

    mov ax, [bp+4]
    mov bx, [bp+6]

    cmp bx, 33
    jge check_x_for_corner

    cmp ax, 16
    jl no_collision
    je check_y_for_left_right


    cmp ax, 303
    jg no_collision 
    je check_y_for_left_right

    cmp bx, 32
    jl no_collision
    je collision_top

    jmp no_collision

check_x_for_corner:
    cmp ax, 16
    je collision_corner
    cmp ax, 303
    je collision_corner
    jmp no_collision

check_y_for_left_right:
    cmp bx, 32
    je collision_lr

collision_lr:
    mov ax, 3
    jmp done_checkWallCollision

collision_top:
    mov ax, 2
    jmp done_checkWallCollision

collision_corner:
    mov ax, 1
    jmp done_checkWallCollision

no_collision:
    mov ax, 0

done_checkWallCollision:
    pop bp
    ret 4



; Handles the ball's collisions based on checkWallCollision
handleCollisions:
    push bp
    mov bp, sp

	cmp ball_y, 183
	je y_183

check_brick:
    push ball_y_vel
    push ball_x_vel 
    push ball_y
    push ball_x
    call checkBrickCollision

    cmp ax, 1
    je invert_x

    cmp ax, 2
    je invert_y

    cmp ax, 3
    je invert_both

check_wall:
    push ball_y
    push ball_x
    call checkWallCollision

    cmp ax, 1
    je invert_x

    cmp ax, 2
    je invert_y

    cmp ax, 3
    je invert_both

    jmp done_handleCollisions

y_183:
	call checkPaddleCollision

	cmp ax, 1
    je collid_left

    cmp ax, 2
    je collid_mid

    cmp ax, 3
    je collid_right


	jmp check_wall

collid_left:
	mov ball_x_vel, -1
	mov ball_y_vel, -1
	jmp done_handleCollisions

collid_mid:
	mov ball_x_vel, 0
	mov ball_y_vel, -1
	jmp done_handleCollisions

collid_right:
	mov ball_x_vel, 1
	mov ball_y_vel, -1
	jmp done_handleCollisions


invert_x:
    neg ball_x_vel
    jmp done_handleCollisions

invert_y:
    neg ball_y_vel
    jmp done_handleCollisions

invert_both:
    neg ball_x_vel
    neg ball_y_vel

done_handleCollisions:
    pop bp
    ret




; Assuming ball_x and ball_y are word-sized variables that store the ball's current position
checkPaddleCollision:
    push bp
    mov bp, sp

    push bx
    push cx
    push dx

    ; Get the color of the pixel right above where the paddle would be
    mov bx, ball_x  ; Move ball_x into BX
    mov cx, ball_y  ; Move ball_y into AX
    inc cx            ; Increment AX to get the position right above the paddle
    push bx           ; Push x onto the stack for get_pixel_color
    push cx           ; Push y onto the stack for get_pixel_color
    call get_pixel_color  ; AL now contains the color value

    ; Check the color and set the return value accordingly
    cmp dx, 0
    je not_above_paddle
    cmp dx, 2Ch
    je above_left_section
    cmp dx, 2Dh
    je above_middle_section
    cmp dx, 2Eh
    je above_right_section


above_left_section:
    mov ax, 1
    jmp collision_done

above_middle_section:
    mov ax, 2
    jmp collision_done

above_right_section:
    mov ax, 3
    jmp collision_done

not_above_paddle:
    mov ax, 0

collision_done:
    pop dx
    pop cx
    pop bx
    pop bp
    ret


; Function to reset the game after the ball is lost
resetAfterBallLoss:
    push bp
    mov bp, sp

	push bx
	push cx

    mov ball_x, 160
    mov ball_y, 144
    mov ball_x_vel, 0
    mov ball_y_vel, -1
    mov paddle_x, 144
	mov paddle_length, 32

	call drawPaddle

    push 144
	push 160 
	push 0Fh 
    call drawPixel

    call decreaseLives

	pop cx
	pop dx
    pop bp
    ret


drawLine_h:
    color EQU ss:[bp+10] ; Color of the line
    x1 EQU ss:[bp+8]    ; Starting X coordinate
    y EQU ss:[bp+6]     ; Y coordinate (constant for horizontal line)
    x2 EQU ss:[bp+4]   ; Ending X coordinate

    push    bp          ; Save base pointer
    mov     bp, sp      ; Set base pointer to current stack pointer

    push    cx          ; Save CX register (used for loop counter or data)
    push    bx          ; Save BX register (used for X coordinate)

    mov     bx, x1      ; Initialize BX with starting X coordinate
    mov     cx, y       ; Initialize CX with Y coordinate
    mov     dx, x2      ; DX used to store ending X coordinate for comparison

    drawLine_h_loop:
        push    cx          ; Push Y coordinate onto stack for drawPixel
        push    bx          ; Push current X coordinate for drawPixel
        push    color       ; Push color for drawPixel
        call    drawPixel   ; Call drawPixel function to color the pixel

        inc     bx          ; Increment X coordinate
        cmp     bx, dx      ; Compare current X with ending X coordinate
        jle     drawLine_h_loop     ; Loop back if current X <= ending X
		

        pop     bx          ; Restore BX register
        pop     cx          ; Restore CX register
        pop     bp          ; Restore base pointer
        ret     8           ; Return and clean up arguments from stack




drawPaddle:

	push    bp          ; Save base pointer
    mov     bp, sp      ; Set base pointer to current stack pointer

    call clearPaddleZone  ; Assuming this procedure doesn't require stack cleanup
	mov bx, 184

drawPaddle_recursive:

    ; Calculate the length of the left/right paddle sections
    
    mov cx, 2
	xor dx, dx
	mov ax, paddle_length
    sub ax, 4
	div cx
    
	
	; Left section
	mov cx, paddle_x
	add ax, cx
	mov dx, ax           
	push 2Ch       
	push cx              
	push bx      
	push dx             
	call drawLine_h


	; Middle section
	mov cx, dx            
	add dx, 4             
	push 2Dh               
	push cx                
	push bx               
	push dx                
	call drawLine_h

	; Right section
    mov cx, dx
	mov dx, paddle_x
    add dx, paddle_length 
	sub dx, 1
    push 2Eh                
    push cx                
    push bx              
    push dx              
    call drawLine_h
	

	inc bx
	cmp bx, 187
	jle drawPaddle_recursive

	pop bp
    ret



drawBall:

	push bp
    mov bp, sp
    ; Erase the ball
    push ball_y
    push ball_x
    push 0
    call drawPixel
    
    ; Update the ball's position
    mov ax, ball_x
    add ax, ball_x_vel
    mov ball_x, ax
    
    mov ax, ball_y
    add ax, ball_y_vel
    mov ball_y, ax
    
    ; Draw the ball at the new position
    push ball_y
    push ball_x
    push 0Fh
    call drawPixel

    pop bp
    ret 6



; draw a single pixel specific to Mode 13h (320x200 with 1 byte per color)
drawPixel:
	color EQU ss:[bp+4]
	x1 EQU ss:[bp+6]
	y1 EQU ss:[bp+8]

	push	bp
	mov	bp, sp

	push	bx
	push	cx
	push	dx
	push	es

	; set ES as segment of graphics frame buffer
	mov	ax, 0A000h
	mov	es, ax


	; BX = ( y1 * 320 ) + x1
	mov	bx, x1
	mov	cx, 320
	xor	dx, dx
	mov	ax, y1
	mul	cx
	add	bx, ax

	; DX = color
	mov	dx, color

	; plot the pixel in the graphics frame buffer
	mov	BYTE PTR es:[bx], dl

	pop	es
	pop	dx
	pop	cx
	pop	bx

	pop	bp

	ret	6



get_pixel_color:
    push bp
    mov bp, sp

    x EQU ss:[bp+6]
	y EQU ss:[bp+4]
    
    push bx
    push cx
    push es

    mov ax, 0A000h
    mov es, ax   

    mov	bx, x
	mov	cx, 320
	mov	ax, y
	mul	cx
	add	bx, ax

    
    mov dl, es:[bx]; Move the pixel color to dx

    pop es
    pop cx
    pop bx

    pop bp
    ret 4    




start:
        mov ax, @data
        mov ds, ax
	
	push OFFSET studentID ; do not change this, change the string in the data section only
	push ds
	call setupGame ; change video mode, draw walls & write score, studentID and lives
	call drawBricks
	
main_loop:
	call drawPaddle
	call drawBall
	call handleCollisions
	call sleep
    call handleLaserCollisions

    ; Check if laser is active
	cmp laser_active, 1
    je drawLaser_call


    ; Check if power-up is active
    cmp powerup_active, 1
    jne ball_lost_check
    dec powerup_counter
    jnz ball_lost_check

    ; Deactivate power-up if powerup_counter reaches 0
    mov powerup_active, 0
    mov paddle_length, 32 ; reset paddle length



ball_lost_check:
	mov ax, ball_y
    cmp ax, 199
	jg ball_lost

	jmp keypressCheck

ball_lost:
	call resetAfterBallLoss
	cmp ax, 0
	jg keyboardInput

	mov ah, 00h
	int 16h
	jmp exit

keypressCheck:
	mov ah, 01h ; check if keyboard is being pressed
	int 16h ; zero flag (zf) is set to 1 if no key pressed
	jz main_loop ; if zero flag set to 1 (no key pressed), loop back

keyboardInput:
	; else get the keyboard input
	mov ah, 00h
	int 16h

	cmp al, 1bh
	je exit_call

	cmp al, 41h
	je move_left

	cmp al, 61h
	je move_left

	cmp al, 44h
	je move_right

	cmp al, 64h
	je move_right

    cmp al, 31h
    je paddle_length_powerup

    cmp al, 32h
    je laser_powerup

	jmp main_loop


drawLaser_call:
    jmp drawLaser

main_loop_call:
    jmp main_loop

exit_call:
    jmp exit 

move_left:
    
    sub paddle_x, 8
    cmp paddle_x, 0
    jge main_loop_call
    mov paddle_x, 0
    jmp main_loop

move_right:
    add paddle_x, 8
	mov ax, paddle_length
	neg ax
	add ax, 320
    cmp paddle_x, ax
    jle main_loop_call
    mov paddle_x, ax
    jmp main_loop

paddle_length_powerup:
    ; Check if score is high enough
    call getScore
    sub ax, last_powerup_score
    cmp ax, 50
    jl main_loop_call

    ; Activate power-up
    mov powerup_active, 1
    mov powerup_counter, 500
    mov last_powerup_score, ax

    ; Increase paddle length
    mov paddle_length, 64

    jmp main_loop

laser_powerup:
    ; Check if score is high enough
    call getScore
    sub ax, last_powerup_score
    cmp ax, 50
    jl main_loop_call

    ; Update last power-up score
    mov last_powerup_score, ax

    ; Update laser initial position (x=paddle_x + (paddle_length/2), y=183)
    mov ax, paddle_length
    shr ax, 1 ; Divide by 2
    add ax, paddle_x
    mov laser_x, ax

    ; Activate power-up
    mov laser_active, 1

    jmp main_loop

; Handles the laser's collisions based on checkWallCollision
handleLaserCollisions:
    push bp
    mov bp, sp

    check_brick_laser:
        push laser_y_vel
        push laser_x_vel 
        push laser_y
        push laser_x
        call checkBrickCollision

        cmp ax, 0
        jne deactivate_laser

    check_wall_laser:
        push laser_y
        push laser_x
        call checkWallCollision

        cmp ax, 0
        jne deactivate_laser

        jmp done_handleLaserCollisions

    deactivate_laser:
        mov laser_active, 0
        ; Erase the laser
        push laser_y
        push laser_x
        push 0
        call drawPixel
        
        jmp done_handleLaserCollisions
    
    done_handleLaserCollisions:
        pop bp
        ret

drawLaser:
	push bp
    mov bp, sp
    ; Erase the laser
    push laser_y
    push laser_x
    push 0
    call drawPixel
    
    ; Update the laser's position
    mov ax, laser_x
    add ax, laser_x_vel
    mov laser_x, ax
    
    mov ax, laser_y
    add ax, laser_y_vel
    mov laser_y, ax
    
    ; Draw the ball at the new position
    push laser_y
    push laser_x
    push 0Fh
    call drawPixel

    pop bp
    jmp main_loop_call
    ret

exit:
        mov ax, 4f02h	; change video mode back to text
        mov bx, 3
        int 10h

        mov ax, 4c00h	; exit
        int 21h

END start

