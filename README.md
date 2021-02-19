# LmaOS

LmaOS is a 65C02 system kernal for the n8 Bit Special Computer, a homebrew breadboard computer.

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

## Software Support

LmaOS is a small kernal that provides a system monitor, software support for the ACIA and VIA, interrupts, and some system library utilities.

### Conventions

LmaOS has a few conventions to consider.
First, LmaOS uses 16 bit pseudo-registers for passing data between system subroutines: `r0` through `r7` (see `registers.inc`.)
These registers should be considered volatile and if you use them in your program and call system functions, they could be mutated.

Second, register values at this time should _also_ be considered volatile (with the exception of interrupt handling) so if you care about these values, push them onto the stack or store them elsewhere before calling system routines.
Exactly what is used should be in the documentation for each subroutine.

Lastly, constants are always in an `.inc` file and code and storage is always in an `.asm` file.

### Monitaur

At bootup, LmaOS boots into its monitor, called Monitaur. 
Monitaur provides 4 basic commands: `rd`, `wr`, `tx`, and `ex`.
All numeric values in Monitaur are in hexadecimal (written as `$<number>` throughout this document).

#### Reading memory

The `rd` command allows you to read system memory. You provide an address and optionally, a length.

```
>rd <address> [<length>]
```

By default, if you dont specify a length, it defaults to `$1`.

```
>rd 0400
A9
```

To read blocks of memory, you can provide a length. Length is provided as a byte and so the maximum value you can read is `$100`.  

```
>rd 1000 10
AB 11 FE 6F D9 DB 2D FD 26 F4 82 FE F1 A6 95 8B 
```

Monitaur will print `$10` values per line. Because of how the monitor is written, to read the full `$100` values, you provide the length as `$0`, not `$FF`.

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
You provide an address and a byte to be written.
Values can only be written 1 at a time through this command.

```
>wr 1000 A5
```

There is no feedback if a write fails because you tried to write to an address this read-only (like ROM).
You can follow up your write with a `rd` if you need to know if it succeeded.

#### Transferring data

The `tx` command allows you to transfer data from the connected system to the n8 Bit Special computer.
You provide an address to start writing the data.

```
>tx 0400
Waiting for XModem transfer...
```

When prompted, your connected system can send a file via the XModem Checksum (not CRC) protocol.
When the transfer is completed or canceled, you will be returned to Monitaur.
The `tx` command will write _all_ data sent, including EOF padding (`$1A` from the serial app I use), it makes no attempt to discover the true EOF.

#### Executing programs

The `ex` command executes code starting at the provided address.

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
A fully working interrupt driven was written if you want to comb the commit history but it was way too complicated.
See `acia.inc` and `acia.asm` for more details.

The XModem receive subroutine used by `tx` is provided for program use as well.
See `xmodem.inc` and `xmodem.asm` for more details.

#### Strings

Some C lib like string utilities are provided including: `StringLength`, `StringCompareN`, `StringCompare`, `StringCopy`, `HexStringToWord`, `ByteToHexString`, and `NibbleToHexString`. See `strings.asm` for more details.

## Future Support

Planned improvements the n8 Bit Special Computer include:
* SD card reader
* 2nd VIA for program use
* Connected display(s): 2 line LCD and a [mini-OLED display](https://www.digikey.nl/product-detail/nl/newhaven-display-intl/NHD-1.69-160128UGC3/NHD-1.69-160128UGC3-ND/4756379)
* More RAM, less ROM

Planned improvements for LmaOS include:
* FAT filesystem support
* bootstrapping Monitaur and other system utilities from FAT storage
* 2 line LCD and OLED display routines
* standalone input (keyboard, controller, etc.)
