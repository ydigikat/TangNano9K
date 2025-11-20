//------------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------------
#ifndef __DRV_H__
#define __DRV_H__

#include <stdbool.h>

#include "bsp.h"


/* ----- GPO peripheral driver --------------------------------------------------- */

/* Pin mask values */
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

static inline void GPO_SetPin(GPO_t *gpo, uint32_t pin_mask)
{
  WRITE_REG(gpo->BSR, pin_mask);
}

static inline void GPO_ClearPin(GPO_t *gpo, uint32_t pin_mask)
{
  WRITE_REG(gpo->BSR, pin_mask << 16U);
}

/* ----- TRACE peripheral driver --------------------------------------------------- */

static inline void UART_SetDivisor(TRACE_t *trace, uint16_t div)
{
  MODIFY_REG(trace->CR, TRACE_CR_DIV, _VAL2FLD(TRACE_CR_DIV, div));
}

static inline bool TRACE_TransmitDataReady(TRACE_t *trace)
{
  return READ_BIT(trace->SR, TRACE_SR_TDR);
}

static inline void TRACE_PutChar(TRACE_t *trace, uint8_t c)
{
  while (!TRACE_TransmitDataReady(trace))
    ;

  WRITE_REG(trace->TD, c);
}

/* ----- Timer driver --------------------------------------------------- */
static inline void TIMER_Start(TIMER_t *timer)
{
  SET_BIT(timer->CR, TIMER_CR_RUN);
}

static inline void TIMER_Pause(TIMER_t *timer)
{
  CLEAR_BIT(timer->CR, TIMER_CR_RUN);
}

static inline void TIMER_Clear(TIMER_t *timer)
{
  SET_BIT(timer->CR, TIMER_CR_CLR);
}

static inline uint64_t TIMER_ReadUs(TIMER_t *timer)
{
  return (((uint64_t)READ_REG(timer->LO)) | ((uint64_t)READ_REG(timer->HI) << 32UL));
}

static inline void TIMER_SleepUs(TIMER_t *timer, uint64_t us)
{
  uint64_t start, now;
  start = TIMER_ReadUs(timer);

  do
  {
    now = TIMER_ReadUs(timer);    
  } while ((now - start) < us);
}

#endif /* __DRV_H__ */