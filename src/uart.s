.syntax unified
.cpu cortex-m0
.fpu softvfp
.thumb

.include "defs.i"

.global UART_Init

.equ UART_BAUD , 115200

UART_Init:
    // RCC_APB1ENR: enable USART2 clock
    ldr  r0, =RCC_APB1ENR
    ldr  r1, =RCC_APB1ENR.USART2EN
    ldr  r2, [r0]
    orrs r2, r1
    str  r2, [r0]
    // RCC_CR2.USART2SW == 0b00 -> PCLK selected as USART2 clock source
    // RCC_CFGR.HPRE == 0b0000, RCC_CFGR.PPRE == 0b000 -> PCLK = SYSCLK

    // USART2_BRR: set USARTDIV for UART_BAUD
    ldr  r0, =USART2_BRR
    ldr  r1, =(SYSCLK / UART_BAUD)
    str  r1, [r0]
    // USART_CR1: enable transmitter, receiver and USART
    ldr  r0, =USART2_CR1
    ldr  r1, =(USARTx_CR1.TE | USARTx_CR1.RE | USARTx_CR1.UE)
    ldr  r2, [r0]
    orrs r2, r1
    str  r2, [r0]
    // USART_CR1.M     == 0b00 -> 1 start bit, 8 data bits
    // USART_CR1.OVER8 == 0b0  -> oversampling by 16
    // USART_CR1.PCE   == 0b0  -> parity disabled
    // USART_CR2.STOP  == 0b00 -> 1 stop bit

    bx   lr
