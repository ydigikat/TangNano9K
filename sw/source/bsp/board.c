/*------------------------------------------------------------------------------------
  Jason Wilden 2025 
  ----------------------------------------------------------------------------------*/
#include "drv.h"

void board_init()
{
  trace_init(TRACE);

  /* Clear & start timer */  
  TIMER_Clear(TIMER1);
  TIMER_Start(TIMER1);
}