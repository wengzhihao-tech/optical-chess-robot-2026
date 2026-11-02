# firmware/Makefile —— 整车固件顶层构建（手写，不由 CubeMX 维护）
#
# 依赖：
#   arm-none-eabi-gcc + GNU make（Windows 侧没有 make，实际在 WSL / Linux 里跑）
#   lib/stm32-chesscar-lib 子模块已 init（钉在 533b247）
#   Drivers/ 下的 STM32F1 HAL 与 CMSIS 源码（来自 ST 官方拆分仓库，见 README）
#
# 工具链不在 PATH 时用 ARM_BIN 指定目录（结尾带分隔符）：
#   make ARM_BIN='/opt/arm-none-eabi/bin/'
#
# 状态（2026-10-29）：本源文件集合已用 Arm GNU Toolchain 14.2.rel1 逐个编译并链接通过
#（85 个 .c + 启动文件，0 error / 0 warning）。构建与烧写记录见 README.md 的
#“构建与烧写记录（2026-10-29）”一节。
# 但 Core/ 目前只是最小 bring-up 骶架：不配置任何引脚与参数，
# 因此产物只能验证“编译 + 链接”，不能上板运行。引脚方案仍待硬件确认。

TARGET    := chesscar
BUILD_DIR := build
LIB_DIR   := ../lib/stm32-chesscar-lib

# ---- 工具链（允许用 ARM_BIN 换目录；路径可能带空格，所以加引号） ----
ARM_BIN ?=
PREFIX  := $(ARM_BIN)arm-none-eabi-
CC      := "$(PREFIX)gcc"
AS      := $(CC) -x assembler-with-cpp
CP      := "$(PREFIX)objcopy"
SZ      := "$(PREFIX)size"

# ---- CubeMX 生成的 Core（当前是最小 bring-up 骶架，批次 B 整体替换） ----
CORE_SRC := $(wildcard Core/Src/*.c)

# ---- STM32F1 HAL 与 CMSIS ----
CMSIS_SRC := Drivers/CMSIS/Device/ST/STM32F1xx/Source/Templates/system_stm32f1xx.c
# 注意：HAL 的 Src/ 里有 3 个 *_template.c（msp / timebase_tim / timebase_rtc_alarm），
# 它们是给用户拄的模板而不是库源文件；一起编会与 Core 里的 HAL_MspInit、HAL_InitTick、
# HAL_TIM_PeriodElapsedCallback、TIM2_IRQHandler 等重复定义，必须排除。
HAL_SRC   := $(filter-out %_template.c,$(wildcard Drivers/STM32F1xx_HAL_Driver/Src/*.c))
# 其余 HAL 源文件全量加入（不在 hal_conf 里使能的模块会被 #if 编空），
# 配 -ffunction-sections 与 -Wl,--gc-sections 不会把没用到的代码带进镜像。

# ---- 手写整车应用层（批次 C，目前只有 app/.gitkeep） ----
APP_SRC := $(wildcard app/*.c)

# ---- 子模块：common + stm32 + examples 里的两个可编译文件（共 20 个 .c） ----
# examples/main_reference.c 不进构建：它是纯注释的接入说明，没有可编译代码。
LIB_SRC := $(wildcard $(LIB_DIR)/common/*.c) \
           $(wildcard $(LIB_DIR)/stm32/*.c) \
           $(LIB_DIR)/examples/app_chesscar.c \
           $(LIB_DIR)/examples/hal_callbacks.c

C_SOURCES   := $(CORE_SRC) $(CMSIS_SRC) $(HAL_SRC) $(APP_SRC) $(LIB_SRC)
ASM_SOURCES := startup_stm32f103xb.s
LDSCRIPT    := STM32F103C8TX_FLASH.ld

# F103 是 Cortex-M3，没有 FPU：不加 -mfpu，浮点走软件实现（见子库 main_reference.c）
CPU    := -mcpu=cortex-m3 -mthumb
DEFS   := -DUSE_HAL_DRIVER -DSTM32F103xB
INCS   := -ICore/Inc -Iapp -I. \
          -I$(LIB_DIR)/common -I$(LIB_DIR)/stm32 -I$(LIB_DIR)/examples \
          -IDrivers/STM32F1xx_HAL_Driver/Inc \
          -IDrivers/STM32F1xx_HAL_Driver/Inc/Legacy \
          -IDrivers/CMSIS/Device/ST/STM32F1xx/Include \
          -IDrivers/CMSIS/Include

# -Wno-unused-parameter：HAL 大量未用参数回调，不加会淹没真正的告警
CFLAGS  := $(CPU) $(DEFS) $(INCS) -std=c99 -O2 -g3 -Wall -Wextra -Wno-unused-parameter \
           -ffunction-sections -fdata-sections -fno-common
ASFLAGS := $(CPU) $(DEFS) -g3
LIBS    := -lc -lm -lnosys
LDFLAGS := $(CPU) -specs=nano.specs -specs=nosys.specs \
           -Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref \
           -Wl,--gc-sections -T$(LDSCRIPT)

# 目标文件按文件名扁平化到 build/obj/：因此工程内不能出现同名 .c。
# 下面这个检查会在有重名时报错，而不是静默丢文件。
C_OBJ   := $(addprefix $(BUILD_DIR)/obj/,$(notdir $(C_SOURCES:.c=.o)))
ASM_OBJ := $(addprefix $(BUILD_DIR)/obj/,$(notdir $(ASM_SOURCES:.s=.o)))

ifneq ($(words $(C_SOURCES)),$(words $(sort $(notdir $(C_SOURCES)))))
$(error 源文件存在同名文件，扁平化的对象名会互相覆盖：$(sort $(notdir $(C_SOURCES))))
endif

vpath %.c $(sort $(dir $(C_SOURCES)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))

ifeq ($(wildcard Core/Src/main.c),)
$(warning 未找到 Core/Src/main.c：CubeMX 工程骶架还没生成，构建会在缺少源文件处停下来。)
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
	$(CP) -O ihex $< $@

%.bin: %.elf
	$(CP) -O binary -S $< $@

size: $(BUILD_DIR)/$(TARGET).elf
	$(SZ) $<

# 烧写（草案，待实物验证）：需要本机有可用的编程器与探针，
# 具体命令与产物名见 firmware/README.md。当前实机没有接入 ST-Link / J-Link，
# 2026-10-29 的实测枚举结果见 README 的构建与烧写记录。
flash: $(BUILD_DIR)/$(TARGET).hex
	STM32_Programmer_CLI -c port=SWD -w $< -v -rst

clean:
	rm -rf $(BUILD_DIR)

# 打印实际参与构建的源文件数，便于核对清单
info:
	@echo "CORE=$(words $(CORE_SRC)) HAL=$(words $(HAL_SRC)) APP=$(words $(APP_SRC)) LIB=$(words $(LIB_SRC)) TOTAL=$(words $(C_SOURCES))"

.PHONY: all size flash clean info
