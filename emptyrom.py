rom = bytearray([0xEA] * 32768)

with open("empty.rom", "wb") as outFile:
	outFile.write(rom);
