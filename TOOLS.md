# Development Tools

A summary of setting up some development tools on a Debian(-based) OS.

The following steps install everything in the local `tools` folder and should be executed right there.

    $ cd tools

## Install Arm GNU Toolchain

Purpose: Build the Thumbfuck F/W binary from assembly source.

    $ wget https://developer.arm.com/-/media/Files/downloads/gnu/12.2.rel1/binrel/arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi.tar.xz
    $ wget https://developer.arm.com/-/media/Files/downloads/gnu/12.2.rel1/binrel/arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc
    $ sha256sum -c arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc

    $ tar -xJf arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi.tar.xz
    $ mv arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi arm

    $ rm -f arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi.tar.xz*

## Build and Install OpenOCD

Purpose: Upload (flash) and debug the Thumbfuck F/W binary.

    $ apt install git libtool-bin libusb-1.0-0-dev libcapstone-dev

    $ git clone https://github.com/openocd-org/openocd.git openocd.git
    $ cd openocd.git
    $ git submodule update --init --recursive

    $ ./bootstrap
    $ ./configure --prefix=$(realpath ../openocd)
    $ make -j9
    $ make install

    $ cd ..
    $ rm -rf openocd.git

## Build and Install gdb with Python3 support

Purpose: Debug the Thumbfuck F/W binary (via OpenOCD, with gdb-dashboard support).

    $ apt install texinfo libgmp-dev python3-dev

    $ wget https://ftp.gnu.org/gnu/gdb/gdb-13.1.tar.xz
    $ wget https://ftp.gnu.org/gnu/gdb/gdb-13.1.tar.xz.sig
    $ wget https://ftp.gnu.org/gnu/gnu-keyring.gpg
    $ gpg --verify --keyring ./gnu-keyring.gpg gdb-13.1.tar.xz.sig
    $ tar Jxf gdb-13.1.tar.xz

    $ mkdir gdb-13.1/build
    $ cd gdb-13.1/build
    $ ../configure --with-python=/usr/bin/python3 --target=arm-none-eabi --enable-interwork --enable-multilib
    $ make -j9

    $ cd ../..
    $ mkdir gdb
    $ cp gdb-13.1/build/gdb/gdb gdb/
    $ cp -r gdb-13.1/build/gdb/data-directory gdb/

    $ rm -rf gdb-13.1* gnu-keyring.gpg

## Install gdb-dashboard

Purpose: Add a powerful and customizable UI to gdb.

    $ apt install git

    $ git clone https://github.com/cyrus-and/gdb-dashboard.git

## Usage

### Flash Thumbfuck F/W with OpenOCD

    $ ./tools/openocd/bin/openocd -f ./tools/openocd/share/openocd/scripts/board/st_nucleo_f0.cfg -c 'program thumbfuck.elf preverify verify reset exit'

### Debug with OpenOCD & gdb

Start OpenOCD:

    $ ./tools/openocd/bin/openocd -f ./tools/openocd/share/openocd/scripts/board/st_nucleo_f0.cfg

Start gdb & connect to OpenOCD:

    $ ./tools/gdb/gdb --data-directory=./tools/gdb/data-directory thumbfuck.elf
    (gdb) target extended-remote:3333
    (gdb) monitor reset halt

or, with gdb-dashboard:

    $ ./tools/gdb/gdb -x ./tools/.gdbinit --data-directory=./tools/gdb/data-directory thumbfuck.elf
    >>> tf-start
