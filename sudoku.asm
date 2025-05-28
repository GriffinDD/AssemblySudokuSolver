# File:	sudoku.asm
# Author: Griffin Danner-Doran, Section 2
# Description: Reads the given puzzle into the puzzle array and
#	       prints the puzzle/banners. Passes the puzzle to the
#	       backtracking module which solves the puzzle if possible
#
# Inputs:      36 ints, 1 per line which are read from STDIN into
#	       a 36 word array labeled puzzle
#
# Outputs:     The elements of the unsolved and solved
#	       puzzle printed in a 6x6 sudoku board
#	       along with various banners and error messages


	.data

str_banner:
	.asciiz "\n**************\n**  SUDOKU  **\n**************\n\n"
puzzle_banner1:
	.asciiz	"Initial Puzzle\n\n"
puzzle_banner2:
	.asciiz "\nFinal Puzzle\n\n"
line_break:
	.asciiz	"\n"
space:
	.asciiz " "
sep:
	.asciiz	"+-----+-----+\n"
border:
	.asciiz	"|"
error_message:
	.asciiz "ERROR: bad input value, Sudoku terminating"
unsolvable_error:
	.asciiz "\nImpossible Puzzle"

	.align 2
	.globl puzzle
puzzle:
	.word 0:36


	.text
	.globl main
	.globl find_solution

#
# Name:         main
#
# Description:  Entry point for the program. Calls the
#		solve_puzzle routine to read, display, and solve the puzzle
#
# Arguments:    None
#
# Returns:      None
#
main:
	addi	$sp, $sp, -4	#make space on stack frame
	sw	$ra, 0($sp)	#save $ra to stack
	jal 	solve_puzzle	#call puzzle reading and display routine
	lw	$ra, 0($sp)	#restore $ra from stack
	addi	$sp, $sp, -4	#reset stack pointer
	jr	$ra		#end program


#
# Name:         solve_puzzle
#
# Description:  Main control function for the program. Calls
#		functions to read, solve, and print the puzzle.
#		Also handles error cases for bad inputs or bad puzzles
#
# Arguments:    None
#
# Returns:      None
#
solve_puzzle:
	addi 	$sp, $sp, -4	#make space on stack frame
	sw 	$ra, 0($sp)	#save $ra to stack
	li	$v0, 4		#load syscall for print string
	la	$a0, str_banner	#print starting banner
	syscall
	jal	read_puzzle	#call function to read the given puzzle
	bgez	$v0, no_error	#if error code was 0, no error occured
				#so jump to no_error and solve normally

	li	$v0, 4		#else, load syscall for print string
	la	$a0, error_message	#print error message for invalid input
	syscall
	j	end_init	#jump to function end

no_error:	#solves and displays the puzzle if valid inputs given
	li	$v0, 4		#load syscall for print string
	la	$a0, puzzle_banner1	#print initial puzzle banner
	syscall
	jal	print_puzzle	#print the initial puzzle
	move	$a0, $zero	#set first row to check to zero
	move	$a1, $zero	#set first col to check to zero
	jal	find_solution	#call function to solve the given puzzle
	bltz	$v0, unsolvable	#jump to unsolvable error case if
				#no path was found($v0 == -1)
	li	$v0, 4		#else, load syscall for print string
	la	$a0, puzzle_banner2	#print final puzzle banner
	syscall
	jal 	print_puzzle	#print the final puzzle
 	j 	end_init	#jump to function end

unsolvable:	#prints error for impossible puzzle
	li	$v0, 4		#load syscall for print string
	la	$a0, unsolvable_error	#print unsolvable error message
	syscall
end_init:
	li	$v0, 4		#load syscall for print string
	la	$a0, line_break	#print a line break at the end
	syscall
	lw	$ra, 0($sp)	#restore $ra from stack
	addi	$sp, $sp, 4	#reset stack pointer
	jr	$ra 		#return to main


#
# Name:         read_puzzle
#
# Description:  This program reads the 36 given ints into puzzle
#		and makes sure they are valid inputs 0 - 6
#
# Arguments:    None
#
# Returns: 	v0: -1 if an invalid int is read, 0 otherwise
#
read_puzzle:
	addi 	$sp, $sp, -8	#make space on stack frame
	sw 	$ra, 0($sp)	#save $ra to stack
	sw	$s0, 4($sp)	#save $s0 to stack
	move	$t0, $zero	#set $t0 to zero
	addi	$t1, $zero, 36	#set $t1 as loop counter max
	la	$s0, puzzle	#use $s0 to hold puzzle address

read_inputs:	#reads all 36 ints given, checks for invalid inputs
	beq	$t0, $t1, exit	#end loop after 36 times
	li	$v0, 5		#load syscall for read int
	syscall
	slti	$t2, $v0, 7	#check if value is less than 7
	beq	$t2, $zero, error	#go to error case if >= 7
	bltz	$v0, error	#go to error case if value is negative
	sw	$v0, 0($s0)	#Otherwise, save new value to puzzle array
	addi	$t0, $t0, 1	#increment $t0 counter
	addi	$s0, $s0, 4	#increment to next puzzle array element
	move	$v0, $zero	#set $v0 to zero
	j	read_inputs	#jump to start of loop

error:		#returns error code -1 if non 0 - 6 value is read
	addi	$v0, $zero, -1	#set function return to error code -1
exit:
	lw	$ra, 0($sp)	#restore $ra from stack
	lw	$s0, 4($sp)	#restore $s0 from stack
	addi	$sp, $sp, 8	#reset stack pointer
	jr	$ra		#return to caller


#
# Name:         print_puzzle
#
# Description:  prints the elements currently in the puzzle array
#		in the 6x6 sudoku board format
#
# Arguments:    None
#
# Returns:      None
#
print_puzzle:
	addi 	$sp, $sp, -8	#make space on stack frame
	sw 	$ra, 0($sp)	#save $ra to stack
	sw	$s0, 4($sp)	#save $s0 to stack
	move	$t0, $zero	#set $t0 to zero
	la	$s0, puzzle	#use $s0 to hold puzzle address

print_loop:	#loops once for each of the 3 rows of 2x3 boxes
	li	$v0, 4		#load syscall for print string
	la	$a0, sep	#print sep between row boxes
	syscall
	slti	$t1, $t0, 3	#check if all 3 box rows are printed
	beq	$t1, $zero, print_complete	#if so, go to program end
	addi	$t0, $t0, 1	#else increment box row counter
	addi	$t3, $zero, 2	#reset counter for rows in each 2x3 box

row_loop:	#loops 2 times, once for each of the 2 rows in a 2x3 row box
	beq	$t3, $zero, print_loop	#jump to next box row when 2 rows printed
	addi	$t3, $t3, -1	#decrement $t3 counter
	addi	$t4, $zero, 2	#set $t4 counter to 2
	move	$t5, $zero	#set $t5 counter to zero

in_rowloop:	#loops for each of the 6 ints and the 3 borders in a row
	slti	$t7, $t5, 4	#check if a new border is needed
	bne	$t7, $zero, box_start	#go normally if box is incomplete
	move	$t5, $zero	#reset to next box in row
	addi	$t4, $t4, -1	#decrement the boxes in this row that are empty
	beq	$t4, $zero, row_border	#if both boxes in this row are empty,
					#print the right puzzle border

box_start: 	#prints out the next element in the row or a border
	beq	$t5, $zero, row_border	#if this is the start of a row
					#go the the border print case
	lw	$t6, 0($s0)	#Otherwise, load next int to print
	addi	$s0, $s0, 4	#increment puzzle array pointer
	beq	$t6, $zero, blank_case	#if int is zero, print a space
	li	$v0, 1		#load syscall for print int
	move	$a0, $t6	#print next int as the cell element
	syscall
	j	normal_case	#dont print extra space if int was printed

blank_case: 	#prints out a space for 0 values in an initial puzzle
	li	$v0, 4		#load syscall for print string
	la	$a0, space	#print space as the cell element
	syscall

normal_case:	#checks if a space needs to be printed after the element
	addi $t5, $t5, 1	#increment row char counter
	slti	$t7, $t5, 4	#check if this character is against a box edge
	beq	$t7, $zero, in_rowloop	#if so, evaluate next char without a space
	li	$v0, 4		#load syscall for print string
	la	$a0, space	#print space between characters
	syscall
	j in_rowloop		#loop to print next char

row_border: 	#prints out a border between boxes and at puzzle edges
	li	$v0, 4		#load syscall for print string
	la	$a0, border	#print border line
	syscall
	addi	$t5, $t5, 1	#increment row char counter
	bne	$t4, $zero, in_rowloop	#if not the end of a puzzle row,
					#start to print the next box in this row
	li	$v0, 4		#load syscall for print string
	la	$a0, line_break	#print line break for next row
	syscall
	move	$t5, $zero	#reset row char counter
	j 	row_loop	#jump to start of row loop
print_complete:
	lw	$ra, 0($sp)	#restore $ra from stack
	lw	$s0, 4($sp)	#restore $s0 from stack
	addi	$sp, $sp, 8	#reset stack pointer
	jr	$ra		#return to caller 
