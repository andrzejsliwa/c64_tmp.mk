DISK_NAME ?= $(notdir $(shell pwd))
DISK_NEW  ?= false
DISK_DIR  ?= disks
DISK ?= $(DISK_DIR)/$(DISK_NAME).d64

BINARY_DIR = bin

VICE_OPTS     ?=
VICE_EXE      ?= x64sc
VICE_PATH     ?= /usr/local/bin/$(VICE_EXE)
DEBUGGER_PATH ?= /Applications/C64\ Debugger.app/Contents/MacOS/C64Debugger
DEBUGGER_OPTS ?= -pass -unpause -autojmp -wait 250

ASSEMBLER = $(BINARY_DIR)/tmpx
CONVERTER = $(BINARY_DIR)/petcom
EXTENSION_BASIC    ?=.bas
EXTENSION_ASSEMBLY ?=.a
EXTENSION_INCLUDES ?=.i
EXTENSION_PROGRAM  ?=.prg
EXTENSION_DEASM    ?=.deasm

ifdef V
	OUTPUT_OPTIONS=
else
	OUTPUT_OPTIONS= 2>&1 > /dev/null
endif

ifdef VICE_REMOTE_MONITOR
	ifeq ($(VICE_REMOTE_MONITOR),true)
		VICE_OPTS += -remotemonitor -remotemonitoraddress localhost:6510
	endif
endif

ifdef VICE_REU
VICE_REU_FILE ?= .reuimage
VICE_REU_SIZE ?= 16384
	ifeq ($(VICE_REU),true)
		VICE_OPTS += -reu -reusize $(VICE_REU_SIZE) -reuimage $(VICE_REU_FILE) -reuimagerw
	endif
endif

ifdef VICE_CARTRR
	VICE_OPTS += -cartrr $(VICE_CARTRR)
endif

SOURCE_DIR = src
LIB_DIR    = lib
BUILD_DIR  = build
BACKUP_DIR = backup

ASM_FILES = $(wildcard $(SOURCE_DIR)/*$(EXTENSION_ASSEMBLY))
ASM_INCS  = $(wildcard $(SOURCE_DIR)/*$(EXTENSION_INCLUDES))
ASM_PRGS  = $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_FILES:$(EXTENSION_ASSEMBLY)=$(EXTENSION_PROGRAM))))
ASM_SOURCES  = $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_FILES:$(EXTENSION_ASSEMBLY)=$(EXTENSION_ASSEMBLY))))
ASM_INCLUDES = $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_INCS:$(EXTENSION_INCLUDES)=$(EXTENSION_INCLUDES))))

BAS_FILES = $(wildcard $(SOURCE_DIR)/*$(EXTENSION_BASIC))
BAS_PRGS  = $(addprefix $(BUILD_DIR)/,$(notdir $(BAS_FILES:$(EXTENSION_BASIC)=$(EXTENSION_PROGRAM))))

all:
	make start $(DEFAULT_PRG)

.PHONY : disk start debug run_retro

start: disk_backup clean compile convert disk run_vice ## build and start emulator (optionally with name of program)

debug: disk_backup clean compile convert ## build and run in debugger (optionally with name of program)
	make run_debug $(DEFAULT_PRG)

$(DISK_DIR):
	mkdir -p $(DISK_DIR)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%$(EXTENSION_PROGRAM): $(SOURCE_DIR)/%$(EXTENSION_ASSEMBLY)
	$(ASSEMBLER) \
		-i $< \
		-o $@ \
		-l $@$(EXTENSION_DEASM) $(OUTPUT_OPTIONS)

$(BUILD_DIR)/%$(EXTENSION_ASSEMBLY): $(SOURCE_DIR)/%$(EXTENSION_ASSEMBLY)
	$(CONVERTER) - $< > $@

$(BUILD_DIR)/%$(EXTENSION_INCLUDES): $(SOURCE_DIR)/%$(EXTENSION_INCLUDES)
	$(CONVERTER) - $< > $@

$(BUILD_DIR)/%$(EXTENSION_PROGRAM): $(SOURCE_DIR)/%$(EXTENSION_BASIC)
	petcat -w2 -o $@ -- $<

clean: ## clean build directory
	rm -r $(BUILD_DIR) || true

$(BACKUP_DIR):
	mkdir -p $(BACKUP_DIR)

disk_backup: $(BACKUP_DIR)
ifeq ($(DISK_NEW),true)
	mv $(DISK) $(BACKUP_DIR)/$(DISK_NAME)_$(shell date '+%Y%m%d%H%M%S').d64 || true
endif

disk_prepare:
	$(BINARY_DIR)/cc1541 -n $(DISK_NAME) $(DISK) $(OUTPUT_OPTIONS)

$(DISK): disk_prepare

define write_file_on_disk
	$(BINARY_DIR)/cc1541 -n $(DISK_NAME) -f "$(patsubst build/%.prg,%,$(2))" -w $(2) -T PRG $(1) $(OUTPUT_OPTIONS)
endef

define write_seq_file_on_disk
	$(BINARY_DIR)/cc1541 -n $(DISK_NAME) -f "$(patsubst build/%.prg,%,$(2))" -w $(2) -T SEQ $(1) $(OUTPUT_OPTIONS)
endef

compile: $(BUILD_DIR) $(ASM_PRGS) ## compile ASSEMBLER source files (src/*.a)

convert_basic: $(BUILD_DIR) $(BAS_PRGS) ## convert BASIC source files (src/*.bas)

convert_asm: $(BUILD_DIR) $(ASM_SOURCES) $(ASM_INCLUDES) ## convert ASSEMBLER source files (build/*.a,*.i)

convert: convert_asm convert_basic

ifeq ($(DISK_NEW),false)
new_disk: disk_prepare
endif

ifeq ($(DISK_NEW),true)
disk: disk_prepare compile convert
else
disk: compile convert
endif
	@$(foreach prg,$(ASM_PRGS),$(call write_file_on_disk,$(DISK),$(prg));)
	@$(foreach asm,$(ASM_SOURCES),$(call write_seq_file_on_disk,$(DISK),$(asm));)
	@$(foreach inc,$(ASM_INCLUDES),$(call write_seq_file_on_disk,$(DISK),$(inc));)
	@$(foreach prg,$(BAS_PRGS),$(call write_file_on_disk,$(DISK),$(prg));)

ifeq (start,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "start"
  START_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn argument to starting config
  ifneq ($(START_ARGS),)
	APP_NAME  := $(firstword $(START_ARGS))
	START_APP := $(DISK):$(APP_NAME)
  endif

  $(eval $(START_ARGS):;@:)
endif

ifeq (run_debug,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "debug"
  DEBUG_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn argument to starting config
  ifneq ($(DEBUG_ARGS),)
	APP_NAME  := $(firstword $(DEBUG_ARGS))
  endif

  $(eval $(DEBUG_ARGS):;@:)
endif

run_vice:
	killall $(VICE_EXE) >/dev/null 2>&1 || true
	$(VICE_PATH) $(VICE_OPTS) \
	-8 $(DISK) $(START_APP) $(OUTPUT_OPTIONS) &

run_retro:
	$(DEBUGGER_PATH) -cartrr rr38p-tmp12reu.bin

run_debug:
	$(DEBUGGER_PATH) \
		-prg $(BUILD_DIR)/$(APP_NAME)$(EXTENSION_PROGRAM) \
		$(DEBUGGER_OPTS) $(OUTPUT_OPTIONS)

define print_help
	grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(1) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36mmake %-20s\033[0m%s\n", $$1, $$2}'
endef

help:
	@printf "\033[36mHelp: \033[0m\n"
	@$(foreach file, $(MAKEFILE_LIST), $(call print_help, $(file));)

$(V).SILENT: