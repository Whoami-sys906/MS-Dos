# Simple MS-DOS Build System
CC      = gcc
AS      = nasm
LD      = ld

CFLAGS  = -m32 -ffreestanding -nostdlib -fno-builtin -fno-stack-protector \
          -fno-pie -no-pie -Wall -Wextra -c -I$(SRC)/include
ASFLAGS = -f elf32
LDFLAGS = -m elf_i386 -T linker.ld --oformat binary

SRC   = src
BUILD = build
BIN   = bin

# Sources
STAGE1   = $(SRC)/boot/stage1.asm
STAGE2   = $(SRC)/boot/stage2.asm
K16      = $(SRC)/kernel/kernel16_clean.asm
KERNEL16_ASM = $(SRC)/kernel/kernel16_clean.asm
K_ASM    = $(SRC)/kernel/kernel_asm.asm
K_C      = $(SRC)/kernel/kernel.c
MEM_C    = $(SRC)/kernel/memory.c
IO_C     = $(SRC)/kernel/io.c
INT_C    = $(SRC)/kernel/interrupts.c
FS_C     = $(SRC)/kernel/filesystem.c
SH_C     = $(SRC)/shell/shell.c

# Binaries
STAGE1_BIN = $(BUILD)/stage1.bin
STAGE2_BIN = $(BUILD)/stage2.bin
K16_BIN    = $(BUILD)/kernel16.bin
K_BIN      = $(BIN)/kernel.bin
OS_IMG     = $(BIN)/msdos.img

# Objects (for 32-bit protected-mode kernel – optional target)
OBJS = $(BUILD)/kernel_asm.o \
       $(BUILD)/kernel.o     \
       $(BUILD)/memory.o     \
       $(BUILD)/io.o         \
       $(BUILD)/interrupts.o \
       $(BUILD)/filesystem.o \
       $(BUILD)/shell.o

.PHONY: all clean run

all: $(OS_IMG)

$(BUILD) $(BIN):
	mkdir -p $@

# ── Boot sectors ────────────────────────────────────────────────
$(STAGE1_BIN): $(STAGE1) | $(BUILD)
	$(AS) -f bin $< -o $@

$(STAGE2_BIN): $(STAGE2) | $(BUILD)
	$(AS) -f bin $< -o $@

$(K16_BIN): $(K16) | $(BUILD)
	$(AS) -f bin $< -o $@

# ── 32-bit kernel (optional – uncomment run target below to use) 
$(BUILD)/kernel_asm.o: $(K_ASM) | $(BUILD)
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD)/kernel.o: $(K_C) | $(BUILD)
	$(CC) $(CFLAGS) $< -o $@

$(BUILD)/memory.o: $(MEM_C) | $(BUILD)
	$(CC) $(CFLAGS) $< -o $@

$(BUILD)/io.o: $(IO_C) | $(BUILD)
	$(CC) $(CFLAGS) $< -o $@

$(BUILD)/interrupts.o: $(INT_C) | $(BUILD)
	$(CC) $(CFLAGS) $< -o $@

$(BUILD)/filesystem.o: $(FS_C) | $(BUILD)
	$(CC) $(CFLAGS) $< -o $@

$(BUILD)/shell.o: $(SH_C) | $(BUILD)
	$(CC) $(CFLAGS) $< -o $@

$(K_BIN): $(OBJS) | $(BIN)
	$(LD) $(LDFLAGS) -o $@ $^

# ── Disk image (real-mode: stage1 + stage2 + kernel16) ──────────
BOOT_BIN = $(BUILD)/boot.bin

$(BOOT_BIN): src/boot/bootloader.asm | $(BUILD)
	nasm -f bin $< -o $@

$(BUILD)/minimal.bin: src/kernel/minimal.asm | $(BUILD)
	nasm -f bin $< -o $@

$(BUILD)/kernel16_clean.bin: src/kernel/kernel16_clean.asm | $(BUILD)
	nasm -f bin $< -o $@

$(BUILD)/simple.bin: src/kernel/simple.asm | $(BUILD)
	nasm -f bin $< -o $@

$(BUILD)/fixed.bin: src/kernel/fixed.asm | $(BUILD)
	nasm -f bin $< -o $@

$(OS_IMG): $(BOOT_BIN) $(BUILD)/fixed.bin | $(BIN)
	dd if=/dev/zero of=$@ bs=1M count=1 2>/dev/null
	dd if=$(BOOT_BIN) of=$@ bs=512 count=1 conv=notrunc
	dd if=build/fixed.bin  of=$@ bs=512 seek=1 conv=notrunc
run: $(OS_IMG)
	qemu-system-i386 -fda $(OS_IMG) -boot a -no-reboot

clean:
	rm -rf $(BUILD) $(BIN)
