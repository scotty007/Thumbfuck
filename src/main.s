.syntax unified
.cpu cortex-m0
.fpu softvfp
.thumb

.include "defs.i"
.include "gpio.i"

.global Main_Loop

Main_Loop:
    GPIO_GetButton
    beq  led_on
    led_off:
        GPIO_SetLedOff
        b    Main_Loop
    led_on:
        GPIO_SetLedOn
        b    Main_Loop
