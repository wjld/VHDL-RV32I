.data
    num: .word 0x00000009
    str0: .string "o quadrado de "
    str1: " eh "

.text
    call main

main:
    lui sp, 3
    addi sp, sp, 0x7ff
    addi sp, sp, 0x7fd
    la a0, str0
    addi a7, zero, 4
    ecall
    la a0, num
    lw a0, 0(a0) #arg
    addi a7, zero, 1
    ecall
    call quad_int
    add t0, zero, a0
    la a0, str1
    addi a7, zero, 4
    ecall
    add a0, zero, t0
    addi a7, zero, 1
    ecall
    addi a7, zero, 10
    ecall

quad_int:
    slti t0, a0, 2
    beq t0, zero, rec_call
    addi a0, zero, 1
    ret

rec_call:
    addi sp, sp, -8
    sw a0, 8(sp)
    sw ra, 4(sp)
    addi a0, a0, -1
    call quad_int
    lw t0, 8(sp)
    add t0, t0, t0
    addi t0, t0, -1
    add a0, a0, t0
    lw ra, 4(sp)
    addi sp, sp, 8
    ret