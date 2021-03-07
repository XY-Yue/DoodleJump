######################################################################
# CSC258H5S Fall 2020 Assembly Final Project
# University of Toronto, St. George
#
# Student: Xingyu Yue, 1005936962
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 5
#
# Which approved additional features have been implemented?
# Game over / retry
# Dynamic increase in difficulity, i.e. less and narrower platforms, less rockets, etc
#
# Relastic physics, gravity exists
# More platforms: blue are moving platforms, white are platforms that will break when jumped once, green are trap 
# 	platforms that gives doodle less velocity up
# Rockets / Springs: Rockets are orange, springs are the black things on some platforms 
#
# Any additional information that the TA needs to know:
# None
######################################################################

.data
	red: .word 0xff0000
	skyBlue: .word 0x87CEEB
	grey: .word 0x696969
	orange: .word 0xFFA500
	black: .word 0x000000
	green: .word 0x008000
	blue: .word 0x0000FF
	white: .word 0xFFFFFF
	displayAddress:	.word 0x10008000
	charAddress: .word 0x10009934
	displayMidAddress: .word 0x10009000
	displayEndAddress: .word 0x1000a000
	platformArray: .space 60
	velocity: .word -5
	score: .word 0
	platformLowerBound: .word 46
	platformGap: .word 0x1
	boom: .word 0
	slow: .word 0x1000b000 # platform that only gives a velocity of 3 up instead of normal platform's 5 up
	moving: .word 0x1000b000 # moving platform
	movingDirection: .word 4
	cloud: .word 0x1000b000	# a platform that breaks when character jump once on it
	rocket: .word 0x1000b000
	spring: .word 0x1000b000
	hasRocket: .word 0
	rocketDuration: .word 0
	
.text
Start: 
	addi $t0, $zero, 0
	sw $t0, score
	sw $t0, hasRocket
	sw $t0, rocketDuration
	addi $t0, $zero, 1
	sw $t0, platformGap
	addi $t0, $zero, -5
	sw $t0, velocity
	addi $t0, $zero, 0x10009934
	sw $t0, charAddress
	addi $t0, $zero, 46
	sw $t0, platformLowerBound
	addi $t0, $zero, 0x1000b000
	sw $t0, slow
	sw $t0, moving
	sw $t0, cloud
	sw $t0, rocket
	sw $t0, spring
	
	lw $t0, displayAddress # $t0 stores the base address for display
	la $t5, platformArray 
	lw $t2, charAddress
	add $t1, $t2, 764 # Get the position of the address to the bottom left of the character
	sw $t1 0($t5) # Set the above address as the start of the first platform so that doodle has a platform below its spawn point
	lw $t1, grey # $t1 stores the grey colour code
	lw $t2, skyBlue # $t2 stores the skyBlue colour code
	lw $t3, red # $t3 stores the red colour code
	jal Repaint
	jal SetStartPlatform # Random generate 9 platforms in the start screen
	jal StartMessage
StartGameLoop:
	lw $t8, 0xffff0000 # Input Listener
	beq $t8, 1, DetectStart
	beq $t8, 0, StartGameLoop
DetectStart: 
	lw $t8, 0xffff0004
	bne $t8, 0x73, StartGameLoop # If input s, start game
	

	jal Repaint
CentralLoop:
	li $v0, 32
	li $a0, 70
	syscall # Sleep for 70 ms
	jal RepaintPlatforms
	jal RepaintDoodle
	jal RedrawSlow
	jal RedrawMoving
	jal RedrawCloud
	jal SetMovingPosition
	jal UpdateChar
	jal RegeneratePlatform
	jal GenerateSpring
	jal GenerateRocket
	jal GenerateCloud
	jal GenerateMoving
	jal GenerateSlow
	jal DrawPlatform
	jal DrawRocket
	jal DrawSpring
	jal DrawSlow
	jal DrawCloud
	jal DrawMoving
	jal CheckCharPos
	jal UpdateDifficulity
	jal DetectSpring
	jal DetectCollusion
	jal SetRocket
	lw $t8, 0xffff0000 # Input Listener
	beq $t8, 1, keyboard_input
	beq $t8, 0, Continue
keyboard_input:	
	lw $t8, 0xffff0004
	beq $t8, 0x65, CentralEnd # If input e, end program
	beq $t8, 0x6a, MoveLeft # If input j, move 2 units left
	beq $t8, 0x6b, MoveRight # If input k, move 2 units right
	j Continue
MoveLeft:
	lw $t7, charAddress
	addi $t7, $t7, -8
	li $s7, 128
	div $t7, $s7
	mfhi $s6
	ble $s6, 100, EndMoveLeft
	addi $t7, $t7, -128
	addi $t7, $t7, -24
EndMoveLeft:
	sw $t7, charAddress
	j Continue
MoveRight:
	lw $t7, charAddress
	addi $t7, $t7, 8
	li $s7, 128
	div $t7, $s7
	mfhi $s6
	ble $s6, 100, EndMoveRight
	addi $t7, $t7, 128
	addi $t7, $t7, -100
EndMoveRight:
	sw $t7, charAddress
	j Continue
Continue:
	jal DrawChar
	jal DetectRocket
	j CentralLoop
CentralEnd:	
	j Exit
	
GenerateSpring:
	lw $t5, spring
	lw $t4, displayEndAddress
	blt $t5, $t4, EndSpringGenerate
	li $v0, 42
	li $a0, 0
	li $a1, 100
	syscall 
	bge $a0, 50, EndSpringGenerate
	la $t9, platformArray 
	lw $s0, displayAddress
	addi $t8, $t9, 60 # Loop end condition
	lw $t4, displayAddress
	FindPlatformLoop:
		bge $t9, $t8, EndSpringGenerate
		lw $t7, 0($t9)
		beq $t7, 0, FindPlatform
		bge $t7, $t4, FindPlatform
		sw $t7, spring
		jr $ra
	FindPlatform:
		addi $t9, $t9, 4
		j FindPlatformLoop
EndSpringGenerate:
	jr $ra
	
GenerateRocket:
	lw $t9, hasRocket
	beq $t9, 1, EndRocketGenerate
	lw $t9, rocket
	lw $t8, displayEndAddress
	ble $t9, $t8, EndRocketGenerate
	
	li $v0, 42
	li $a0, 0
	li $a1, 100
	syscall 
	
	blt $a0, 0, EndRocketGenerate
	la $t8, platformArray
	lw $t7, displayAddress
	addi $t6, $t8, 56
	RocketGenerateLoop:
		blt $t6, $t8, EndRocketGenerate
		lw $t5, 0($t6)
		bge $t5, $t7, NextRocketGenerate
		addi $t5, $t5, -128
		addi $t5, $t5, -128
		sw $t5, rocket
		jr $ra
	NextRocketGenerate:
		addi $t6, $t6, -4
		j RocketGenerateLoop
EndRocketGenerate:
	jr $ra
	
GenerateMoving:
	lw $t9, moving
	lw $t8, displayEndAddress
	ble $t9, $t8, EndGenerateMoving
	lw $t8, displayAddress
StartGenerateMoving:

	lw $t6, platformLowerBound
	li $v0, 42
	li $a0, 0
	li $a1, 3
	add $a0, $a0, $t6
	li $t7, 128
	mult $a0, $t7
	mflo $t7
	add $t9, $t8, $t7
	addi $t6, $t6, -5
	sw $t9, moving
	sw $t6, platformLowerBound

EndGenerateMoving:
	jr $ra
	
SetMovingPosition:
	lw $t9, moving
	lw $t8, movingDirection
	li $t7, 128
	div $t9, $t7
	mfhi $t7
	ble $t7, 0, PlatformMoveRight
	bge $t7, 100, PlatformMoveLeft
	j ContinueMoving
PlatformMoveLeft:
	li $t8, -4
	j ContinueMoving
PlatformMoveRight:	
	li $t8, 4
	j ContinueMoving
ContinueMoving:
	add $t9, $t9, $t8
	sw $t9, moving
	sw $t8, movingDirection
	jr $ra
	
GenerateCloud:
	lw $t9, cloud
	lw $t8, displayEndAddress
	ble $t9, $t8, EndGenerateCloud
	lw $t8, displayAddress
StartGenerateCloud:
	lw $t6, platformLowerBound
	li $v0, 42
	li $a0, 0
	li $a1, 25
	syscall 
	
	li $t7, 4
	mult $t7, $a0
	mflo $t7
	add $t8, $t8, $t7
	
	li $v0, 42
	li $a0, 0
	li $a1, 3
	add $a0, $a0, $t6
	li $t7, 128
	mult $a0, $t7
	mflo $t7
	add $t9, $t8, $t7
	addi $t6, $t6, -5
	sw $t9, cloud
	sw $t6, platformLowerBound
	
EndGenerateCloud:
	jr $ra
	
GenerateSlow:
	lw $t9, slow
	lw $t8, displayEndAddress
	ble $t9, $t8, EndGenerateSlow
	lw $t8, displayAddress
	
	lw $t6, platformLowerBound
	li $v0, 42
	li $a0, 0
	li $a1, 25
	syscall 
	
	li $t7, 4
	mult $t7, $a0
	mflo $t7
	add $t8, $t8, $t7
	
	add $a0, $t6, 2
	li $t7, 128
	mult $a0, $t7
	mflo $t7
	add $t9, $t8, $t7
	addi $t6, $t6, -4
	sw $t9, slow
	sw $t6, platformLowerBound
EndGenerateSlow:
	jr $ra
	
DrawSpring:
	lw $t5, spring
	lw $t4, displayAddress
	blt $t5, $t4, EndDrawSpring
	li $t9, 0x000000
	sw $t9, 8($t5)
	sw $t9, 12($t5)
	sw $t9, 16($t5)
EndDrawSpring:
	jr $ra
	
DrawRocket:
	lw $t9, rocket
	lw $t8, displayAddress
	blt $t9, $t8, EndDrawRocket
	li $t7, 0xFFA500
	sw $t7, 12($t9)
	sw $t7, 140($t9)
	sw $t7, 136($t9)
	sw $t7, 144($t9)
EndDrawRocket:
	jr $ra
	
DrawSlow:
	lw $t5, slow
	lw $t4, displayAddress
	blt $t5, $t4, EndDrawSlow
	li $t9, 0x008000
	sw $t9, 0($t5)
	sw $t9, 4($t5)
	sw $t9, 8($t5)
	sw $t9, 12($t5)
	sw $t9, 16($t5)
	sw $t9, 20($t5)
	sw $t9, 24($t5)
EndDrawSlow:
	jr $ra
	
DrawMoving:
	lw $t5, moving
	lw $t4, displayAddress
	blt $t5, $t4, EndDrawMoving
	li $t9, 0x0000FF
	sw $t9, 0($t5)
	sw $t9, 4($t5)
	sw $t9, 8($t5)
	sw $t9, 12($t5)
	sw $t9, 16($t5)
	sw $t9, 20($t5)
	sw $t9, 24($t5)
EndDrawMoving:
	jr $ra
	
DrawCloud:
	lw $t5, cloud
	lw $t4, displayAddress
	blt $t5, $t4, EndDrawCloud
	li $t9, 0xFFFFFF
	sw $t9, 0($t5)
	sw $t9, 4($t5)
	sw $t9, 8($t5)
	sw $t9, 12($t5)
	sw $t9, 16($t5)
	sw $t9, 20($t5)
	sw $t9, 24($t5)
EndDrawCloud:
	jr $ra
	
RedrawSlow:
	lw $t5, slow
	lw $t4, displayAddress
	blt $t5, $t4, EndRedrawSlow
	sw $t2, 0($t5)
	sw $t2, 4($t5)
	sw $t2, 8($t5)
	sw $t2, 12($t5)
	sw $t2, 16($t5)
	sw $t2, 20($t5)
	sw $t2, 24($t5)
EndRedrawSlow:
	jr $ra
	
RedrawMoving:
	lw $t5, moving
	lw $t4, displayAddress
	blt $t5, $t4, EndRedrawMoving
	sw $t2, 0($t5)
	sw $t2, 4($t5)
	sw $t2, 8($t5)
	sw $t2, 12($t5)
	sw $t2, 16($t5)
	sw $t2, 20($t5)
	sw $t2, 24($t5)
EndRedrawMoving:
	jr $ra
	
RedrawCloud:
	lw $t5, cloud
	lw $t4, displayAddress
	blt $t5, $t4, EndRedrawCloud
	sw $t2, 0($t5)
	sw $t2, 4($t5)
	sw $t2, 8($t5)
	sw $t2, 12($t5)
	sw $t2, 16($t5)
	sw $t2, 20($t5)
	sw $t2, 24($t5)
EndRedrawCloud:
	jr $ra
	
UpdateDifficulity:
	lw $t9, platformGap
	lw $t8, score
	bge $t8, 300, Seven
	bge $t8, 250, six
	bge $t8, 200, five
	bge $t8, 150, four
	bge $t8, 100, three
	bge $t8, 50, two
	bge $t8, 0, UpdateDifficulityEnd
Seven:
	li $t9, 7
	j UpdateDifficulityEnd
six:
	li $t9, 6
	j UpdateDifficulityEnd
five:
	li $t9, 5
	j UpdateDifficulityEnd
four:
	li $t9, 4
	j UpdateDifficulityEnd
three:
	li $t9, 3
	j UpdateDifficulityEnd
two:
	li $t9, 2
	j UpdateDifficulityEnd
UpdateDifficulityEnd:	
	sw $t9, platformGap
	jr $ra
	
Repaint:
	lw $t9, displayAddress
	lw $t8, displayEndAddress 
	Loop:
		bge $t9, $t8, end
		sw $t2, 0($t9) # Repaint every pixel on the display
		addi $t9, $t9, 4
		j Loop
	end: 
		jr $ra
DrawChar: 
	lw $t9, charAddress # Drawing the character by filling every unit necessary
	sw $t3, 12($t9)
	sw $t3, 136($t9)
	sw $t3, 140($t9)
	sw $t3, 144($t9)
	sw $t3, 260($t9)
	sw $t3, 264($t9)
	sw $t3, 268($t9)
	sw $t3, 272($t9)
	sw $t3, 276($t9)
	sw $t3, 384($t9)
	sw $t3, 396($t9)
	sw $t3, 408($t9)
	sw $t3, 520($t9)
	sw $t3, 524($t9)
	sw $t3, 528($t9)
	sw $t3, 644($t9)
	sw $t3, 648($t9)
	sw $t3, 656($t9)
	sw $t3, 660($t9)
	lw $t8, hasRocket
	bne $t8, 1, EndCharDrawing
	li $t8, 0xFFA500
	sw $t8, 652($t9)
	sw $t8, 780($t9)
	sw $t8, 908($t9)
	sw $t8, 1164($t9)
	sw $t8, 1420($t9)
	jr $ra
EndCharDrawing:
	li $t5, 0
	sw $t5, rocketDuration
	jr $ra
	
DrawPlatform:
	la $t9, platformArray 
	lw $s0, displayAddress
	lw $s7, score
	addi $t8, $t9, 60 # Loop end condition
	PlatformLoop:
		bge $t9, $t8, PlatformEnd
		lw $t7, 0($t9)
		beq $t7, 0, PlatformEnd # Do not draw if this address is 0, meaning platform does not exist
		blt $t7, $s0, FinishDrawingPlatform
		sw $t1, 0($t7)
		sw $t1, 4($t7)
		sw $t1, 8($t7)
		sw $t1, 12($t7)
		sw $t1, 16($t7)
		bge $s7, 300, FinishDrawingPlatform
		sw $t1, 20($t7)
		bge $s7, 250, FinishDrawingPlatform
		sw $t1, 24($t7)
		bge $s7, 150, FinishDrawingPlatform
		sw $t1, 28($t7)
	FinishDrawingPlatform:
		addi $t9, $t9, 4
		j PlatformLoop
	PlatformEnd:
		jr $ra
		
SetRocket:
	lw $t9, rocketDuration
	beq $t9, 0, EndSetRocket
	addi $t9, $t9, -1
	bgt $t9, 0, EndSetRocket
	li $t9, 0
	sw $t9, hasRocket
	
EndSetRocket:
	sw $t9, rocketDuration
	jr $ra
		
UpdateChar:
	lw $t9, charAddress
	lw $t8, velocity
	la $t7, charAddress
	la $t6, velocity
	lw $s0, displayMidAddress
	addi $t5, $zero, 128 
	mult $t5, $t8 # Total address change to move up or down 
	mflo $t5
	add $t9, $t9, $t5 # Move the character
	lw $s1, hasRocket
	beq $s1, 1, UpdateCharNext
	addi $t8, $t8, 1 # Change the velocity so that it falls quicker and quicker
	
UpdateCharNext:
	li $s1, 128
	lw $s7, platformLowerBound
MoveThingsDown:
	bge $t9, $s0, RecordCharChange
	addi $t9, $t9, 128
	la $s2, platformArray
	li $t4, 0
	lw $s4, score
	addi $s4, $s4, 1
	sw $s4, score
	addi $s7, $s7, 1
	sw $s7, platformLowerBound
	lw $s6, spring
	addi $s6, $s6, 128
	sw $s6, spring
	lw $s6, rocket
	addi $s6, $s6, 128
	sw $s6, rocket
	lw $s6, slow
	addi $s6, $s6, 128
	sw $s6, slow
	lw $s6, moving
	addi $s6, $s6, 128
	sw $s6, moving
	lw $s6, cloud
	addi $s6, $s6, 128
	sw $s6, cloud
MovePlatformDown:
	bge $t4, 15, MoveThingsDown
	lw $s3, 0($s2)
	addi $s3, $s3, 128
	sw $s3, 0($s2)
	addi $s2, $s2, 4
	addi $t4, $t4, 1
	j MovePlatformDown
RecordCharChange:
	sw $t9, 0($t7)
	sw $t8, 0($t6)
	jr $ra
	
DetectSpring:
	li $t5, 0x000000
	lw $t9, velocity 
	blt $t9, 0, EndDetection # Do not detect collusion if character moving up
	lw $t9, charAddress 
	addi $t9, $t9, 772 # Look at the address below character's foot
	lw $t8, 0($t9)
	beq $t8, $t5, HasSpring # Look below character's left foot
	lw $t8, 4($t9)
	beq $t8, $t5, HasSpring
	lw $t8, 8($t9)
	beq $t8, $t5, HasSpring
	lw $t8, 12($t9)
	beq $t8, $t5, HasSpring
	lw $t8, 16($t9)
	beq $t8, $t5, HasSpring
	jr $ra
HasSpring:
	li $t7, -8 
	sw $t7, velocity
	jr $ra
	
DetectRocket:
	lw $t9, rocket
	lw $t8, displayAddress
	blt $t9, $t8, EndRocketDetect
	lw $t8, 8($t9)
	beq $t8, $t3, HasRocket
	lw $t8, 16($t9)
	beq $t8, $t3, HasRocket
	addi $t9, $t9, -128
	lw $t8, 12($t9)
	beq $t8, $t3, HasRocket
	j EndRocketDetect
HasRocket:
	lw $t9, rocket
	lw $t8, 12($t9)
	beq $t8, $t2, EndRocketDetect
	lw $t8, 140($t9)
	beq $t8, $t2, EndRocketDetect
	lw $t8, 136($t9)
	beq $t8, $t2, EndRocketDetect
	lw $t8, 144($t9)
	beq $t8, $t2, EndRocketDetect
	sw $t2, 12($t9)
	sw $t2, 140($t9)
	sw $t2, 136($t9)
	sw $t2, 144($t9)
	li $t9, 0x1000b000
	sw $t9, rocket
	li $t9, 1
	sw $t9, hasRocket
	li $t9, -8
	sw $t9, velocity
	li $t9, 50
	sw $t9, rocketDuration
EndRocketDetect:
	jr $ra
	
	
DetectCollusion:
	lw $t9, velocity 
	blt $t9, 0, EndDetection # Do not detect collusion if character moving up
	lw $t9, charAddress 
	addi $t9, $t9, 772 # Look at the address below character's foot
	addi $t7, $zero, 0 # Loop variable
	lw $t6, velocity
DetectionLoop:
	bgt $t7, $t6, EndDetection 
	
	lw $t8, 0($t9)
	addi $t5, $t1, 0
	beq $t8, $t5, SetAddr # Look below character's left foot
	li $t5, 0x000000
	beq $t8, $t5, SetAddr
	li $t5, 0x0000FF
	beq $t8, $t5, SetAddr
	li $t5, 0xFFFFFF
	beq $t8, $t5, SetAddr
	li $t5, 0x008000
	beq $t8, $t5, SetAddr
	
	lw $t8, 4($t9)
	addi $t5, $t1, 0
	beq $t8, $t5, SetAddr
	li $t5, 0x000000
	beq $t8, $t5, SetAddr
	li $t5, 0x0000FF
	beq $t8, $t5, SetAddr
	li $t5, 0xFFFFFF
	beq $t8, $t5, SetAddr
	li $t5, 0x008000
	beq $t8, $t5, SetAddr
	
	lw $t8, 8($t9)
	addi $t5, $t1, 0
	beq $t8, $t5, SetAddr
	li $t5, 0x000000
	beq $t8, $t5, SetAddr
	li $t5, 0x0000FF
	beq $t8, $t5, SetAddr
	li $t5, 0xFFFFFF
	beq $t8, $t5, SetAddr
	li $t5, 0x008000
	beq $t8, $t5, SetAddr
	
	lw $t8, 12($t9)
	addi $t5, $t1, 0
	beq $t8, $t5, SetAddr
	li $t5, 0x000000
	beq $t8, $t5, SetAddr
	li $t5, 0x0000FF
	beq $t8, $t5, SetAddr
	li $t5, 0xFFFFFF
	beq $t8, $t5, SetAddr
	li $t5, 0x008000
	beq $t8, $t5, SetAddr
	
	lw $t8, 16($t9)
	addi $t5, $t1, 0
	beq $t8, $t5, SetAddr # Look below character's right foot
	li $t5, 0x000000
	beq $t8, $t5, SetAddr
	li $t5, 0x0000FF
	beq $t8, $t5, SetAddr
	li $t5, 0xFFFFFF
	beq $t8, $t5, SetAddr
	li $t5, 0x008000
	beq $t8, $t5, SetAddr
	
	addi $t9, $t9, 128 # Next row
	addi $t7, $t7, 1
	j DetectionLoop
EndDetection: 
	jr $ra
	
SetAddr:
	bne $t7, 0, ChangeVelo # change the velocity so that next fram character falls right on the platform
	beq $t5, $t1, DetectedNormal
	beq $t5, 0x0000FF, DetectedNormal
	beq $t5, 0x008000, DetectedSlow
	beq $t5, 0x000000, DetectedSpring
	beq $t5, 0xFFFFFF, DetectedCloud
	
DetectedNormal:
	addi $t7, $t7, -5 # change the velocity to positive if the character is on the platform
	j ChangeVelo
	
DetectedSpring:
	addi $t7, $t7, -8 
	j ChangeVelo
	
DetectedSlow:
	addi $t7, $t7, -3
	j ChangeVelo
	
DetectedCloud:
	addi $t7, $t7, -5 
	lw $t5, cloud
	sw $t2, 0($t5)
	sw $t2, 4($t5)
	sw $t2, 8($t5)
	sw $t2, 12($t5)
	sw $t2, 16($t5)
	sw $t2, 20($t5)
	sw $t2, 24($t5)
	li $t5, 0x1000b000
	sw $t5, cloud
	j ChangeVelo
	
ChangeVelo:
	sw $t7, velocity
	jr $ra

SetStartPlatform:
	la $t9, platformArray
	addi $t8, $t9, 60 # Loop End
	addi $t9, $t9, 4
	lw $t4, platformLowerBound # Lower bound for the random numbers
	StartPlatformLoop:
		bge $t9, $t8, StartPlatformEnd
		lw $t7, 0($t9)
		lw $t6, displayAddress
		li $v0, 42
		li $a0, 0
		li $a1, 24
		syscall # Random generate a platform's x position
		addi $s0, $zero, 4
		mult $a0, $s0
		mflo $s0
		add $t6, $t6, $s0
		li $v0, 42
		li $a0, 0
		li $a1, 4
		syscall # Random generate a platform's y position
		add $a0, $a0, $t4 # Add to the lower bound for a y position that fits the lower bound
		addi $s0, $zero, 128
		mult $a0, $s0
		mflo $s0
		add $t6, $t6, $s0
		sw $t6, 0($t9)
		addi $t9, $t9, 4
		addi $t4, $t4, -5
		j StartPlatformLoop
	StartPlatformEnd:
		sw $t4, platformLowerBound
		jr $ra
		
RepaintDoodle:
	lw $t9, charAddress # Paint all of the doodle white
	sw $t2, 12($t9)
	sw $t2, 136($t9)
	sw $t2, 140($t9)
	sw $t2, 144($t9)
	sw $t2, 260($t9)
	sw $t2, 264($t9)
	sw $t2, 268($t9)
	sw $t2, 272($t9)
	sw $t2, 276($t9)
	sw $t2, 384($t9)
	sw $t2, 396($t9)
	sw $t2, 408($t9)
	sw $t2, 520($t9)
	sw $t2, 524($t9)
	sw $t2, 528($t9)
	sw $t2, 644($t9)
	sw $t2, 648($t9)
	sw $t2, 656($t9)
	sw $t2, 660($t9)
	lw $t8, hasRocket
	bne $t8, 1, EndRepaintDoodle
	sw $t2, 652($t9)
	sw $t2, 780($t9)
	sw $t2, 908($t9)
	sw $t2, 1164($t9)
	sw $t2, 1420($t9)
EndRepaintDoodle:
	jr $ra
		
RepaintPlatforms:
	lw $t9, rocket
	lw $t8, displayAddress
	blt $t9, $t8, RepaintPfStart
	sw $t2, 12($t9)
	sw $t2, 140($t9)
	sw $t2, 136($t9)
	sw $t2, 144($t9)
RepaintPfStart:
	la $t9, platformArray
	li $t8, 0 # Repaint each platform
	lw $t4, displayAddress
	lw $t7, displayEndAddress
	IteratePlatform:
		beq $t8, 15, EndIterating
		lw $t5, 0($t9)
		blt $t5, $t4, NextPlatform
		bge $t5, $t7, NextPlatform
		sw $t2, 0($t5)
		sw $t2, 4($t5)
		sw $t2, 8($t5)
		sw $t2, 12($t5)
		sw $t2, 16($t5)
		sw $t2, 20($t5)
		sw $t2, 24($t5)
		sw $t2, 28($t5)
	NextPlatform:
		addi $t8, $t8, 1
		addi $t9, $t9, 4
		j IteratePlatform
	EndIterating:
		jr $ra
		
CheckCharPos:
	lw $t9, displayEndAddress
	lw $t8, charAddress 
	addi $t8, $t8, 768
	bge $t8, $t9, ConfirmExit
	jr $ra
	
RegeneratePlatform:
	la $t9, platformArray
	addi $t8, $t9, 60 # Loop End
	lw $t4, platformLowerBound # Lower bound for the random numbers
	lw $s7, displayEndAddress
	RegeneratePlatformLoop:
		bge $t9, $t8, RegeneratePlatformEnd
		lw $t7, 0($t9)
		blt $t7, $s7, RegenerateNext
		lw $t6, displayAddress
		li $v0, 42
		li $a0, 0
		li $a1, 24
		syscall # Random generate a platform's x position
		addi $s0, $zero, 4
		mult $a0, $s0
		mflo $s0
		add $t6, $t6, $s0
		li $v0, 42
		li $a0, 0
		li $a1, 4
		syscall # Random generate a platform's y position
		add $a0, $a0, $t4 # Add to the lower bound for a y position that fits the lower bound
		#add $a0, $a0, $s5
		addi $s0, $zero, 128
		mult $a0, $s0
		mflo $s0
		add $t6, $t6, $s0
		sw $t6, 0($t9)
		lw $s5, platformGap
		sub $t4, $t4, $s5
		addi $t4, $t4, -4
	RegenerateNext:
		addi $t9, $t9, 4
		j RegeneratePlatformLoop
	RegeneratePlatformEnd:
		sw $t4, platformLowerBound
	jr $ra
		
StartMessage:
	lw $t9, displayMidAddress
	#S
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 148($t9)
	sw $t1, 136($t9)
	sw $t1, 264($t9)
	sw $t1, 392($t9)
	sw $t1, 396($t9)
	sw $t1, 400($t9)
	sw $t1, 404($t9)
	sw $t1, 532($t9)
	sw $t1, 660($t9)
	sw $t1, 788($t9)
	sw $t1, 784($t9)
	sw $t1, 780($t9)
	sw $t1, 648($t9)
	# :
	sw $t1, 156($t9)
	sw $t1, 668($t9)
	# s
	sw $t1, 40($t9)
	sw $t1, 44($t9)
	sw $t1, 48($t9)
	sw $t1, 180($t9)
	sw $t1, 168($t9)
	sw $t1, 296($t9)
	sw $t1, 424($t9)
	sw $t1, 428($t9)
	sw $t1, 432($t9)
	sw $t1, 436($t9)
	sw $t1, 564($t9)
	sw $t1, 692($t9)
	sw $t1, 820($t9)
	sw $t1, 816($t9)
	sw $t1, 812($t9)
	sw $t1, 680($t9)
	#T
	sw $t1, 56($t9)
	sw $t1, 60($t9)
	sw $t1, 64($t9)
	sw $t1, 188($t9)
	sw $t1, 316($t9)
	sw $t1, 444($t9)
	sw $t1, 572($t9)
	sw $t1, 700($t9)
	sw $t1, 828($t9)
	#A
	sw $t1, 72($t9)
	sw $t1, 76($t9)
	sw $t1, 80($t9)
	sw $t1, 200($t9)
	sw $t1, 328($t9)
	sw $t1, 456($t9)
	sw $t1, 460($t9)
	sw $t1, 584($t9)
	sw $t1, 712($t9)
	sw $t1, 840($t9)
	sw $t1, 208($t9)
	sw $t1, 336($t9)
	sw $t1, 464($t9)
	sw $t1, 592($t9)
	sw $t1, 720($t9)
	sw $t1, 848($t9)
	#R
	sw $t1, 88($t9)
	sw $t1, 216($t9)
	sw $t1, 344($t9)
	sw $t1, 472($t9)
	sw $t1, 476($t9)
	sw $t1, 600($t9)
	sw $t1, 604($t9)
	sw $t1, 728($t9)
	sw $t1, 736($t9)
	sw $t1, 856($t9)
	sw $t1, 864($t9)
	sw $t1, 92($t9)
	sw $t1, 96($t9)
	sw $t1, 224($t9)
	sw $t1, 352($t9)
	sw $t1, 480($t9)
	#T
	sw $t1, 104($t9)
	sw $t1, 108($t9)
	sw $t1, 112($t9)
	sw $t1, 236($t9)
	sw $t1, 364($t9)
	sw $t1, 492($t9)
	sw $t1, 620($t9)
	sw $t1, 748($t9)
	sw $t1, 876($t9)
	jr $ra
	
EndMessage:
	lw $t9, displayMidAddress
	addi $t9, $t9, -1280
	#o
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)
	sw $t1, 148($t9)
	sw $t1, 276($t9)
	sw $t1, 136($t9)
	sw $t1, 264($t9)
	sw $t1, 392($t9)
	sw $t1, 396($t9)
	sw $t1, 400($t9)
	sw $t1, 404($t9)
	# v
	sw $t1, 32($t9)
	sw $t1, 40($t9)
	sw $t1, 160($t9)
	sw $t1, 288($t9)
	sw $t1, 168($t9)
	sw $t1, 296($t9)
	sw $t1, 420($t9)
	# e
	sw $t1, 48($t9)
	sw $t1, 52($t9)
	sw $t1, 56($t9)
	sw $t1, 176($t9)
	sw $t1, 184($t9)
	sw $t1, 304($t9)
	sw $t1, 308($t9)
	sw $t1, 312($t9)
	sw $t1, 432($t9)
	sw $t1, 560($t9)
	sw $t1, 564($t9)
	sw $t1, 568($t9)
	#r
	sw $t1, 68($t9)
	sw $t1, 196($t9)
	sw $t1, 324($t9)
	sw $t1, 452($t9)
	sw $t1, 200($t9)
	sw $t1, 76($t9)
	sw $t1, 80($t9)
	#!
	sw $t1, 92($t9)
	sw $t1, 220($t9)
	sw $t1, 348($t9)
	sw $t1, 476($t9)
	sw $t1, 732($t9)
	
	addi $t9, $t9, 1280
	addi $t9, $t9, 1280
	
	#E
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 136($t9)
	sw $t1, 264($t9)
	sw $t1, 392($t9)
	sw $t1, 396($t9)
	sw $t1, 400($t9)
	sw $t1, 520($t9)
	sw $t1, 648($t9)
	sw $t1, 776($t9)
	sw $t1, 780($t9)
	sw $t1, 784($t9)
	# :
	sw $t1, 156($t9)
	sw $t1, 668($t9)
	# e
	sw $t1, 48($t9)
	sw $t1, 52($t9)
	sw $t1, 56($t9)
	sw $t1, 176($t9)
	sw $t1, 184($t9)
	sw $t1, 304($t9)
	sw $t1, 308($t9)
	sw $t1, 312($t9)
	sw $t1, 432($t9)
	sw $t1, 560($t9)
	sw $t1, 564($t9)
	sw $t1, 568($t9)
	#x
	sw $t1, 68($t9)
	sw $t1, 84($t9)
	sw $t1, 200($t9)
	sw $t1, 208($t9)
	sw $t1, 332($t9)
	sw $t1, 460($t9)
	sw $t1, 584($t9)
	sw $t1, 592($t9)
	sw $t1, 708($t9)
	sw $t1, 724($t9)
	#i
	sw $t1, 92($t9)
	sw $t1, 348($t9)
	sw $t1, 476($t9)
	sw $t1, 604($t9)
	sw $t1, 732($t9)
	#T
	sw $t1, 108($t9)
	sw $t1, 232($t9)
	sw $t1, 236($t9)
	sw $t1, 240($t9)
	sw $t1, 364($t9)
	sw $t1, 492($t9)
	sw $t1, 620($t9)
	sw $t1, 748($t9)
	sw $t1, 752($t9)
	jr $ra
	
ConfirmExit:
	jal Repaint
	jal StartMessage
	jal EndMessage
ExitInputListener:
	lw $t8, 0xffff0000 # Input Listener
	beq $t8, 1, DetectEnd
	beq $t8, 0, ExitInputListener
DetectEnd: 
	lw $t8, 0xffff0004
	beq $t8, 0x73, Start # If input s, start game
	beq $t8, 0x65, Exit
	j ExitInputListener

Exit:
	li $v0, 10 # terminate the program gracefully
	syscall
