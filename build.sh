#!/bin/bash

# Build script for Simple MS-DOS
# This script builds the entire operating system

echo "Building Simple MS-DOS..."

# Check if required tools are installed
if ! command -v nasm &> /dev/null; then
    echo "Error: NASM is not installed"
    echo "Please install NASM: sudo apt-get install nasm"
    exit 1
fi

if ! command -v i386-elf-gcc &> /dev/null; then
    echo "Error: i386-elf-gcc is not installed"
    echo "Please install i386-elf-gcc: sudo apt-get install gcc-i386-elf"
    exit 1
fi

if ! command -v qemu-system-i386 &> /dev/null; then
    echo "Error: QEMU is not installed"
    echo "Please install QEMU: sudo apt-get install qemu-system-x86"
    exit 1
fi

# Clean previous build
echo "Cleaning previous build..."
make clean

# Build the OS
echo "Building OS..."
make

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo ""
    echo "To run the OS:"
    echo "  make run"
    echo ""
    echo "To build only:"
    echo "  make build-image"
    echo ""
    echo "Disk image created: bin/msdos.img"
else
    echo "Build failed!"
    exit 1
fi
