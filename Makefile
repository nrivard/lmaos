PROJECT_DIR:=LmaOS.65c02
INCLUDE_DIR:=$(PROJECT_DIR)/include
SRC_DIR:=$(PROJECT_DIR)/src

CL65?=$(shell which cl65)
ifeq ($(CL65),)
$(error Install the CC65 suite and include it in your PATH)
endif

PYTHON?=$(shell which python3)	# you may have to rename this to just `python` if your default system Python is v3
ifeq ($(PYTHON),)
$(error Install Python3 and include it in your PATH)
endif

ROM_SRCS+=$(wildcard $(SRC_DIR)/*.asm)
OBJECTS:=$(patsubst %.asm,%.o,$(filter %.asm,$(ROM_SRCS)))
INC_FILES:=$(filter %.inc,$(ROM_SRCS))

LINK_CONFIG:=$(PROJECT_DIR)/memorymap.cfg
ROM_BIN:=lmaos.rom
MAP_FILE:=$(ROM_BIN).map
LISTING_FILE:=$(ROM_BIN).listing
GENERATED_INCLUDE_FILE:=$(INCLUDE_DIR)/lmaos.inc
CLEAN_FILES=$(ROM_BIN) $(OBJECTS) $(LISTING_FILE) $(ROM_BIN).map

CL65_FLAGS=-t none -C $(LINK_CONFIG) --asm-include-dir $(INCLUDE_DIR) -l $(LISTING_FILE) -vm --mapfile $(MAP_FILE) --cpu 65C02 -o ./$(ROM_BIN) 

.PHONY: all
all:
	$(CL65) $(CL65_FLAGS) $(SRC_DIR)/main.asm
	$(PYTHON) Scripts/generate_lmaos_inc.py $(MAP_FILE) $(GENERATED_INCLUDE_FILE)

.PHONY: clean
clean:
	rm -f $(CLEAN_FILES)

.PHONY: pad
pad:
	$(PYTHON) Scripts/padrom.py $(ROM_BIN)

.PHONY: install
install: pad
	minipro -p AT28C256 -w $(ROM_BIN)
