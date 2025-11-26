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

  inout       tri          sda_io,
  inout       tri          scl_io,

  input `VAR  logic        select_i,  
  
  output      logic        mem_ready_o,    
  input `VAR  logic [3:0]  mem_wstrb_i,    
  input `VAR  logic [31:0] mem_addr_i,     
  input `VAR  logic [31:0] mem_wdata_i,    
  output      logic [31:0] mem_rdata_o      
);

//------------------------------------------------------------------------------
// Register offsets
//------------------------------------------------------------------------------
localparam CR = 4'h00;   // Control
localparam SR = 4'h01;   // Status
localparam TX = 4'h02;   // TX data
localparam RX = 4'h03;   // RX data 

//------------------------------------------------------------------------------
// Decode addresses
//------------------------------------------------------------------------------
logic wr_cr, wr_tx, rd_rx, rd_sr;

assign wr_cr = (|mem_wstrb_i && select_i && (mem_addr_i[5:2] == CR));
assign wr_tx = (|mem_wstrb_i && select_i && (mem_addr_i[5:2] == TX));
assign rd_rx = (select_i && mem_addr_i[5:2] == RX);
assign rd_sr = (select_i && mem_addr_i[5:2] == SR);

//------------------------------------------------------------------------------
// Registers
//------------------------------------------------------------------------------
logic [7:0] tx_data;
logic [7:0] rx_data;
logic [6:0] dev_addr;
logic       read_enable;
logic       start;

logic       done;
logic       busy;
logic       ack_error;


//------------------------------------------------------------------------------
// Process
//------------------------------------------------------------------------------
always_ff @(posedge clk_mcu_i) begin
  if (!rst_mcu_ni) begin
    tx_data     <= 8'd0;
    rx_data     <= 8'd0;
    dev_addr    <= 7'd0;
    read_enable <= 1'b0;
    start       <= 1'b0;    
  end else begin
    // Defaults
    start       <= 1'b0;    

    // Write TX register
    if (wr_tx) begin
      tx_data <= mem_wdata_i[7:0];
    end

    // Write CR register, this triggers transaction
    if (wr_cr && !busy) begin
      dev_addr    <= mem_wdata_i[6:0];
      read_enable <= mem_wdata_i[7];
      start       <= 1'b1;      
    end

    // Latch RX data
    if (done) begin
      rx_data <= data_from_i2c;
    end    
  end
end

//------------------------------------------------------------------------------
// I2C controller
//------------------------------------------------------------------------------
logic [7:0] data_from_i2c;

i2c_controller #(
  .I2C_CLK_HZ(400_000),
  .SYS_CLK_HZ(16_000_000)
) ic (
  .clk_i         (clk_mcu_i),
  .rst_ni        (rst_mcu_ni),
  .start_i       (start),
  .restart_i     (1'b0),          // Tied low - not used in this project
  .read_enable_i (read_enable),
  .dev_addr_i    (dev_addr),
  .data_i        (tx_data),
  .data_o        (data_from_i2c),
  .done_o        (done),
  .busy_o        (busy),
  .ack_error_o   (ack_error),
  .sda_io        (sda_io),
  .scl_io        (scl_io)
);

//------------------------------------------------------------------------------
// Read MUX
//------------------------------------------------------------------------------
assign mem_rdata_o = rd_sr ? {29'b0, ack_error, done, busy} :
                     rd_rx ? {24'b0, rx_data} :
                     32'b0;

assign mem_ready_o = select_i;   // Single cycle response                     

endmodule