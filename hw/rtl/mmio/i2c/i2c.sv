//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none
`include "../../common_defs.svh"

module i2c
(
  input `VAR  logic        clk_i,
  input `VAR  logic        rst_ni,
  input `VAR  logic        clk_mcu_i,
  input `VAR  logic        rst_mcu_ni,
  input `VAR  logic        select_i,
  
       

  output      logic        mem_ready_o,    
  input `VAR  logic [3:0]  mem_wstrb_i,    
  input `VAR  logic [31:0] mem_addr_i,     
  input `VAR  logic [31:0] mem_wdata_i,    
  output      logic [31:0] mem_rdata_o     
);


assign mem_ready_o = select_i;
assign mem_rdata_o = 32'h0;

endmodule
