.data
    .equ LF,            10
    .equ NULL,          0
    .equ TRUE,          1
    .equ FALSE,         0
    .equ EXIT_SUCCESS,  0
    .equ STDIN,         0
    .equ STDOUT,        1
    .equ STDERR,        2
    .equ SYS_exit,      1
    .equ SYS_fork,      2
    .equ SYS_read,      3
    .equ SYS_write,     4
    .equ SYS_open,      5
    .equ SYS_close,     6
    .equ SYS_creat,     8
    .equ SYS_time,      13

    options_array: # array to fill out options
        .long 0 # hex
        .long 0 # decimal
        .long 0 # signed
        .long 0 # question
    
    longest_length:
        .long 0 # length of output binary string

    arguments:
        .long 0 # argument 1
        .long 0 # argument 2
    
    arg_lengths:
        .long 0 # argument 1 length
        .long 0 # arg 2 length

    solution:
        .long 0 # solution value

    carry_overflow:
        .long 0 # carry
        .long 0 # overflow

    msigbit:
        .long 0 # msb

    carry_string:
        .string " C"

    overflow_string:
        .string " O"

    negative_decimal_output:
        .long 0 # if set then print a hyphen before value of solution

    .operations:  # jump table to perform an operation
        .long .A  # x = 0
        .long .D  # x = 1
        .long .I  # x = 2
        .long .L  # x = 3
        .long .M  # x = 4
        .long .N  # x = 5
        .long .O  # x = 6
        .long .R  # x = 7
        .long .S  # x = 8
        .long .T  # x = 9
        .long .X  # x = 10
        .long .default

    question_flag_set:
        .string "Here is how to format input: $ binco [<option>] [<operator>] <arg1> [<arg2>]\n"

    newline:
        .string "\n"
    
.text
    .globl printString
    .globl main

main:
    pushl %ebp               # prologue
    movl  %esp, %ebp    
    pushl %ebx
    pushl %esi
    movl     $1, %ebx        # We're going to loop over the arguments, we have completed zero so far.
parse_options:
    movl    12(%ebp), %esi          # Get **argv pointer to the vector table
    movl    (%esi,%ebx,4), %esi     # Use the pointer to indirectly load the address of the
                                    # next command line argument. %ebx is the index
    cmpb $0x2D, (%esi)  # compare first byte to the esi register
    je option_checker
    
parse_options_indexing:
    incl    %ebx                    # Cool, we have completed one more argument
    cmpl    8(%ebp), %ebx           # argc is the first argument on the stack
    jl    parse_options         # if we have more to process, keep going



    movl $1, %ebx # start at first index of argc
parse_operation:
    cmpl 8(%ebp), %ebx # compare the index were at to the number of arguments
    je gather_input  # if we went through all the indexes and no operation, take in input

    movl    12(%ebp), %esi          # Get **argv pointer to the vector table
    pushl %esi # save the argv pointer for when we use it in the operation
    movl    (%esi,%ebx,4), %esi     # Use the pointer to indirectly load the address of the
                                    # next command line argument. %ebx is the index
    
    movl $11, %eax # incase no operation runs, start at default

    cmpb $0x41, (%esi) # if operation is A it will go to first index of jump table
    je operation_A
    cmpb $0x44, (%esi) # D operation
    je operation_D
    cmpb $0x49, (%esi) # I operation
    je operation_I
    cmpb $0x4C, (%esi) # L operation
    je operation_L
    cmpb $0x4D, (%esi) # M operation
    je operation_M
    cmpb $0x4E, (%esi) # N operation
    je operation_N
    cmpb $0x4F, (%esi) # O operation
    je operation_O
    cmpb $0x52, (%esi) # R operation
    je operation_R
    cmpb $0x53, (%esi) # S operation
    je operation_S
    cmpb $0x54, (%esi) # T operation
    je operation_T
    cmpb $0x58, (%esi) # X operation
    je operation_X

    cmpl $10, %eax
    jg .default

run_operation:
    jmp *.operations(,%eax, 4)  # go through jump table and run operation


gather_input: #no operations ran, only take binary input now
    movl $1, %ebx   # start at the first argument

take_in_argument:
    cmpl 8(%ebp), %ebx  # if we iterate past the final command line argument, move on
    je print_part
    movl    12(%ebp), %esi          # Get **argv pointer to the vector table
    movl    (%esi,%ebx,4), %esi     # Use the pointer to indirectly load the address of the
                                    # next command line argument. %ebx is the index
    cmpb $0x2D, (%esi)
    je is_an_option

input_is_validated:
    movl 12(%ebp), %esi # reload the argv pointer
    call translate_binary_string
    movl %edx, longest_length # store length of argument if printing in binary
    # check if theres another cla if so send an error
    movl %edx, arg_lengths # store length of arg
    movl %eax, solution  # store value in solution
   


print_part:

    cmpl $1, options_array
    je convert_to_hexadecimal 

    cmpl $1, options_array+4 
    je convert_to_decimal

    jmp convert_to_binary

print_carry:
    cmpl $1, carry_overflow
    je print_carry_flag

print_overflow:
    cmpl $1, carry_overflow+4
    je print_overflow_flag

done:
    movl $newline, %esi # print out newline at the end
    call printString 
    popl %esi
    popl %ebx 
    popl %ebp                       # epilogue
    movl $0, %eax
    ret


print_carry_flag:
    movl $carry_string, %esi
    call printString
    jmp print_overflow

print_overflow_flag:
    movl $overflow_string, %esi
    call printString
    jmp done


convert_to_hexadecimal:
    pushl %eax # save value to access for later
    movl $0, %edx # reset edx for counter
loop_register_digits:
    shrl $1, %eax
    incl %edx # add one to length of register
    cmpl $0, %eax # if register is zero jump out
    je decipher_number_hexadecimal_chars
    jmp loop_register_digits

decipher_number_hexadecimal_chars:
    popl %eax # return to value of eax
    cmpl $5, %edx
    jl one_hex_char
    cmpl $9, %edx
    jl two_hex_chars
    cmpl $13, %edx
    jl three_hex_chars
    cmpl $17, %edx
    jl four_hex_chars
    cmpl $21, %edx
    jl five_hex_chars
    cmpl $25, %edx
    jl six_hex_chars
    cmpl $29, %edx
    jl seven_hex_chars
    jmp eight_hex_chars

continue_converting_to_hex:
    cmpl $0, %eax # see if we need to convert anymore values
    je print_out_hex
    pushl %eax # save value of the register 
    andl $0xF, %eax # single out the bottom 4 bits in the eax reg
    cmpl $0, %eax
    je stack_add_zero
    cmpl $1, %eax
    je stack_add_one
    cmpl $2, %eax
    je stack_add_two
    cmpl $3, %eax
    je stack_add_three
    cmpl $4, %eax
    je stack_add_four
    cmpl $5, %eax
    je stack_add_five
    cmpl $6, %eax
    je stack_add_six
    cmpl $7, %eax
    je stack_add_seven
    cmpl $8, %eax
    je stack_add_eight
    cmpl $9, %eax
    je stack_add_nine
    cmpl $10, %eax
    je stack_add_A
    cmpl $11, %eax
    je stack_add_B
    cmpl $12, %eax
    je stack_add_C
    cmpl $13, %eax
    je stack_add_D
    cmpl $14, %eax
    je stack_add_E 
    jmp stack_add_F

print_out_hex:
    movl %edx, %esi # store number of ascii digits printed

hex_print_loop:
    cmpl $0, %esi # see if we need to print anymore ascii chars
    je print_carry
    movl $1, %edx # print out each character 1 by 1
    movl %esp,  %ecx  # move address of string into ecx reg
    movl    $STDOUT,%ebx        # first argument: file handle (stdout)
    movl    $SYS_write,%eax     # system call number (sys_write)
    int     $0x80               # call kernel using the int instruction (32 bit)
    decl %esi # remove 1 from counter 
    popl %ecx # print out next char
    jmp hex_print_loop


stack_add_zero:
    movl $0x30, %ecx # move zero ascii into ecx
    jmp add_hex_val_to_stack

stack_add_one:
    movl $0x31, %ecx # move one ascii into ecx 
    jmp add_hex_val_to_stack

stack_add_two:
    movl $0x32, %ecx # move two ascii into ecx
    jmp add_hex_val_to_stack

stack_add_three:
    movl $0x33, %ecx # move three ascii into ecx
    jmp add_hex_val_to_stack

stack_add_four:
    movl $0x34, %ecx # move four ascii into ecx
    jmp add_hex_val_to_stack

stack_add_five:
    movl $0x35, %ecx # move five ascii into ecx
    jmp add_hex_val_to_stack

stack_add_six:
    movl $0x36, %ecx # move six ascii into ecx
    jmp add_hex_val_to_stack

stack_add_seven:
    movl $0x37, %ecx # move 8 ascii into ecx
    jmp add_hex_val_to_stack

stack_add_eight:
    movl $0x38, %ecx # move 9...
    jmp add_hex_val_to_stack

stack_add_nine:
    movl $0x39, %ecx
    jmp add_hex_val_to_stack

stack_add_A:
    movl $0x41, %ecx
    jmp add_hex_val_to_stack

stack_add_B:
    movl $0x42, %ecx
    jmp add_hex_val_to_stack

stack_add_C:
    movl $0x43, %ecx
    jmp add_hex_val_to_stack

stack_add_D:
    movl $0x44, %ecx
    jmp add_hex_val_to_stack

stack_add_E:
    movl $0x45, %ecx
    jmp add_hex_val_to_stack

stack_add_F:
    movl $0x46, %ecx
    jmp add_hex_val_to_stack

add_hex_val_to_stack:
    popl %eax # return to original value of eax
    shrl $4, %eax # remove the bottom 4 bits 
    pushl %ecx # push saved value of ecx
    jmp continue_converting_to_hex

one_hex_char:
    movl $1, %edx
    jmp continue_converting_to_hex

two_hex_chars:
    movl $2, %edx
    jmp continue_converting_to_hex

three_hex_chars:
    movl $3, %edx
    jmp continue_converting_to_hex

four_hex_chars:
    movl $4, %edx
    jmp continue_converting_to_hex

five_hex_chars:
    movl $5, %edx
    jmp continue_converting_to_hex

six_hex_chars:
    movl $6, %edx
    jmp continue_converting_to_hex

seven_hex_chars:
    movl $7, %edx
    jmp continue_converting_to_hex

eight_hex_chars:
    movl $8, %edx
    jmp continue_converting_to_hex



convert_to_decimal:
    cmpl $1, options_array+8 # see if signed is set
    je signed_decimal_setup

convert_to_decimal_setup:
    movl $10, %ebx # were gonna divide by 10 to get the solution character
    movl $0, %esi  # count how many decimals we create

convert_to_decimal_loop:
    movl $0, %edx  # store the remainder here to find which character
    divl %ebx # divide eax by 10 (ebx), store quotient in eax, store remainder in edx
    addl $48, %edx  # add 48 to find the ascii value
    pushl %edx  # store the ascii value onto the stack
    incl %esi  # increment how many decimals we make
    cmpl $0, %eax  # see if the quotient is zero
    je print_out_decimal_values
    jmp convert_to_decimal_loop

print_out_decimal_values:
    cmpl $1, negative_decimal_output
    je push_negative_sign

decimal_value_print:
    cmpl $0, %esi
    je print_carry
    movl $1, %edx  # number of bytes to write
    movl %esp,  %ecx  # move address of string into ecx reg
    movl    $STDOUT,%ebx        # first argument: file handle (stdout)
    movl    $SYS_write,%eax     # system call number (sys_write)
    int     $0x80               # call kernel using the int instruction (32 bit)
    popl %edx # move onto the next character
    decl %esi  # decrement our counter 
    jmp decimal_value_print


signed_decimal_setup:
    cmpl $1, carry_overflow # first check if leading bit is in carry
    je remove_carry_from_decimal_output

    movl longest_length, %edx
    subl $1, %edx # find msb val
msb_decimal_check_loop:
    cmpl $0, %edx  # no more shifts to be made
    je check_msb_val
    decl %edx 
    shrl $1, %eax
    jmp msb_decimal_check_loop

check_msb_val:
    cmpl $0, %eax # if leading digit is 0, skip this process
    je fix_eax_decimal # fix eax val then go to that address

    movl $1, negative_decimal_output
    movl longest_length, %edx
    subl $1, %edx # shift left the bits we shifted right

value_to_subtract_from_decimal:
    cmpl $0, %edx # no more shifts
    je subtract_negative_from_output
    decl %edx
    shll $1, %eax
    addl $1, %eax
    jmp value_to_subtract_from_decimal

subtract_negative_from_output:
    movl solution, %edx # load solution
    subl %edx, %eax  # subtract negative from output val
    addl $1, %eax    # correct positive val to print out
    jmp convert_to_decimal_setup

push_negative_sign:
    movl $0x2D, %edx
    pushl %edx # push negative sign
    incl %esi  # inc number of chars to print
    jmp decimal_value_print

remove_carry_from_decimal_output:
    movl $1, %ecx # value to subtract from output
    movl longest_length, %edx # how many times to shift it left

remove_carry_from_dec_loop:
    cmpl $0, %edx
    je remove_carry_val_dec
    shll $1, %ecx
    decl %edx
    jmp remove_carry_from_dec_loop

remove_carry_val_dec:
    subl %ecx, %eax # new printing val
    jmp convert_to_decimal_setup

fix_eax_decimal:    
    movl solution, %eax
    jmp convert_to_decimal_setup


convert_to_binary:
    movl longest_length, %edx #  how long the register is in bits
    movl longest_length, %esi # save length of register in bits again
    movl $0, %ecx # use this to push to the stack

    cmpl $1, carry_overflow # see if carry is set, add 1 to length of output
    je add_to_length_of_binary_output

loop_through_register:
    cmpl $0, %edx
    je print_then_pop_string
    pushl %eax  # save the value of eax
    andl $1, %eax # mask off every bit except bottom one
    cmpl $1, %eax # see if the value is one
    je add_one_to_stack

check_for_zero:
    cmpl $0, %eax # see if the value is zero
    je add_zero_to_stack

finish_creating_binary_string:
    shrl %eax # check next digit
    jmp loop_through_register 

print_then_pop_string:
    movl $1, %edx
    movl %esp,  %ecx  # move address of string into ecx reg
    movl    $STDOUT,%ebx        # first argument: file handle (stdout)
    movl    $SYS_write,%eax     # system call number (sys_write)
    int     $0x80               # call kernel using the int instruction (32 bit)
    popl %ecx # move onto next character
    decl %esi
    cmpl $0, %esi
    je print_carry
    jmp print_then_pop_string

add_one_to_stack:
    popl %eax # return to value of eax
    movb $0x31, %cl
    pushl %ecx # add byte '1' to the stack
    decl %edx # one less char to print out
    jmp finish_creating_binary_string

add_zero_to_stack:
    popl %eax # return to value of eax
    movb $0x30, %cl
    pushl %ecx  # add byte '0' to the stack
    decl %edx # one less char to print out
    jmp finish_creating_binary_string

add_to_length_of_binary_output:
    incl %edx
    incl %esi 
    jmp loop_through_register



#```````````````````````````````````````````````````````````````````````````````
# Command line example program from Ed Jorgensen's book for x86-64
# This code has been adapated for 32 bit GAS syntax. 
#
# Jorgensen E. x86-64 Assembly Language Programming with Ubuntu. Ed Jorgensen; 2019.

#```````````````````````````````````````````````````````````````````````````````````````
# global procedure to display a null terminated string to the screen
# %esi - pointer to string
#
# Count the number of non-zero characters in the string to print and 
# call the operating system to print a string of that length
# 

.globl printString

printString:
    pushl   %ebp
    movl    %esp, %ebp
    push    %ebx

    movl    %esi, %ebx
    movl    $0, %edx

strCountLoop:    
    cmpb    $NULL, (%ebx)       # compare byte against NULL
    je      strCountDone        # byte == NULL, so we're done
    incl    %edx
    incl    %ebx
    jmp     strCountLoop

strCountDone:
    cmpl    $0, %edx
    je      prtDone

# edx, the third argument, now contains the message length

# print the message

    movl    %esi,%ecx           # second argument: pointer to message to write
    movl    $STDOUT,%ebx        # first argument: file handle (stdout)
    movl    $SYS_write,%eax     # system call number (sys_write)
    int     $0x80               # call kernel using the int instruction (32 bit)

prtDone:
    popl    %ebx
    popl    %ebp
    ret

#```````````````````````````````````````````````````````````````````````````````
# Command line example program from Ed Jorgensen's book for x86-64
# This code has been adapated for 32 bit GAS syntax. 
#
# Jorgensen E. x86-64 Assembly Language Programming with Ubuntu. Ed Jorgensen; 2019.
#error message printing
printStringError:
    pushl   %ebp
    movl    %esp, %ebp
    push    %ebx

    movl    %esi, %ebx
    movl    $0, %edx

strCountLoop2:    
    cmpb    $NULL, (%ebx)       # compare byte against NULL
    je      strCountDone2       # byte == NULL, so we're done
    incl    %edx
    incl    %ebx
    jmp     strCountLoop2

strCountDone2:
    cmpl    $0, %edx
    je      prtDone2

# edx, the third argument, now contains the message length

# print the message

    movl    %esi,%ecx           # second argument: pointer to message to write
    movl    $STDERR,%ebx        # first argument: file handle (stdout)
    movl    $SYS_write,%eax     # system call number (sys_write)
    int     $0x80               # call kernel using the int instruction (32 bit)

prtDone2:
    popl    %ebx
    popl    %ebp
    ret


option_checker:
    incl %esi
    cmpb $0x68, (%esi)  # cmp if letter h is there
    je set_hexidecimal

    cmpb $0x64, (%esi) # cmp if letter d is there
    je set_decimal

    cmpb $0x73, (%esi) # cmp if letter s is there
    je set_signed

    cmpb $0x3F, (%esi) # cmp if ? is there
    je set_question


option_checker_finish:
    jmp parse_options_indexing

set_hexidecimal:
    movl $1, options_array
    jmp option_checker_finish

set_decimal:
    movl $1, options_array+4
    jmp option_checker_finish

set_signed:
    movl $1, options_array+8
    jmp option_checker_finish

set_question:
    jmp question_error



.A:  # and function
    popl %esi        # return the original argv pointer
    pushl %esi       # save argv pointer for arg2
    incl %ebx        # were on the next command line argument now
    call translate_binary_string
    movl %edx, longest_length # store the longest length in memory
    movl %edx, arg_lengths # store length of first arg
    movl %eax, arguments  # save the binary value of arg1 into memory

    popl %esi        # return to argv pointer
    incl %ebx        # were on the 2nd argument for this operation
    call translate_binary_string
    movl %edx, arg_lengths+4 # store length of arg2
    movl %eax, arguments+4 # store second arg in memory

    cmpl longest_length, %edx
    jg move_longest_length_and

finish_and:
    cmpl $0, options_array+8
    je perform_and

    movl arguments, %eax # load arg 1 into eax
    movl arg_lengths, %edx # load length of arg1
    call sign_flag_checker_for_arg # fix arg1 for sign flag
    movl %eax, arguments # store correct signed val in arg1
    movl arguments+4, %eax # load arg2
    movl arg_lengths+4, %edx # load length of arg2
    call sign_flag_checker_for_arg # fix arg2 for sign flag
    movl %eax, arguments+4 # store val into arg2

perform_and:
    movl arguments, %eax # move first arg into eax
    movl arguments+4, %edx # move second arg into edx

    andl %edx, %eax  # perform the operation
    movl %eax, solution # store solution
    jmp print_part

move_longest_length_and:
    movl %edx, longest_length
    jmp finish_and


.D: # difference function
    popl %esi        # return the original argv pointer
    pushl %esi       # save argv pointer for arg2
    incl %ebx        # were on the next command line argument now
    call translate_binary_string
    movl %edx, longest_length # store the longest length in memory
    movl %edx, arg_lengths
    movl %eax, arguments  # save the binary value of arg1 into memory (A)

    popl %esi        # return to argv pointer
    incl %ebx        # were on the 2nd argument for this operation
    call translate_binary_string 
    movl %edx, arg_lengths+4
    movl %eax, arguments+4 # move binary value of arg2 into (B)

    cmpl longest_length, %edx
    jg move_longest_length_diff

finish_diff:
    cmpl $0, options_array+8
    je perform_diff

    movl arguments, %eax # load arg 1 into eax
    movl arg_lengths, %edx
    call sign_flag_checker_for_arg # fix arg1 for sign flag
    movl %eax, arguments # store correct signed val in arg1
    movl arguments+4, %eax # load arg2
    movl arg_lengths+4, %edx
    call sign_flag_checker_for_arg # fix arg2 for sign flag
    movl %eax, arguments+4 # store val into arg2
    
perform_diff:
    movl arguments, %eax # move first arg into eax (A)
    movl arguments+4, %edx # move second arg into edx (B)

    subl %edx, %eax  # perform the operation eax-edx, (A-B) 
    jmp print_part

# carry and overflow
    movl arguments, %eax # store arg 1 in eax
    movl $32, %edx 
    subl longest_length, %edx # how many times to shift val left

format_arg1_diff:
    cmpl $0, %edx
    je format_arg2_diff_1
    shll $1, %eax # shift arg length by 1
    decl %edx
    jmp format_arg1_diff
    
format_arg2_diff_1:
    movl %eax, arguments # store shifted arg1 in mem
    movl arguments+4, %eax # store arg 2 in eax
    movl $32, %edx 
    subl longest_length, %edx # how many times to shift val left

format_arg2_diff_2:
    cmpl $0, %edx
    je perform_co_check_diff
    shll $1, %eax # shift arg length by 1
    decl %edx
    jmp format_arg2_diff_2

perform_co_check_diff:
    movl %eax, arguments+4 # store shifted arg2 in mem
    movl arguments, %eax
    movl arguments+4, %edx
    addl %eax, %edx
    jc set_carry_flag_diff

check_overflow_diff:
    jo set_overflow_flag_diff

    movl solution, %eax
    jmp print_part

move_longest_length_diff:
    movl %edx, longest_length
    jmp finish_diff

set_carry_flag_diff:
    movl $1, carry_overflow
    jmp check_overflow_diff

set_overflow_flag_diff:
    movl $1, carry_overflow+4
    movl solution, %eax
    jmp print_part


.I: # inclusive or function
    popl %esi        # return the original argv pointer
    pushl %esi       # save argv pointer for arg2
    incl %ebx        # were on the next command line argument now
    call translate_binary_string
    movl %edx, longest_length # store the longest length in memory
    movl %edx, arg_lengths
    movl %eax, arguments  # save the binary value of arg1 into memory

    popl %esi        # return to argv pointer
    incl %ebx        # were on the 2nd argument for this operation
    call translate_binary_string
    movl %edx, arg_lengths+4
    movl %eax, arguments+4 # store arg2 in memory

    cmpl longest_length, %edx
    jg move_longest_length_or

finish_or:
    cmpl $0, options_array+8
    je perform_or

    movl arguments, %eax # load arg 1 into eax
    movl arg_lengths, %edx
    call sign_flag_checker_for_arg # fix arg1 for sign flag
    movl %eax, arguments # store correct signed val in arg1
    movl arguments+4, %eax # load arg2
    movl arg_lengths+4, %edx
    call sign_flag_checker_for_arg # fix arg2 for sign flag
    movl %eax, arguments+4 # store val into arg2

perform_or:
    movl arguments, %eax # move first arg into eax
    movl arguments+4, %edx # move second arg into edx

    orl %edx, %eax  # perform the operation
    movl %eax, solution
    jmp print_part

move_longest_length_or:
    movl %edx, longest_length
    jmp finish_or


.L: # shift left , first reg is shift amount, second is shifted reg
    popl %esi        # return the original argv pointer
    pushl %esi       # save argv pointer for arg2
    incl %ebx        # were on the next command line argument now
    call translate_binary_string
    movl %edx, longest_length # store the longest length in memory
    movl %edx, arg_lengths
    movl %eax, arguments  # save the binary value of arg1 into memory

    popl %esi        # return to argv pointer
    incl %ebx        # were on the 2nd argument for this operation
    call translate_binary_string
    movl %edx, arg_lengths+4
    movl %eax, arguments+4

    cmpl longest_length, %edx
    jg move_longest_length_lshift

finish_lshift:
    cmpl $0, options_array+8
    je lshift_loop_setup

    movl arguments, %eax # load arg 1 into eax
    movl arg_lengths, %edx
    call sign_flag_checker_for_arg # fix arg1 for sign flag
    movl %eax, arguments # store correct signed val in arg1
    jmp lshift_loop_setup

move_longest_length_lshift:
    movl %edx, longest_length
    jmp finish_lshift

lshift_loop_setup:
    movl arguments, %eax # shifted reg
    movl arguments+4, %edx # bits to shift
 
shift_left_loop:
    decl %edx
    shll $1, %eax
    cmpl $0, %edx
    je print_part
    jmp shift_left_loop



.M: # multiply
    popl %esi        # return the original argv pointer
    pushl %esi       # save argv pointer for arg2
    incl %ebx        # were on the next command line argument now
    call translate_binary_string
    movl %edx, longest_length # store the longest length in memory
    movl %edx, arg_lengths 
    movl %eax, arguments  # save the binary value of arg1 into arguments

    popl %esi        # return to argv pointer
    incl %ebx        # were on the 2nd argument for this operation
    call translate_binary_string
    movl %edx, arg_lengths+4
    movl %eax, arguments+4

    cmpl longest_length, %edx
    jg move_longest_length_mul

finish_mull:
    cmpl $0, options_array+8
    je perform_mull

    movl arguments, %eax # load arg 1 into eax
    movl arg_lengths, %edx
    call sign_flag_checker_for_arg # fix arg1 for sign flag
    movl %eax, arguments # store correct signed val in arg1
    movl arguments+4, %eax # load arg2
    movl arg_lengths+4, %edx
    call sign_flag_checker_for_arg # fix arg2 for sign flag
    movl %eax, arguments+4 # store val into arg2

perform_mull:
    movl arguments, %eax
    movl arguments+4, %edx

    imull %edx, %eax  # perform the multiplication
    movl %eax, solution
    jmp print_part

move_longest_length_mul:
    movl %edx, longest_length
    jmp finish_mull



.N: # unary minus
    popl %esi        # return the original argv pointer
    incl %ebx         # were on the next command line argument now
    call translate_binary_string
    movl %edx, longest_length # store the longest length in memory
    movl %eax, arguments # store arg1 in memory

# check msb, if was originally 1, then label msb 1, else don't change it
    decl %edx
unary_loop:
    cmpl $0, %edx
    je check_unary
    shrl %eax
    decl %edx
    jmp unary_loop

check_unary:
    cmpl $1, %eax
    je set_msb_unary

perform_unary:
    movl arguments, %eax
    negl %eax # perform the operation
    call reformat_register

    cmpl $1, msigbit
    je proper_printing_for_unary
    jmp print_part

proper_printing_for_unary:
    cmpl $1, options_array
    je convert_to_hexadecimal
    cmpl $1, options_array+4
    je convert_to_decimal_setup
    jmp print_part

set_msb_unary:
    movl $1, msigbit
    jmp perform_unary



.O: # ones complement
    popl %esi        # return the original argv pointer
    incl %ebx        # were on the next command line argument now
    call translate_binary_string
    movl %edx, longest_length # store the longest length in memory
    movl %eax, arguments # save binary val of arg1

# check msb, if was originally 1, then label msb 1, else don't change it
    decl %edx 
ocomp_loop:
    cmpl $0, %edx
    je check_ocomp
    shrl %eax
    decl %edx
    jmp ocomp_loop

check_ocomp:
    cmpl $1, %eax
    je set_msb_ocomp

perform_ocomp:
    movl arguments, %eax
    notl %eax # perform the operation
    call reformat_register

    cmpl $1, msigbit
    je proper_printing_for_ocomp
    jmp print_part
    
proper_printing_for_ocomp:
    cmpl $1, options_array
    je convert_to_hexadecimal
    cmpl $1, options_array+4
    je convert_to_decimal_setup
    jmp print_part

set_msb_ocomp:
    movl $1, msigbit
    jmp perform_ocomp


.R:  # arithmetic shift right, first is reg shifted, second is shift amount
    popl %esi        # return the original argv pointer
    pushl %esi       # save argv pointer for arg2
    incl %ebx        # were on the next command line argument now
    call translate_binary_string
    movl %edx, longest_length # store the longest length in memory
    movl %edx, arg_lengths # store arg length 1
    movl %eax, arguments  # save the binary value of arg1 into arguments

    popl %esi        # return to argv pointer
    incl %ebx        # were on the 2nd argument for this operation
    call translate_binary_string
    movl %edx, arg_lengths+4 # store arglength 2
    movl %eax, arguments+4

    cmpl longest_length, %edx
    jg move_longest_length_rshift

finish_rshift:
    cmpl $0, options_array+8
    je shift_right_loop

    movl arguments, %eax # load arg 1 into eax
    movl arg_lengths, %edx # load arg1 length
    call sign_flag_checker_for_arg # fix arg1 for sign flag
    movl %eax, arguments # store correct signed val in arg1
    jmp shift_right_loop

move_longest_length_rshift:
    movl %edx, longest_length
    jmp finish_rshift

shift_right_loop:
    movl arguments, %eax # shifted reg
    movl arguments+4, %edx # bits to shift

    cmpl $0, options_array+8
    je unsigned_shift_right
    movl $1, negative_decimal_output
    jmp signed_shift_right

unsigned_shift_right:
    decl %edx
    shrl $1, %eax
    cmpl $0, %edx
    je print_part
    jmp unsigned_shift_right

signed_shift_right:
    decl %edx
    shrl $1, %eax
    cmpl $0, %edx
    je print_part
    jmp signed_shift_right


.S: #sum 
    popl %esi        # return the original argv pointer
    pushl %esi       # save argv pointer for arg2
    incl %ebx        # were on the next command line argument now
    call translate_binary_string
    movl %edx, longest_length # store the longest length in memory
    movl %edx, arg_lengths # store length of first arg here
    movl %eax, arguments  # save the binary value of arg1 into arguments array

    popl %esi        # return to argv pointer
    incl %ebx        # were on the 2nd argument for this operation
    call translate_binary_string
    movl %edx, arg_lengths+4 # store length of arg2
    movl %eax, arguments+4

    cmpl longest_length, %edx
    jg move_longest_length_sum

finish_sum:
    cmpl $0, options_array+8
    je perform_sum

    movl arguments, %eax # load arg 1 into eax
    movl arg_lengths, %edx # load length of arg1
    call sign_flag_checker_for_arg # fix arg1 for sign flag
    movl %eax, arguments # store correct signed val in arg1
    movl arguments+4, %eax # load arg2
    movl arg_lengths+4, %edx # load length of arg2
    call sign_flag_checker_for_arg # fix arg2 for sign flag
    movl %eax, arguments+4 # store val into arg2

perform_sum:
    movl arguments, %eax # move first arg into eax
    movl arguments+4, %edx # move second arg into edx

    addl %edx, %eax  # perform the operation
    movl %eax, solution # store solution in memory

# carry and overflow
    movl arguments, %eax # store arg 1 in eax
    movl $32, %edx 
    subl longest_length, %edx # how many times to shift val left

format_arg1_sum:
    cmpl $0, %edx
    je format_arg2_sum_1
    shll $1, %eax # shift arg length by 1
    decl %edx
    jmp format_arg1_sum
    
format_arg2_sum_1:
    movl %eax, arguments # store shifted arg1 in mem
    movl arguments+4, %eax # store arg 2 in eax
    movl $32, %edx 
    subl longest_length, %edx # how many times to shift val left

format_arg2_sum_2:
    cmpl $0, %edx
    je perform_co_check_sum
    shll $1, %eax # shift arg length by 1
    decl %edx
    jmp format_arg2_sum_2

perform_co_check_sum:
    movl %eax, arguments+4 # store shifted arg2 in mem
    movl arguments, %eax
    movl arguments+4, %edx
    addl %eax, %edx
    jc set_carry_flag_sum

check_overflow_sum:
    jo set_overflow_flag_sum

    movl solution, %eax
    jmp print_part

move_longest_length_sum:
    movl %edx, longest_length
    jmp finish_sum

set_carry_flag_sum:
    movl $1, carry_overflow
    jmp check_overflow_sum

set_overflow_flag_sum:
    movl $1, carry_overflow+4
    movl solution, %eax
    jmp print_part


.T: # twos complement
    popl %esi  # go back to original argv pointer
    incl %ebx        # were on the next command line argument now
    call translate_binary_string
    movl %edx, longest_length # store the longest length in memory
    movl %eax, arguments # save binary val of arg1
 
# check msb, if was originally 1, then label msb 1, else don't change it
    decl %edx
tcomp_loop:
    cmpl $0, %edx
    je check_tcomp
    shrl %eax
    decl %edx
    jmp tcomp_loop

check_tcomp:
    cmpl $1, %eax
    je set_msb_tcomp

perform_tcomp:
    movl arguments, %eax
    negl %eax # perform the operation
    call reformat_register

    cmpl $1, msigbit
    je proper_printing_for_tcomp
    jmp print_part

proper_printing_for_tcomp:
    cmpl $1, options_array
    je convert_to_hexadecimal
    cmpl $1, options_array+4
    je convert_to_decimal_setup
    jmp print_part

set_msb_tcomp:
    movl $1, msigbit
    jmp perform_tcomp



.X: # exclusive or function
    popl %esi        # return the original argv pointer
    pushl %esi       # save argv pointer for arg2
    incl %ebx        # were on the next command line argument now
    call translate_binary_string
    movl %edx, longest_length # store the longest length in memory
    movl %edx, arg_lengths # store length of first arg
    movl %eax, arguments  # save the binary value of arg1 into memory

    popl %esi        # return to argv pointer
    incl %ebx        # were on the 2nd argument for this operation
    call translate_binary_string
    movl %edx, arg_lengths+4 # store length of arg2
    movl %eax, arguments+4 # store arg2 in memory

    cmpl longest_length, %edx
    jg move_longest_length_xor

finish_xor:
    cmpl $0, options_array+8
    je perform_xor

    movl arguments, %eax # load arg 1 into eax
    movl arg_lengths, %edx # load length of arg1
    call sign_flag_checker_for_arg # fix arg1 for sign flag
    movl %eax, arguments # store correct signed val in arg1
    movl arguments+4, %eax # load arg2
    movl arg_lengths+4, %edx # load length of arg2
    call sign_flag_checker_for_arg # fix arg2 for sign flag
    movl %eax, arguments+4 # store val into arg2

perform_xor:
    movl arguments, %eax # move first arg into eax
    movl arguments+4, %edx # move second arg into edx

    xorl %edx, %eax  # perform the operation
    movl %eax, solution # store solution
    jmp print_part 

move_longest_length_xor:
    movl %edx, longest_length
    jmp finish_xor


reformat_register:
    movl $32, %ecx
    subl longest_length, %ecx # how many shifts

reformat_register_loop:
    cmpl $0, %ecx # how many left shifts necessary
    je reformat_loop_back_prep
    decl %ecx
    shll $1, %eax
    jmp reformat_register_loop

reformat_loop_back_prep:
    movl $32, %ecx
    subl longest_length, %ecx # how many shifts

reformat_loop_back:
    cmpl $0, %ecx # how many right shifts
    je finish_reformatting
    decl %ecx
    shrl $1, %eax
    jmp reformat_loop_back

finish_reformatting:
    movl %eax, solution
    ret


.default:
    incl %ebx # no operation ran, go back to operation checker on next index
    popl %esi # pop esi off the stack for consistency
    jmp parse_operation



is_an_option:
    incl %ebx #check next command line argument
    jmp take_in_argument



operation_A:
    movl $0, %eax
    jmp run_operation

operation_D:
    movl $1, %eax
    jmp run_operation

operation_I:
    movl $2, %eax
    jmp run_operation

operation_L:
    movl $3, %eax
    jmp run_operation

operation_M:
    movl $4, %eax
    jmp run_operation

operation_N:
    movl $5, %eax
    jmp run_operation

operation_O:
    movl $6, %eax
    jmp run_operation

operation_R:
    movl $7, %eax
    jmp run_operation

operation_S:
    movl $8, %eax
    jmp run_operation

operation_T:
    movl $9, %eax
    jmp run_operation

operation_X:
    movl $10, %eax
    jmp run_operation



translate_binary_string:
    movl (%esi,%ebx,4), %esi  # move first address to argument 1 to the esi register
    pushl %esi # save first address of arg1
    movl $0, %edx  # counter for the length of the string
    movl $0, %eax  # binary value of argument 1
string_length_loop: 
    cmpb    $0x00, (%esi)       # compare byte against a NULL byte
    je      length_of_string_done        # byte == NULL == 0x00, so we're done
    incl    %edx
    incl    %esi
    jmp     string_length_loop

length_of_string_done:
    popl %esi # go back to starting index of string
    pushl %edx # save length of string
create_binary_value:
    cmpl $0, %edx  # if counter is done then we move on
    je finish_translating_string
    decl %edx
    cmpb $0x31, (%esi)  # compare ascii character of '1' to the address that esi is currently pointing at
    je add_to_binary_value
continue_solving_for_string:
    cmpl $0, %edx
    je finish_translating_string
    shll $1, %eax
    incl %esi # check next character
    jmp create_binary_value

add_to_binary_value:
    addl $1, %eax
    jmp continue_solving_for_string

finish_translating_string:
    popl %edx # save length of string
    ret



question_error:
    movl $question_flag_set, %esi # move string to be printed
    jmp fatal

fatal:
    call printStringError
    popl %esi
    popl %ebx
    popl %ebp
    movl $1, %eax # move 1 into eax for returning error
    ret




sign_flag_checker_for_arg:
    pushl %eax # save value of argument
    movl %edx, %ecx # store length of arg in ecx
    cmpl longest_length, %ecx
    je skip_arg
    popl %eax # move value of eax back into it
    pushl %ecx # save counter
    pushl %eax # save register value 

loop_register_to_find_leading_digit:
    cmpl $1, %ecx # loop through string is done
    je decide_leading_bit
    decl %ecx
    shrl %eax
    jmp loop_register_to_find_leading_digit

decide_leading_bit:
    cmpl $0, %eax
    je skip_arg_2

    # fix register of eax so value has leading ones up to length of longest arg
    popl %eax # return value of argument
    popl %ecx # return length of arg
    movl longest_length, %edx  # length of longest reg
    subl %ecx, %edx # how many digits of 1 we want
    pushl %ecx # save arg length
    movl $0, %ecx # new register to add
add_ones_to_register:
    addl $1, %ecx
    decl %edx # dec counter of how many ones to add
    cmpl $0, %edx # see if amount of args are 0
    je add_to_total
    shll $1, %ecx
    jmp add_ones_to_register

add_to_total:
    movl %ecx, %edx # save stored ones on edx
    popl %ecx # go back to length of arg

shift_added_ones_to_fit_reg:
    cmpl $0, %ecx
    je add_to_arg_reg
    shll %edx 
    decl %ecx
    jmp shift_added_ones_to_fit_reg

add_to_arg_reg:
    addl %edx, %eax
    ret


skip_arg:
    popl %eax # return to value of argument
    movl %eax, %eax
    ret

skip_arg_2:
    popl %eax
    popl %ecx
    movl %eax, %eax
    ret
