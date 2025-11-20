/*------------------------------------------------------------------------------
 * Jason Wilden 2025
 *------------------------------------------------------------------------------
 * Linker script for picorv32
 *----------------------------------------------------------------------------*/

MEMORY
{
    /* 8KB SRAM starting at address 0 */
    ram (rwx) : ORIGIN = 0x00000000, LENGTH = 8K
}

/* Get rid of RWX warning, note that the picorv32 has no MPU so ignores these making
it enirely possible to write data over the program code (text) and constants (rodata) */
PHDRS
{
    text PT_LOAD FLAGS(5);   /* R+X */
    rodata PT_LOAD FLAGS(4); /* R */
    data PT_LOAD FLAGS(6);   /* R+W */
}

SECTIONS
{
    /* Code section */
    .text : {
        . = ALIGN(4);
        *(.text.start)      /* Startup code first */
        *(.text*)           /* Other code */
        . = ALIGN(4);
    } > ram :text

    /* Read-only data */
    .rodata : {
        . = ALIGN(4);
        *(.rodata*)
        . = ALIGN(4);
    } > ram :rodata

    /* Initialized data */
    .data : {
        . = ALIGN(4);
        __data_start = .;
        *(.data*)
        . = ALIGN(4);
        __data_end = .;
    } > ram :data

    /* Uninitialized data (BSS) cleared in startup.s*/
    .bss : {
        . = ALIGN(4);
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > ram :data

    /* Stack grows down from end of RAM */
    /* Stack pointer will point to top of RAM, first push goes to top-4 */
    .stack (NOLOAD) : {
        . = ALIGN(16);
        __stack_bottom = .;
        . += 0x100;  /* Reserve 256 bytes for stack checking */
        . = ALIGN(16);
    } > ram

    /* Stack top is at the very end of RAM */
    __stack_top = ORIGIN(ram) + LENGTH(ram);

    /* Check for stack overflow into .bss */
    ASSERT(__stack_bottom < __stack_top, "ERROR: Stack overlaps with .bss")
    ASSERT(. <= __stack_top, "ERROR: Program too large for RAM")

    /* Discard unwanted sections */
    /DISCARD/ : {
        *(.eh_frame)
        *(.comment)
    }
}

ENTRY(_start)