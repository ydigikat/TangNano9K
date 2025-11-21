//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none
`include "common_defs.svh"

module tangnano9k_top (
    input `VAR  logic    clk_i,  

    output      logic        ftdi_o,  
    input `VAR  logic        midi_i,
    output      logic[4:0]   led_o,    
    output      logic        led_trap_o,    
    output      logic        i2c_scl_o,
    inout       tri          i2c_sda_io,

    output      logic[15:0]  dio_o 
);

  localparam MCU_FREQ=16_000_000;


  //------------------------------------------------------------------------------
  // Clock and reset generation.
  //------------------------------------------------------------------------------
  logic clk, clk_mcu;
  logic rst_n, rst_mcu_n;

  clock_gen cg (
      .clk_i        (clk_i),        
      .clk_o        (clk),          // System clock (48MHz)
      .rst_no       (rst_n),      
      .clk_mcu_o    (clk_mcu),      // MCU clock (16MHz)
      .rst_mcu_no   (rst_mcu_n)
  );


  //------------------------------------------------------------------------------
  // MCU (SOC)
  //------------------------------------------------------------------------------
  logic trap;
  logic[15:0] gpo;

  soc #(
     .WORD_ADDRESS_WIDTH('d12),       // SRAM 16KB (4096 words)
     .REGS('d16),
     .MCU_FREQ(MCU_FREQ),
     .PERIPH_BASE_ADDR('h8000_0000),
     .B0_MEM_FILE(`B0_MEM_FILE),
     .B1_MEM_FILE(`B1_MEM_FILE),
     .B2_MEM_FILE(`B2_MEM_FILE),
     .B3_MEM_FILE(`B3_MEM_FILE)
  )
  sc (
    .clk_i(clk),
    .rst_ni(rst_n),
    .clk_mcu_i(clk_mcu),
    .rst_mcu_ni(rst_mcu_n),        
    .trap_o(trap),    
    .trace_o(ftdi_o),    
    .midi_i(midi_i),
    .dio_o(dio_o),
    .gpo_o(gpo)
  );



  //------------------------------------------------------------------------------
  // Outputs
  //------------------------------------------------------------------------------
  assign led_o = (~gpo[4:0]);  
  assign led_trap_o = ~trap;

  endmodule


`default_nettype wire
