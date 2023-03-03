.syntax unified
.cpu cortex-m0
.fpu softvfp
.thumb

.global GPIO_Init

GPIO_Init:
    adds r0, r0, #1
    bx lr
