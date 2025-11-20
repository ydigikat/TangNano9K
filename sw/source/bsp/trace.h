//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
#ifndef __TRACE_H__
#define __TRACE_H__

#include <stdint.h>
#include <stddef.h>

void trace_init(void);
void trace_print(const char *str);
void trace_printf(const char *fmt,uint32_t arg1, uint32_t arg2, uint32_t arg3);

#endif /* __TRACE_H__ */