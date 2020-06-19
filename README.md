# GBA.Dart

A faithful [GameBoy Advance][] [Emulator][] written in [Dart][].

[gameboy advance]: https://en.wikipedia.org/wiki/Game_Boy_Advance
[emulator]: https://en.wikipedia.org/wiki/Emulator
[dart]: https://dart.dev/

## Resources

See [doc/resources.md](doc/resources.md) for a summary and links to resources.

Some sites, repositiories, and documents were referenced or used in order to
build this package - so a special thanks to all of them. Some of these resources
are on sites that don't seem extremely reliable, so there is a copy of most of
them in the [`doc/pdf` folder](doc/pdf).

## CPU

The GameBoy Advance uses a 32-bit [ARM7TDMI][] CPU, running an
[ARMv4 architecture][]. This CPU, like many ARM CPUs, has two modes of
processing: _ARM_ and _THUMB_. ARM intsructions are encoded as 32-bit opcodes,
while THUMB instructions are encoded as 16-bit opcodes. Most GBA games generally
used ARM instructions when inside the GBA's 32KB Work RAM, while THUMB is used
everywhere else, especially in memory areas with a 16-bit bus.

[arm7tdmi]: doc/pdf/arm7tdmi/arm7-tdmi-datasheet.pdf
[armv4 architecture]: https://en.wikipedia.org/wiki/ARM_architecture

### Opcodes

#### `ARM`

- ARM opcodes provide a higher level of flexibility.
- ARM instructions are executed conditionally (if certain CPU flags are set).

#### `THUMB`

- It may take multiple THUMB instructions to achieve the same result as ARM.
- THUMB opcodes only have access to a limited number of the CPU’s registers.
- THUMB opcodes always set the CPU’s condition flags (optional for ARM).

### Registers

- 13 General Purpose Registers (R0-R12).
- Stack Pointer (R13).
- Link Register (R14).
- Program Counter (R15).
- Current Program Status Register and a Saved Program Status Register.
- Some of these registers are banked depending on the state of the CPU.
