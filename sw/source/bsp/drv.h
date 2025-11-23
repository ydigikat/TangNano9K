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

/* GPIO Pin masks */
#define GPO_PIN_0 (GPO_BSR_0)               /*!< Select pin 0 */
#define GPO_PIN_1 (GPO_BSR_1)               /*!< Select pin 1 */
#define GPO_PIN_2 (GPO_BSR_2)               /*!< Select Pin 2 */
#define GPO_PIN_3 (GPO_BSR_3)               /*!< Select Pin 3 */
#define GPO_PIN_4 (GPO_BSR_4)               /*!< Select Pin 4 */
#define GPO_PIN_5 (GPO_BSR_5)               /*!< Select Pin 5 */
#define GPO_PIN_6 (GPO_BSR_6)               /*!< Select Pin 6 */
#define GPO_PIN_7 (GPO_BSR_7)               /*!< Select Pin 7 */
#define GPO_PIN_8 (GPO_BSR_8)               /*!< Select Pin 8 */
#define GPO_PIN_9 (GPO_BSR_9)               /*!< Select Pin 9 */
#define GPO_PIN_10 (GPO_BSR_10)             /*!< Select Pin 10 */
#define GPO_PIN_11 (GPO_BSR_11)             /*!< Select Pin 11 */
#define GPO_PIN_12 (GPO_BSR_12)             /*!< Select Pin 12 */
#define GPO_PIN_13 (GPO_BSR_13)             /*!< Select Pin 13 */
#define GPO_PIN_14 (GPO_BSR_14)             /*!< Select Pin 14 */
#define GPO_PIN_15 (GPO_BSR_15)             /*!< Select Pin 15 */
#define GPO_PIN_16 (GPO_BSR_16)             /*!< Select Pin 16 */

/**
 * GPO_SetPin
 * \brief Set one or more pins to high
 * \param gpo The GPO peripheral instance.
 * \param pin_mask Combination of GPIO pin masks
 * \return none
 */
static inline void GPO_SetPin(GPO_t *restrict gpo, uint32_t pin_mask)
{
  WRITE_REG(gpo->BSR, pin_mask);
}

/**
 * GPO_ClearPin
 * \brief Set one or more pins to low (reset)
 * \param gpo The GPO peripheral instance.
 * \param pin_mask Combination of GPIO pin masks
 * \return none
 */
static inline void GPO_ClearPin(GPO_t *restrict gpo, uint32_t pin_mask)
{
  WRITE_REG(gpo->BSR, pin_mask << 16U);
}

/* ----- TRACE low-level driver --------------------------------------------------- */

#define TRACE_SUCCESS (0UL)           /*!< Successful call */
#define TRACE_TIMEOUT (2UL)           /*!< Call timed out */
#define TRACE_TIMEOUT_COUNT (10000)   /*!< Timeout counter value */

static const uint8_t TRACE_DIV = (SYS_FREQ/(115200*16)-1); /*!< 115200 divisor */

/**
 * TRACE_SetDivisor
 * \brief Sets the baud rate divisor: f/(baud*16))-1
 * \param trace The TRACE peripheral instance.
 * \param div The divisor count value.  TRACE_DIV constant sets 115200
 * \return none
 */
static inline void TRACE_SetDivisor(TRACE_t *restrict trace, uint16_t div)
{
  MODIFY_REG(trace->CR, TRACE_CR_DIV, _VAL2FLD(TRACE_CR_DIV, div));
}

/**
 * TRACE_TransmitDataReady
 * \brief Flag indicating that trace is ready to transmit data.
 * \param trace The TRACE peripheral instance.
 * \return The value of the flag
 */
static inline bool TRACE_TransmitDataReady(TRACE_t *restrict trace)
{
  return READ_BIT(trace->SR, TRACE_SR_TXRDY);
}

/**
 * TRACE_PutChar
 * \brief Transmit a character (blocking call)
 * \param trace The TRACE peripheral instance.
 * \param c The character to send
 * \return TRACE_SUCCESS or TRACE_TIMEOUT
 */
static inline uint8_t TRACE_PutChar(TRACE_t *restrict trace, uint8_t c)
{
  uint16_t timeout_count = TRACE_TIMEOUT_COUNT;

  WRITE_REG(trace->TD, c);

  while (!TRACE_TransmitDataReady(trace))
  {
    if(timeout_count-- == 0)
    {
      return TRACE_TIMEOUT;
    }
  }

  return TRACE_SUCCESS;
}

/* ----- Timer low-level driver --------------------------------------------------- */

/**
 * TIMER_Start
 * \brief Starts the timer running (from the last paused value).
 * \param timer The TIMER peripheral instance.
 * \return none
 */
static inline void TIMER_Start(TIMER_t *restrict timer)
{
  SET_BIT(timer->CR, TIMER_CR_RUN);
}

/**
 * TIMER_Pause
 * \brief Pauses the timer.  
 * \param timer The TIMER peripheral instance.
 * \return none
 */
static inline void TIMER_Pause(TIMER_t *restrict timer)
{
  CLEAR_BIT(timer->CR, TIMER_CR_RUN);
}

/**
 * TIMER_Clear
 * \brief Clears the timer coutner.
 * \param timer The TIMER peripheral instance.
 * \return none
 */
static inline void TIMER_Clear(TIMER_t *restrict timer)
{
  SET_BIT(timer->CR, TIMER_CR_CLR);
}

/**
 * TIMER_ReadUs
 * \brief Returns the number of microseconds the timer has counterd.
 * \param timer The TIMER peripheral instance.
 * \return 64-bit microseconds count.
 */
static inline uint64_t TIMER_ReadUs(TIMER_t *restrict timer)
{
  return (((uint64_t)READ_REG(timer->LO)) | ((uint64_t)READ_REG(timer->HI) << 32UL));
}

/**
 * TIMER_SleepUs
 * \brief Blocks execution for the number of microseconds specified.
 * \param timer The TIMER peripheral instance.
 * \param us 64-bit delay in microseconds.
 * \return none
 */
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
#define I2C_SUCCESS (0UL)             /*<! Successful call */
#define I2C_ERROR (1UL)               /*<! Error (nack) from worker device */
#define I2C_TIMEOUT (2UL)             /*<! Timeout error */
#define I2C_TIMEOUT_COUNT (10000)     /*<! Timeout counter */

/**
 * I2C_Busy
 * \brief Returns the state of the I2C bus
 * \param i2c The I2C peripheral instance.
 * \return 1=Busy, 0=Idle
 */
static inline uint8_t I2C_Busy(I2C_t *restrict i2c)
{
  return (READ_BIT(i2c->SR, I2C_SR_BUSY));
}

/**
 * I2C_Done
 * \brief Returns true when the I2C command is completed.
 * \param i2c The I2C peripheral instance.
 * \return 1=Done, 0=Incomplete
 */
static inline uint8_t I2C_Done(I2C_t *restrict i2c)
{
  return (READ_BIT(i2c->SR, I2C_SR_DONE));
}

/**
 * I2C_Error
 * \brief Indicates a NACK from the worker device.
 * \param i2c The I2C peripheral instance.
 * \return 1=Error (NACK), 0=Success
 */
static inline uint8_t I2C_Error(I2C_t *restrict i2c)
{
  return (READ_BIT(i2c->SR, I2C_SR_ERR));
}

/**
 * I2C_ReadByte
 * \brief Reads a byte from the device with the specified address.
 * \param i2c The I2C peripheral instance.
 * \param addr The 7-bit address of the device.
 * \param data Address of buffer to hold the byte read.
 * \return I2C_SUCCESS, I2C_ERROR or I2C_TIMEOUT
 */
static inline int8_t I2C_ReadByte(I2C_t *restrict i2c, uint8_t addr, uint8_t *restrict data)
{
  uint16_t timeout = I2C_TIMEOUT_COUNT;

  while (I2C_Busy(i2c))
  {
    if (timeout-- == 0)
    {
      return I2C_TIMEOUT;
    }
  }

  WRITE_REG(i2c->CR, (addr & 0x7F) | I2C_CR_RW);

  while (!I2C_Done(i2c) && !I2C_Error(i2c))
  {
    if (timeout-- == 0)
    {
      return I2C_TIMEOUT;
    }
  }

  if (I2C_Error(i2c))
  {
    return I2C_ERROR;
  }

  *data = (uint8_t)READ_REG(i2c->RX);

  return I2C_SUCCESS;
}

/**
 * I2C_WriteByte
 * \brief Writes a byte to the device with the specified address.
 * \param i2c The I2C peripheral instance.
 * \param addr The 7-bit address of the device.
 * \param data The byte to write.
 * \return I2C_SUCCESS, I2C_ERROR or I2C_TIMEOUT
 */
static inline int8_t I2C_WriteByte(I2C_t *restrict i2c, uint8_t addr, uint8_t data)
{
  uint16_t timeout = I2C_TIMEOUT_COUNT;

  while (I2C_Busy(i2c))
  {
    if (timeout-- == 0)
    {
      return I2C_TIMEOUT;
    }
  }

  WRITE_REG(i2c->TX, data);
  WRITE_REG(i2c->CR, (addr & 0x7F));

  while (!I2C_Done(i2c) && !I2C_Error(i2c))
  {
    if (timeout-- == 0)
    {
      return I2C_TIMEOUT;
    }
  }

  if (I2C_Error(i2c))
  {
    return I2C_ERROR;
  }

  return I2C_SUCCESS; 
}

/* ----- High level driver functions --------------------------------------------------- */
#ifdef USE_HIGH_LEVEL_DRIVERS

void trace_init(TRACE_t *restrict trace);
void trace_print(TRACE_t *restrict trace, const char *str);
void trace_printf(TRACE_t *restrict trace, const char *fmt, uint32_t arg1, uint32_t arg2, uint32_t arg3);

#endif

#endif /* __DRV_H__ */