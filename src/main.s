.syntax unified
.cpu cortex-m0
.fpu softvfp
.thumb

.include "defs.i"
.include "gpio.i"  // used regs: r0, r1
.include "uart.i"  // used regs: r0, r1, r5-r7

.global Main_Start

.equ STACK_RESERVE , 40  // 32 + up to 7 alignment (for exception/interrupt handlers)
.equ PROGMEM_START , SRAM_BASE
.equ DATAMEM_END   , SRAM_END - STACK_RESERVE

Main_Start:
    UART_LoadRegs
    ldr  r0, =DATAMEM_END
    subs r0, #1
    mov  r12, r0
Main_reset:
    ldr  r2, =PROGMEM_START  // reset PP
    mov  r11, r2  // reset end-of-program (start-of-data) address
Main_prompt:
    movs r0, #'\n'
    UART_WaitWrite prompt_1
    movs r0, #'-'
    UART_WaitWrite prompt_2
    GPIO_SetLedOff
main_loop:
    UART_CheckRead main_loop
    // byte received
    mov  r8, r0
    GPIO_SetLedOn
    mov  r0, r8
    // check for valid command
    cmp  r0, #'l'
    beq  Load_program
    cmp  r0, #'e'
    beq  Exec_program
    cmp  r0, #'r'
    beq  Reset_program
    // not a valid command, ignore
    GPIO_SetLedOff
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
    // not an opcode
    cmp  r0, 0x00     // 'EOF' (ASCII 'NUL')
    beq  load_done    // end loading
    b    load_loop    // ignore
load_dm_inc:
    adr  r0, Exec_dm_inc
    b    load_opcode
load_dm_dec:
    adr  r0, Exec_dm_dec
    b    load_opcode
load_dp_inc:
    adr  r0, Exec_dp_inc
    b    load_opcode
load_dp_dec:
    adr  r0, Exec_dp_dec
    b    load_opcode
load_pp_jfz:
    // check max program size (+ 4 bytes space + 4 bytes stack)
    adds r2, STACK_RESERVE + 8
    cmp  sp, r2
    ble  Error_load_overflow
    subs r2, STACK_RESERVE + 8
    // size OK
    adr  r0, Exec_pp_jfz
    stm  r2!, {r0}  // PM[PP++] = opcode executor address
    adds r2, #4     // PP++ (make space for opcode address after the closing bracket)
    push {r2}       // store opcode address after this opening bracket
    b    load_loop
load_pp_jbn:
    // check for empty stack (missing opening bracket)
    ldr  r0, =SRAM_END
    cmp  sp, r0
    beq  Error_load_opening
    // opening bracket OK
    // check max program size (+ 4 bytes space)
    adds r2, STACK_RESERVE + 4
    cmp  sp, r2
    ble  Error_load_overflow
    subs r2, STACK_RESERVE + 4
    // size OK
    adr  r0, Exec_pp_jbn
    stm  r2!, {r0}  // PM[PP++] = opcode executor address
    pop  {r0}       // opcode address after the opening bracket
    stm  r2!, {r0}  // PM[PP++] = opcode address after the opening bracket
    subs r0, #4     // space address of the opening bracket
    str  r2, [r0]   // PM[space] = opcode address after this closing bracket
    b    load_loop
load_dm_out:
    adr  r0, Exec_dm_out
    b    load_opcode
load_dm_inb:
    adr  r0, Exec_dm_inb
load_opcode:
    // check max program size
    adds r2, STACK_RESERVE
    cmp  sp, r2
    ble  Error_load_overflow
    subs r2, STACK_RESERVE
    // size OK
    stm  r2!, {r0}  // PM[PP++] = opcode executor address
    b    load_loop
load_done:
    // check for non-empty stack (missing closing bracket(s))
    ldr  r0, =SRAM_END
    cmp  sp, r0
    bne  Error_load_closing
    // brackets balanced
    mov  r11, r2   // store end-of-program (start-of-data) address
    movs r0, #'r'  // prepare for Reset_program

Reset_program:
    UART_WaitWrite cmd_reset  // r0 == 'r'
    // clear DM
    movs r0, #0x00
    ldr  r1, =DATAMEM_END
    mov  r3, r11  // start-of-data address
    clear_dm_loop:
        stm  r3!, {r0}  // DM[DP++] = 0x00000000
        cmp  r3, r1
        bne  clear_dm_loop
    ldr  r2, =PROGMEM_START  // reset PP
    mov  r3, r11  // reset DP
    b    Main_prompt

Exec_program:
    UART_WaitWrite cmd_exec  // r0 == 'e'
Exec_loop:
    // TODO: drop all received bytes until program end (except for dm_inb) ?
    // check button
    GPIO_GetButton
//    beq  Main_prompt  // break execution
    beq  exec_done  // break execution
    // check PP
    cmp  r2, r11
//    beq  Main_prompt  // end of program
    beq  exec_done  // end of program
    // execute opcode
    ldm  r2!, {r0}  // load executor address, PP++
    mov  pc, r0
exec_done:  // intermediate jump, Main_prompt out of range for beq instruction
    b    Main_prompt

/* NOTE: alignment required for opcode executors (for adr instruction in Load_program) */

.align
Exec_dm_inc:  // opcode: +
    ldrb r0, [r3]
    adds r0, #1
    strb r0, [r3]
    b    Exec_loop

.align
Exec_dm_dec:  // opcode: -
    ldrb r0, [r3]
    subs r0, #1
    strb r0, [r3]
    b    Exec_loop

.align
Exec_dp_inc:  // opcode: >
    // check for DM overflow
    cmp  r3, r12
    beq  Error_dp_inc
    // DP ok, increment it
    adds r3, #1
    b    Exec_loop

.align
Exec_dp_dec:  // opcode: <
    // check for DM underflow
    cmp  r3, r11
    beq  Error_dp_dec
    // DP ok, decrement it
    subs r3, #1
    b    Exec_loop

.align
Exec_pp_jfz:  // opcode: [
    // PM[PP] == opcode address after the closing bracket
    ldrb r0, [r3]
    cmp  r0, #0x00
    beq  exec_pp_jxx_jump
    adds r2, #4  // PP++ (advance to opcode address after space)
    b    Exec_loop

.align
Exec_pp_jbn:  // opcode: ]
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
Exec_dm_out:  // opcode: .
    ldrb r0, [r3]
    UART_WaitWrite exec_dm_out
    b    Exec_loop

.align
Exec_dm_inb:  // opcode: ,
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

Error_load_overflow:  // PM overflow (while loading)
    // TODO: drop all received bytes until load end ?
    movs r0, #'+'
    b    error_load_reset

Error_load_opening:  // missing opening bracket (while loading)
    // TODO: drop all received bytes until load end ?
    movs r0, #'['
    b    error_load_reset

Error_load_closing:  // missing closing bracket(s) (on load end)
    movs r0, #']'

error_load_reset:
    ldr  r1, =SRAM_END
    mov  sp, r1  // reset SP
    UART_WaitWrite error_load
    b    Main_reset

Error_dp_inc:  // DM overflow
    movs r0, #'>'
    b    error_exec_return

Error_dp_dec:  // DM underflow
    movs r0, #'<'

error_exec_return:
    subs r2, #4  // set PP back to the failed opcode
    UART_WaitWrite error_exec
    b    Main_prompt
