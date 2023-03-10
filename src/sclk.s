.syntax unified
.cpu cortex-m0
.fpu softvfp
.thumb

.include "defs.i"

.global SCLK_Init

SCLK_Init:
    // FLASH_ACR: set one-wait-state latency (24MHz < SYSCLK ≤ 48MHz), enable prefetch buffer
    ldr  r0, =FLASH_ACR
    ldr  r1, =(FLASH_ACR.LATENCY_ONE | FLASH_ACR.PRFTBE)
    ldr  r2, [r0]
    orrs r2, r1
    str  r2, [r0]

    // RCC_CFGR.PLLSRC == 0b00 -> HSI/2 selected as PLL input (PREDIV forced to 2)
    // RCC_CFGR: set PLL multiplication factor to 12 (8MHz HSI / 2 * 12 -> 48MHz)
    ldr  r0, =RCC_CFGR
    ldr  r1, =RCC_CFGR.PLLMUL_12
    ldr  r2, [r0]
    orrs r2, r1
    str  r2, [r0]
    // RCC_CR: enable PLL
    ldr  r0, =RCC_CR
    ldr  r1, =RCC_CR.PLLON
    ldr  r2, [r0]
    orrs r2, r1
    str  r2, [r0]
    // wait for PLL to get ready
    ldr  r1, =RCC_CR.PLLRDY
    wait_pll_ready:
        ldr  r2, [r0]
        tst  r2, r1
        beq  wait_pll_ready

    // RCC_CFGR: select PLL as system clock
    ldr  r0, =RCC_CFGR
    ldr  r1, =RCC_CFGR.SW_PLL
    ldr  r2, [r0]
    orrs r2, r1
    str  r2, [r0]
    // wait for clock switch
    ldr  r1, =RCC_CFGR.SWS_PLL
    wait_pll_selected:
        ldr  r2, [r0]
        tst  r2, r1
        beq  wait_pll_selected

    bx   lr
