# An ARM Linux program from scratch

A 32-bit ARM Linux program written in assembly using [customasm][customasm].

It converts lowercase characters to uppercase, leaving other characters untouched.

## Rationale

The idea behind this project was to produce a working Linux binary without relying on any tool that contains knowledge about Linux or any specific CPU. Surprisingly enough, all that's needed to achieve this is:
- An agnostic assembler
- The [ELF][elf] specification (to produce a working executable)
- The [ARM][arm] instruction set specification (for the actual program)
- The [Linux system call][syscall] specification (to communicate with the kernel)

Here's the corresponding tools and resources I ended up using:
- First python, then the amazing [customasm] project
- [In-depth: ELF - The Extensible & Linkable Format](https://youtu.be/nC1U1LJQL8o) by stacksmashing 
- [The ARM7TDMI-S Data Sheet](https://iitd-plos.github.io/col718/ref/arm-instructionset.pdf)
- [The Linux system call table for ARM 32-bit](https://chromium.googlesource.com/chromiumos/docs/+/master/constants/syscalls.md#arm-32_bit_EABI)


## Tools

First install [qemu][qemu] and [customasm][customasm]:
```bash
# Install qemu, unless you're already on a raspberry pi
$ sudo apt install qemu-user
# Install customasm, or download from: https://github.com/hlorenzi/customasm/releases
$ cargo install customasm
```

## Assembly

Then assemble the `upper` binary:
```bash
# Assemble with customasm and give executable access
$ customasm upper.asm -o upper && chmod +x upper
customasm v0.11.4 (x86_64-unknown-linux-gnu)
assembling `upper.asm`...
writing `upper`...
success
```

## Execution

And try it out:
```bash
# Run with qemu explicitely
$ qemu-arm upper --help
Usage: upper [OPTION]
Transform lowercase ascii characters to uppercase.

Other ascii characters are left untouched.
Data is read from stdin and written to stdout.

  --help  display this help and exit

# Or implicitely
$ echo "1.. 2.. This is a test.." | ./upper
1.. 2.. THIS IS A TEST..

# The binary is actually quite small, about half a KB
wc -c upper
501 upper

# customasm can also produce an annotated binary
$ customasm upper.asm -f annotated -p
customasm v0.11.4 (x86_64-unknown-linux-gnu)
assembling `upper.asm`...
success

  outp | addr | data

   0:0 |    0 | 7f          ; #d 0x7f
   1:0 |    1 | 45 4c 46    ; "ELF"
   ...
```

[elf]: https://en.wikipedia.org/wiki/Executable_and_Linkable_Format
[arm]: https://en.wikipedia.org/wiki/ARM_architecture
[qemu]: https://www.qemu.org/
[syscall]: https://en.wikipedia.org/wiki/System_call
[customasm]: https://github.com/hlorenzi/customasm