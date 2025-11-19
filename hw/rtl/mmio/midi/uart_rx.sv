//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------

`default_nettype none
`include "../../common_defs.svh"


module uart_rx 
(
  input `VAR  logic        clk_i,
  input `VAR  logic        rst_ni,
  input `VAR  logic[10:0]  div_i,
  input `VAR  logic        rx_i,
  output      logic        rx_done_o,
  output      logic[7:0]   data_o
);

//---------------------------------------------------------------------------
// State registers
//---------------------------------------------------------------------------
uart_state_t state, state_next;
logic [10:0] sample_div, sample_div_next;
logic [3:0] sample_cnt, sample_cnt_next;
logic[2:0] bit_cnt, bit_cnt_next;
logic [7:0] data, data_next;

always_ff @(posedge clk_i) begin
  if (!rst_ni) begin
    state <= Idle;
    sample_div <= 0;
    sample_cnt <= 0;
    bit_cnt <= 0;
    data <= 0;      
  end else begin
    state <= state_next;
    sample_div <= sample_div_next;
    sample_cnt <= sample_cnt_next;
    bit_cnt <= bit_cnt_next;
    data <= data_next;          
  end
end

//------------------------------------------------------------------------------
// Sample count divider. 
//------------------------------------------------------------------------------
logic sample_inc;
assign sample_div_next = (sample_div == div_i) ? 11'd0 : sample_div + 11'd1;
assign sample_inc = (sample_div == div_i);

//---------------------------------------------------------------------------
// Next state logic
//---------------------------------------------------------------------------
always_comb begin
  state_next = state;
  rx_done_o = 1'b0;
  sample_cnt_next = sample_cnt;
  bit_cnt_next = bit_cnt;
  data_next = data;

  unique case (state)
    // Stay in idle until we see the line go low. 
    Idle: begin
      if (!rx_i) begin
        state_next = Start;
        sample_cnt_next = 0;
      end
    end

    Start:begin
      // Walk 7 samples into the start bit, this sets us up so that adding
      // 15 samples will place us in the middle of each of the subsequent
      // data and stop bits. 
      if (sample_inc) begin        
        if (sample_cnt == 7) begin
          state_next = Data;
          sample_cnt_next = 0;
          bit_cnt_next = 0;
        end else begin
          sample_cnt_next = sample_cnt + 'b1;
        end
      end
    end

    Data: begin
      // Receive the 8 data bits.
      if (sample_inc) begin
        if (sample_cnt == 15) begin
          sample_cnt_next = 0;
          data_next = {rx_i, data[7:1]};
          if (bit_cnt == 7) begin
            state_next = Stop;
          end else begin
            bit_cnt_next = bit_cnt + 1'b1;
          end
        end else begin
          sample_cnt_next = sample_cnt + 1'b1;
        end
      end
    end

    Stop: begin
      // Wait for the single stop bit to pass before indicating
      // that we're done and returning to Idle state.
      if (sample_inc) begin
        if (sample_cnt == 15) begin
          state_next = Idle;
          rx_done_o = 1'b1;
        end else begin
          sample_cnt_next = sample_cnt + 1'b1;
        end
      end
    end

    default: state_next = state;

  endcase
end

//---------------------------------------------------------------------------
// Output logic
//---------------------------------------------------------------------------
assign data_o = data;

endmodule

`default_nettype wire