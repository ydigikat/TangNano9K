//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none `timescale 1ns / 10ps

module i2s_tx_tb ();

  //------------------------------------------------------------------------------
  // Test control
  //------------------------------------------------------------------------------
  integer test_failures = 0;
  integer test_count = 0;
  time req_pulse_time = 0;

  //------------------------------------------------------------------------------
  // Monitors
  //------------------------------------------------------------------------------
  always @(posedge clk) begin
    if (req) req_pulse_time = $time;  // request pulse in sys clock domain
  end

  //------------------------------------------------------------------------------
  // Clocks and resets
  //------------------------------------------------------------------------------
  logic clk = 0;
  always #5 clk = ~clk;

  logic aud_clk = 0;
  always #20 aud_clk = ~aud_clk;

  logic rst_n, aud_rst_n;
  initial begin
    rst_n = 0;
    aud_rst_n = 0;
    #50;
    rst_n = 1;
    aud_rst_n = 1;
  end

  //------------------------------------------------------------------------------
  // Unit under test
  //------------------------------------------------------------------------------
  logic aud_bclk, aud_lrclk, aud_sda, req;
  logic [31:0] sample;

  i2s_tx uut (
      .clk_i(clk),
      .rst_ni(rst_n),
      .clk_aud_i(aud_clk),
      .rst_aud_ni(aud_rst_n),
      .req_o(req),
      .sample_i(sample),
      .aud_bclk_o(aud_bclk),
      .aud_lrclk_o(aud_lrclk),
      .aud_sda_o(aud_sda)
  );

  //------------------------------------------------------------------------------
  // Tests
  //------------------------------------------------------------------------------

  // Check that the LRCLK/BCLK ratio is correct.
  task automatic verify_lrclk;

    integer bclk_edge_count = 0;

    // Start at a clean point  
    @(posedge aud_lrclk);
    #1;

    // Count exactly 32 BCLK edges
    repeat (32) begin
      @(negedge aud_bclk);
      bclk_edge_count += 1;
    end

    #1;

    // After 32 clocks, should be back at posedge
    if (aud_lrclk !== 1'b1) begin
      $display("FAIL: verify_lrclk, not aligned after 32 clocks");
      test_failures += 1;
    end

    if (bclk_edge_count != 32) begin
      $display("FAIL: verify_lrclk, expected 32 clock edges, got %0d", bclk_edge_count);
      test_failures += 1;
    end
    test_count++;
  endtask

  // Verify that the sample request pulse is sent at the correct time and in 
  // the correct clock domain.
  task automatic verify_sample_req;
    integer bclk_edge_count = 0;
    integer clk_edge_count = 0;
    time end_time;
    integer i = 0;

    @(negedge aud_lrclk);
    //$display("  [%0t] LRCLK negedge - starting count", $time);
    #1;

    // Let any previous frame's pulse complete
    repeat (2) @(posedge clk);
    #1;

    req_pulse_time = 0;

    repeat (32) begin
      @(negedge aud_bclk);
      bclk_edge_count += 1;
      //$display("  [%0t] LRCLK negedge - BIT [%0d] ",$time, i++);    
    end

    end_time = $time;

    #20;  // Pending pulse needs to complete (half audio clock cycle)

    //$display("  [%0t] Count ended at %0t, req pulsed at %0t", $time, end_time, req_pulse_time);

    if (req_pulse_time == 0 || req_pulse_time < end_time) begin
      $display("FAIL: verify_sample_req, pulse not at expected time");
      test_failures += 1;
    end
    test_count++;
  endtask

  // Verify that audio frames are serialised correctly, this also confirms
  // bit ordering is correct and parallel load is working as expected.
  task automatic verify_frame(logic [31:0] expected_result);
    logic [31:0] captured_sample;
    logic failed = 0;
    integer i = 31;

    wait (req);
    sample = expected_result;

    repeat (32) begin
      @(negedge aud_bclk);
      #1;

      // Confirm each bit, this verifies ordering of LR samples
      if (aud_sda != expected_result[i]) begin
        failed = 1'b1;
        $display("FAIL: Bit: %0d | expecting %0x, got %0x", i,
                 expected_result[i], aud_sda);
      end
      i--;

    end
    if (failed) test_failures++;
    test_count++;
  endtask

  //------------------------------------------------------------------------------
  // Test executor
  //------------------------------------------------------------------------------
  initial begin
    $dumpfile("i2s_tx_tb.fst");
    $dumpvars(0, i2s_tx_tb);
    $display("TESTBENCH: i2s_tx_tb");

    sample = 0;

    // Wait for a stable uut
    wait (rst_n && aud_rst_n);
    repeat (2) @(negedge aud_lrclk);

  
    verify_lrclk();
    verify_sample_req();
    verify_frame(32'b0000000000000001_0000000000000001);  // LSB
    verify_frame(32'b1000000000000000_1000000000000000);  // MSB
    verify_frame(32'b0);                                  // Zeros
    verify_frame(32'hFFFF_FFFF);                          // Max
    verify_frame(32'hCAFE_FEED);                          // Pattern

    for (integer i = 0; i < 25; i++) begin                // Streaming
      verify_frame(sample);
    end

    repeat (10) @(posedge clk);

    if (test_failures == 0) $display("PASS: All %0d tests passed.",test_count);
    else $fatal(1, "FAIL: i2s_tx_tb. %0d test(s) failed.", test_failures);

    $finish;    
  end


endmodule

