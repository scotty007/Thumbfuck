.macro GPIO_GetButton
    ldr  r0, =GPIOC_IDR
    ldr  r0, [r0]
    ldr  r1, =GPIOx_IDR.IDR13
    tst  r0, r1  // Z:=1 if button pressed (PC13 @ low level)
.endm

.macro GPIO_SetLedOn
    ldr  r0, =GPIOA_BSRR
    ldr  r1, =GPIOx_BSRR.BS5
    str  r1, [r0]
.endm

.macro GPIO_SetLedOff
    ldr  r0, =GPIOA_BSRR
    ldr  r1, =GPIOx_BSRR.BR5
    str  r1, [r0]
.endm
