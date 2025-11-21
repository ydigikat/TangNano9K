//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
// Non parametric UART, 8N1
//------------------------------------------------------------------------------
`default_nettype none
`include "../../common_defs.svh"

module uart_tx (
  input `VAR  logic         clk_i,
  input `VAR  logic         rst_ni,
  input `VAR  logic[10:0]   div_i,
  input `VAR  logic[7:0]    data_i,
  input `VAR  logic         tx_start_i,
  output      logic         tx_done_o, 
  output      logic         tx_o
);

//-----------------------------------------------------------------------------
// States
//-----------------------------------------------------------------------------
typedef enum logic[2:0] 
{  
  Idle,
  Start,
  Data,
  Stop
} uart_state_t;

//------------------------------------------------------------------------------
// State registers
//------------------------------------------------------------------------------
uart_state_t state, state_next;
logic[10:0] sample_div, sample_div_next;
logic[3:0] sample_cnt, sample_cnt_next;
logic[2:0] bit_cnt, bit_cnt_next;
logic[7:0] data, data_next;

logic tx, tx_next;

always_ff @(posedge clk_i) begin
  if(!rst_ni) begin
    state <= Idle;
    bit_cnt <= 0;
    sample_cnt <= 0;
    data <= 0;    
    tx <= 1'b1;
  end else begin
    state <= state_next;
    bit_cnt <= bit_cnt_next;
    sample_cnt <= sample_cnt_next;
    data <= data_next;
    tx <= tx_next;
  end
end

//------------------------------------------------------------------------------
// Sample count divider. This generates pulses at 16 x the Baud rate, these are
// used to time the length of the transmitted data bits.  The receiving UART
// will sample them at the same rate.  This is often referred to as a baud
// rate generator.
//------------------------------------------------------------------------------
always_ff @(posedge clk_i) begin
  if(!rst_ni) sample_div <= 0;
  else sample_div <= sample_div_next;
end

logic sample_inc;
assign sample_div_next = (sample_div == div_i) ? 11'd0 : sample_div + 11'd1;
assign sample_inc = (sample_div == div_i);

//------------------------------------------------------------------------------
// Next state logic, this drives the state machine.
//------------------------------------------------------------------------------
always_comb begin
  state_next = state;
  bit_cnt_next = bit_cnt;
  sample_cnt_next = sample_cnt;
  data_next = data;
  tx_next = tx;  

  unique case(state) 
    
    // Hold line high until we get a start request from the caller.
    Idle: begin
      tx_next = 1'b1;
      if(tx_start_i) begin
        state_next = Start;
        sample_cnt_next = 0;
        data_next = data_i;
      end
    end

    // Send start bit by holding the line low for 15 samples.
    Start: begin
      tx_next = 1'b0;
      if(sample_inc) begin
        if(sample_cnt == 'd15) begin
          state_next = Data;
          sample_cnt_next = 0;
          bit_cnt_next = 0;
        end else begin
          sample_cnt_next = sample_cnt + 1'b1;
        end
      end
    end
    
    // Shift out the data bits, every 16 samples
    Data: begin
      tx_next = data[0];
      if(sample_inc) begin
        if(sample_cnt == 'd15) begin
          sample_cnt_next = 0;
          data_next = data >> 1'b1;

          if(bit_cnt == 7) begin
            state_next = Stop;
          end else begin
            bit_cnt_next = bit_cnt + 1'b1;
          end
        end else begin
          sample_cnt_next = sample_cnt + 1'b1;
        end
      end
    end
    
    // Signal stop bit, this lasts for 16 samples.
    Stop: begin
      tx_next = 1'b1;
      if(sample_inc) begin
        if(sample_cnt == 'd15) begin
          state_next = Idle;          
        end else begin
          sample_cnt_next = sample_cnt + 1'b1;
        end
      end
    end

    // Avoid latches
    default:state_next = state;

  endcase
end

//------------------------------------------------------------------------------
// outputs
//------------------------------------------------------------------------------
assign tx_o = tx;
assign tx_done_o = (state == Idle);       // If we're idle then we're also done.

endmodule

`default_nettype wire