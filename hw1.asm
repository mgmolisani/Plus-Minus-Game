### PLUS MINUS GAME ###
# Use the MARS command line to pass in a single argument string of + and -

.globl main
.data
  	default_str: .asciiz "+--+++---+---++-+-+--+-"
  	.align 2
  	string: .space 4
  	label_pre_str: .asciiz "String: "
  	label_post_str: .asciiz "\n"
  	winnable_str: .asciiz "Result: Winnable\n"
  	not_winnable_str: .asciiz "Result: Not Winnable\n"
.text

# The main process
main:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# Store string or use default
	jal get_str
	# Print the string
	jal print_label
	lw $a0, string
	# Find who won
	jal isWinnable
	move $a0, $v0
	# Print the result
	jal print_result
	lw $ra, 0($sp)
	addi $sp, $sp, 4
        li $v0, 10       	# system call 10 is exit()
        li $a0, 0          	# setting return code of program to 0 (success)
	syscall			# Equivalent to "return" statement in main.

# Returns the initial string depending on if there were command args
get_str:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# if (argc == 2) 
	# NOTE: We actually check (argc == 1) as default behavior is not to save program name in argv[0] like in C
	li $t0, 1
	bne $a0, $t0, get_str_else
	lw $t1, 0($a1)
	# string = argv[1];
	sw $t1, string
	j str_return
get_str_else:
	# string = strdup(default_str);
	la $a0, default_str
	jal strdup
	sw $v0, string
str_return:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
# String duplicate. Uses the strlen function and pseudoinstruction to allocate memory in the heap before copying the string
strdup:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	move $s0, $a0
	jal strlen
	move $a0, $v0
	li $v0, 9
	syscall
	# int i = 0;
	li $t1, 0
strdup_loop:
	# i < length
	bge $t1, $a0, exit_loop_str
	add $t2, $s0, $t1
	add $t3, $v0, $t1
	# copy
	lb $t4, 0($t2)
	sb $t4, 0($t3)
	# i++
	addi $t1, $t1, 1
	j strdup_loop
exit_loop_str:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	addi $sp, $sp, 8
	# v0 = ptr to allocated heap mem
	jr $ra
	
# int isWinnable(char *str)
# $a0 = *str
isWinnable:
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp) # len
	sw $s1, 8($sp) # result
	sw $s2, 12($sp) # i
	sw $s3, 16($sp) # str store
	# int len = strlen(str);
	move $s3, $a0
	jal strlen
	move $s0, $v0
	move $a0, $s3
	# int result = 1;
	li $s1, 1
	# loop init
	# int i = 0
	li $s2, 0
	# len - 1;
	subi $s0, $s0, 1
for_loop:
	# i < len - 1;
	bge $s2, $s0, exit_loop
	add $t0, $a0, $s2
	addi $t1, $t0, 1
	lb $t2, 0($t0) # str[i]
	lb $t3, 0($t1) # str[i+1]
	# if (str[i] == '-' && str[i+1] == '-') 
	bne $t2, '-', else
	bne $t3, '-', else
	# str[i] = str[i+1] = '+';
	li $t4, '+'
	sb $t4, ($t0) # str[i]
	sb $t4, ($t1) # str[i+1]
	# result = !isWinnable(str);
	jal isWinnable
	slti $s1, $v0, 1
	add $t0, $a0, $s2
	addi $t1, $t0, 1
	# str[i] = str[i+1] = '-';
	li $t4, '-'
	sb $t4, ($t0) # str[i]
	sb $t4, ($t1) # str[i+1]
	# if (result)
	beqz $s1, else
	# return 1;
	li $v0, 1
	j isWinnable_return
else:
	# i++
	addi $s2, $s2, 1
	j for_loop
exit_loop:
	# return result;
	move $v0, $s1
isWinnable_return:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	addi $sp, $sp, 20
	jr $ra

# String length. Used in isWinnable and in strdup. Recursive search through the string for the null termination.
strlen:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $v0, 0
strlen_loop:
	lb $t0, 0($a0)
	beqz $t0, strlen_return
	addi $v0, $v0, 1
	addi $a0, $a0, 1
	j strlen_loop
strlen_return:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
# printf() helper
print_str:
	li $v0, 4
	syscall
	jr $ra

# Prints the string that is being evaluated.
# printf("String: %s\n", string);
print_label: 
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, label_pre_str
	jal print_str
	lw $a0, string
	jal print_str
	la $a0, label_post_str
	jal print_str
print_label_return:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Prints the result of the game.
print_result:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# if (isWinnable(string))
	beqz $a0, print_not_winnable
	la $a0, winnable_str
	# printf ("Result: Winnable\n");
	jal print_str
	j print_result_return
print_not_winnable:
	la $a0, not_winnable_str
	# printf ("Result: Not Winnable\n");
	jal print_str
print_result_return:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
