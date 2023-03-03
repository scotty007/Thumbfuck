.syntax unified
.cpu cortex-m0
.fpu softvfp
.thumb

.global UART_Init

UART_Init:
    adds r0, r0, #1
    bx lr
