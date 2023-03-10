.macro UART_LoadRegs
    ldr  r3, =USART2_ISR
    ldr  r4, =USARTx_ISR.RXNE
    ldr  r5, =USARTx_ISR.TXE
    ldr  r6, =USART2_RDR
    ldr  r7, =USART2_TDR
.endm

.macro UART_CheckRead address
    // check for UART RX byte
    ldr  r0, [r3]
    tst  r0, r4
    beq  \address  // nothing received
    // byte received, read it (resets USART2_ISR.RXNE)
    ldr  r0, [r6]
.endm

.macro UART_WaitWrite label
    uart_wait_txe_loop_\label:
        // check TX ready state
        ldr  r1, [r3]
        tst  r1, r5
        beq  uart_wait_txe_loop_\label
    // ready to send
    str  r0, [r7]
.endm
