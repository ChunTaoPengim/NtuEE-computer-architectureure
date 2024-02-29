.globl __start

.rodata
    msg0: .string "This is HW1-2: \n"
    msg1: .string "Enter shift: "
    msg2: .string "Plaintext: "
    msg3: .string "Ciphertext: "
.text

################################################################################
  # print_char function
  # Usage: 
  #     1. Store the beginning address in x20
  #     2. Use "j print_char"
  #     The function will print the string stored from x20 
  #     When finish, the whole program with return value 0

print_char:
    addi a0, x0, 4
    la a1, msg3
    ecall
  
    add a1,x0,x20
    ecall

  # Ends the program with status code 0
    addi a0,x0,10
    ecall
    
################################################################################

__start:
  # Prints msg
    addi a0, x0, 4
    la a1, msg0
    ecall

  # Prints msg1
    addi a0, x0, 4
    la a1, msg1
    ecall
  # Reads an int
    addi a0, x0, 5
    ecall
    add a6, a0, x0
    
  # Prints msg2
    addi a0, x0, 4
    la a1, msg2
    ecall
    
    addi a0,x0,8
    li a1, 0x10150
    addi a2,x0,2047
    ecall
  # Load address of the input string into a0
    add a0,x0,a1


################################################################################ 
main:
    # a0 = destination
    # x20 = source
    li x20, 0x10200
    li t1, '\n'
    li t2,0
    li t3, ' '
    li t4, '0'
    li t5, 'a'
    li t6, 26
    jal L
    
L:
    
    lb      t0, 0(a0)    # Load a char from the src
    beq     t0, t1, fin  # if meet "\n", finish the process
    beq     t0, t3, else # if meet white space, add 0,1,2,3...
    add     t0, t0, a6    # make the shift
    sub     t0, t0, t5    # sub "a"
    addi    t0, t0, 26
    remu    t0, t0, t6    # make t0 from 0 to 25
    add     t0, t0, t5    # add back "a"
    sb      t0, 0(x20)    # Store the value
    addi    a0, a0, 1     # Advance source one byte
    addi    x20, x20, 1   # Advance destination one byte
    addi    t2, t2, -1    # record how much bite
    jal L             # Go back to the start of the loop
fin:
    add x20, x20, t2
    j print_char         
       
else:
    mv t0, t4
    sb   t0, 0(x20)
    addi    a0, a0, 1      # Advance source one byte
    addi    x20, x20, 1    # Advance destination one byte
    addi    t2, t2, -1 
    addi t4, t4, 1
    jal L
  
################################################################################

