/**
 * @file    startup_stm32f103xb.s
 * @brief   STM32F103xB（中容量，64/128KB Flash）GCC 启动文件。
 *
 * 来源说明：本文件按 STM32CubeF1 的 GCC 模板 startup_stm32f103xb.s 等价手写。
 * 本机未安装 STM32CubeF1 包，仓库内也没有现成副本（已确认），所以按 STM32F103xB
 * 的中断向量定义逐项写出。若后续由 STM32CubeMX 生成，或从 STM32CubeF1 复制，
 * 请用官方版本替换本文件——功能应完全一致。
 *
 * 向量表顺序依据：STM32F103xB 的 CMSIS 设备头 IRQn_Type 定义
 * （WWDG_IRQn = 0 ... USBWakeUp_IRQn = 42，共 43 个外部中断）。
 * 本文件只覆盖系统异常 16 项 + 外部中断 43 项，不含高温/互联型器件才有的
 * TIM8 / ADC3 / FSMC / SDIO / TIM5 / SPI3 / UART4 / UART5 / TIM6 / TIM7 / DMA2。
 */

  .syntax unified
  .cpu cortex-m3
  .fpu softvfp
  .thumb

.global  g_pfnVectors
.global  Default_Handler

/* 链接脚本中定义的符号：.data 初值在 Flash 中的起点，以及 .data / .bss 边界 */
.word  _sidata
.word  _sdata
.word  _edata
.word  _sbss
.word  _ebss

/* STM32F10x 中容量器件 RAM 启动模式用的标志字（与 ST 模板保持一致） */
.equ  BootRAM, 0xF108F85F

/**
 * @brief  复位后首先执行的代码：建立栈指针，搬运 .data，清零 .bss，
 *         调用 SystemInit 与 C 运行时初始化，最后进入 main。
 */
  .section  .text.Reset_Handler
  .weak  Reset_Handler
  .type  Reset_Handler, %function
Reset_Handler:
  ldr   sp, =_estack    /* 显式设置栈指针（等于 SRAM 末尾） */

/* 把 .data 段的初值从 Flash 拷到 SRAM */
  movs  r1, #0
  b  LoopCopyDataInit

CopyDataInit:
  ldr  r3, =_sidata
  ldr  r3, [r3, r1]
  str  r3, [r0, r1]
  adds  r1, r1, #4

LoopCopyDataInit:
  ldr  r0, =_sdata
  ldr  r3, =_edata
  adds  r2, r0, r1
  cmp  r2, r3
  bcc  CopyDataInit
  ldr  r2, =_sbss
  b  LoopFillZerobss

/* 清零 .bss 段 */
FillZerobss:
  movs  r3, #0
  str  r3, [r2], #4

LoopFillZerobss:
  ldr  r3, = _ebss
  cmp  r2, r3
  bcc  FillZerobss

/* 系统时钟初始化（CMSIS 的 SystemInit，定义在 system_stm32f1xx.c） */
  bl  SystemInit
/* C 运行时初始化（.init_array 等） */
  bl  __libc_init_array
/* 进入应用入口 */
  bl  main

LoopForever:
  b  LoopForever

.size  Reset_Handler, .-Reset_Handler

/**
 * @brief  未被应用覆盖的中断全部落到这里（死循环，便于调试时定位）。
 * @note   该段被放入 .text，链接脚本用 --gc-sections 时由向量表 KEEP 住。
 */
  .section  .text.Default_Handler,"ax",%progbits
Default_Handler:
Infinite_Loop:
  b  Infinite_Loop
  .size  Default_Handler, .-Default_Handler

/******************************************************************************
 * 弱符号中断服务程序：应用在 C 代码里定义同名函数即可覆盖。
 * 未覆盖时全部指向 Default_Handler。
 ******************************************************************************/
  .macro  IRQ handler
  .weak  \handler
  .set   \handler, Default_Handler
  .endm

  IRQ  NMI_Handler
  IRQ  HardFault_Handler
  IRQ  MemManage_Handler
  IRQ  BusFault_Handler
  IRQ  UsageFault_Handler
  IRQ  SVC_Handler
  IRQ  DebugMon_Handler
  IRQ  PendSV_Handler
  IRQ  SysTick_Handler

  IRQ  WWDG_IRQHandler
  IRQ  PVD_IRQHandler
  IRQ  TAMPER_IRQHandler
  IRQ  RTC_IRQHandler
  IRQ  FLASH_IRQHandler
  IRQ  RCC_IRQHandler
  IRQ  EXTI0_IRQHandler
  IRQ  EXTI1_IRQHandler
  IRQ  EXTI2_IRQHandler
  IRQ  EXTI3_IRQHandler
  IRQ  EXTI4_IRQHandler
  IRQ  DMA1_Channel1_IRQHandler
  IRQ  DMA1_Channel2_IRQHandler
  IRQ  DMA1_Channel3_IRQHandler
  IRQ  DMA1_Channel4_IRQHandler
  IRQ  DMA1_Channel5_IRQHandler
  IRQ  DMA1_Channel6_IRQHandler
  IRQ  DMA1_Channel7_IRQHandler
  IRQ  ADC1_2_IRQHandler
  IRQ  USB_HP_CAN1_TX_IRQHandler
  IRQ  USB_LP_CAN1_RX0_IRQHandler
  IRQ  CAN1_RX1_IRQHandler
  IRQ  CAN1_SCE_IRQHandler
  IRQ  EXTI9_5_IRQHandler
  IRQ  TIM1_BRK_IRQHandler
  IRQ  TIM1_UP_IRQHandler
  IRQ  TIM1_TRG_COM_IRQHandler
  IRQ  TIM1_CC_IRQHandler
  IRQ  TIM2_IRQHandler
  IRQ  TIM3_IRQHandler
  IRQ  TIM4_IRQHandler
  IRQ  I2C1_EV_IRQHandler
  IRQ  I2C1_ER_IRQHandler
  IRQ  I2C2_EV_IRQHandler
  IRQ  I2C2_ER_IRQHandler
  IRQ  SPI1_IRQHandler
  IRQ  SPI2_IRQHandler
  IRQ  USART1_IRQHandler
  IRQ  USART2_IRQHandler
  IRQ  USART3_IRQHandler
  IRQ  EXTI15_10_IRQHandler
  IRQ  RTCAlarm_IRQHandler
  IRQ  USBWakeUp_IRQHandler

/******************************************************************************
 * 中断向量表：必须放在镜像最前面（链接脚本把它固定在 0x08000000）。
 *
 * 偏移对照（外部中断 = 0x40 + IRQn × 4）：
 *   TIM2   (IRQn 28) → 0xB0    TIM3   (29) → 0xB4    TIM4   (30) → 0xB8
 *   USART1 (IRQn 37) → 0xD4    I2C1_EV(31) → 0xBC
 *   DMA1_Channel1 (11) → 0x6C  DMA1_Channel5 (15) → 0x7C  ADC1_2 (18) → 0x88
 ******************************************************************************/
  .section  .isr_vector,"a",%progbits
  .type  g_pfnVectors, %object
  .size  g_pfnVectors, .-g_pfnVectors

g_pfnVectors:
  .word  _estack
  .word  Reset_Handler
  .word  NMI_Handler
  .word  HardFault_Handler
  .word  MemManage_Handler
  .word  BusFault_Handler
  .word  UsageFault_Handler
  .word  0
  .word  0
  .word  0
  .word  0
  .word  SVC_Handler
  .word  DebugMon_Handler
  .word  0
  .word  PendSV_Handler
  .word  SysTick_Handler

  .word  WWDG_IRQHandler                    /*  0  Window Watchdog           */
  .word  PVD_IRQHandler                     /*  1  PVD through EXTI          */
  .word  TAMPER_IRQHandler                  /*  2  Tamper                   */
  .word  RTC_IRQHandler                     /*  3  RTC through EXTI         */
  .word  FLASH_IRQHandler                   /*  4  FLASH                    */
  .word  RCC_IRQHandler                     /*  5  RCC                      */
  .word  EXTI0_IRQHandler                   /*  6  EXTI Line0               */
  .word  EXTI1_IRQHandler                   /*  7  EXTI Line1               */
  .word  EXTI2_IRQHandler                   /*  8  EXTI Line2               */
  .word  EXTI3_IRQHandler                   /*  9  EXTI Line3               */
  .word  EXTI4_IRQHandler                   /* 10  EXTI Line4               */
  .word  DMA1_Channel1_IRQHandler           /* 11  DMA1 Channel 1           */
  .word  DMA1_Channel2_IRQHandler           /* 12  DMA1 Channel 2           */
  .word  DMA1_Channel3_IRQHandler           /* 13  DMA1 Channel 3           */
  .word  DMA1_Channel4_IRQHandler           /* 14  DMA1 Channel 4           */
  .word  DMA1_Channel5_IRQHandler           /* 15  DMA1 Channel 5           */
  .word  DMA1_Channel6_IRQHandler           /* 16  DMA1 Channel 6           */
  .word  DMA1_Channel7_IRQHandler           /* 17  DMA1 Channel 7           */
  .word  ADC1_2_IRQHandler                  /* 18  ADC1 & ADC2              */
  .word  USB_HP_CAN1_TX_IRQHandler          /* 19  USB HP / CAN1 TX         */
  .word  USB_LP_CAN1_RX0_IRQHandler         /* 20  USB LP / CAN1 RX0        */
  .word  CAN1_RX1_IRQHandler                /* 21  CAN1 RX1                 */
  .word  CAN1_SCE_IRQHandler                /* 22  CAN1 SCE                 */
  .word  EXTI9_5_IRQHandler                 /* 23  EXTI Line 9..5           */
  .word  TIM1_BRK_IRQHandler                /* 24  TIM1 Break               */
  .word  TIM1_UP_IRQHandler                 /* 25  TIM1 Update              */
  .word  TIM1_TRG_COM_IRQHandler            /* 26  TIM1 Trigger/Commutation */
  .word  TIM1_CC_IRQHandler                 /* 27  TIM1 Capture Compare     */
  .word  TIM2_IRQHandler                    /* 28  TIM2                     */
  .word  TIM3_IRQHandler                    /* 29  TIM3                     */
  .word  TIM4_IRQHandler                    /* 30  TIM4                     */
  .word  I2C1_EV_IRQHandler                 /* 31  I2C1 Event               */
  .word  I2C1_ER_IRQHandler                 /* 32  I2C1 Error               */
  .word  I2C2_EV_IRQHandler                 /* 33  I2C2 Event               */
  .word  I2C2_ER_IRQHandler                 /* 34  I2C2 Error               */
  .word  SPI1_IRQHandler                    /* 35  SPI1                     */
  .word  SPI2_IRQHandler                    /* 36  SPI2                     */
  .word  USART1_IRQHandler                  /* 37  USART1                   */
  .word  USART2_IRQHandler                  /* 38  USART2                   */
  .word  USART3_IRQHandler                  /* 39  USART3                   */
  .word  EXTI15_10_IRQHandler               /* 40  EXTI Line 15..10         */
  .word  RTCAlarm_IRQHandler                /* 41  RTC Alarm via EXTI       */
  .word  USBWakeUp_IRQHandler               /* 42  USB Wakeup from suspend  */
  .word  BootRAM

  .size  g_pfnVectors, .-g_pfnVectors
