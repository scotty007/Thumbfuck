.syntax unified
.cpu cortex-m0
.fpu softvfp
.thumb

.include "defs.i"

.global GPIO_Init

GPIO_Init:
    // RCC_AHBENR: enable GPIOA/GPIOC clocks (PA2/PA3: USART2, PA5: LED, PC13: button)
    ldr  r0, =RCC_AHBENR
    ldr  r1, =(RCC_AHBENR.IOPAEN | RCC_AHBENR.IOPCEN)
    ldr  r2, [r0]
    orrs r2, r1
    str  r2, [r0]

    // GPIOA_MODER: set PA2/PA3 to alternate function mode, PA5 to output mode
    ldr  r0, =GPIOA_MODER
    ldr  r1, =(GPIOx_MODER.MODER2_AF | GPIOx_MODER.MODER3_AF | GPIOx_MODER.MODER5_OUT)
    ldr  r2, [r0]
    orrs r2, r1
    str  r2, [r0]
    // GPIOA_OTYPER  = 0x00000000 -> PA2/PA5: push-pull
    // GPIOA_OSPEEDR = 0x0C000000 -> PA2/PA5: low speed
    // GPIOA_PUPDR   = 0x24000000 -> PA2/PA3/PA5: no pull-up, no pull-down
    // GPIOx_AFRL: set PA2/PA3 alternate function to AF1 (USART2_TX/USART2_RX)
    ldr  r1, =(GPIOx_AFRL.AFSEL2_AF1 | GPIOx_AFRL.AFSEL3_AF1)
    ldr  r2, [r0, #(GPIOA_AFRL - GPIOA_MODER)]
    orrs r2, r1
    str  r2, [r0, #(GPIOA_AFRL - GPIOA_MODER)]

    // GPIOC_MODER = 0x00000000 -> PC13: input mode
    // GPIOC_PUPDR = 0x00000000 -> PC13: no pull-up, no pull-down

    bx lr
