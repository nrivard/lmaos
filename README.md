# LmaOS

LmaOS is a 65C02 system kernal for the n8 Bit Special Computer, a homebrew breadboard computer.

## Getting Started

To build LmaOS, you will need `make` and the [CC65 suite](https://cc65.github.io) or my unreleased 65C02 IDE for macOS, System On Chip (how did you get this? It's unreleased!)

```bash
$ make
/usr/local/bin/cl65 -t none -C LmaOS.65c02/memorymap.cfg --asm-include-dir LmaOS.65c02/include -l lmaos.rom.listing -vm --mapfile lmaos.rom.map --cpu 65C02 -o ./lmaos.rom  LmaOS.65c02/src/main.asm
```

To install LmaOS on an EEPROM for use in your n8 Bit Special Computer, you will need [minipro](https://gitlab.com/DavidGriffith/minipro) and a TL866II Plus programmer.

```bash
$ make install
minipro -p AT28C256 -w lmaos.rom
Found TL866II+ 04.2.122 (0x27a)
Erasing... 0.02Sec OK
Protect off...OK
Writing Code...  6.78Sec  OK
Reading Code...  0.48Sec  OK
```

## Hardware Support

The n8 Bit Special computer is a homebrew breadboard computer built around a WDC 65C02 8 bit CPU operating at 2Mhz.
This is connected to:

* Atmel AT28C256 for 32K of ROM
* Cypress CY62256NL for 32K of RAM
* WDC 65C22 VIA for system timer and GPIO
* Rockwell 65C51 for RS232 @ 19200 baud, 8.N.1 (8 bit, no parity, 1 stop bit) for serial communication
* GAL22V10 for address decoding and multi-device interrupt handling
* DS1813 for reset circuitry
* FT232 breakout board to connect to an external system via USB

<img src="n8bit.png" alt="n8 bit special computer" width="300"/>

### Memory Layout

<img src="n8bitmemorylayout.png" alt="n8 bit memory layout graph" height="400"/>

The n8 Bit Special computer has the following memory layout:

| Device | Address Range |
|--------|---------------|
| Zero Page | `$0000...$00FF` |
| Stack | `$0100...$01FF` |
| RAM | `$0200...$7EFF` |
| VIA 1 | `$7F00...$7F3F` |
| VIA 2 | `$7F40...$7F7F` |
| ACIA | `$7F80...$7FBF` |
| Display | `$7FC0...$7FFF` |
| ROM | `$8000...$FFFF` |

You will notice that each I/O device gets exactly `$40` addresses, starting at `$7F00`, though your device likely won't need nearly this many. For example, the 1602a based LCD display uses 2 addresses while the VIA uses 16.

### Expansion

Most of the hardware is set for the system: CPU, RAM, ROM, VIA 1 (for interfacing with an SD card interface and possibly keyboard input), ACIA, and some kind of display. At present, the address decoder has carved out another I/O device for a 2nd VIA. This should be considered an additional I/O slot that can be used for whatever you want.

In addition, the address decoder can process interrupts from up to 4 devices. VIA 1 and the ACIA currently use 2 of these, but a 2nd I/O device and your display can also generate interrupts. This will require changing LmaOS to provide a writable vectored interrupt handler, after which it is up to your software to determine how to respond to events from these new devices.

## Software Support

LmaOS is a small kernal that provides a system monitor, software support for the ACIA and VIA, interrupts, and some system library utilities.

### Conventions

LmaOS has a few conventions to consider.
First, LmaOS uses 16 bit pseudo-registers for passing data between system subroutines: `r0` through `r7` (see `registers.inc`.)
These registers should be considered volatile and if you use them in your program and call system functions, they could be mutated.

Second, register values at this time should _also_ be considered volatile (with the exception of interrupt handling) so if you care about these values, push them onto the stack or store them elsewhere before calling system routines.
Exactly what is used should be in the documentation for each subroutine.

Lastly, some programming conventions are:

* constants and volatile storage (`.bss`) are in an `.inc` file
* code and non-volatile storage (`RODATA`) are in an `.asm` file
* Border-line excessive use of local labels in subroutines (prefixed with `@`).
Not all of these local labels are actually used as labels (in the assembler sense) but instead are intended as self-documenting organizational tools.

For example, many routines will have an immediate local label named `@Preamble` on entry to a subroutine and almost all have a `@Done` before `RTS` even when no branches jump to it.
It's not strictly necessary, you could jump to the top-level label if necessary, but I like to organize the code this way.

```asm
RandomSubroutine:
@Preamble:
    PHA
    PHX
@GenerateRandomNumber:
    ...
@Done:
    PLX
    PLA
    RTS
```

### Monitaur

At bootup, LmaOS boots into its monitor, called Monitaur. 
Monitaur provides 4 basic commands: `rd`, `wr`, `tx`, and `ex`.
All numeric values in Monitaur are in hexadecimal (written as `$<number>` throughout this document).
Where noted, a `word` is 16 bits and a `byte` is 8 bits.

In general, Monitaur parses all values as a word but a command may ignore the upper nibble if it expects a byte.
See `monitaur.inc` and `monitaur.asm` for more details.

#### Reading memory

The `rd` command allows you to read system memory. You provide an address (word) and, optionally, a length (byte).

```
>rd 0400
A9
```

By default, if you don't specify a length, it defaults to `$1`.
To read blocks of memory, you can provide a length.

```
>rd 1000 10
AB 11 FE 6F D9 DB 2D FD 26 F4 82 FE F1 A6 95 8B
```
 
Monitaur will print `$10` values per line.
Length is provided as a byte and so the maximum value you can read is `$100`. 
To read the full `$100` values, because of how the monitor is written, you must provide the length as `$0` not `$FF`.

```
>rd 1000 0
AB 11 FE 6F D9 DB 2D FD 26 F4 82 FE F1 A6 95 8B 
25 33 49 6F 8D C0 03 3C EA D7 9F F6 0F CB ED E1 
D3 73 F8 4C C7 BA 7F B7 EB 53 5B 5E DD BC FA C1 
63 B7 E8 8F 29 91 A2 5C 13 1B E7 F7 73 72 73 BE 
B1 91 14 FC DA 5A 9F E7 D7 8F CF 7F 82 6E DB F7 
3F E7 AA 9B 1E A8 61 D9 4B 5D FF 9C 58 B7 74 BA 
7C 3D 26 FE 73 77 9F 1E 9B 5F 70 BE 75 AB 37 A3 
45 E4 B5 28 E0 E3 3D C4 D5 F1 9F 60 8F 9C 7E A3 
EE 9E F9 3E EA DF 27 EF F3 55 C8 E8 6D 1A F7 BE 
DA B3 26 C6 FE EE FD 6F 67 58 A7 79 F5 58 B5 4D 
B5 36 FA A8 66 9D B5 91 FF FA 8B B7 FF BF D3 39 
4F E7 F3 BF 39 BF D7 D0 F5 7F FF 9B E8 6C 93 9C 
2C 5C DE DD DD B3 75 7F 3E DE 7B C8 4F 4F 65 EA 
7F E4 5F 51 BF 70 B1 1B FF FF E6 D2 EA F9 77 BD 
93 EE EE 37 51 0F 8B 9E 8F E4 F9 B7 AF CE B7 BB 
FF 13 BE F9 EF FA FF EE ED 27 67 E0 5F BD 11 83
```

#### Writing memory

The `wr` command allows you to write to system memory (provided it is writeable!)
You provide an address (word) and a value (byte) to be written.

```
>wr 1000 A5
```

Values can only be written 1 at a time through this command.
There is no feedback if a write fails because you tried to write to an address that is read-only (like ROM).
If you need to know if your `wr` succeeded, send a `rd` command with the address and verify the value.

#### Transferring data

The `tx` command allows you to transfer data from the connected system to the n8 Bit Special Computer.
You provide an address (word) to start writing the data.

```
>tx 0400
Waiting for XModem transfer...
```

When prompted, your connected system can send a file via the XModem Checksum (not CRC) protocol.
When the transfer is completed or canceled, you will be returned to Monitaur.
The `tx` command will write _all_ data sent, including EOF padding (`$1A` from the serial app I use), it makes no attempt to discover the true EOF.

#### Executing programs

The `ex` command executes code starting at the provided address (word).

```
>ex 0400
```

`ex` does this by jumping to the provided address as a subroutine (`JSR <address>`).
Your program is expected to know where it will be written (because you likely used `tx` and provided that address!)
When your program is done executing, calling `RTS` will return you to Monitaur.

_Note: You should always start writing your program after address $0400, as there are two `$80` length buffers needed by Monitaur (for command storage) and `tx` (for packet storage) as well as some other bookkeeping when transferring data._

### System utilities

LmaOS provides some system support for the ACIA and the VIA as well as some built-in strings utilities.

#### VIA

The VIA provides system timer support from Timer 1. 
If you want to take advantage of system uptime and jiffies, do not use Timer 1 and do not disable interrupts. 
At this time, GPIO is connected to 2 8-bit LED banks, providing a full 16 bits of information!
In the future, VIA1 will be entirely dedicated to system tasks and a second VIA will be provided for program use.
See `via.inc` and `via.asm` for more details.

#### ACIA

Basic ACIA functions are provided: `ACIAGetByte`, `ACIASendByte`, and `ACIASendString`.
All of these routines are synchronous, meaning they could lock up the system if there is no response from a connected system.
A fully working interrupt driven ACIA implementation was written if you want to comb the commit history but it was way too complicated for realworld use.
See `acia.inc` and `acia.asm` for more details.

The XModem receive subroutine used by `tx` is provided for program use as well: `XModemReceive`.
See `xmodem.inc` and `xmodem.asm` for more details.

#### Strings

Some C lib like string utilities are provided including: `StringLength`, `StringCompareN`, `StringCompare`, `StringCopy`, `HexStringToWord`, `ByteToHexString`, and `NibbleToHexString`. See `strings.asm` for more details.

## Writing Programs

To write programs for the n8 Bit Special Computer (and LmaOS), copy any of the relevant include (`.inc`) files for your use.
Set an origin for your program (I like `$0400`) as there is no built-in relocation scheme yet.
If your program just performs a small task, remember to call `RTS` to return to Monitaur.
If you never need to return to Monitaur, don't worry about it!

_Note: When you transfer your program, the transfer location must match the origin!_

Here's a very simple uploaded program that will write an alternating pattern on the connected 16 bit LED banks (you can see the result of this program in the system photo):

```asm
.org $0400

Main:
    LDA #$AA
    STA VIA1_PORT_A
    STA VIA1_PORT_B
    RTS

.include "via.inc"
```

Then transfer the program using Monitaur and execute it:

```
LmaOS v1.0
Unauthorized access of this N8 Bit Special computer will result in prosecution!
>tx 0400
Waiting for XModem transfer...
Transmission successful.
>ex 0400
>
```

If you need to execute system provided (ROM) subroutines, copy `lmaos.inc` into your project.
This file is not actually used by LmaOS; instead it is just a listing of the addresses of externally available system functionality.

_Note: as of this writing, the addresses listed in`lmaos.inc` are very volatile from version to version. If you update your system ROM to a later version, this listing is likely different and you will have to recopy the include file and reassemble your program(s)._

```asm
.org $0400

Main:
@ClearScreen:
    LDA #(LCD_INSTR_CLEAR)
    JSR LCDSendInstruction
@PrintMsg:
    LDA #<WelcomeMsg
    LDX #>WelcomeMsg
    JSR LCDPrintString
@Done:
    RTS

WelcomeMsg: .asciiz "Welcome to LmaOS!"

.include "lmaos.inc"
```

Now, have fun!

## Future Support

Planned improvements for the n8 Bit Special Computer include:

* SD card reader
* Expansion slot for 1 additinal I/O card (`VIA2_CS` signal from the address decoder)
* Connected display: 1602a LCD or a [mini-OLED display](https://www.digikey.nl/product-detail/nl/newhaven-display-intl/NHD-1.69-160128UGC3/NHD-1.69-160128UGC3-ND/4756379)
* More RAM, less ROM

Planned improvements for LmaOS include:

* FAT filesystem support
* bootstrapping Monitaur and other system utilities from FAT storage
* 2 line LCD and OLED display routines
* standalone input (keyboard, controller, etc.)
