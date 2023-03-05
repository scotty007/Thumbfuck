.syntax unified
.cpu cortex-m0
.fpu softvfp
.thumb

.include "defs.i"
.include "gpio.i"

.global Main_Start

Main_Start:
    ldr  r3, =USART2_ISR
    ldr  r4, =USARTx_ISR.RXNE
    ldr  r5, =USARTx_ISR.TXE
    ldr  r6, =USART2_RDR
    ldr  r7, =USART2_TDR

Main_Loop:
    // check for UART RX byte
    ldr  r0, [r3]
    tst  r0, r4
    beq  handle_led  // nothing rececved
    // byte received, echo back
    ldr  r1, [r6]  // resets USART2_ISR.RXNE
wait_txe_loop:
    // check TX ready state
    ldr  r0, [r3]
    tst  r0, r5
    beq  wait_txe_loop
    // ready to send
    str  r1, [r7]

handle_led:
    GPIO_GetButton
    beq  led_on
    led_off:
        GPIO_SetLedOff
        b    Main_Loop
    led_on:
        GPIO_SetLedOn
        b    Main_Loop
