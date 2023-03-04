TARGET = thumbfuck

TOOLS_ARM = ./tools/arm/bin/arm-none-eabi
AS = $(TOOLS_ARM)-as
LD = $(TOOLS_ARM)-ld
OD = $(TOOLS_ARM)-objdump
SZ = $(TOOLS_ARM)-size

ASFLAGS = -I src -mcpu=cortex-m0 -mthumb --warn -g
LDFLAGS = -T stm32f072rbt6.ld -nostdlib

SRCS = $(wildcard src/*.s)
OBJS = $(SRCS:.s=.o)

.PHONY: all clean

all: $(TARGET).lst

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

$(TARGET).elf: $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

$(TARGET).lst: $(TARGET).elf
	$(OD) -d -S -w $< > $@
	$(SZ) $<

clean:
	rm -f $(OBJS)
	rm -f $(TARGET).elf
	rm -f $(TARGET).lst
