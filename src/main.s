.syntax unified
.cpu cortex-m0
.fpu softvfp
.thumb

.include "defs.i"
.include "gpio.i"  // used regs: r0, r1
.include "uart.i"  // used regs: r0, r1, r3-r7

.global Main_Start

.equ PROGMEM_START , SRAM_BASE
.equ DATAMEM_END   , SRAM_END

Main_Start:
    ldr  r2, =PROGMEM_START  // reset PP
    mov  r12, r2  // set end-of-program (start-of-data) address
    UART_LoadRegs

Main_prompt:
    movs r0, #'\n'
    UART_WaitWrite prompt_1
    movs r0, #'?'
    UART_WaitWrite prompt_2

Main_loop:
    UART_CheckRead Main_loop
    // check for valid command
    cmp  r0, #'l'
    beq  Load_Program
    cmp  r0, #'e'
    beq  Exec_program
    // not a valid command, ignore
    b    Main_loop

Load_Program:
    UART_WaitWrite cmd_load  // r0 == 'l'
    ldr  r2, =PROGMEM_START  // reset PP
Load_loop:
    // check button
    GPIO_GetButton
    beq  Load_done  // end loading
    UART_CheckRead Load_loop
    // check for Brainfuck opcode
    cmp  r0, #'+'
    beq  Load_opcode
    cmp  r0, #'-'
    beq  Load_opcode
    cmp  r0, #'>'
    beq  Load_opcode
    cmp  r0, #'<'
    beq  Load_opcode
    cmp  r0, #'['
    beq  Load_opcode
    cmp  r0, #']'
    beq  Load_opcode
    cmp  r0, #'.'
    beq  Load_opcode
    cmp  r0, #','
    beq  Load_opcode
    // not an opcode, ignore
    b    Load_loop
Load_opcode:
    // TODO: check max program size
    stm  r2!, {r0}  // PM[PP++] = opcode
    b    Load_loop
Load_done:
    mov  r12, r2  // set end-of-program (start-of-data) address

Reset_Program:
    // clear DM
    movs r0, #0x00
    ldr  r1, =DATAMEM_END
    mov  r2, r12  // start-of-data address
    clear_dm_loop:
        stm  r2!, {r0}  // DM[r2++] = 0x00
        cmp  r2, r1
        bne  clear_dm_loop
    ldr  r2, =PROGMEM_START  // reset PP
    // TODO: reset DP
    b    Main_prompt  // back to prompt

Exec_program:
    UART_WaitWrite cmd_exec  // r0 == 'e'
    b    Main_prompt
