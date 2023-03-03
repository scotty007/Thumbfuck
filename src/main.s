.syntax unified
.cpu cortex-m0
.fpu softvfp
.thumb

.global Main_Loop

Main_Loop:
    adds r0, r0, #1
    b .
