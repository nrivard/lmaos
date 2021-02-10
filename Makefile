PROJECT_DIR:=LmaOS.65c02
INCLUDE_DIR:=$(PROJECT_DIR)/include
SRC_DIR:=$(PROJECT_DIR)/src

CA65?=$(shell which ca65)
ifeq ($(CA65),)
$(error Install the CC65 suite and include it in your PATH)
endif

LD65?=$(shell which cl65)
ifeq ($(LD65),)
$(error Install the CC65 suite and include it in your PATH)
endif

ROM_SRCS+=$(wildcard $(SRC_DIR)/*.asm)
OBJECTS:=$(patsubst %.asm,%.o,$(filter %.asm,$(ROM_SRCS)))
INC_FILES:=$(filter %.inc,$(ROM_SRCS))

LINK_CONFIG:=$(PROJECT_DIR)/memorymap.cfg
ROM_BIN:=main.bin
CLEAN_FILES+=$(ROM_BIN)

CL65_FLAGS=-C $(LINK_CONFIG) --asm-include-dir $(INCLUDE_DIR) -vm --mapfile $(ROM_BIN).map -l listing.txt
CA65_FLAGS=-I $(INCLUDE_DIR) --cpu 65C02
LD65_FLAGS=-C $(LINK_CONFIG)

CLEAN_FILES:=$(OBJECTS) $(ROM_BIN) $(ROM_BIN).map

.PHONY: all
all: $(ROM_BIN)

.PHONY: clean
clean:
	rm -f $(CLEAN_FILES)

.PHONY: install
install:
	minipro -p AT28C256 -w $(ROM_BIN)

$(ROM_BIN): $(OBJECTS) $(LINK_CONFIG)
	$(LD65) $(LD65_FLAGS) -o "$@" $(OBJECTS)

$(SRC_DIR)/%.o: $(SRC_DIR)/%.asm $(INC_FILES) $(LINK_CONFIG)
	$(CA65) $(CA65_FLAGS) -o "$@" "$<"
