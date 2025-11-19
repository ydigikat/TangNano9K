//-----------------------------------------------------------------------------
// Jason Wilden 2025
//-----------------------------------------------------------------------------
`default_nettype none
`include "common_defs.svh"

module buffer #(
    parameter unsigned BUF_SIZE=16,
    parameter unsigned DATA_WIDTH=8,
    parameter unsigned BUF_ADDR_SIZE=$clog2(BUF_SIZE)
) (
    input `VAR logic                   clk_i,
    input `VAR logic                   rst_ni,

    input `VAR logic                   wr_i, rd_i,
    input `VAR logic[DATA_WIDTH-1:0]   wdata_i,
    output logic[DATA_WIDTH-1:0]       rdata_o,

    output logic                      empty_o,
    output logic                      full_o
);



  typedef logic [BUF_ADDR_SIZE-1:0] buf_ptr_t;

  logic [DATA_WIDTH-1:0] buffer[BUF_SIZE];
  buf_ptr_t head, head_next;
  buf_ptr_t tail, tail_next;
  logic full_flag, full_flag_next;

  //-----------------------------------------------------------------------------
  // State registers
  //-----------------------------------------------------------------------------
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      head <= 0;
      tail <= 0;
      full_flag <= 0;
    end else begin
      head <= head_next;
      tail <= tail_next;
      full_flag <= full_flag_next;
    end
  end

  //-----------------------------------------------------------------------------
  // Buffer write
  //-----------------------------------------------------------------------------
  always_ff @(posedge clk_i) begin
    if (wr_i && !full_o) begin
      buffer[head] <= wdata_i;
    end
  end

  //-----------------------------------------------------------------------------
  // Next state logic
  //-----------------------------------------------------------------------------
  always_comb begin
    head_next = head;
    tail_next = tail;
    full_flag_next = full_flag;

    if (wr_i && !full_o) begin
      head_next = head + 1;  // Natural wraparound for power-of-2 sizes
      if (head_next == tail && !rd_i) begin
        full_flag_next = 1;
      end
    end

    if (rd_i && !empty_o) begin
      tail_next = tail + 1;  // Natural wraparound for power-of-2 sizes
      full_flag_next = 0;
    end
  end

  //-----------------------------------------------------------------------------
  // Output logic
  //-----------------------------------------------------------------------------
  assign rdata_o = buffer[tail];
  assign empty_o = (head == tail) && !full_flag;
  assign full_o = full_flag;

endmodule

`default_nettype wire