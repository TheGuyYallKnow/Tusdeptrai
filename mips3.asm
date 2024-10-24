.data
array:         .space 40  
prompt_insert: .asciiz "Please insert element "
newline:       .asciiz "\n"
prompt1:       .asciiz "Second largest value is: "
prompt2:       .asciiz ", found at index: "
no_second_largest: .asciiz "No second largest value found."
comma:         .asciiz ", " 

.text
        li $t0, 0               # $t0 là bi?n ??m cho vòng l?p
input_loop:
        li $t2, 10              # T?ng s? ph?n t? m?ng là 10
        blt $t0, $t2, continue_input  
        j find_largest          # nh?p xong thì tìm giá tr? l?n nh?t

continue_input:
        # IN Prompt Insert
        li $v0, 4     
        la $a0, prompt_insert
        syscall

        # In ch? s? ph?n t?
        li $v0, 1
        move $a0, $t0
        syscall

        # In dòng m?i
        li $v0, 4
        la $a0, newline
        syscall

        # Nh?p ph?n t? 
        li $v0, 5     
        syscall
        la $t1, array   
        sll $t2, $t0, 2         # Tính offset
        add $t1, $t1, $t2   
        sw $v0, 0($t1)      

        addi $t0, $t0, 1        # T?ng bi?n ??m
        j input_loop            # Vòng l?p nh?p

find_largest:
        # T?o bi?n Large1 và Large2
        li $t3, -10000          # $t3 = Large1
        li $t4, -10000          # $t4 = Large2
        li $t0, 0               # i = 0
        la $t1, array           # ??a ch? c?a m?ng

        # Vòng l?p tìm ph?n t? l?n nh?t (Large1)
find_large1_loop:
        li $t2, 10
        blt $t0, $t2, process_large1  # N?u $t0 < 10 thì ti?p t?c tìm Large1
        j find_large2           # N?u ?ã xong thì tìm Large2

process_large1:
        lw $t5, 0($t1)          # $t5 = arr[i]
        blt $t5, $t3, next1     # N?u arr[i] < Large1 thì b? qua
        move $t3, $t5           # Large1 = arr[i]
        
next1:
        addi $t1, $t1, 4        # T?ng ??a ch? c?a m?ng
        addi $t0, $t0, 1
        j find_large1_loop      # Quay l?i vòng l?p

find_large2:
        # Reset l?i bi?n ??m và ??a ch? m?ng ?? tìm Large2
        li $t0, 0               # i = 0
        la $t1, array           # ??a ch? c?a m?ng

find_large2_loop:
        li $t2, 10
        blt $t0, $t2, process_large2  # N?u $t0 < 10 thì ti?p t?c tìm Large2
        j print_value           # N?u ?ã xong thì in giá tr?

process_large2:
        lw $t5, 0($t1)          # $t5 = arr[i]
        beq $t5, $t3, next2     # N?u arr[i] == Large1, b? qua
        blt $t5, $t4, next2     # N?u arr[i] <= Large2, b? qua
        move $t4, $t5           # Large2 = arr[i]

next2:
        addi $t1, $t1, 4        # T?ng ??a ch? c?a m?ng
        addi $t0, $t0, 1
        j find_large2_loop      # Quay l?i vòng l?p

print_value:
        # Ki?m tra n?u không tìm th?y Large2
        li $t6, -10000
        beq $t4, $t6, no_second_largest_message

        # In giá tr? Large2
	li $v0, 4        
        la $a0, prompt1
        syscall

        li $v0, 1           
        move $a0, $t4           # In Large2
        syscall

        # In các ch? s? c?a Large2
        li $t0, 0               # i = 0
        la $t1, array           # Reset l?i ?? tr? v? array[0]
        li $t7, 0               # $t7 dùng ?? ki?m tra xem có in d?u ph?y hay không

print_index_loop:
        li $t2, 10
        blt $t0, $t2, process_index  # N?u $t0 < 10 thì ti?p t?c in ch? s?
        j end_program           # K?t thúc ch??ng trình

process_index:
        lw $t5, 0($t1)          # $t5 = arr[i]
        bne $t5, $t4, next3     # N?u arr[i] != Large2 thì b? qua

        # In d?u ph?y n?u không ph?i ch? s? ??u tiên
        li $t6, 0
        beq $t7, $t6, skip_comma
        li $v0, 4
        la $a0, comma
        syscall

skip_comma:
        # In chu?i "found at index: " sau khi in s? ??u tiên
        li $t6, 0
        beq $t7, $t6, first_index_label
        j print_number

first_index_label:
        li $v0, 4
        la $a0, prompt2
        syscall
        addi $t7, $t7, 1        # ?ánh d?u r?ng ?ã in ch? s? ??u tiên

print_number:
        # In ch? s? i (0-based index)
        li $v0, 1
        move $a0, $t0
        syscall

next3:
        addi $t1, $t1, 4        # T?ng ??a ch? c?a m?ng
        addi $t0, $t0, 1
        j print_index_loop      # Quay l?i vòng l?p

no_second_largest_message:
        # In thông báo không tìm th?y Large2
        li $v0, 4
        la $a0, no_second_largest
        syscall
        j end_program

end_program:
        li $v0, 10         
        syscall