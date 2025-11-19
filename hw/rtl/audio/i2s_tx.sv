//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
// This is a simple Philips standard I2S TX controller implementation.
//
// Data is transmitted serially, MSB first, on the negedge of the first BCLK 
// after the LRCLK going low.  
//
// A single cycle (system clock domain) req pulse is sent at the end of
// each audio frame to signal that the next sample is required.
//
// Each sample is 32 bits {16 left, 16 right}.
//------------------------------------------------------------------------------
`default_nettype none
`include "../common_defs.svh"

module i2s_tx (
  input `VAR logic       clk_i,              
  input `VAR logic       rst_ni,   
  input `VAR logic       clk_aud_i,            
  input `VAR logic       rst_aud_ni,

  // Sample
  output logic           req_o,
  input `VAR logic[31:0] sample_i,

  // I2S data
  output logic           aud_bclk_o,
  output logic           aud_lrclk_o,
  output logic           aud_sda_o
);

//------------------------------------------------------------------------------
// State registers
//------------------------------------------------------------------------------

logic sda, sda_next, aud_lrclk, aud_lrclk_next;
logic [4:0] bit_cnt, bit_cnt_next;
logic [31:0] sample, sample_next;


always_ff @(negedge clk_aud_i) begin
  if(~rst_aud_ni) begin
    bit_cnt <= 5'b0;
    aud_lrclk <= 1'b0;        
    sda <= 1'b0;
  end else begin
    bit_cnt <= bit_cnt_next;
    aud_lrclk <= aud_lrclk_next;        
    sda <= sda_next;    
  end
end

//------------------------------------------------------------------------------
// Parallel load on posedge of clock
//------------------------------------------------------------------------------
always_ff @(posedge clk_aud_i) begin
  if(~rst_aud_ni) begin
    sample <= 32'b0;
  end else begin
    sample <= sample_next;
  end
end

//------------------------------------------------------------------------------
// Next sample pulse in system clock domain synchronizer
//------------------------------------------------------------------------------
logic req, req_synq1;                                    
always_ff @(posedge clk_i) begin                  
  req_synq1 <= clk_aud_i;                              
  req <= (req_synq1 && !clk_aud_i) && !aud_lrclk && (bit_cnt == 0);                   
end

//------------------------------------------------------------------------------
// Next state logic
//------------------------------------------------------------------------------

// Serial bit counter (16 bits)
always_comb begin
  if(bit_cnt == 15) bit_cnt_next = 0;
  else bit_cnt_next = bit_cnt + 5'd1;
end

// LRCLK toggles on bit 15 - low == left channel.
always_comb begin
  aud_lrclk_next = aud_lrclk;
  if(bit_cnt == 15) aud_lrclk_next = ~aud_lrclk;
end

// Parallel load of next sample
always_comb begin
  sample_next = sample;
  if(~aud_lrclk && bit_cnt == 0) sample_next = sample_i;
end

// Serialise data out
always_comb begin
  sda_next = aud_lrclk ? sample[15-bit_cnt] : sample[31-bit_cnt];
end

//------------------------------------------------------------------------------
// Output logic
//------------------------------------------------------------------------------
assign aud_lrclk_o = aud_lrclk;
assign aud_bclk_o = clk_aud_i;      
assign req_o = req;
assign aud_sda_o = sda;

endmodule
