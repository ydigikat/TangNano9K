//------------------------------------------------------------------------------
// Jason Wilden 2025
// Trace functions.
//------------------------------------------------------------------------------
#ifndef __SERIAL_H__
#define __SERIAL_H__

#include <stdint.h>
#include <stddef.h>

void serial_print(const char *str);
void serial_printf(const char *fmt,uint32_t arg1, uint32_t arg2, uint32_t arg3);

#endif /* __SERIAL_H__ */