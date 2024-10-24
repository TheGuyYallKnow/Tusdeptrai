.data
array:     .space 128         
newline:    .asciiz "\n"
comma_space: .asciiz ", "       
instruction:     .asciiz "Enter the string: "
input_array: .space 256        
semi_colon: .asciiz "; "
.text
.globl main
main:

    li $v0, 4                  
    la $a0, instruction             
    syscall


    li $v0, 8                  
    la $a0, input_array     
    li $a1, 256                
    syscall


    la $t0, array
    li $t1, 128
    li $t2, 0                
init_count:
    beq $t1, $zero, process_string 
    sb $t2, 0($t0)            
    addi $t0, $t0, 1           
    addi $t1, $t1, -1          
    j init_count

process_string:
    la $a0, input_array        
    la $t0, array             
loop_input:
    lb $t1, 0($a0)            
    beq $t1, $zero, print_chars  # neu het array thi print


    li $t4, ','         
    beq $t1, $t4, skip_char    
    li $t4, ' '                 
    beq $t1, $t4, skip_char   


    add $t2, $t1, $t0           # nhay toi o cura ky tu do 
    lb $t3, 0($t2)             
    addi $t3, $t3, 1            # +1
    sb $t3, 0($t2)              # 
skip_char:
    addi $a0, $a0, 1            # move to next
    j loop_input

print_chars:

    li $t1, 0                   # t1 luu giu gia tri cua character
    li $t7, 1                   # t7 la minimum frequency

print_loop:
    li $t4, 128                 # End at ASCII code 127
    beq $t1, $t4, increase_freq # If finished checking, check next frequency

    la $t0, array        
    add $t2, $t1, $t0         
    lb $t3, 0($t2)             


    bne $t3, $t7, next_char     # If frequency doesn't match, check next character


    li $t5, 32
    li $t6, 126
    blt $t1, $t5, next_char  
    bgt $t1, $t6, next_char    

    # IN character
    move $a0, $t1              
    li $v0, 11                 
    syscall

    # Print ", "
    la $a0, comma_space        
    li $v0, 4                 
    syscall

    # Print the count
    move $a0, $t3            
    li $v0, 1                
    syscall

    # Print "; "
    la $a0, semi_colon
    li $v0, 4
    syscall

next_char:
    addi $t1, $t1, 1            # Move to the next character in ASCII table
    j print_loop

increase_freq:
    addi $t7, $t7, 1           
    li $t1, 0                  
    li $t4, 128                
    bne $t7, $t4, print_loop    # Loop until all frequencies are printed

end:
    li $v0, 10                
    syscall
