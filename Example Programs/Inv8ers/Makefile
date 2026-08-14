SRC_DIR:=src
INCLUDE_DIR:=../../LmaOS.65c02/include

CL65?=$(shell which cl65)
ifeq ($(CL65),)
$(error Install the CC65 suite and include it in your PATH)
endif

all:
	$(CL65) -t none --cpu 65C02 --asm-include-dir $(INCLUDE_DIR) -o MAIN.PRG $(SRC_DIR)/main.asm
