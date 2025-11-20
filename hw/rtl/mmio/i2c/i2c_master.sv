//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none
`include "../../common_defs.svh"

module i2c_master
(
  input `VAR  logic        clk_i,
  input `VAR  logic        rst_ni,
  input `VAR  logic        clk_mcu_i,
  input `VAR  logic        rst_mcu_ni,
  input `VAR  logic        select_i,
  
  inout       tri          i2c_sda,
  inout       tri          i2c_scl,       

  output      logic        mem_ready_o,    
  input `VAR  logic [3:0]  mem_wstrb_i,    
  input `VAR  logic [31:0] mem_addr_i,     
  input `VAR  logic [31:0] mem_wdata_i,    
  output      logic [31:0] mem_rdata_o     
);

//------------------------------------------------------------------------------
// Registers
//------------------------------------------------------------------------------
localparam CR = 4'h00;                   // Control 
localparam TD = 4'h02;                   // Write Data
localparam RD = 4'h03;                   // Read Data

//------------------------------------------------------------------------------
// Determine operation
//------------------------------------------------------------------------------
logic wr_divisor, wr_i2c, rd_i2c;

assign wr_divisor = (|mem_wstrb_i && select_i && (mem_addr_i[5:2] == CR));
assign wr_i2c = (|mem_wstrb_i && select_i && (mem_addr_i[5:2] == TD));
assign rd_i2c = (select_i && mem_addr_i[5:2] == RD);

//------------------------------------------------------------------------------
// State registers
//------------------------------------------------------------------------------
logic [15:0] div, div_next;
logic [7:0] data, data_next;
logic ready, ack;

always_ff @(posedge clk_i) begin
  if(!rst_ni) begin
    div <= 1'b0;    
    data <= 1'b0;
  end else begin
    div <= div_next;
    data <= data_next;
  end
end

always_comb begin
  
  div_next = (wr_divisor ? mem_wdata_i[15:0] : div);  
  
end

endmodule
