/*------------------------------------------------------------------------------------
  Jason Wilden 2025 
  ----------------------------------------------------------------------------------*/
#ifndef __BSP_H__
#define __BSP_H__

#include <stdint.h>

/* Configuration */
#define MCU_FREQ (16000000UL)
#define SYS_FREQ (48000000UL)
#define UART_DIV (25UL)      /* SYS_FREQ/(115200*16)-1 = 25 */

/* Bit helpers */
#define SET_BIT(REG, BIT) ((REG) |= (BIT))
#define CLEAR_BIT(REG, BIT) ((REG) &= ~(BIT))
#define READ_BIT(REG, BIT) ((REG) & (BIT))
#define CLEAR_REG(REG) ((REG) = (0x0))
#define WRITE_REG(REG, VAL) ((REG) = (VAL))
#define READ_REG(REG) ((REG))
#define MODIFY_REG(REG, CLEARMASK, SETMASK) WRITE_REG((REG), (((READ_REG(REG)) & (~(CLEARMASK))) | (SETMASK)))
#define _VAL2FLD(field, value) (((uint32_t)(value) << field##_Pos) & field##_Msk)
#define _FLD2VAL(field, value) (((uint32_t)(value) & field##_Msk) >> field##_Pos)

/* Access restrictors */
#define __I volatile const
#define __O volatile
#define __IO volatile

/* Register structures */
typedef struct
{
  __IO uint32_t BSR; /* Bit set/reset register  */
} GPO_t;

typedef struct 
{
    __IO uint32_t CR; /* Control register */
    __I uint32_t SR;  /* Status reigster  */
    __O uint32_t TD;  /* TX data register */
    __I uint32_t RD;  /* RX data register */
} UART_t;

typedef struct
{
  __IO uint32_t CR;    /* Control register */
  __O uint32_t LO;     /* Counter low word */
  __O uint32_t HI;     /* Counter high word */
} TIMER_t;

/* Memory map */
#define SRAM_BASE (0x00000000UL)
#define PERIPH_BASE (0x80000000UL)

/* MMIO base addresses */
#define GPO_BASE (PERIPH_BASE + 0x00UL)
#define UART_BASE (PERIPH_BASE + 0x40UL)
#define TIMER_BASE (PERIPH_BASE + 0x80UL)

/* MMIO declarations */
#define GPO ((GPO_t *) GPO_BASE)
#define UART ((UART_t *) UART_BASE)
#define TIMER ((TIMER_t *) TIMER_BASE)


/* ----- GPO REGISTERS ----------------------------------------------------------------- */

/* Data register - pins */
#define GPO_BSR_0_Pos (0U)
#define GPO_BSR_0_Msk (0x1UL << GPO_BSR_0_Pos)
#define GPO_BSR_0 GPO_BSR_0_Msk
#define GPO_BSR_1_Pos (1U)
#define GPO_BSR_1_Msk (0x1UL << GPO_BSR_1_Pos)
#define GPO_BSR_1 GPO_BSR_1_Msk
#define GPO_BSR_2_Pos (2U)
#define GPO_BSR_2_Msk (0x1UL << GPO_BSR_2_Pos)
#define GPO_BSR_2 GPO_BSR_2_Msk
#define GPO_BSR_3_Pos (3U)
#define GPO_BSR_3_Msk (0x1UL << GPO_BSR_3_Pos)
#define GPO_BSR_3 GPO_BSR_3_Msk
#define GPO_BSR_4_Pos (4U)
#define GPO_BSR_4_Msk (0x1UL << GPO_BSR_4_Pos)
#define GPO_BSR_4 GPO_BSR_4_Msk
#define GPO_BSR_5_Pos (5U)
#define GPO_BSR_5_Msk (0x1UL << GPO_BSR_5_Pos)>
#define GPO_BSR_5 GPO_BSR_5_Msk
#define GPO_BSR_6_Pos (6U)
#define GPO_BSR_6_Msk (0x1UL << GPO_BSR_6_Pos)
#define GPO_BSR_6 GPO_BSR_6_Msk
#define GPO_BSR_7_Pos (7U)
#define GPO_BSR_7_Msk (0x1UL << GPO_BSR_7_Pos)
#define GPO_BSR_7 GPO_BSR_7_Msk
#define GPO_BSR_8_Pos (8U)
#define GPO_BSR_8_Msk (0x1UL << GPO_BSR_8_Pos)
#define GPO_BSR_8 GPO_BSR_8_Msk
#define GPO_BSR_9_Pos (9U)
#define GPO_BSR_9_Msk (0x1UL << GPO_BSR_9_Pos)
#define GPO_BSR_9 GPO_BSR_9_Msk
#define GPO_BSR_10_Pos (10U)
#define GPO_BSR_10_Msk (0x1UL << GPO_BSR_10_Pos)
#define GPO_BSR_10 GPO_BSR_10_Msk
#define GPO_BSR_11_Pos (11U)
#define GPO_BSR_11_Msk (0x1UL << GPO_BSR_11_Pos)
#define GPO_BSR_11 GPO_BSR_11_Msk
#define GPO_BSR_12_Pos (12U)
#define GPO_BSR_12_Msk (0x1UL << GPO_BSR_12_Pos)
#define GPO_BSR_12 GPO_BSR_12_Msk
#define GPO_BSR_13_Pos (13U)
#define GPO_BSR_13_Msk (0x1UL << GPO_BSR_13_Pos)
#define GPO_BSR_13 GPO_BSR_13_Msk
#define GPO_BSR_14_Pos (14U)
#define GPO_BSR_14_Msk (0x1UL << GPO_BSR_14_Pos)
#define GPO_BSR_14 GPO_BSR_14_Msk
#define GPO_BSR_15_Pos (15U)
#define GPO_BSR_15_Msk (0x1UL << GPO_BSR_15_Pos)
#define GPO_BSR_15 GPO_BSR_15_Msk

/* ----- UART REGISTERS ----------------------------------------------------------------- */

/* Control register */
#define UART_CR_DIV_Pos (0U)
#define UART_CR_DIV_Msk (0x7FFUL << UART_CR_DIV_Pos) /* 0x000007FF */
#define UART_CR_DIV (UART_CR_DIV_Msk)                /* [10:0] divisor (2**11)-1 = 7FF*/

/* Status register */
#define UART_SR_TDR_Pos (0U)
#define UART_SR_TDR_Msk (0x1UL << UART_SR_TDR_Pos) /* 0x00000001 */
#define UART_SR_TDR (UART_SR_TDR_Msk)              /* [0] Ready for TX */

#define UART_SR_RDR_Pos (1U)
#define UART_SR_RDR_Msk (0x1UL << UART_SR_RDR_Pos) /* 0x00000002 */
#define UART_SR_RDR (UART_SR_RDR_Msk)              /* [1] Ready for RX */

/* Data register, serial data out */
#define UART_TD_DB_Pos (0U)
#define UART_TD_DB_Msk (0xFFUL << TRACE_TD_DB_Pos)  /* 0x000000FF*/
#define UART_TD_DB (TRACE_TD_DB_Msk)                /* [7:0] output data byte */

/* ----- TIMER REGISTERS ----------------------------------------------------------------- */

/* Control register */
#define TIMER_CR_RUN_Pos (0U)
#define TIMER_CR_RUN_Msk (0x1UL << TIMER_CR_RUN_Pos)
#define TIMER_CR_RUN (TIMER_CR_RUN_Msk)             /* [0] start/stop timer running */
#define TIMER_CR_CLR_Pos (1U)
#define TIMER_CR_CLR_Msk (0x1UL << TIMER_CR_CLR_Pos)
#define TIMER_CR_CLR (TIMER_CR_CLR_Msk)             /* [1] clear timer counter */

#endif /* __BSP_H__ */

