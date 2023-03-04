/*
 * NUCLEO-F072RB connections:
 * - PA5 : user LED
 * - PC13: user button (external 4k7 pull-up, H/W debounced)
 */

/*
 * SRAM mapping
 */
.equ    SRAM_BASE               , 0x20000000
.equ    SRAM_SIZE               , 0x00004000
.equ    SRAM_END                , SRAM_BASE + SRAM_SIZE

/*
 * peripherals memory mapping
 */
.equ    PERIPH_BASE             , 0x40000000
.equ    APBPERIPH_BASE          , PERIPH_BASE + 0x00000000
.equ    AHBPERIPH_BASE          , PERIPH_BASE + 0x00020000
.equ    AHB2PERIPH_BASE         , PERIPH_BASE + 0x08000000
// APB peripherals
// AHB peripherals
.equ    RCC_BASE                , AHBPERIPH_BASE + 0x00001000
.equ    RCC_AHBENR              , RCC_BASE + 0x14                       // RCC AHB peripheral clock register
// AHB2 peripherals
.equ    GPIOA_BASE              , AHB2PERIPH_BASE + 0x00000000
.equ    GPIOA_MODER             , GPIOA_BASE + 0x00                     // GPIOA port mode register
.equ    GPIOA_BSRR              , GPIOA_BASE + 0x18                     // GPIOA port bit set/reset register
.equ    GPIOC_BASE              , AHB2PERIPH_BASE + 0x00000800
.equ    GPIOC_IDR               , GPIOC_BASE + 0x10                     // GPIOC port input data register

/*
 * peripheral registers bits
 */
// RCC
.equ    RCC_AHBENR.IOPAEN       , 0b1 << 17                             // GPIOA port clock enable
.equ    RCC_AHBENR.IOPCEN       , 0b1 << 19                             // GPIOC port clock enable
// GPIOx
.equ    GPIOx_MODER.MODER5_OUT  , 0b01 << (5 * 2)                       // Px5 pin output mode
.equ    GPIOx_IDR.IDR13         , 0b1 << 13                             // Px13 input data
.equ    GPIOx_BSRR.BS5          , 0b1 << 5                              // Px5 pin set
.equ    GPIOx_BSRR.BR5          , 0b1 << (16 + 5)                       // Px5 pin reset
