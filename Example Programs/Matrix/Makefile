SRC_DIR:=src
INCLUDE_DIR:=../../LmaOS.65c02/include
LINK_CONFIG:=memorymap.cfg

CL65?=$(shell which cl65)
ifeq ($(CL65),)
$(error Install the CC65 suite and include it in your PATH)
endif

all:
	$(CL65) -t none --cpu 65C02 --asm-include-dir $(INCLUDE_DIR) -C $(LINK_CONFIG) --mapfile main.map -o MAIN.PRG $(SRC_DIR)/main.asm
