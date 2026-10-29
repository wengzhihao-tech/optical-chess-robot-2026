# firmware/ —— 整车固件工程（STM32F103C8T6）

本目录是光电象棋机器人的整车固件层：STM32 应用层、构建入口、启动文件与链接脚本。
算法层与 HAL 适配层不在这里实现，而是通过子模块 `lib/stm32-chesscar-lib` 引用
（父仓库协作约定：驱动与算法改动走子库，本仓库只做应用层与集成）。

## 当前状态（2026-10-29）

- 已落地：顶层 `Makefile`、`startup_stm32f103xb.s`、`STM32F103C8TX_FLASH.ld`、本说明。
- 未落地：`chesscar.ioc` 与 CubeMX 生成的 `Core/`、`Drivers/`，所以现在还不能完整构建。
- **引脚方案仍待硬件确认**：本目录不固化任何引脚定义，也没有修改子库
  `stm32/bsp_config.h` 的通道宏。TIM1 两路 PWM 的引脚、两个编码器定时器的
  重映射、ADC1 八路通道与探头 OUT1~OUT8 的对应关系、I2C1 与 USART1 的引脚
  取舍，都需要上板核对后再定（详见 `docs/` 中待补的引脚表）。
- 硬件层尚未在实物 STM32 上验证（子库 README 的既有结论），因此本文的烧写
  与验证部分一律是**草案**，不是已验证事实。

## 目录与文件清单

```
firmware/
├── README.md                       # 本文件（手写）
├── Makefile                        # 顶层构建（手写，不由 CubeMX 维护）
├── startup_stm32f103xb.s           # 启动与中断向量表（手写，ST GCC 模板的等价版本）
├── STM32F103C8TX_FLASH.ld          # 链接脚本（手写，ST GCC 模板的等价版本）
├── chesscar.ioc                    # CubeMX 工程定义（待生成）
├── Core/
│   ├── Inc/                        # CubeMX 生成（main.h / stm32f1xx_hal_conf.h / stm32f1xx_it.h）
│   └── Src/                        # CubeMX 生成（main.c、中断入口、MSP、外设初始化分离件）
├── Drivers/
│   ├── CMSIS/                      # CubeMX 生成（复制必要库文件）
│   └── STM32F1xx_HAL_Driver/       # CubeMX 生成（复制必要库文件）
└── app/                            # 手写整车应用层（暂为空占位，见 app/.gitkeep）
```

逐项说明：

| 路径 | 作用 | 来源 | 现在有无 |
|---|---|---|---|
| `Makefile` | 编译参数、源文件收集、包含路径、链接、elf/hex/bin/map 产物规则 | 手写 | 已有 |
| `startup_stm32f103xb.s` | 中断向量表、Reset_Handler、堆栈初值 | 手写（ST GCC 模板等价版本） | 已有 |
| `STM32F103C8TX_FLASH.ld` | 内存布局与段分配，栈 1 KB、堆 512 B | 手写（ST GCC 模板等价版本） | 已有 |
| `chesscar.ioc` | CubeMX 工程配置（芯片/时钟/外设/DMA/NVIC/生成开关） | CubeMX | 待生成 |
| `Core/Src/main.c` | 时钟与 `MX_xxx_Init()`，只在 USER CODE 区补 `App_Init()` / `App_Loop()` | CubeMX | 待生成 |
| `Core/Src/{tim,usart,i2c,adc,dma,gpio}.c` | 各外设初始化（需在 CubeMX 里打开“生成外设初始化的 .c/.h 分离”） | CubeMX | 待生成 |
| `Core/Src/stm32f1xx_it.c` | 中断入口，需勾选 Generate IRQ handler + Call HAL handler | CubeMX | 待生成 |
| `Core/Src/stm32f1xx_hal_msp.c` | 时钟与引脚低层初始化 | CubeMX | 待生成 |
| `Drivers/CMSIS`、`Drivers/STM32F1xx_HAL_Driver` | HAL 与 CMSIS 源码 | CubeMX（复制必要库文件） | 待生成 |
| `app/` | 整车主入口与赛题任务调度 | 手写 | 空占位 |
| `lib/stm32-chesscar-lib/common/*.c`（12 个） | 平台无关算法层 | 子模块，**不复制**，按路径进构建 | 已钉 533b247 |
| `lib/stm32-chesscar-lib/stm32/*.c`（6 个） | HAL 适配层 | 子模块，不复制 | 已在 |
| `lib/stm32-chesscar-lib/examples/app_chesscar.c`、`hal_callbacks.c` | 参考应用与回调挂接点 | 子模块，进构建 | 已在 |
| `lib/stm32-chesscar-lib/examples/main_reference.c` | 接入说明（纯注释） | 子模块，**不进构建** | 已在 |
| `lib/stm32-chesscar-lib/test/` | PC 端自测 | 子模块，不进固件构建 | 已在 |

`build/` 与 `*.elf` / `*.hex` / `*.bin` / `*.map` 已被仓库根 `.gitignore` 排除，
产物不入库（与根 README 的「构建产物不入库」一致）。

## 依赖

- `arm-none-eabi-gcc`（本机已装 14.2.rel1）+ GNU make：本机没有 make，实际在 WSL2 Ubuntu 22.04 里执行。
- 子模块已初始化：`git submodule update --init --recursive`（当前钉在 `533b247`）。
- 网络：clone 需要代理，本机示例用 `-c http.proxy=http://127.0.0.1:7892`。

## 构建

先确认算法层没被带动：

```bash
cd lib/stm32-chesscar-lib/test && make run    # 期望 14 个编译单元零警告、160 项断言全过
cd ../../../firmware
```

再构建固件（需要先由 CubeMX 生成 `Core/` 与 `Drivers/`，否则会报缺 `Core/Src/main.c`）：

```bash
make -j"$(nproc)"     # 产出 build/chesscar.elf / .hex / .bin / .map
make size             # 看 Flash / RAM 占用
make clean
```

Windows 侧直接构建需要 `make` 或 Ninja 生成器；本机未核实是否有 Ninja，所以当前
确定可用的路径是 WSL。CMakeLists 作为 Makefile 的备选尚未落地。

链接时会看到两类预期内的告警：

- `_close / _lseek / _read / _write is not implemented`：由 `-specs=nosys.specs` 引起，
  工程里加入 `Core/Src/syscalls.c` 后消失。
- `has a LOAD segment with RWX permissions`：新版 binutils 对 STM32 常规内存布局的提示，
  不影响运行，可用 `-Wl,--no-warn-rwx-segments` 抑制。

两条都已在最小测试宿主上复现确认。

## 产物名

| 产物 | 路径 | 说明 |
|---|---|---|
| `chesscar.elf` | `firmware/build/chesscar.elf` | 带调试信息，GDB/OpenOCD 烧写与调试用 |
| `chesscar.hex` | `firmware/build/chesscar.hex` | Intel HEX，GUI 工具与命令行首选 |
| `chesscar.bin` | `firmware/build/chesscar.bin` | 裸二进制，需显式指定起始地址 `0x08000000` |
| `chesscar.map` | `firmware/build/chesscar.map` | 链接映射，复核栈/堆与 `--gc-sections` 效果 |

## 烧写（草案，待实物验证）

> 本节是待验证草案：库 README 明确写着硬件层尚未在实物 STM32 上验证，
> 子库内也没有任何烧写命令或产物名约定，以下命令与产物名尚未在实机上跑过。

```bash
# 路线 1：ST-Link + STM32CubeProgrammer CLI（推断：本机是否已安装未核实）
STM32_Programmer_CLI -c port=SWD -w build/chesscar.hex -v -rst

# 路线 2：OpenOCD + ST-Link
openocd -f interface/stlink.cfg -f target/stm32f1x.cfg \
        -c "program build/chesscar.elf verify reset exit"

# 路线 3：J-Link（本机已装 J-Link V698e / V870 / V888）
JLinkExe -device STM32F103C8 -if SWD -speed 4000 -autoconnect 1
#   命令模式下：loadfile build/chesscar.hex   →   r   →   go   →   qc
```

Keil uVision（本机已装 5.43.1.0 + ARM Compiler 5.06）走自己的工程与 Download 按钮，
与上述 Makefile 路线二选一，不要混用同一份 `firmware/`。

## 下载后如何验证（草案）

1. **烧写完整性**：`STM32_Programmer_CLI` 的 `-v` 校验或 OpenOCD 的 `verify`。
2. **时钟与节拍**：OLED 应在 100 ms 节拍刷新，显示模式、探头掩码、偏差、左右速度；黑屏先看 `OLED_GetErrorCount()`。
3. **链路**：115200 8N1 发协议帧，读 `UartLink_GetValidFrameCount()` / `GetCrcErrorCount()` / `GetOverrunCount()`。
4. **探头（子库点名的实物验证项）**：串口打印 8 路原始 ADC 值（0~4095），逐路确认 Rank 与探头 OUT1~OUT8 的对应关系，并确认 `ADC_LineSensor_GetRaw()` 在首次扫描后返回 true。
5. **编码器方向**：架空正转，两侧计数应为正；为负只改 `ENCODER_LEFT_DIRECTION_SIGN` / `ENCODER_RIGHT_DIRECTION_SIGN`，不动算法。
6. **运动与斜坡**：加减速度、角速度变化率、低速下限、换向保持拍数四个物理值需上车实测。

## 后续批次（待确认后执行）

- 批次 B：用 STM32CubeMX 生成 `chesscar.ioc` 与 `Core/`、`Drivers/`，生成设置里必须打开
  “生成外设初始化的 .c/.h 分离”与“复制必要库文件”；NVIC 需使能 TIM2/TIM3/TIM4、
  USART1、DMA1 Channel1、DMA1 Channel5，并勾选 Call HAL handler。
- 批次 C：`app/` 下写整车主入口与赛题任务调度，把 `examples/app_chesscar.c` 里
  直接 `HAL_ADC_Start_DMA` 的写法改为走 `ADC_LineSensor_Init()` / `ADC_LineSensor_GetRaw()`。
- 引脚确定后：在 `stm32/bsp_config.h` 里固化 ADC 通道与 Rank 对应关系，
  并补上该文件 CubeMX 清单缺失的 DMA Settings 与 NVIC 两行；这属于子库改动，
  需在 `stm32-chesscar-lib` 提交后更新父仓库子模块指针。

## 未验证与未读到的部分

- `startup_stm32f103xb.s` 与 `STM32F103C8TX_FLASH.ld` 是按 ST GCC 模板等价手写的：
  本机未安装 STM32CubeF1 包，仓库内也没有现成副本（已确认）。建议在 CubeMX
  生成后用官方版本覆盖，功能应完全一致。
- 本工程尚未完整构建过：`Core/` 与 `Drivers/` 不存在，因此 HAL 源文件集合、
  烧写命令与产物均无实测数据。
- 启动文件与链接脚本已单独做过最小验证：用 arm-none-eabi-gcc 14.2.rel1 汇编
  `startup_stm32f103xb.s`，再用一个最小宿主（`SystemInit` + `main` + 若干强符号中断）
  按 `STM32F103C8TX_FLASH.ld` 链接通过：`.isr_vector` 为 240 字节，`_estack = 0x20005000`，
  `._user_heap_stack` 为 0x600，TIM2 / TIM3 / TIM4 / USART1 / DMA1_Channel1 /
  DMA1_Channel5 / ADC1_2 / I2C1_EV 在向量表中的偏移与 CMSIS 的 IRQn 编号一致。
  完整固件构建仍待 `Core/`、`Drivers/` 落地。
- 链接脚本里的内存取值（Flash 64 KB / SRAM 20 KB）按 STM32F103C8T6 常规规格填写，
  未在实物上核对。
