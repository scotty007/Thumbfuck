# Thumbfuck

                       _____ _____ _____ _____
      ________________/     V     V     V     \
     /                |     |     |     |     |
    |  T  H  U  M  B  |  F  |  U  |  C  |  K  |
     \________________|     |     |     |     |
                      |     |     |     |     |
                      |     |     |     |     |
                      |     |     |     |     |
                       \___/ \___/ \___/ \___/

A [Brainfuck](https://en.wikipedia.org/wiki/Brainfuck) interpreter, written in Thumb
assembly (ARMv6-M) for Cortex-M0 microcontrollers, namely the STM32F072RBT6 on a
[NUCLEO-F072RB](https://www.st.com/en/evaluation-tools/nucleo-f072rb.html) board.

Thumbfuck (*TF*) loads and runs Brainfuck (*BF*) source code, using serial
communication for I/O.

*BF* programs and data share the on-chip 16kByte SRAM, which limits the size of
program (*PM*) and data (*DM*) memories.
When the program pointer (*PP*) reaches the end of *PM*, *TF* returns to the
command prompt (see below). There's no need for some end-of-program marker.
*DM* cells are 8 bit wide and wrap over (`+` and `-` *BF* operations).
Moving the data pointer (*DP*) outside the *DM* range (`<` and `>` *BF* operations)
raises an error (see below).

An initial *BF* program, which prints the logo above, is loaded and ready to
run on reset.

## Installation

The NUCLEO board comes with an embedded ST-LINK/V2-1 debugger/programmer.
Use your favorite ST-LINK tool (e.g. [OpenOCD](https://openocd.org/)) to upload
the *TF* F/W binary.

Pre-built ELF binaries can be found in the `elf` folder.

To build the F/W from source, the Arm GNU Toolchain is required.
A simple `make` will generate the ELF binary and an assembler listing file (assuming
the `TOOLS_ARM` variable in `Makefile` points to the correct toolchain location).

For some notes on how to set up and use required development (and optional debugging)
tools, see [TOOLS.md](TOOLS.md).

## Usage

*TF* uses the on-chip USART2 (available via USB through the on-board ST-LINK) for
a simple serial interface.

Connect the board and open your favorite serial terminal program (115200-8N1).
Press the on-board RESET button. You should find yourself at the *TF* command
prompt (see below).

**NOTE:** *TF* and almost all *BF* programs out there use a single`LF` (`0x0A`,
'`\n`') character for line breaks. Configure your terminal program accordingly.

### Commands

At the command prompt (a '`-`' character) *TF* waits for the following commands:

- '`:`' - *Load* program
- '`(`' - *Run* (loaded) program
- '`)`' - *Reset* program (to re-run it)

Each accepted command character is echoed back, all other input is ignored.
The on-board USER LED is lit during command execution.

After the *Load* command *TF* accepts *BF* source code (including comments,
just type or paste it in). The source code is not echoed back.
To end loading and return to the command prompt, press the on-board USER button
or send a zero (`0x00`) byte.
There's only one program loaded at a time.

A running program can be paused by pressing the on-board USER button, and resumed
with the *Run* command.

The *Reset* command sets *PP* to the start of *PM* and clears all *DM* cells
to zero (`0x00`).

### Input

*TF* implements blocking input.
When the running program reaches a read-char *BF* operation (`,`), it outputs an
input prompt character ('`,`') and waits until a byte has been received.
All unexpected input is discarded.

### Errors

When an error occurs, *TF* outputs the following error characters:

While loading a program or at end of loading:

- '`+`' - *PM* overflow
- '`[`' - unbalanced brackets (missing opening)
- '`]`' - unbalanced brackets (missing closing)

While running a program:

- '`<`' - *DM* underflow
- '`>`' - *DM* overflow

### Example

Calculate all prime numbers up to 42.

- At the command prompt, type '`:`' to begin loading.
- Copy/paste *BF* code from `dev/prime.b`.
- Press the on-board USER button (or send `0x00`) to end loading.
- Back at the command prompt, type '`(`' to run the program.
- At the input prompts, type '`4`', '`2`' and `LF`.

Then sit back and watch ...

    -:
    -(Primes up to: ,,,2 3 5 7 11 13 17 19 23 29 31 37 41

## License

Thumbfuck is distributed under the terms of the [MIT license](LICENSE).

The `dev/prime.b` file is taken from Urban Müller's original
[`brainfuck-2.lha`](http://main.aminet.net/dev/lang/brainfuck-2.lha) archive.
No license included.
