//------------------------------------------------------------------------------
// Jason Wilden 2025
//-----------------------------------------------------------------------------
#include "drv.h"
#include "trace.h"

extern void board_init();

int main(void)
{  
  bool toggle = true;

  board_init();

  while (1)
  { 
    TIMER_SleepUs(TIMER,500000);
    
    toggle = !toggle;

    if(toggle) 
      GPO_SetPin(GPO,GPO_PIN_1);    
    else
      GPO_ClearPin(GPO,GPO_PIN_1);

    trace_printf("Timer is now %d\n", TIMER_ReadUs(TIMER), 0, 0);    
  }

  return 0;
}
