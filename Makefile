PROJECT_DIR:=LmaOS.65c02
INCLUDE_DIR:=$(PROJECT_DIR)/include
SRC_DIR:=$(PROJECT_DIR)/src

CL65?=$(shell which cl65)
ifeq ($(CL65),)
$(error Install the CC65 suite and include it in your PATH)
endif

ROM_SRCS+=$(wildcard $(SRC_DIR)/*.asm)
OBJECTS:=$(patsubst %.asm,%.o,$(filter %.asm,$(ROM_SRCS)))
INC_FILES:=$(filter %.inc,$(ROM_SRCS))

LINK_CONFIG:=$(PROJECT_DIR)/memorymap.cfg
ROM_BIN:=lmaos.rom
MAP_FILE:=$(ROM_BIN).map
LISTING_FILE:=$(ROM_BIN).listing
CLEAN_FILES=$(ROM_BIN) $(OBJECTS) $(LISTING_FILE) $(ROM_BIN).map

CL65_FLAGS=-t none -C $(LINK_CONFIG) --asm-include-dir $(INCLUDE_DIR) -l $(LISTING_FILE) -vm --mapfile $(MAP_FILE) --cpu 65C02 -o ./$(ROM_BIN) 

.PHONY: all
all:
	$(CL65) $(CL65_FLAGS) $(SRC_DIR)/main.asm

.PHONY: clean
clean:
	rm -f $(CLEAN_FILES)

.PHONY: install
install:
	minipro -p AT28C256 -w $(ROM_BIN)
