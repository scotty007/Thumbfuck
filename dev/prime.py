#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
A simple Thumbfuck interpreter benchmark, crunching prime numbers.

The prime.b file is taken from Urban Müller's original brainfuck-2.lha archive.
"""

import sys
import time

import serial

SERIAL_PORT = '/dev/ttyACM0'

SOURCE_FILE = 'prime.b'
MAX_PRIME = 100
NUM_RUNS = 3
SHOW_PROGRESS = True

PROMPT_CMD_BYTE = b'-'
PROMPT_INB_BYTE = b','

LOAD_CMD_BYTE = b':'
LOAD_END_BYTE = b'\x00'
RESET_CMD_BYTE = b')'
EXEC_CMD_BYTE = b'('

conn = serial.Serial(SERIAL_PORT, 115200, timeout=0.5)
print('connected', end='')
sys.stdout.flush()
conn.write(RESET_CMD_BYTE)
if conn.read() == RESET_CMD_BYTE:
    print()
else:
    print(', press RESET button')
while conn.read() != PROMPT_CMD_BYTE:
    pass

print(f'reading program from "{SOURCE_FILE}" ...')
with open(SOURCE_FILE) as f:
    source_code = f.read()
source_bytes = source_code.encode('ascii')

input_bytes = [bytes(c.encode('ascii')) for c in f'{MAX_PRIME}\n']

print('loading program ...')
conn.write(LOAD_CMD_BYTE)
if conn.read() != LOAD_CMD_BYTE:
    exit(1)
conn.write(source_bytes)
conn.write(LOAD_END_BYTE)
if conn.read() != b'\n':  # load error
    exit(2)

run_times = []
for num_run in range(NUM_RUNS):
    run_str = f'[{num_run + 1}/{NUM_RUNS}]'
    if num_run:
        print(f'{run_str} resetting program ...')
        conn.write(RESET_CMD_BYTE)
        if conn.read() != RESET_CMD_BYTE:
            exit(4)
    while conn.read() != PROMPT_CMD_BYTE:
        pass

    print(f'{run_str} starting program ...')
    conn.write(EXEC_CMD_BYTE)
    if conn.read() != EXEC_CMD_BYTE:
        exit(3)

    print(f'{run_str} sending input ...')
    for input_byte in input_bytes:
        while conn.read() != PROMPT_INB_BYTE:
            pass
        conn.write(input_byte)

    start_time = time.time()
    print(f'{run_str} calculating up to {MAX_PRIME} ...')
    if SHOW_PROGRESS:
        print(run_str, end=' ')
        while True:
            rx_byte = conn.read()
            if rx_byte == PROMPT_CMD_BYTE:
                break
            if rx_byte in (b'', b'\n'):
                continue
            print(rx_byte.decode('ascii'), end='')
            sys.stdout.flush()
        print()
    else:
        while conn.read() != PROMPT_CMD_BYTE:
            pass
    end_time = time.time()
    run_time = end_time - start_time
    print(f'{run_str} calculation time: {run_time:.3f} seconds')
    run_times.append(run_time)
print(f'average calculation time: {sum(run_times) / NUM_RUNS:.3f} seconds')

conn.close()
