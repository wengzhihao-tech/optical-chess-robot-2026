/*
 * STM32F103C8Tx 链接脚本（GCC / ld）
 *
 * 器件：STM32F103C8T6，Flash 64 KB，SRAM 20 KB。
 * 来源：按 STM32CubeF1 的 GCC 模板（STM32F103XB_FLASH.ld）等价手写，文件名按
 * CubeMX 对 C8Tx 的命名习惯取 STM32F103C8TX_FLASH.ld。本机未安装 STM32CubeF1 包，
 * 仓库内也没有现成副本；若后续由 CubeMX 生成同名文件，请用官方版本替换。
 *
 * 与 firmware/Makefile 的约定：-TSTM32F103C8TX_FLASH.ld，入口 Reset_Handler。
 */

/* 入口点：与 startup_stm32f103xb.s 中的 Reset_Handler 对应 */
ENTRY(Reset_Handler)

/* 栈顶 = SRAM 末尾。startup 里的 ldr sp, =_estack 也引用这个符号。 */
_estack = ORIGIN(RAM) + LENGTH(RAM);

/* 链接期保留的最小堆与栈空间（见 ._user_heap_stack 段）
 * 堆 512 B：库与示例全程使用静态缓冲，没有 malloc；仅在启用 printf 时留余量。
 * 栈 1 KB：F103 无 FPU，浮点走软件库，10 ms 主循环里的两路 PID 是栈开销最大的路径。
 * 二者都是建议值，需用 .map 与 arm-none-eabi-size 复核实际用量后再调。 */
_Min_Heap_Size  = 0x200;   /* 512 B  */
_Min_Stack_Size = 0x400;   /* 1024 B */

MEMORY
{
  RAM   (xrw) : ORIGIN = 0x20000000, LENGTH = 20K
  FLASH (rx)  : ORIGIN = 0x08000000, LENGTH = 64K
}

SECTIONS
{
  /* 中断向量表必须位于镜像最前面 */
  .isr_vector :
  {
    . = ALIGN(4);
    KEEP(*(.isr_vector))
    . = ALIGN(4);
  } >FLASH

  .text :
  {
    . = ALIGN(4);
    *(.text)
    *(.text*)
    *(.glue_7)
    *(.glue_7t)
    *(.eh_frame)

    KEEP (*(.init))
    KEEP (*(.fini))

    . = ALIGN(4);
    _etext = .;
  } >FLASH

  .rodata :
  {
    . = ALIGN(4);
    *(.rodata)
    *(.rodata*)
    . = ALIGN(4);
  } >FLASH

  .ARM.extab :
  {
    . = ALIGN(4);
    *(.ARM.extab* .gnu.linkonce.armextab.*)
    . = ALIGN(4);
  } >FLASH

  .ARM :
  {
    . = ALIGN(4);
    __exidx_start = .;
    *(.ARM.exidx*)
    __exidx_end = .;
    . = ALIGN(4);
  } >FLASH

  .preinit_array :
  {
    . = ALIGN(4);
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array*))
    PROVIDE_HIDDEN (__preinit_array_end = .);
    . = ALIGN(4);
  } >FLASH

  .init_array :
  {
    . = ALIGN(4);
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array*))
    PROVIDE_HIDDEN (__init_array_end = .);
    . = ALIGN(4);
  } >FLASH

  .fini_array :
  {
    . = ALIGN(4);
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT(.fini_array.*)))
    KEEP (*(.fini_array*))
    PROVIDE_HIDDEN (__fini_array_end = .);
    . = ALIGN(4);
  } >FLASH

  /* .data 段的初值在 Flash 中，运行前由 startup 拷到 SRAM */
  _sidata = LOADADDR(.data);

  .data :
  {
    . = ALIGN(4);
    _sdata = .;
    *(.data)
    *(.data*)
    . = ALIGN(4);
    _edata = .;
  } >RAM AT> FLASH

  . = ALIGN(4);
  .bss :
  {
    . = ALIGN(4);
    _sbss = .;
    __bss_start__ = _sbss;
    *(.bss)
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    _ebss = .;
    __bss_end__ = _ebss;
  } >RAM

  /* 链接期占用检查：堆栈空间必须能从 RAM 剩余部分分配出来，否则报错。 */
  ._user_heap_stack :
  {
    . = ALIGN(8);
    PROVIDE ( end = . );
    PROVIDE ( _end = . );
    . = . + _Min_Heap_Size;
    . = . + _Min_Stack_Size;
    . = ALIGN(8);
  } >RAM

  /DISCARD/ :
  {
    libc.a ( * )
    libm.a ( * )
    libgcc.a ( * )
  }

  .ARM.attributes 0 : { *(.ARM.attributes) }
  .comment 0        : { *(.comment) }
}
