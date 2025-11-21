# Timer
The timer is a 64-bit counter which increments at 1us intervals.  

Read the LO register first when retrieving the counter value, this will latch the
HI value at the same time ensuring an atomic 64 bit value.

## Registers

### Timer control register
**Address offset:** 0x00  
**Reset value:** 0x0000_0000

| Bits | Access | Purpose |
|------|--------|---------|
| 31-2 |        | unused  |
| 1    | Write  | Clear timer counter |
| 0    | Write  | Start/Pause timer | 

Note that clearing the start timer bit [0] will pause the timer without clearing the current value.  


### GPO low word register
**Address offset:** 0x01  
**Reset value:** 0x0000_0000

| Bits | Access | Purpose |
|------|--------|---------|
| 31-0 | Read   | Low word of 64 bit timer counter |


### GPO high word register
**Address offset:** 0x02
**Reset value:** 0x0000_0000

| Bits | Access | Purpose |
|------|--------|---------|
| 31-0 | Read   | High word of 64 bit timer counter |

#### Examples
```c
#include "bsp.h"

/* Clear and start timer */
SET_BIT(TIMER->CR,TIMER_CR_CLR)
SET_BIT(TIMER->CR,TIMER_CR_RUN)

/* Read timer value */
uint64_t x = (((uint64_t)READ_REG(timer->LO)) | ((uint64_t)READ_REG(timer->HI) << 32UL));

/* Pause timer */
CLEAR_BIT(TIMER->CR,TIMER_CR_RUN)

```

## Driver 
The TIMER driver provides the following functions:

- TIMER_Start(TIMER)
- TIMER_Pause(TIMER)
- TIMER_Clear(TIMER)
- TIMER_SleepUs(TIMER, microseconds)
- TIMER_ReadUs(TIMER)


#### Examples
```c
#include "drv.h"

TIMER_Clear(TIMER);
TIMER_Start(TIMER);

while(1)
{
  // Blocking sleep
  TIMER_SleepUs(TIMER, 500000);

  uint64_t count_after_sleep = TIMER_ReadUs(TIMER);
}

Timer_Pause();
```

