/*------------------------------------------------------------------------------------
  Jason Wilden 2025 
  ----------------------------------------------------------------------------------*/
#include "drv.h"
#include "trace.h"

static void timer_init()
{
  /* Clear & start timer */  
  TIMER_Clear(TIMER);
  TIMER_Start(TIMER);
}

void board_init()
{
  trace_init();
  timer_init();
}