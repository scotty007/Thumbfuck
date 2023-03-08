.syntax unified
.cpu cortex-m0
.fpu softvfp
.thumb

.include "defs.i"

.section .vector_table,"a",%progbits
Vector_Table:
    .word SRAM_END                          // stack init address
    .word Reset_Handler+1                   // our entry point
    // Cortex-M0 exceptions
    .word Default_Handler+1                 // NMI_Handler
    .word HardFault_Handler+1               // what the [brain]fuck!?
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word Default_Handler+1                 // SVC_Handler
    .word 0
    .word 0
    .word Default_Handler+1                 // PendSV_Handler
    .word Default_Handler+1                 // SysTick_Handler
    // STM32F0 interrupts
    .word Default_IRQHandler+1              // WWDG_IRQHandler
    .word Default_IRQHandler+1              // PVD_VDDIO2_IRQHandler
    .word Default_IRQHandler+1              // RTC_IRQHandler
    .word Default_IRQHandler+1              // FLASH_IRQHandler
    .word Default_IRQHandler+1              // RCC_CRS_IRQHandler
    .word Default_IRQHandler+1              // EXTI0_1_IRQHandler
    .word Default_IRQHandler+1              // EXTI2_3_IRQHandler
    .word Default_IRQHandler+1              // EXTI4_15_IRQHandler
    .word Default_IRQHandler+1              // TSC_IRQHandler
    .word Default_IRQHandler+1              // DMA1_Channel1_IRQHandler
    .word Default_IRQHandler+1              // DMA1_Channel2_3_IRQHandler
    .word Default_IRQHandler+1              // DMA1_Channel4_5_6_7_IRQHandler
    .word Default_IRQHandler+1              // ADC1_COMP_IRQHandler
    .word Default_IRQHandler+1              // TIM1_BRK_UP_TRG_COM_IRQHandler
    .word Default_IRQHandler+1              // TIM1_CC_IRQHandler
    .word Default_IRQHandler+1              // TIM2_IRQHandler
    .word Default_IRQHandler+1              // TIM3_IRQHandler
    .word Default_IRQHandler+1              // TIM6_DAC_IRQHandler
    .word Default_IRQHandler+1              // TIM7_IRQHandler
    .word Default_IRQHandler+1              // TIM14_IRQHandler
    .word Default_IRQHandler+1              // TIM15_IRQHandler
    .word Default_IRQHandler+1              // TIM16_IRQHandler
    .word Default_IRQHandler+1              // TIM17_IRQHandler
    .word Default_IRQHandler+1              // I2C1_IRQHandler
    .word Default_IRQHandler+1              // I2C2_IRQHandler
    .word Default_IRQHandler+1              // SPI1_IRQHandler
    .word Default_IRQHandler+1              // SPI2_IRQHandler
    .word Default_IRQHandler+1              // USART1_IRQHandler
    .word Default_IRQHandler+1              // USART2_IRQHandler
    .word Default_IRQHandler+1              // USART3_4_IRQHandler
    .word Default_IRQHandler+1              // CEC_CAN_IRQHandler
    .word Default_IRQHandler+1              // USB_IRQHandler

.text

Default_Handler:
Default_IRQHandler:
    b .

HardFault_Handler:
    b .

Reset_Handler:
    // SP = MSP = SRAM_END (set by H/W)
    bl SCLK_Init  // pedal to the metal!
    bl GPIO_Init
    bl UART_Init
    b  Main_Start
