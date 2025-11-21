//------------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------------
#ifndef __DRV_H__
#define __DRV_H__

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include "bsp.h"

/* ----- GPO low-level driver --------------------------------------------------- */
#define GPO_PIN_0 (GPO_BSR_0)
#define GPO_PIN_1 (GPO_BSR_1)
#define GPO_PIN_2 (GPO_BSR_2)
#define GPO_PIN_3 (GPO_BSR_3)
#define GPO_PIN_4 (GPO_BSR_4)
#define GPO_PIN_5 (GPO_BSR_5)
#define GPO_PIN_6 (GPO_BSR_6)
#define GPO_PIN_7 (GPO_BSR_7)
#define GPO_PIN_8 (GPO_BSR_8)
#define GPO_PIN_9 (GPO_BSR_9)
#define GPO_PIN_10 (GPO_BSR_10)
#define GPO_PIN_11 (GPO_BSR_11)
#define GPO_PIN_12 (GPO_BSR_12)
#define GPO_PIN_13 (GPO_BSR_13)
#define GPO_PIN_14 (GPO_BSR_14)
#define GPO_PIN_15 (GPO_BSR_15)
#define GPO_PIN_16 (GPO_BSR_16)

static inline void GPO_SetPin(GPO_t *restrict gpo, uint32_t pin_mask)
{
  WRITE_REG(gpo->BSR, pin_mask);
}

static inline void GPO_ClearPin(GPO_t *restrict gpo, uint32_t pin_mask)
{
  WRITE_REG(gpo->BSR, pin_mask << 16U);
}

/* ----- TRACE low-level driver --------------------------------------------------- */
static const uint8_t TRACE_DIV = SYS_FREQ / (115200*16)-1;

static inline void TRACE_SetDivisor(TRACE_t *restrict trace, uint16_t div)
{
  MODIFY_REG(trace->CR, TRACE_CR_DIV, _VAL2FLD(TRACE_CR_DIV, div));
}

static inline bool TRACE_TransmitDataReady(TRACE_t *restrict trace)
{
  return READ_BIT(trace->SR, TRACE_SR_TDR);
}

static inline void TRACE_PutChar(TRACE_t *restrict trace, uint8_t c)
{
  while (!TRACE_TransmitDataReady(trace))
  {
      ;
  }
    
  WRITE_REG(trace->TD, c);
}

/* ----- Timer low-level driver --------------------------------------------------- */
static inline void TIMER_Start(TIMER_t *restrict timer)
{
  SET_BIT(timer->CR, TIMER_CR_RUN);
}

static inline void TIMER_Pause(TIMER_t *restrict timer)
{
  CLEAR_BIT(timer->CR, TIMER_CR_RUN);
}

static inline void TIMER_Clear(TIMER_t *restrict timer)
{
  SET_BIT(timer->CR, TIMER_CR_CLR);
}

static inline uint64_t TIMER_ReadUs(TIMER_t *restrict timer)
{
  return (((uint64_t)READ_REG(timer->LO)) | ((uint64_t)READ_REG(timer->HI) << 32UL));
}

static inline void TIMER_SleepUs(TIMER_t *restrict timer, uint64_t us)
{
  uint64_t start, now;
  start = TIMER_ReadUs(timer);

  do
  {
    now = TIMER_ReadUs(timer);
  } while ((now - start) < us);
}

/* ----- I2C low level driver --------------------------------------------------- */
#define I2C_START (0x00 << 8)
#define I2C_WRITE (0x01 << 8)
#define I2C_READ (0x02 << 8)
#define I2C_RESTART (0x04 << 8)

static const uint32_t I2C_DIV_STD = (MCU_FREQ * 1000000 / 100 / 4);
static const uint32_t I2C_DIV_FAST = (MCU_FREQ * 1000000 / 400 / 4);

static inline void I2C_SetDivisor(I2C_t *restrict i2c, uint32_t div)
{
   MODIFY_REG(i2c->CR, I2C_CR_DIV, _VAL2FLD(I2C_CR_DIV, div));
}

static inline uint8_t I2C_Ready(I2C_t *restrict i2c)
{
  return READ_BIT(i2c->RD, I2C_RD_RDY);
}

static inline void I2C_Start(I2C_t *restrict i2c)
{
  while (!I2C_Ready(i2c))
    ;
  SET_BIT(i2c->CR, I2C_START);
}

static inline void I2C_Restart(I2C_t *restrict i2c)
{
  while (!I2C_Ready(i2c))
    ;
  SET_BIT(i2c->CR, I2C_RESTART);
}

static inline void I2C_Stop(I2C_t *restrict i2c)
{
  while (!I2C_Ready(i2c))
    ;
  CLEAR_BIT(i2c->CR, I2C_START);
}

static inline bool I2C_WriteByte(I2C_t *restrict i2c, uint8_t data)
{
  while (!I2C_Ready(i2c))
    ;

  WRITE_REG(i2c->WD, data | I2C_WRITE);
  while (!I2C_Ready(i2c))
    ;

  return READ_BIT(i2c->RD, I2C_RD_ACK);
}

static inline uint8_t I2C_ReadByte(I2C_t *restrict i2c, uint8_t final)
{
  while (!I2C_Ready(i2c))
    ;

  WRITE_REG(i2c->WD, final | I2C_READ);
  while (!I2C_Ready(i2c))
    ;

  return READ_REG(i2c->RD) & 0x00FF;
}

/* ----- High level driver functions --------------------------------------------------- */
void trace_init(TRACE_t *restrict trace);
void trace_print(TRACE_t *restrict trace,const char *str);
void trace_printf(TRACE_t *restrict trace,const char *fmt,uint32_t arg1, uint32_t arg2, uint32_t arg3);

void i2c_init(I2C_t *restrict i2c);
uint8_t i2c_read_transaction(I2C_t *restrict i2c,uint8_t addr, uint8_t bytes[], size_t len, bool restart);
uint8_t i2c_write_transaction(I2C_t *restrict i2c, uint8_t addr, uint8_t bytes[], size_t len, bool restart);

#endif /* __DRV_H__ */