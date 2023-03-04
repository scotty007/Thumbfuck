.syntax unified
.cpu cortex-m0
.fpu softvfp
.thumb

.include "defs.i"

.global GPIO_Init

GPIO_Init:
    // enable GPIOA/GPIOC clocks (PA5: LED, PC13: button)
    ldr  r0, =RCC_AHBENR
    ldr  r1, =(RCC_AHBENR.IOPAEN | RCC_AHBENR.IOPCEN)
    ldr  r2, [r0]
    orrs r2, r1
    str  r2, [r0]

    // set PA5 to output mode
    ldr  r0, =GPIOA_MODER
    ldr  r1, =GPIOx_MODER.MODER5_OUT
    ldr  r2, [r0]
    orrs r2, r1
    str  r2, [r0]
    // GPIOA_OTYPER  = 0x00000000 -> PA5: push-pull
    // GPIOA_OSPEEDR = 0x0C000000 -> PA5: low speed
    // GPIOA_PUPDR   = 0x24000000 -> PA5: no pull-up, no pull-down

    // GPIOC_MODER   = 0x00000000 -> PC13: input mode
    // GPIOC_PUPDR   = 0x00000000 -> PC13: no pull-up, no pull-down

    bx lr
