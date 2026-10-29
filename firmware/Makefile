# firmware/Makefile —— 整车固件顶层构建（手写，不由 CubeMX 维护）
#
# 依赖：
#   arm-none-eabi-gcc 14.2.rel1（本机已装在 "C:\Program Files (x86)\Arm GNU Toolchain arm-none-eabi\14.2 rel1"）
#   GNU make（本机没有，实际在 WSL2 Ubuntu 22.04 里执行）
#   lib/stm32-chesscar-lib 子模块已 init（钉在 533b247）
#
# 状态：骨架已落地；Core/ 与 Drivers/ 由 STM32CubeMX 生成（待办，见 firmware/README.md），
#       所以现在直接 make 会在缺少 Core/Src/main.c 处停下——这是预期行为。
#
# 引脚方案仍待硬件确认：本 Makefile 不固化任何引脚，也不指定复用功能。

TARGET    := chesscar
BUILD_DIR := build
LIB_DIR   := ../lib/stm32-chesscar-lib

# ---- CubeMX 生成的工程源文件（批次 B 落地，名字按 CubeMX 默认生成结果） ----
CUBE_SRC := \
  Core/Src/main.c \
  Core/Src/stm32f1xx_it.c \
  Core/Src/stm32f1xx_hal_msp.c \
  Core/Src/system_stm32f1xx.c \
  Core/Src/syscalls.c \
  Core/Src/sysmem.c \
  Core/Src/gpio.c \
  Core/Src/dma.c \
  Core/Src/tim.c \
  Core/Src/usart.c \
  Core/Src/i2c.c \
  Core/Src/adc.c
# HAL 源文件按 stm32f1xx_hal_conf.h 里实际启用的模块挑选
# （rcc / gpio / dma / cortex / tim / uart / i2c / adc / flash / pwr），
# 全量加入也可以，但必须配 -ffunction-sections 与 -Wl,--gc-sections。

# ---- 手写整车应用层（批次 C） ----
APP_SRC := $(wildcard app/*.c)

# ---- 子模块：common 全部 12 个 + stm32 全部 6 个 + examples 的 2 个 ----
# examples/main_reference.c 不进构建：它是纯注释的接入说明，没有可编译代码。
LIB_SRC := $(wildcard $(LIB_DIR)/common/*.c) \
           $(wildcard $(LIB_DIR)/stm32/*.c) \
           $(LIB_DIR)/examples/app_chesscar.c \
           $(LIB_DIR)/examples/hal_callbacks.c

C_SOURCES   := $(CUBE_SRC) $(APP_SRC) $(LIB_SRC)
ASM_SOURCES := startup_stm32f103xb.s
LDSCRIPT    := STM32F103C8TX_FLASH.ld

PREFIX := arm-none-eabi-
CC     := $(PREFIX)gcc
AS     := $(PREFIX)gcc -x assembler-with-cpp
CP     := $(PREFIX)objcopy
SZ     := $(PREFIX)size
HEX    := $(CP) -O ihex
BIN    := $(CP) -O binary -S

# F103 是 Cortex-M3，没有 FPU：不加 -mfpu，浮点用软件实现
CPU    := -mcpu=cortex-m3 -mthumb
DEFS   := -DUSE_HAL_DRIVER -DSTM32F103xB
INCS   := -ICore/Inc -Iapp -I. \
          -I$(LIB_DIR)/common -I$(LIB_DIR)/stm32 -I$(LIB_DIR)/examples \
          -IDrivers/STM32F1xx_HAL_Driver/Inc \
          -IDrivers/STM32F1xx_HAL_Driver/Inc/Legacy \
          -IDrivers/CMSIS/Device/ST/STM32F1xx/Include \
          -IDrivers/CMSIS/Include

CFLAGS  := $(CPU) $(DEFS) $(INCS) -std=c99 -O2 -g3 -Wall -Wextra \
           -ffunction-sections -fdata-sections -fno-common
ASFLAGS := $(CPU) $(DEFS) -g3
LIBS    := -lc -lm -lnosys
LDFLAGS := $(CPU) -specs=nano.specs -specs=nosys.specs \
           -Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref \
           -Wl,--gc-sections -T$(LDSCRIPT)

# 目标文件按文件名扁平化到 build/obj/：因此工程内不能出现同名 .c。
# 当前文件清单无重名；若将来引入重名，需改成保留目录结构。
C_OBJ   := $(addprefix $(BUILD_DIR)/obj/,$(notdir $(C_SOURCES:.c=.o)))
ASM_OBJ := $(addprefix $(BUILD_DIR)/obj/,$(notdir $(ASM_SOURCES:.s=.o)))

vpath %.c $(sort $(dir $(C_SOURCES)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))

ifeq ($(wildcard Core/Src/main.c),)
$(warning 未找到 Core/Src/main.c：CubeMX 工程骨架还没生成，构建会在缺少源文件处停下来。)
endif

all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin

$(BUILD_DIR)/obj/%.o: %.c
	@mkdir -p $(@D)
	$(CC) -c $(CFLAGS) $< -o $@

$(BUILD_DIR)/obj/%.o: %.s
	@mkdir -p $(@D)
	$(AS) $(ASFLAGS) -c $< -o $@

$(BUILD_DIR)/$(TARGET).elf: $(C_OBJ) $(ASM_OBJ) $(LDSCRIPT)
	$(CC) $(C_OBJ) $(ASM_OBJ) $(LDFLAGS) $(LIBS) -o $@
	$(SZ) $@

%.hex: %.elf
	$(HEX) $< $@

%.bin: %.elf
	$(BIN) $< $@

size: $(BUILD_DIR)/$(TARGET).elf
	$(SZ) $<

# 烧写（草案，待实物验证）：产物名与命令的完整说明见 firmware/README.md。
# 需要本机有 STM32CubeProgrammer CLI；未核实是否已安装。
flash: $(BUILD_DIR)/$(TARGET).hex
	STM32_Programmer_CLI -c port=SWD -w $< -v -rst

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all size flash clean
