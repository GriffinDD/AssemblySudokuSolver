# File:  backtrack.asm
# Author: Griffin Danner-Doran, Section 2
# Description: Solves the puzzle read in and stored by sudoku.asm
#	       Starts from the upper leftmost cell of the supplied puzzle
#	       and uses backtracking to resolve empty cells, directly modifies puzzle array.
#	       Returns 1 or -1 to sudoku.asm, with 1 meaning a complete puzzle
#	       and -1 meaning an impossible puzzle
#
# Inputs:     The 36 word puzzle array created and populated in sudoku.asm
#
# Outputs:    A solved version of the puzzle array and $v0 = 1
#	      when the puzzle can be solved, else incomplete puzzle
#	      and $v0 = -1 if not



	.text
	.align 2
	.globl  puzzle
	.globl  find_solution


#
# Name:         find_solution
#
# Description:  A recursive backtracking function that solves the given cell
#		and recurses to the next cell in the puzzle array, fills in
#		all empty cells and returns 1 if a solution exists. Otherwise,
#		returns an error code.
#
# Arguments:	a0: the row to check, indexed 0 - 5
#		a1: the col to check, indexed 0 - 5
#
# Returns:	v0: 1 if valid solution from this cell, -1 otherwise
#		note: a return of -1 from the initial call(cell 0,0)
#		indicates an impossible puzzle and triggers
#		the error message to be printed in sudoku.asm.
#		For other cells, it is used to prune invalid solutions.
find_solution:
	addi    $sp, $sp, -28   #make space on stack frame
        sw      $ra, 0($sp)     #save $ra to stack
        sw      $s0, 4($sp)     #save $s0 to stack
	sw      $s1, 8($sp)     #save $s1 to stack
	sw      $s2, 12($sp)    #save $s2 to stack
	sw	$s3, 16($sp)	#save $s3 to stack
	sw	$a0, 20($sp)	#save $a0 to stack
	sw	$a1, 24($sp)	#save $a1 to stack
	move	$s1, $zero	#set $s1 to zero
	move	$s2, $a0	#store $a0 in $s2
	move	$s3, $a1	#store $a1 in $s3
	addi	$v0, $zero, -1	#$v0 defaults to -1
	addi	$t0, $zero, 6	#save the max number of cols in $t0
	bne	$t0, $s3, recurse	#run normal recursion if not
					#on col 6, reset to next row otherwise

end_of_row:	#resets col counter and checks if final cell has been reached
	addi	$t0, $t0, -1	#decrement $t0 down to 5
	beq	$t0, $s2, solved	#jump to success case if also on row 5
					#(ie last solved cell was col 5, row 5)
	move	$s3, $zero	#otherwise, reset col to zero
	addi	$s2, $s2, 1	#and prepare to check next row

recurse:	#attempts to solve the supplied cell
	la	$s0, puzzle	#load address of puzzle into $s0
	mul	$t0, $s2, 24	#set $t0 to offset of row
	add	$s0, $s0, $t0	#set $s0 to address of given row
	mul	$t0, $s3, 4	#set $t0 to offset of col
	add	$s0, $s0, $t0	#set $s0 to address of given cell
	lw	$t0, 0($s0)	#load the item in said cell
	beq	$t0, $zero, test_values	#if item is 0, jump to value tests
	move 	$s1, $t0	#else, save current item to $s1
	move	$a2, $s1	#move current item to $a2
	move	$a0, $s2	#move row to check into $a0
	move	$a1, $s3	#move col to check into $a1
	sw	$zero, 0($s0)	#save zero in this cell so it is not considered
				#a copy of itself when tested

	jal	test_valid	#make sure that this supplied element is valid
				#to ensure the given puzzle is solvable
	sw	$s1, 0($s0)	#restore the element to its cell
	bltz	$v0, end	#return -1 if this cell is invalid
	addi	$a1, $s3, 1	#otherwise, increment col to check
	jal	find_solution	#and recurse on that cell
	j	end		#jump to end afterwards

test_values:	#tests each value 1-6 for validity in an empty cell
	addi	$s1, $s1, 1	#increment $s1 to the next cell possiblity, up to 6
	slti	$t0, $s1, 7	#check if all possible elements have been tested
	beq	$t0, $zero, end	#and exit loop if all elments checked
	move	$a0, $s2	#move row to check into $a0
	move	$a1, $s3	#move col to check into $a1
	move	$a2, $s1	#move tested input into $a2
	jal	test_valid	#test if the cell is valid
	bltz	$v0, test_values	#test next input if cell is invalid
	sw	$s1, 0($s0)	#otherwise, save value since it is valid
	addi	$a1, $s3, 1	#increment to next column
	move	$a0, $s2	#make sure $a0 has row to check
	jal	find_solution	#recurse on next cell
	bgez	$v0, end	#end recursion if this path is valid
	sw	$zero, 0($s0)	#otherwise this path is invalid, so reset cell to 0
	j	test_values	#repeat loop for other test inputs
solved:
	addi	$v0, $zero, 1	#set $v0 to 1 if whole problem is solved
end:
        lw      $ra, 0($sp)     #restore $ra from stack
        lw      $s0, 4($sp)     #restore $s0 from stack
	lw      $s1, 8($sp)     #restore $s1 from stack
	lw      $s2, 12($sp)    #restore $s2 from stack
	lw	$s3, 16($sp)	#restore $s3 from stack
        lw      $a0, 20($sp)    #restore $a0 from stack
        lw      $a1, 24($sp)    #restore $a1 from stack
	addi	$sp, $sp, 28	#reset stack pointer
	jr	$ra		#jump to caller


#
# Name:         test_valid
#
# Description:  checks if the cell described by the given
#		row and col is valid by all 3 criteria
#		with the given value
#
# Arguments:    a0: the row to check, indexed 0 - 5
#		a1: the col to check, indexed 0 - 5
#               a2: the number to check for, 1 - 6
#
# Returns:      v0: -1 if the element is invalid, 1 otherwise
test_valid:
	addi    $sp, $sp, -24   #make space on stack frame
        sw      $ra, 0($sp)     #save $ra to stack
        sw      $s0, 4($sp)     #save $s0 to stack
	sw      $s1, 8($sp)     #save $s1 to stack
	sw      $s2, 12($sp)    #save $s2 to stack
	sw	$a0, 16($sp)	#save $a0 to stack
	sw	$a1, 20($sp)	#save $a1 to stack
	move	$s0, $a2	#set $s0 to given value
	move	$s1, $a0	#store $a0 in $s1
	move	$s2, $a1	#store $a1 in $s2
	addi	$v0, $zero, 1	#$v0 defaults to 1, a valid input

	move	$a1, $s0	#move tested input into $a1
	move	$a0, $s1	#move row to check into $a0
	jal	check_row	#check if row is valid with input
	bltz	$v0, test_end	#return invalid if row is invalid
	move	$a0, $s2	#move col to check into $a0
	jal	check_column	#check if col is valid with input
	bltz	$v0, test_end	#return invalid if col is invalid
	move	$a0, $s1	#move row into $a0
	move	$a1, $s2	#move col into $a1
	move	$a2, $s0	#move test input into $a2
	jal	check_box	#test if box is valid with input
test_end:
     	lw      $ra, 0($sp)     #restore $ra from stack
        lw      $s0, 4($sp)     #restore $s0 from stack
	lw      $s1, 8($sp)     #restore $s1 from stack
	lw      $s2, 12($sp)    #restore $s2 from stack
        lw      $a0, 16($sp)    #restore $a0 from stack
        lw      $a1, 20($sp)    #restore $a1 from stack
	addi	$sp, $sp, 24	#reset stack pointer
	jr	$ra		#return to caller


#
# Name:         check_column
#
# Description:  checks all elements in the given col
#               and looks for copies of the given value
#
# Arguments:    a0: the col to check, indexed 0 - 5
#               a1: the number to check for, 1 - 6
#
# Returns:      v0: -1 if there is a copy of the given element, 1 otherwise
check_column:
	mul	$t0, $a0, 4	#multiply col location by 4 to get offset
	la	$t1, puzzle	#load puzzle array address into $t1
	add	$t0, $t0, $t1	#set $t0 to address of row 0, col a0
	move	$t1, $zero	#set $t1 counter to zero
	addi	$v0, $zero, 1	#default case is no copy found

column_loop:	#checks all 6 rows in the given column
	slti	$t2, $t1, 6	#check if all rows have been covered
	beq	$t2, $zero, column_end	#exit loop if rows 0-5 checked
	addi	$t1, $t1, 1	#increment counter $t1
	lw	$t2, 0($t0)	#load the current element viewed
	addi	$t0, $t0, 24	#increment to next row
	bne	$t2, $a1, column_loop	#continue loop if not a copy
	addi	$v0, $zero, -1	#set return to -1 since copy found
column_end:
	jr	$ra		#return to caller


#
# Name:         check_row
#
# Description:  checks all elements in the given row
#               and looks for copies of the given value
#
# Arguments:    a0: the row to check, indexed 0 - 5
#               a1: the number to check for, 1 - 6
#
# Returns:      v0: -1 if there is a copy of the given element, 1 otherwise
check_row:
        mul	$t0, $a0, 24    #multiply row location by 24 to get offset
	la	$t1, puzzle	#load puzzle array address into $t1
	add	$t0, $t0, $t1	#set $t0 to address of row a0, col 0
        move    $t1, $zero      #set $t1 counter to zero
        addi    $v0, $zero, 1   #default case is no copy found

row_loop:	#checks all 6 columns in the given row
        slti    $t2, $t1, 6     #check if all cols have been covered
        beq     $t2, $zero, row_end  #exit loop if cols 0-5 checked
	addi	$t1, $t1, 1	#increment counter $t1
        lw      $t2, 0($t0)     #load the current element viewed
        addi    $t0, $t0, 4    #increment to next col
        bne     $t2, $a1, row_loop   #continue loop if not a copy
        addi    $v0, $zero, -1  #set return to -1 since copy found
row_end:
	jr	$ra		#return to caller


#
# Name:         check_box
#
# Description:  checks all elements in the box containing
#		the cell described by the given row and col
#		and looks for copies of the given value
#
# Arguments:    a0: the row to check, indexed 0 - 5
#		a1: the col to check, indexed 0 - 5
#               a2: the number to check for, 1 - 6
#
# Returns:      v0: -1 if there is a copy of the given element, 1 otherwise
check_box:
	div	$t0, $a0, 2	#find which box row this cell is
	mul	$t0, $t0, 48	#get the offset of the box's upper row
	div	$t1, $a1, 3	#get which box col this cell is
	mul	$t1, $t1, 12	#get the offset of the box's leftmost col
	add	$t0, $t0, $t1	#get the offset of the box's upper left element
	la	$t1, puzzle	#load puzzle array address into $t1
	add	$t0, $t0, $t1 	#set $t0 to address of upper left element
	addi	$v0, $zero, 1	#default case is no copy found
	addi	$t2, $zero, 2	#set $t2 counter to 2
	addi	$t3, $zero, 3	#set $t3 counter to 3
	j	check_box_cols	#start loop through the box's cols

check_box_rows:	#checks each of the 2 rows in the box
	addi	$t3, $zero, 3	#reset col counter to 3
	addi	$t0, $t0, 12	#adjust address to be the first col, second row of target box

check_box_cols:	#check each of the 3 cols in each row
	lw	$t4, 0($t0)	#load next element in the box
	addi	$t0, $t0, 4	#increment to next col
	beq	$t4, $a2, copy_found	#jump to copy case if copy found
	addi	$t3, $t3, -1	#otherwise, decrement col counter
	bne	$t3, $zero, check_box_cols	#jump to start of inner loop if not all cols in row are checked
	addi	$t2, $t2, -1	#decrement row counter
	bne	$t2, $zero, check_box_rows	#jump to outer loop if not all rows are checked
	j	box_end		#go to end case once both loops end
copy_found:
	addi	$v0, $zero, -1	#set $v0 to -1 if copy found
box_end:
	jr	$ra		#return to caller
