//------------------------------------------------------------------------------
// Jason Wilden 2025
//-----------------------------------------------------------------------------
#include "drv.h"
#include "serial.h"

uint32_t x;

int main(void)
{
  x = 0;

  /* Write pattern to onboard LEDs */
  GPO_SetPin(GPO, GPO_PIN_0 | GPO_PIN_2 | GPO_PIN_4 | GPO_PIN_1);

  GPO_ClearPin(GPO, GPO_PIN_1);

  /* Set serial out BAUD divisor */
  serial_printf("Setting divisor to %d\n", UART_DIV, 0, 0);
  UART_SetDivisor(UART, UART_DIV);

  /* Clear timer */
  serial_print("Clearing timer\n");
  TIMER_Clear(TIMER);

  /* Start Timer */
  serial_print("Starting timer\n");
  TIMER_Start(TIMER);

  bool toggle = true;

  while (1)
  {
    serial_printf("Da value of x is %d\n", x++, 0, 0);
    // GPO_TogglePin(GPO,GPO_PIN_0);

    uint64_t start, now;

    start = TIMER_ReadUs(TIMER);
    serial_printf("start = %d\n", start, 0, 0);

    do
    {
      now = TIMER_ReadUs(TIMER);
    } while ((now - start) < 500000); // 500ms

    toggle = !toggle;

    if(toggle) 
    {
      GPO_SetPin(GPO,GPO_PIN_1);
    }
    else
    {
      GPO_ClearPin(GPO,GPO_PIN_1);
    }

    // GPO_TogglePin(GPO,GPO_PIN_1);
    
    serial_printf("now = %d, diff = %d\n", now, now-start, 0);
  }

  return 0;
}
