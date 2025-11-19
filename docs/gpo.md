# GPO

The general purpose output port has a single 32-bit set/reset register, ```GPO->BSR```.

The SOC module exposes a gpo_port[15:0] bus which is used by the design to assign physical output pins, these can be off-chip or to the onboard peripherals.  The physical characteristics of the pin (pull-up, vcc etc) are defined in the physical constraint file and are not programmable or assignable to specific pins through the GPO port itself.

The ```BSR``` register is a 32-bit register which allows the setting and resetting of individual output bits in the GPO module. The register contains 2 bits for each output, a set bit and a reset bit.  In the event of both a set and reset being set for a bit at the same time, the set takes priority.

## Registers

### GPO bit set/reset register (BSR)
**Address offset:** 0x00  
**Reset value:** 0x0000_0000

|31 |30 |29 |28 |27 |26 |25 |24 |23 |22 |21 |20 |19 |18 |17 |16 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|R15|R14|R13|R12|R11|R10|R9 |R8 |R7 |R6 |R5 |R4 |R3 |R2 |R1 |R0 |
| W | W |W | W |W | W |W | W |W | W |W | W |W | W |W | W |W | W |

|15 |14 |13 |12 |11 |10 |9  |8  |7  |6  |5  |4  |3  |2  |1  |0  |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|S15|S14|S13|S12|S11|S10|S9 |S8 |S7 |S6 |S5 |S4 |S3 |S2 |S1 |S0 |
| W | W |W | W |W | W |W | W |W | W |W | W |W | W |W | W |W | W |

```R15-R0``` [31:16]  : Reset (clear) bit 15-0.  
```S15-S0``` [15:0]   : Set bit 15-0.  

Setting either R or S to 0 has no effect.  Setting S1 to 1 will set bit 1, setting R1 to 1 will clear bit 1 and so on.

Reading the register returns zeroes.

#### Examples
```c
#include "bsp.h"

/* Set pins 0 and 1 */
WRITE_REG(GPO->BSR,GPO_BSR_0|GPO_BSR_1)

/* Reset pins 0 and 1 */
WRITE_REG(GPO->BSR, (GPO_BSR_0|GPO_BSR_1) << 16); 
```

## Driver 
The GPO driver provides the following functions:

- GPO_SetPin(GPO, mask) : Sets one or more pins.
- GPO_ClearPin(GPO, mask) : Resets one or more pins.
- GPO_TogglePin(GPO, mask) : Toggles one or more pins between set and reset.


#### Examples
```c
#include "drv.h"

/* Set pins */
GPO_SetPin(GPO,GPO_PIN_0|GPO_PIN_1);

/* Note: The #defines GPO_PIN_x are aliases for the GPO_BSR_x mask values, either can be used */

/* Clear (reset) pins */
GPO_ClearPin(GPO,GPO_PIN_0|GPO_PIN_1);

/* Toggle a pin */
GPO_TogglePin(GPO,GPO_PIN_5);
```











