BASEROM = baserom.z64
TARGET = pokestadium
NON_MATCHING = 0

# Fail early if baserom does not exist
ifeq ($(wildcard $(BASEROM)),)
$(error Baserom `$(BASEROM)' not found.)
endif

BUILD_DIR := build
ROM := $(TARGET).z64
ELF := $(BUILD_DIR)/$(TARGET).elf
LD_SCRIPT := $(TARGET).ld
LD_MAP := $(BUILD_DIR)/$(TARGET).map
ASM_DIRS := asm asm/os asm/libleo asm/libultra asm/libultra/os asm/libultra/io asm/libultra/gu asm/libultra/libc asm/libultra/al
DATA_DIRS := bin assets
SRC_DIRS := $(shell find src -type d)

C_FILES := $(foreach dir,$(SRC_DIRS),$(wildcard $(dir)/*.c))
S_FILES := $(foreach dir,$(ASM_DIRS),$(wildcard $(dir)/*.s))
DATA_FILES := $(foreach dir,$(DATA_DIRS),$(wildcard $(dir)/*.bin))

# Object files
O_FILES := $(foreach file,$(C_FILES),$(BUILD_DIR)/$(file:.c=.c.o)) \
           $(foreach file,$(S_FILES),$(BUILD_DIR)/$(file:.s=.s.o)) \
           $(foreach file,$(DATA_FILES),$(BUILD_DIR)/$(file:.bin=.bin.o)) \

SPLAT_YAML := splat.yaml
SPLAT = $(PYTHON) tools/n64splat/split.py $(SPLAT_YAML)

##################### Compiler Options #######################
CROSS = mips-linux-gnu-
AS = $(CROSS)as
LD = $(CROSS)ld
OBJDUMP = $(CROSS)objdump
OBJCOPY = $(CROSS)objcopy
CPP := cpp

#CC         := $(QEMU_IRIX) -L tools/ido7.1_compiler tools/ido7.1_compiler/usr/bin/cc
#CC_OLD     := $(QEMU_IRIX) -L tools/ido5.3_compiler tools/ido5.3_compiler/usr/bin/cc

CC = tools/ido_recomp/linux/7.1/cc
CC_OLD = tools/ido_recomp/linux/5.3/cc

ASFLAGS = -EB -mtune=vr4300 -march=vr4300 -Iinclude

# we support Microsoft extensions such as anonymous structs, which the compiler does support but warns for their usage. Surpress the warnings with -woff.
CFLAGS  = -G 0 -non_shared -Xfullwarn -Xcpluscomm -Iinclude -Wab,-r4300_mul -D _LANGUAGE_C -woff 649,838,712

LDFLAGS = -T undefined_syms.txt -T undefined_syms_auto.txt -T undefined_funcs_auto.txt -T $(BUILD_DIR)/$(LD_SCRIPT) -Map $(BUILD_DIR)/$(TARGET).map --no-check-sections

OPTFLAGS := -O2

######################## Targets #############################

$(foreach dir,$(SRC_DIRS) $(ASM_DIRS) $(DATA_DIRS) $(COMPRESSED_DIRS) $(MAP_DIRS) $(BGM_DIRS),$(shell mkdir -p build/$(dir)))

# Libultra O1 files
build/src/libultra/os/osSendMesg.c.o: OPTFLAGS := -O1
build/src/libultra/os/osStopThread.c.o: OPTFLAGS := -O1
build/src/libultra/os/osRecvMesg.c.o: OPTFLAGS := -O1
build/src/libultra/io/pigetcmdq.c.o: OPTFLAGS := -O1

default: all

LD_SCRIPT = $(TARGET).ld

all: $(BUILD_DIR) $(BUILD_DIR)/$(ROM) verify

clean:
	rm -rf asm bin assets $(BUILD_DIR) undefined_syms_auto.txt undefined_funcs_auto.txt

submodules:
	git submodule update --init --recursive

split:
	rm -rf $(DATA_DIRS) $(ASM_DIRS) && ./tools/n64splat/split.py $(SPLAT_YAML)

setup: clean submodules split
	
$(BUILD_DIR):
	echo $(C_FILES)
	mkdir $(BUILD_DIR)

$(BUILD_DIR)/$(LD_SCRIPT): $(LD_SCRIPT)
	@mkdir -p $(shell dirname $@)
	$(CPP) -P -DBUILD_DIR=$(BUILD_DIR) -o $@ $<

$(BUILD_DIR)/$(TARGET).bin: $(BUILD_DIR)/$(TARGET).elf
	$(OBJCOPY) $< $@ -O binary

$(BUILD_DIR)/$(TARGET).elf: $(O_FILES) $(BUILD_DIR)/$(LD_SCRIPT)
	@$(LD) $(LDFLAGS) -o $@

$(BUILD_DIR)/%.c.o: %.c
	$(CC) -c $(CFLAGS) $(OPTFLAGS) -o $@ $^

$(BUILD_DIR)/%.s.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

$(BUILD_DIR)/%.bin.o: %.bin
	$(LD) -r -b binary -o $@ $<

# final z64 updates checksum
$(BUILD_DIR)/$(ROM): $(BUILD_DIR)/$(TARGET).bin
	@cp $< $@

verify: $(BUILD_DIR)/$(ROM)
	md5sum -c checksum.md5

.PHONY: all clean default split setup

print-% : ; $(info $* is a $(flavor $*) variable set to [$($*)]) @true
