//------------------------------------------------------------------------------
// Jason Wilden 2025
//-----------------------------------------------------------------------------
#include "drv.h"

extern void board_init();

int main(void)
{  
  bool toggle = true;

  board_init();

  while (1)
  { 
    TIMER_SleepUs(TIMER1,500000);
    
    toggle = !toggle;

    if(toggle) 
    {
      GPO_SetPin(GPO1,GPO_PIN_0);    
    }
    else
    {
      GPO_ClearPin(GPO1,GPO_PIN_0);
    }

    trace_printf(TRACE, "Timer is now %d\n", TIMER_ReadUs(TIMER1), 0, 0);    
  }

  return 0;
}
