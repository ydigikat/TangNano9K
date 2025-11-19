//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
#include "serial.h"
#include "drv.h"

static inline void putchar_blocking(char c) {    
    UART_PutChar(UART,c);
}

static void print_str(const char *s) {
    while (*s) {
        if (*s == '\n') putchar_blocking('\r');
        putchar_blocking(*s++);
    }
}

static void print_hex(uint32_t val, uint8_t digits) {
    const char hex[] = "0123456789ABCDEF";
    for (int i = (digits - 1) * 4; i >= 0; i -= 4) {
        putchar_blocking(hex[(val >> i) & 0xF]);
    }
}


static void print_dec(uint32_t val) {
    if (val == 0) {
        putchar_blocking('0');
        return;
    }
    
    char buf[10];
    int i = 0;
    while (val) {
        buf[i++] = '0' + (val % 10);
        val /= 10;
    }
    while (i > 0) putchar_blocking(buf[--i]);
}

void serial_print(const char *str)
{
    serial_printf(str,0,0,0);
}

void serial_printf(const char *fmt,uint32_t arg1, uint32_t arg2, uint32_t arg3) 
{   
    // Format string 
    uint32_t args[3] = {arg1, arg2, arg3};
    int arg_idx = 0;
    
    while (*fmt) {
        if (*fmt == '%' && arg_idx < 3) {
            fmt++;
            switch (*fmt) {
                case 'd': print_dec(args[arg_idx++]); break;
                case 'x': print_hex(args[arg_idx++], 8); break;
                case 'h': print_hex(args[arg_idx++], 4); break;  // Short hex
                case 'b': print_hex(args[arg_idx++], 2); break;  // Byte hex
                case 's': print_str((const char*)args[arg_idx++]); break;
                case 'c': putchar_blocking(args[arg_idx++] & 0xFF); break;
                default: putchar_blocking(*fmt);
            }
        } else {
            if (*fmt == '\n') putchar_blocking('\r');
            putchar_blocking(*fmt);
        }
        fmt++;
    }
}