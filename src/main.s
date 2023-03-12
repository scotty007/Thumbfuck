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
    // TODO: check max program size (+ 4 bytes space + 4 bytes stack)
    adr  r0, Exec_PP_JFZ
    stm  r2!, {r0}  // PM[PP++] = opcode executor address
    adds r2, #4     // PP++ (make space for opcode address after the closing bracket)
    push {r2}       // store opcode address after this opening bracket
    b    load_loop
load_pp_jbn:
    // TODO: check for empty stack (missing opening bracket)
    // TODO: check max program size (+ 4 bytes space)
    adr  r0, Exec_PP_JBN
    stm  r2!, {r0}  // PM[PP++] = opcode executor address
    pop  {r0}       // opcode address after the opening bracket
    stm  r2!, {r0}  // PM[PP++] = opcode address after the opening bracket
    subs r0, #4     // space address of the opening bracket
    str  r2, [r0]   // PM[space] = opcode address after this closing bracket
    b    load_loop
load_dm_out:
    adr  r0, Exec_DM_OUT
    b    load_opcode
load_dm_inb:
    adr  r0, Exec_DM_INB
load_opcode:
    // TODO: check max program size
    stm  r2!, {r0}  // PM[PP++] = opcode executor address
    b    load_loop
load_done:
    // TODO: check for non-empty stack (missing closing bracket(s))
    mov  r12, r2  // store end-of-program (start-of-data) address

Reset_program:
    // clear DM
    movs r0, #0x00
    ldr  r1, =DATAMEM_END
    mov  r3, r12  // start-of-data address
    clear_dm_loop:
        stm  r3!, {r0}  // DM[DP++] = 0x00000000
        cmp  r3, r1
        bne  clear_dm_loop
    ldr  r2, =PROGMEM_START  // reset PP
    mov  r3, r12  // reset DP
    b    Main_prompt

Exec_program:
    UART_WaitWrite cmd_exec  // r0 == 'e'
Exec_loop:
    // check button
    GPIO_GetButton
    beq  Main_prompt  // break execution
    // check PP
    cmp  r2, r12
    beq  Main_prompt  // end of program
    // execute opcode
    ldm  r2!, {r0}  // load executor address, PP++
    mov  pc, r0

/* NOTE: alignment required for opcode executors (for adr instruction in Load_program) */

.align
Exec_DM_INC:  // opcode: +
    ldrb r0, [r3]
    adds r0, #1
    strb r0, [r3]
    b    Exec_loop

.align
Exec_DM_DEC:  // opcode: -
    ldrb r0, [r3]
    subs r0, #1
    strb r0, [r3]
    b    Exec_loop

.align
Exec_DP_INC:  // opcode: >
    // TODO: check for DM overflow
    adds r3, #1
    b    Exec_loop

.align
Exec_DP_DEC:  // opcode: <
    // TODO: check for DM underflow
    subs r3, #1
    b    Exec_loop

.align
Exec_PP_JFZ:  // opcode: [
    // PM[PP] == opcode address after the closing bracket
    ldrb r0, [r3]
    cmp  r0, #0x00
    beq  exec_pp_jxx_jump
    adds r2, #4  // PP++ (advance to opcode address after space)
    b    Exec_loop

.align
Exec_PP_JBN:  // opcode: ]
    // PM[PP] == opcode address after the opening bracket
    ldrb r0, [r3]
    cmp  r0, #0x00
    bne  exec_pp_jxx_jump
    adds r2, #4  // PP++ (advance to opcode address after space)
    b    Exec_loop

exec_pp_jxx_jump:
    ldr  r2, [r2]  // PP = PM[PP]
    b    Exec_loop

.align
Exec_DM_OUT:  // opcode: .
    ldrb r0, [r3]
    UART_WaitWrite exec_dm_out
    b    Exec_loop

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
    b    Exec_loop
exec_dm_inb_break:
    subs r2, #4  // set PP back to this opcode
    b    Main_prompt
