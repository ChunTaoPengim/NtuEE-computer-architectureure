.data
    n: .word 10
    
.text
.globl __start

FUNCTION:
    # Todo: Define your own function in HW1
    # You should store the output into x10
  addi t5, x0, 5 # make t5 = 5
  addi t6, x0, 6
  addi t3, x0, 1
  # make t6 = 6
  # make t7 = 7
  
  sw ra, 0(sp)
  mv t0, a0 # let t0 = n
  jal ra, T # call the function
  mv a0, t0
  lw ra,0(sp)
  jalr zero, 0(ra)
  
  
T:
  addi sp, sp, -16
  sw ra, 8(sp)
  sw t0,0(sp)
  srai t2, t0, 1 # t2 = a0/2
  bge t2, t3, rec # t2>=1 call recursive function
  addi t0,zero,2 # else set t0 = 2
  addi sp, sp, 16
  jalr zero, 0(ra) # return value
rec:
   srai t0, t0, 1 # n = n/2
   jal ra, T # get the function value of T(n/2)
   addi t1,t0,0 # restore the result in t1
   lw t0,0(sp) # restore n
   lw ra,8(sp) 
   addi sp,sp,16 # pop stack
   mul t1, t1, t5 # compute 5 * T(n/2)
   mul a3, t0, t6 # compute 6n
   addi a3, a3, 4 # compute 6n+4
   add t0, t1,a3 # return 5* T(n/2) + 6n +4
   jalr zero, 0(ra) # return


# Do NOT modify this part!!!
__start:
    la   t0, n
    lw   x10, 0(t0)
    jal  x1,FUNCTION
    la   t0, n
    sw   x10, 4(t0)
    addi a0,x0,10
    ecall