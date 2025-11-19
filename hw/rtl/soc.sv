//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
// This is a simple SOC used for control plane functions.  It uses the Yosys
// picorv32 with the native memory interface.  No modules generate IRQs.
//------------------------------------------------------------------------------
`default_nettype none
`include "common_defs.svh"

module soc #( parameter WORD_ADDRESS_WIDTH,
                    REGS,
                    PERIPH_BASE_ADDR,
                    MCU_FREQ,
                    B0_MEM_FILE,
                    B1_MEM_FILE,
                    B2_MEM_FILE,
                    B3_MEM_FILE)
(
  input `VAR logic clk_i,           // 48MHz system clock
  input `VAR logic rst_ni,
  input `VAR logic clk_mcu_i,       // 16MHz MCU clock
  input `VAR logic rst_mcu_ni,  

  output logic trap_o,

  output logic[15:0] gpo_o,  
  output logic trace_o,    
  input  `VAR logic midi_i,

  output logic[15:0] dio_o  
);

//------------------------------------------------------------------------------
// Native memory interface signals
//------------------------------------------------------------------------------
logic        mem_valid;   // High when core access memory (fetch, load or store)
logic        mem_instr;   // High if fetching an instruction, low for data.
logic        mem_ready;   // Ack from memory/peripheral that access is complete.
logic [31:0] mem_addr;    // 32-bit byte address of memory accessed.
logic [31:0] mem_wdata;   // 32-bit data to be written;
logic [3:0]  mem_wstrb;   // Indicates active bytes in write data 0-3, 0+1, 2+3
logic [31:0] mem_rdata;   // 32-bit data read.
logic        trap;        // Indicates an untrapped processor fault.

//------------------------------------------------------------------------------
// Memory map
//------------------------------------------------------------------------------
localparam SRAM_SIZE = (1 << (WORD_ADDRESS_WIDTH + 2));   
localparam GPO_BASE   = PERIPH_BASE_ADDR  +'h00;            
localparam UART_BASE =   PERIPH_BASE_ADDR +'h40;           
localparam TIM_BASE =   PERIPH_BASE_ADDR  +'h80;  
localparam I2C_BASE =   PERIPH_BASE_ADDR  +'hC0;          

//------------------------------------------------------------------------------
// PicoRV32 RISC V soft core processor (https://github.com/YosysHQ/picorv32)
//------------------------------------------------------------------------------
picorv32 #(
  .STACKADDR(SRAM_SIZE-4),   
  .PROGADDR_RESET(32'h00000000)  
) mcu (
  .clk(clk_mcu_i),
  .resetn(rst_mcu_ni),
  .trap(trap),

  .mem_valid(mem_valid),
  .mem_instr(mem_instr),
  .mem_ready(mem_ready),
  .mem_addr(mem_addr),
  .mem_wdata(mem_wdata),
  .mem_wstrb(mem_wstrb),
  .mem_rdata(mem_rdata),

   // Unused (reduce warning noise)
  .irq(32'h0),
  .eoi(),
  .trace_valid(),
  .trace_data(),
  .pcpi_valid(),
  .pcpi_insn(),
  .pcpi_rs1(),
  .pcpi_rs2(),// 8000_00
  .pcpi_wr(1'b0),
  .pcpi_rd(32'h0),
  .pcpi_wait(1'b0),
  .pcpi_ready(1'b0)
);  	

//------------------------------------------------------------------------------
// MCU trap handler
//------------------------------------------------------------------------------
assign trap_o = trap;

//------------------------------------------------------------------------------
// Address decoding - module select based on address being accessed
//------------------------------------------------------------------------------
logic sram_sel, gpo_sel, uart_sel, timer_sel, i2c_sel;

// SRAM selector (stating at 0x00000000)
assign sram_sel =  mem_valid && (mem_addr  < SRAM_SIZE);  

// Peripheral selectors (starting at 0x80000000)
assign gpo_sel =   mem_valid && (mem_addr >= GPO_BASE && mem_addr < UART_BASE);
assign uart_sel = mem_valid && (mem_addr >= UART_BASE && mem_addr < TIM_BASE);
assign timer_sel = mem_valid && (mem_addr >= TIM_BASE && mem_addr < I2C_BASE);
assign i2c_sel = mem_valid && (mem_addr >= I2C_BASE && mem_addr < I2C_BASE + 'h40);

//------------------------------------------------------------------------------
// Read data multiplexing
//------------------------------------------------------------------------------
logic sram_rdy, gpo_rdy, uart_rdy, timer_rdy, i2c_rdy;
logic [31:0] sram_rdata,uart_rdata, gpo_rdata, timer_rdata, i2c_rdata;

// Data access complete
assign mem_ready = mem_valid && (sram_rdy | gpo_rdy | uart_rdy | timer_rdy | i2c_rdy);

// Select the correct read data bus
assign mem_rdata =  sram_sel ? sram_rdata  :                     
                    gpo_sel ? gpo_rdata :
                    uart_sel ? uart_rdata : 
                    timer_sel ? timer_rdata :
                    i2c_sel ? i2c_rdata :
                    32'h0;                 

//------------------------------------------------------------------------------
// SRAM module. 
//------------------------------------------------------------------------------
sram #(
  .WORD_ADDRESS_WIDTH(WORD_ADDRESS_WIDTH),
  .B0_MEM_FILE(B0_MEM_FILE),
  .B1_MEM_FILE(B1_MEM_FILE),
  .B2_MEM_FILE(B2_MEM_FILE),
  .B3_MEM_FILE(B3_MEM_FILE)
) ram (
  .clk_i(clk_mcu_i),
  .rst_ni(rst_mcu_ni),
  .select_i(sram_sel),
  .mem_ready_o(sram_rdy),
  .mem_addr_i(mem_addr),   
  .mem_wstrb_i(mem_wstrb),
  .mem_wdata_i(mem_wdata),
  .mem_rdata_o(sram_rdata)
);

//------------------------------------------------------------------------------
// GPO (general purpose output) module.
//------------------------------------------------------------------------------
gpo gp(  
  .clk_i(clk_i),
  .rst_ni(rst_ni),
  .clk_mcu_i(clk_mcu_i),
  .rst_mcu_ni(rst_mcu_ni),
  .select_i(gpo_sel),
  .gpo_o(gpo_o),
  .mem_ready_o(gpo_rdy),
  .mem_addr_i(mem_addr),
  .mem_wstrb_i(mem_wstrb),
  .mem_wdata_i(mem_wdata),
  .mem_rdata_o(gpo_rdata)  
);


//------------------------------------------------------------------------------
// Trace (serial printf) module.
//------------------------------------------------------------------------------
trace tc(
  .clk_i(clk_i),
  .rst_ni(rst_ni),
  .clk_mcu_i(clk_mcu_i),                
  .rst_mcu_ni(rst_mcu_ni),  
  .select_i(uart_sel),
  .trace_o(trace_o),  
  .mem_ready_o(uart_rdy),
  .mem_addr_i(mem_addr),
  .mem_wstrb_i(mem_wstrb),
  .mem_wdata_i(mem_wdata),
  .mem_rdata_o(uart_rdata)
);

//------------------------------------------------------------------------------
// Timer (simple counter) module
//------------------------------------------------------------------------------
timer #(.MCU_FREQ(MCU_FREQ)) tim
(
  .clk_i(clk_i),
  .rst_ni(rst_ni),
  .clk_mcu_i(clk_mcu_i),                
  .rst_mcu_ni(rst_mcu_ni),  
  .select_i(timer_sel),  
  .mem_ready_o(timer_rdy),
  .mem_addr_i(mem_addr),
  .mem_wstrb_i(mem_wstrb),
  .mem_wdata_i(mem_wdata),
  .mem_rdata_o(timer_rdata)
);

//------------------------------------------------------------------------------
// I2C module
//------------------------------------------------------------------------------
i2c i2c
(
  .clk_i(clk_i),
  .rst_ni(rst_ni),
  .clk_mcu_i(clk_mcu_i),                
  .rst_mcu_ni(rst_mcu_ni),  
  .select_i(i2c_sel),  
  .mem_ready_o(i2c_rdy),
  .mem_addr_i(mem_addr),
  .mem_wstrb_i(mem_wstrb),
  .mem_wdata_i(mem_wdata),
  .mem_rdata_o(i2c_rdata)
);

//------------------------------------------------------------------------------
// Logic analyser outputs
//------------------------------------------------------------------------------
assign dio_o = {15'h0,trace_o};


endmodule

`default_nettype wire