# GPO

The general purpose output port has a single 32-bit set/reset register, ```GPO->BSR```.

The SOC module exposes a gpo_port[15:0] bus which is used by the design to assign physical output pins, these can be off-chip or to the onboard peripherals.  The physical characteristics of the pin (pull-up, vcc etc) are defined in the physical constraint file and are not programmable or assignable to specific pins through the GPO port itself.

The ```BSR``` register is a 32-bit register which allows the setting and resetting of individual output bits in the GPO module. The register contains 2 bits for each output, a set bit and a reset bit.  The BSR is used as the output register directly and it cannot be read so there is no way to obtain the current status of a GPO pin.

## Registers

### GPO bit set/reset register (BSR)
**Address offset:** 0x00  
**Reset value:** 0x0000_0000

| Bits | Access | Purpose |
|------|--------|---------|
|31-16 | Write  | Reset (clear) GPO pins 15-0 |
|15-0  | Write  | Set GPO pins 15-0 |

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


#### Examples
```c
#include "drv.h"

/* Set pins */
GPO_SetPin(GPO,GPO_PIN_0|GPO_PIN_1);


/* Clear (reset) pins */
GPO_ClearPin(GPO,GPO_PIN_0|GPO_PIN_1);

```











