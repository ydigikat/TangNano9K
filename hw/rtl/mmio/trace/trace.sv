//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none
`include "../../common_defs.svh"


module trace
(
  input `VAR  logic        clk_i,
  input `VAR  logic        rst_ni,
  input `VAR  logic        clk_mcu_i,
  input `VAR  logic        rst_mcu_ni,
  input `VAR  logic        select_i,   
  output      logic        trace_o,       

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
localparam SR = 4'h01;                   // Status  
localparam TD = 4'h02;                   // TX Data
localparam RD = 4'h03;                   // RX Data

//------------------------------------------------------------------------------
// Determine operation
//------------------------------------------------------------------------------
logic wr_divisor, wr_uart, rd_status;

assign wr_divisor = (|mem_wstrb_i && select_i && (mem_addr_i[5:2] == CR));
assign wr_uart = (|mem_wstrb_i && select_i && (mem_addr_i[5:2] == TD));
assign rd_status = (select_i && mem_addr_i[5:2] == SR);


//------------------------------------------------------------------------------
// State registers
//------------------------------------------------------------------------------
logic [10:0] div, div_next;
logic [7:0]  data, data_next;
logic send, send_next;

always_ff @(posedge clk_mcu_i) begin
  if(!rst_mcu_ni) begin
    div <= 0;
    data <= 0;
    send <= 0;    
  end else begin
    div <= div_next;
    data <= data_next;
    send <= send_next;    
  end
end

//------------------------------------------------------------------------------
// Next state logic
//------------------------------------------------------------------------------
always_comb begin  
  data_next = data;
  
  div_next = (wr_divisor ? mem_wdata_i[10:0] : div);  

  send_next = 1'b0;  

  if(wr_uart && done) begin
    data_next = mem_wdata_i[7:0];
    send_next = 1'b1;
  end 
end

logic mem_ready;

always_ff @(posedge clk_mcu_i) begin
  if(!rst_mcu_ni) begin
    mem_ready <= 1'b0;    
  end else begin
    mem_ready <= (wr_uart ? done : select_i);          
  end
end



//------------------------------------------------------------------------------
// UART peripherals
//------------------------------------------------------------------------------
logic tx, done;

uart_tx utx (
  .clk_i(clk_i),
  .rst_ni(rst_ni),  
  .div_i(div),
  .data_i(data),
  .tx_start_i(send),
  .tx_done_o(done),
  .tx_o(tx)
);

//------------------------------------------------------------------------------
// Output logic
//------------------------------------------------------------------------------
assign trace_o = tx;
assign mem_rdata_o = (rd_status ? {31'h0,done} : 32'h0);
assign mem_ready_o = mem_ready;


endmodule

`default_nettype wire