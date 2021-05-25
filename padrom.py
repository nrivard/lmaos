import os
import sys

if len(sys.argv) != 2:
	print("You must provide a rom filename")
	sys.exit()


rom = sys.argv[1]
res = os.stat(rom)

if res.st_size != 0x4000:
	print("File must be 16k to be padded")
	sys.exit()

zeroes = bytearray([0] * 0x4000)

with open(rom, "rb") as romFile:
	romData = romFile.read()


with open(rom, "wb") as romFile:
	romFile.write(zeroes)
	romFile.write(romData)
