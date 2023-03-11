.syntax unified
.cpu cortex-m0
.fpu softvfp
.thumb

.include "defs.i"
.include "gpio.i"  // used regs: r0, r1
.include "uart.i"  // used regs: r0, r1, r5-r7

.global Main_Start

.equ PROGMEM_START , SRAM_BASE
.equ DATAMEM_END   , SRAM_END

Main_Start:
    ldr  r2, =PROGMEM_START  // reset PP
    mov  r12, r2  // reset end-of-program (start-of-data) address
    UART_LoadRegs
Main_prompt:
    movs r0, #'\n'
    UART_WaitWrite prompt_1
    movs r0, #'?'
    UART_WaitWrite prompt_2
main_loop:
    UART_CheckRead main_loop
    // check for valid command
    cmp  r0, #'l'
    beq  Load_program
    cmp  r0, #'e'
    beq  Exec_program
    // not a valid command, ignore
    b    main_loop

Load_program:
    UART_WaitWrite cmd_load  // r0 == 'l'
    ldr  r2, =PROGMEM_START  // reset PP
load_loop:
    // check button
    GPIO_GetButton
    beq  load_done  // end loading
    UART_CheckRead load_loop
    // check for Brainfuck opcode
    cmp  r0, #'+'
    beq  load_dm_inc  // DM[DP]++
    cmp  r0, #'-'
    beq  load_dm_dec  // DM[DP]--
    cmp  r0, #'>'
    beq  load_dp_inc  // DP++
    cmp  r0, #'<'
    beq  load_dp_dec  // DP--
    cmp  r0, #'['
    beq  load_pp_jfz  // Jump Forward if DM[DP] is Zero
    cmp  r0, #']'
    beq  load_pp_jbn  // Jump Back if DM[DP] in Not zero
    cmp  r0, #'.'
    beq  load_dm_out  // write(DM[DP])
    cmp  r0, #','
    beq  load_dm_inb  // DM[DP] = read() (blocking)
    // not an opcode, ignore
    b    load_loop
load_dm_inc:
    adr  r0, Exec_DM_INC
    b    load_opcode
load_dm_dec:
    adr  r0, Exec_DM_DEC
    b    load_opcode
load_dp_inc:
    adr  r0, Exec_DP_INC
    b    load_opcode
load_dp_dec:
    adr  r0, Exec_DP_DEC
    b    load_opcode
load_pp_jfz:
    adr  r0, Exec_PP_JFZ
    b    load_opcode
load_pp_jbn:
    adr  r0, Exec_PP_JBN
    b    load_opcode
load_dm_out:
    adr  r0, Exec_DM_OUT
    b    load_opcode
load_dm_inb:
    adr  r0, Exec_DM_INB
load_opcode:
    // TODO: check max program size
    adds r0, #1  // set execution mode to Thumb (for blx instruction in Exec_program)
    stm  r2!, {r0}  // PM[PP++] = opcode executor address
    b    load_loop
load_done:
    mov  r12, r2  // store end-of-program (start-of-data) address

Reset_program:
    // clear DM
    movs r0, #0x00
    ldr  r1, =DATAMEM_END
    mov  r3, r12  // start-of-data address
    clear_dm_loop:
        stm  r3!, {r0}  // DM[DP++] = 0x00
        cmp  r3, r1
        bne  clear_dm_loop
    ldr  r2, =PROGMEM_START  // reset PP
    mov  r3, r12  // reset DP
    b    Main_prompt

Exec_program:
    UART_WaitWrite cmd_exec  // r0 == 'e'
exec_loop:
    // check button
    GPIO_GetButton
    beq  Main_prompt  // break execution
    // check PP
    cmp  r2, r12
    beq  Main_prompt  // end of program
    // execute opcode
    ldm  r2!, {r0}
    blx  r0
    b    exec_loop

/* NOTE: alignment required for opcode executors (for adr instruction in Load_program) */

.align
Exec_DM_INC:  // opcode: +
    ldrb r0, [r3]
    adds r0, #1
    strb r0, [r3]
    bx   lr

.align
Exec_DM_DEC:  // opcode: -
    ldrb r0, [r3]
    subs r0, #1
    strb r0, [r3]
    bx   lr

.align
Exec_DP_INC:  // opcode: >
    // TODO: check for DM overflow
    adds r3, #1
    bx   lr

.align
Exec_DP_DEC:  // opcode: <
    // TODO: check for DM underflow
    subs r3, #1
    bx   lr

.align
Exec_PP_JFZ:  // opcode: [
    // TODO
    bx   lr

.align
Exec_PP_JBN:  // opcode: ]
    // TODO
    bx   lr

.align
Exec_DM_OUT:  // opcode: .
    ldrb r0, [r3]
    UART_WaitWrite exec_dm_out
    bx   lr

.align
Exec_DM_INB:  // opcode: ,
    movs r0, #','
    UART_WaitWrite exec_dm_inb
exec_dm_inb_loop:
    // check button
    GPIO_GetButton
    beq exec_dm_inb_break  // break execution
    // check for input byte
    UART_CheckRead exec_dm_inb_loop
    // got it
    strb r0, [r3]
    bx   lr
exec_dm_inb_break:
    subs r2, #4  // set PP back to this opcode
    b    Main_prompt
