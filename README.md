# Simple MS-DOS Implementation

A minimal MS-DOS-like operating system written in C and assembly.

## Prerequisites

### Development Tools
- **NASM** (Netwide Assembler)
- **GCC cross-compiler** for i386-elf
- **QEMU** for testing
- **Binutils** for i386-elf

### Installation

#### Ubuntu/Debian:
```bash
sudo apt-get install nasm qemu-system-x86 gcc-i386-elf binutils-i386-elf
```

#### macOS:
```bash
brew install nasm qemu
# For cross-compiler, you may need to build from source or use a different approach
```

#### Windows (with WSL):
```bash
sudo apt-get install nasm qemu-system-x86 gcc-i386-elf binutils-i386-elf
```

## Project Structure

```
MS-DOS/
├── src/
│   ├── boot/
│   │   └── bootloader.asm      # Boot sector (512 bytes)
│   ├── kernel/
│   │   ├── kernel.c           # Main kernel code
│   │   ├── kernel_asm.asm     # Kernel assembly functions
│   │   ├── memory.c           # Memory management
│   │   ├── io.c               # Basic I/O functions
│   │   ├── filesystem.c       # Simple filesystem
│   │   └── interrupts.c       # Interrupt handlers
│   ├── shell/
│   │   └── shell.c            # Command interpreter
│   └── include/
│       ├── kernel.h           # Kernel headers
│       ├── io.h               # I/O definitions
│       └── types.h            # Basic types
├── build/                     # Build output
├── bin/                       # Final binaries
├── Makefile                   # Build system
├── linker.ld                 # Linker script
└── README.md                  # This file
```

## Building

```bash
# Build the entire OS
make

# Build just the disk image
make build-image

# Run in QEMU
make run

# Clean build files
make clean
```

## Features

### Bootloader
- 512-byte MBR
- Loads kernel at 0x1000
- Basic BIOS calls

### Kernel
- Memory management
- System calls
- Interrupt handling
- Basic I/O

### Shell
- Command interpreter
- Built-in commands (dir, type, cls, exit)
- Program execution

## Architecture

### Memory Layout
- `0x0000-0x03FF` - IVT (Interrupt Vector Table)
- `0x0400-0x04FF` - BIOS Data Area
- `0x0500-0x07FF` - Bootloader stack
- `0x1000-0x9FFF` - Kernel
- `0xA000-0xFFFF` - User programs

### System Calls
- `0x21` - DOS-compatible interrupts
- `0x10` - Video services
- `0x13` - Disk services
- `0x16` - Keyboard services

## Testing

The OS is designed to run in QEMU. Use `make run` to start the virtual machine.

## Limitations

- Single-tasking (no multitasking)
- Simple filesystem (flat file structure)
- Limited memory management
- No networking
- No GUI

## Development

To add new features:
1. Add system calls to `kernel/interrupts.c`
2. Implement functionality in appropriate kernel files
3. Add shell commands in `shell/shell.c`
4. Update headers as needed

## License

Educational use only.
