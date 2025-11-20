/*------------------------------------------------------------------------------------
  Jason Wilden 2025 
  ----------------------------------------------------------------------------------*/
#ifndef __BSP_H__
#define __BSP_H__

#include <stdint.h>

/* Configuration */
#define MCU_FREQ (16000000UL)
#define SYS_FREQ (48000000UL)
#define TRACE_DIV (25UL)      /* SYS_FREQ/(115200*16)-1 = 25 */

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
    __I uint32_t SR;  /* Status register  */
    __O uint32_t TD;  /* Trace data register */    
} TRACE_t;

typedef struct
{
  __IO uint32_t CR;    /* Control register */
  __O uint32_t LO;     /* Counter low word */
  __O uint32_t HI;     /* Counter high word */
} TIMER_t;

typedef struct 
{
  __IO uint32_t CR;    /* Control register */
  __I  uint32_t WD;    /* Write data */
  __O  uint32_t RD;    /* Read data */
} I2C_t;


/* Memory map */
#define SRAM_BASE (0x00000000UL)
#define PERIPH_BASE (0x80000000UL)

/* MMIO base addresses */
#define GPO_BASE (PERIPH_BASE + 0x00UL)
#define TRACE_BASE (PERIPH_BASE + 0x40UL)
#define TIMER_BASE (PERIPH_BASE + 0x80UL)
#define I2C_BASE (PERIPH_BASE + 0xC0UL)

/* MMIO declarations */
#define GPO ((GPO_t *) GPO_BASE)
#define TRACE ((TRACE_t *) TRACE_BASE)
#define TIMER ((TIMER_t *) TIMER_BASE)
#define I2C ((I2C_t *)) I2C_BASE)


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

/* ----- TRACE REGISTERS ----------------------------------------------------------------- */

/* Control register */
#define TRACE_CR_DIV_Pos (0U)
#define TRACE_CR_DIV_Msk (0x7FFUL << TRACE_CR_DIV_Pos) /* 0x000007FF */
#define TRACE_CR_DIV (TRACE_CR_DIV_Msk)                /* [10:0] divisor */

/* Status register */
#define TRACE_SR_TDR_Pos (0U)
#define TRACE_SR_TDR_Msk (0x1UL << TRACE_SR_TDR_Pos) /* 0x00000001 */
#define TRACE_SR_TDR (TRACE_SR_TDR_Msk)              /* [0] Ready for TX */
#define TRACE_SR_RDR_Pos (1U)
#define TRACE_SR_RDR_Msk (0x1UL << TRACE_SR_RDR_Pos) /* 0x00000002 */
#define TRACE_SR_RDR (TRACE_SR_RDR_Msk)              /* [1] Ready for RX */

/* Data register, serial data out */
#define TRACE_TD_DB_Pos (0U)
#define TRACE_TD_DB_Msk (0xFFUL << TRACE_TD_DB_Pos)  /* 0x000000FF*/
#define TRACE_TD_DB (TRACE_TD_DB_Msk)                /* [7:0] output data byte */

/* ----- TIMER REGISTERS ----------------------------------------------------------------- */

/* Control register */
#define TIMER_CR_RUN_Pos (0U)
#define TIMER_CR_RUN_Msk (0x1UL << TIMER_CR_RUN_Pos)
#define TIMER_CR_RUN (TIMER_CR_RUN_Msk)             /* [0] start/stop timer running */
#define TIMER_CR_CLR_Pos (1U)
#define TIMER_CR_CLR_Msk (0x1UL << TIMER_CR_CLR_Pos)
#define TIMER_CR_CLR (TIMER_CR_CLR_Msk)             /* [1] clear timer counter */

/* ----- I2C REGISTERS ----------------------------------------------------------------- */

/* Control register */
#define I2C_CR_DIV_Pos (0U)
#define I2C_CR_DIV_Msk (0xFFFFUL << I2C_CR_DIV_Pos) /* 0x0000FFFF */
#define I2C_CR_DIV (I2C_CR_DIV_Msk)                 /* [15:0] divisor (2**16)-1 = FFFF*/

/* Write register */
#define I2C_WD_DATA_Pos (0U)                        /* 0x000000FF */
#define I2C_WD_DATA_Msk (0xFFUL)                    /* [7:0] data */
#define I2C_WD_DATA (I2C_WD_DATA_Msk)
#define I2C_WD_CMD_Pos (8U)                         /* 0x00000100 */
#define I2C_WD_CMD_Msk (0x07UL)                     /* [10:8] command */
#define I2C_WD_CMD (I2C_WD_CMD)

/* Read register */
#define I2C_RD_DATA_Pos (0U)                        /* 0x000000FF */
#define I2C_RD_DATA_Msk (0xFFUL)                    /* [7:0] data */
#define I2C_RD_DATA (I2C_RD_DATA_Msk)
#define I2C_WD_RDY_Pos (8U)                         /* 0x00000100 */
#define I2C_WD_RDY_Msk (0x01UL)                     /* [8] ready */
#define I2C_WD_RDY (I2C_WD_RDY_Msk)
#define I2C_WD_ACK_Pos (9U)                         /* 0x00000200 */
#define I2C_WD_ACK_Msk (0x01UL)                     /* [9] ack bit */
#define I2C_WD_ACK (I2C_WD_ACK_Msk)

#endif /* __BSP_H__ */

