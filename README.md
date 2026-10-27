# 光电象棋机器人 2026

光协第五届光电设计大赛参赛工程（整车），目标 2026-11-30 交付。

本仓库是整车工程的主仓库：应用层、硬件、文档与联调记录都在这里；电机驱动、编码器测速、PID、串口协议等可复用代码统一放在 [stm32-chesscar-lib](https://github.com/wengzhihao-tech/stm32-chesscar-lib)，本仓库通过子模块引用，不重复实现。

## 目录规划（待落地）

- firmware/  STM32 应用层：主控逻辑、任务调度、通信协议适配
- lib/       子模块：stm32-chesscar-lib（HAL 可复用库）
- hardware/  原理图、PCB、BOM、结构件与装配说明
- docs/      方案、赛题要求、调试记录、测试报告
- tests/     PC 端自测、日志回放与参数标定脚本

## 进度（截至 2026-10-27）

- 已完成：可复用 HAL 库 stm32-chesscar-lib —— TB6612 电机驱动、编码器测速、串级 PID、串口 DMA 协议、SSD1306 OLED、8 路光电循迹，算法层与平台解耦并带 PC 端自测。
- 未开始：整车本体（机械装配、传感器布局、整车主控、联调）。截至本仓库建立时，整车仍无实机推进记录。

## 里程碑

- 2026-10-15  项目启动
- 2026-10-27  本仓库建立，作为整车工程主仓库
- 2026-11-30  交付

## 协作约定

- 驱动与算法层改动走 stm32-chesscar-lib；本仓库只做应用层与集成，避免同一逻辑两处实现。
- 提交信息格式：模块: 动作（例：motor: 增加堵转保护）。
- 构建产物、编译中间件、大体积二进制不入库，用 Release 或网盘分发。

## 许可

待定。引用的 stm32-chesscar-lib 为 MIT 许可。
---

## 构建与运行

### 依赖

- git ≥ 2.34（本机实测 2.55.0.windows.2）
- PC 端自测：`gcc` + `make`。Windows 侧未装 gcc/make，实测可用环境是 WSL2 的 Ubuntu 22.04.5（gcc 11.4.0 / make 4.3 / git 2.34.1），下面自测命令均在 WSL 内执行。
- 固件（待落地）：arm-none-eabi-gcc 14.2.rel1（已装交叉工具链，不能用于主机自测）或 Keil uVision 5；STM32CubeMX 用于生成工程骨架。
- 网络：clone 需要可用的 HTTPS 代理，直连 github.com 实测失败。本机系统代理为 `127.0.0.1:7892`，示例命令用 `-c http.proxy=...` 临时指定。

### 克隆（含子模块）

```bash
git clone --recurse-submodules -c http.proxy=http://127.0.0.1:7892 \
  https://github.com/wengzhihao-tech/optical-chess-robot-2026.git
```

已经克隆过、但 `lib/stm32-chesscar-lib` 是空目录时：

```bash
git submodule update --init --recursive
```

子模块当前钉在 `stm32-chesscar-lib` 的提交 `533b247`（main 尖端，2026-10-27）。

### PC 端自测（当前唯一可复现的构建）

在 WSL 中执行：

```bash
cd lib/stm32-chesscar-lib/test
make run          # 全部用例（基础 + 赛题专用 + 运动斜坡）
make run-base     # 只跑基础模块（PID / 编码器 / 探头 / 协议）
make run-match    # 只跑赛题专用模块（定位 / 决策 / 导航 / 状态机 / 视觉）
make run-ramp     # 只跑运动斜坡（软启动 / 换向 / 低速下限）
make clean        # 删除自测可执行文件
```

编译参数是 `gcc -std=c99 -Wall -Wextra -I../common`，链接 `-lm`；产物是 `test/` 目录下三个无扩展名可执行文件 `selftest`、`selftest_match`、`selftest_ramp`，直接运行即打印断言结果。

`lib/stm32-chesscar-lib/README.md` 记录的期望结果：14 个编译单元零警告零错误，160 项断言全部通过（基础 38 + 赛题专用 100 + 运动斜坡 22），含 CRC16-CCITT-FALSE 标准向量 `"123456789" → 0x29B1`。

### 整车固件构建（待落地，非可复现步骤）

`stm32-chesscar-lib` 只提供平台无关的 `common/` 算法层、HAL 适配的 `stm32/` 层与 `examples/app_chesscar.c`：仓库内没有顶层 Makefile/CMakeLists、没有 `.ioc`、没有 startup 与链接脚本，所以整车固件目前没有可复现的编译命令。落地路径是在 `firmware/` 下用 STM32CubeMX 建 STM32F103 工程（PWM、编码器模式定时器、I2C1、USART1+DMA、ADC1+DMA），把 `lib/stm32-chesscar-lib/common` 与 `lib/stm32-chesscar-lib/stm32` 加入 include 路径，按 `stm32/bsp_config.h` 填引脚，用 `examples/app_chesscar.c` 组织主循环与中断回调。

### 烧写（待补）

库内没有任何烧写/下载命令，也没有约定产物名，其 README 明确写着硬件层尚未在实物 STM32 上验证。这一节等 `firmware/` 工程落地后再补具体命令，暂为占位。

### 已知缺口

- `common/` 共 12 个 `.c`，其中 `speed_control.c` 不参与 PC 自测（依赖硬件接口）；`stm32/` 的 6 个 `.c` 与 `examples/` 的 3 个 `.c` 也不在自测范围内。
- 硬件层未在实物上验证：引脚分配、编码器方向、ToF 改址、ADC Circular DMA 启动顺序与 8 路 Rank 对应关系都需上板确认。
- 串口协议（`lib/stm32-chesscar-lib/docs/PROTOCOL.md`）只有规格，没有随库提供的 PC 端上位机脚本。
