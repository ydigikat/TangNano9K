//------------------------------------------------------------------------------
// Jason Wilden 2025
//-----------------------------------------------------------------------------
#include "drv.h"
#include "serial.h"

uint32_t x;

int main(void)
{
  x = 0;

  /* Write test pattern to onboard LEDs */
  GPO_SetPin(GPO, GPO_PIN_0 | GPO_PIN_2 | GPO_PIN_4);  

  /* Set serial out BAUD divisor */
  UART_SetDivisor(UART, UART_DIV);

  /* Clear & start timer */  
  TIMER_Clear(TIMER);
  TIMER_Start(TIMER);

  bool toggle = true;

  while (1)
  {
  
    serial_printf("Da value of x is %d\n", x++, 0, 0);
    
    TIMER_SleepUs(TIMER,500000);
    
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
  }

  return 0;
}
