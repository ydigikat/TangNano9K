//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
#include "drv.h"

/**
 * i2c_init
 * \brief Initialises the I2C peripheral with default values.
 */
void i2c_init(I2C_t *restrict i2c)
{
  I2C_SetDivisor(i2c,I2C_DIV_STD);
}

/**
 * i2c_write_transaction
 * \brief Writes a series of bytes to an i2c connected device.
 * \param addr The address of the device.
 * \param bytes An array of bytes to transmit.
 * \param len The number of bytes to transmit.
 * \param restart Indicates the connection should be left open at the end of the transaction.
 * \returns The number of bytes (including address) transmitted.
 */
uint8_t i2c_write_transaction(I2C_t *restrict i2c,uint8_t addr, uint8_t bytes[], size_t len, bool restart)
{
  uint8_t addr_byte;
  uint8_t sent;

  addr_byte = (addr << 1);    /* 7 bit address, LSB is 0 for write */
  I2C_Start(i2c);
  sent = I2C_WriteByte(i2c,addr_byte);

  for(uint8_t i=0; i<len; i++)    /* Write data */
  {
    sent += I2C_WriteByte(i2c,bytes[i]);
  }

  if(restart)
  {
    I2C_Restart(i2c);
  }
  else
  {
    I2C_Stop(i2c);
  }

  return sent;
}

uint8_t i2c_read_transaction(I2C_t *restrict i2c,uint8_t addr, uint8_t bytes[], size_t len, bool restart)
{

}