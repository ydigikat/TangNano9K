# SOC Modules (MMIO)
The SOC peripherals are implemented as memory mapped IO devices (MMIO) with a memory map providing for upto 16 32-bit registers for each device.  

The peripherals can be controlled by directly settings and reading bits in the registers which are defined in the ```bsp.h``` header file.  

The ```bsp.h``` file is similar to the ARM CMSIS hardware abstraction layer.  It defines the register structures for each peripheral and a number of masks to assist in writing bits to the registers.  In addition it includes a set of helper bit and register accessor macros.

For example:
```c
SET_BIT(TIMER1->CR, TIMER_CR_CLEAR);
SET_BIT(TIMER1->CR, TIMER_CR_RUN);

uint64_t us_start = ((uint64_t)READ_REG(TIMER1->LO)) |
                   ((uint64_t)READ_REG(TIMER1->HI) << 32UL);

/* Do something that takes a while */

uint64_t us_stop = ((uint64_t)READ_REG(TIMER1->LO)) |
                   ((uint64_t)READ_REG(TIMER1->HI) << 32UL);

```

While it is possible to use these macros directly, the project provides driver functions which wrap these low level macros.  In general these result is more understandable code with little or no overhead.


## Drivers
Drivers are supplied for the MMIO devices provided by the SOC.  These are divided into 2 distinct types of function:

1. Low-level driver functions.
2. High-level driver functions.

The low-level driver functions are thin wrappers around direct register access.  These always take the peripheral instance (address) as their first parameter.  Since these are passed an instance they are able to support more than one peripheral of the same kind (providing the SOC has also instatiated these).

For example:

```c
I2C_SetDivisor(I2C1,I2C_DIV_STD);
I2C_Start(I2C1);
I2C_WriteByte(I2C1,addr);
uint8_t ret = I2C_ReadByte(I2C1,false);
I2C_Stop(I2C1);
```

The high-level driver functions are fewer than the low-level and typically contain software functions that orchestrate a set of lower-level functions. These also take an instance parameter.

For example:
```c
i2c_init(I2C1);
uint8_t sent = i2c_write_transaction(I2C1,address, byte_array, 10, false);
```

## Peripherals
| Peripheral | Documentation|
| ---------- | -------------|
| GPO1       | [GPO](gpo.md)|
| I2C1       | [I2C](i2c.md)|
| TIMER1     | [TIMER](timer.md)|
| TRACE      | [TRACE](trace.md)|
| MIDI_IN    | [MIDI](midi.md)|
