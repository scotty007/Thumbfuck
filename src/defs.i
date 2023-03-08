/*
 * NUCLEO-F072RB connections:
 * - PA2 : PA3 on ST-LINK MCU (USART_TX -> STLK_RX)
 * - PA3 : PA2 on ST-LINK MCU (USART_RX <- STLK_TX)
 * - PA5 : user LED
 * - PC13: user button (external 4k7 pull-up, H/W debounced)
 */

/*
 * system clock
 */
.equ    SYSCLK                  , 48000000                              // PLL @ 48MHz (8MHz HSI / 2 * 12)

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
.equ    USART2_BASE             , APBPERIPH_BASE + 0x00004400
.equ    USART2_CR1              , USART2_BASE + 0x00                    // USART2 control register 1
.equ    USART2_BRR              , USART2_BASE + 0x0c                    // USART2 baud rate register
.equ    USART2_ISR              , USART2_BASE + 0x1c                    // USART2 interrupt and status register
.equ    USART2_RDR              , USART2_BASE + 0x24                    // USART2 receive data register
.equ    USART2_TDR              , USART2_BASE + 0x28                    // USART2 transmit data register
// AHB peripherals
.equ    RCC_BASE                , AHBPERIPH_BASE + 0x00001000
.equ    RCC_CR                  , RCC_BASE + 0x00                       // RCC clock control register
.equ    RCC_CFGR                , RCC_BASE + 0x04                       // RCC clock configuration register
.equ    RCC_AHBENR              , RCC_BASE + 0x14                       // RCC AHB peripheral clock register
.equ    RCC_APB1ENR             , RCC_BASE + 0x1c                       // RCC APB1 peripheral clock enable register
.equ    FLASH_BASE              , AHBPERIPH_BASE + 0x00002000
.equ    FLASH_ACR               , FLASH_BASE + 0x00                     // FLASH access control register
// AHB2 peripherals
.equ    GPIOA_BASE              , AHB2PERIPH_BASE + 0x00000000
.equ    GPIOA_MODER             , GPIOA_BASE + 0x00                     // GPIOA port mode register
.equ    GPIOA_BSRR              , GPIOA_BASE + 0x18                     // GPIOA port bit set/reset register
.equ    GPIOA_AFRL              , GPIOA_BASE + 0x20                     // GPIOA alternate function low register
.equ    GPIOC_BASE              , AHB2PERIPH_BASE + 0x00000800
.equ    GPIOC_IDR               , GPIOC_BASE + 0x10                     // GPIOC port input data register

/*
 * peripheral registers bits
 */
// RCC
.equ    RCC_CR.PLLON            , 0b1 << 24                             // PLL enable
.equ    RCC_CR.PLLRDY           , 0b1 << 25                             // PLL clock ready flag
.equ    RCC_CFGR.SW_PLL         , 0b10 << 0                             // PLL selected as system clock
.equ    RCC_CFGR.SWS_PLL        , 0b10 << 2                             // PLL used as system clock
.equ    RCC_CFGR.PLLMUL_12      , 0b1010 << 18                          // PLL multiplication factor 12
.equ    RCC_AHBENR.IOPAEN       , 0b1 << 17                             // GPIOA port clock enable
.equ    RCC_AHBENR.IOPCEN       , 0b1 << 19                             // GPIOC port clock enable
.equ    RCC_APB1ENR.USART2EN    , 0b1 << 17                             // USART2 clock enable
// FLASH
.equ    FLASH_ACR.LATENCY_ONE   , 0b001 << 0                            // one wait state access latency
.equ    FLASH_ACR.PRFTBE        , 0b1 << 4                              // prefetch buffer enable
// GPIOx
.equ    GPIOx_MODER.MODER2_AF   , 0b10 << (2 * 2)                       // Px2 pin alternate function mode
.equ    GPIOx_MODER.MODER3_AF   , 0b10 << (3 * 2)                       // Px3 pin alternate function mode
.equ    GPIOx_MODER.MODER5_OUT  , 0b01 << (5 * 2)                       // Px5 pin output mode
.equ    GPIOx_IDR.IDR13         , 0b1 << 13                             // Px13 input data
.equ    GPIOx_BSRR.BS5          , 0b1 << 5                              // Px5 pin set
.equ    GPIOx_BSRR.BR5          , 0b1 << (16 + 5)                       // Px5 pin reset
.equ    GPIOx_AFRL.AFSEL2_AF1   , 0b0001 << (2 * 4)                     // Px2 alternate function AF1 (USART2_TX for PA2)
.equ    GPIOx_AFRL.AFSEL3_AF1   , 0b0001 << (3 * 4)                     // Px3 alternate function AF1 (USART2_RX for PA3)
// USARTx
.equ    USARTx_CR1.UE           , 0b1 << 0                              // USART enable
.equ    USARTx_CR1.RE           , 0b1 << 2                              // receiver enable
.equ    USARTx_CR1.TE           , 0b1 << 3                              // transmitter enable
.equ    USARTx_ISR.RXNE         , 0b1 << 5                              // read data register not empty
.equ    USARTx_ISR.TXE          , 0b1 << 7                              // transmit data register empty
