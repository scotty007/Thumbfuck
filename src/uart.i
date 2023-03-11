.macro UART_LoadRegs
    ldr  r5, =USART2_BASE
    ldr  r6, =USARTx_ISR.RXNE
    ldr  r7, =USARTx_ISR.TXE
.endm

.macro UART_CheckRead address
    // check for UART RX byte
    ldr  r0, [r5, #(USART2_ISR - USART2_BASE)]
    tst  r0, r6
    beq  \address  // nothing received
    // byte received, read it (resets USART2_ISR.RXNE)
    ldr  r0, [r5, #(USART2_RDR - USART2_BASE)]
.endm

.macro UART_WaitWrite label
    uart_wait_txe_loop_\label:
        // check TX ready state
        ldr  r1, [r5, #(USART2_ISR - USART2_BASE)]
        tst  r1, r7
        beq  uart_wait_txe_loop_\label
    // ready to send
    str  r0, [r5, #(USART2_TDR - USART2_BASE)]
.endm
