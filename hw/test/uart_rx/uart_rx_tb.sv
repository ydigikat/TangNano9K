//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none 
`timescale 1ns / 10ps

module uart_rx_tb ();

  //------------------------------------------------------------------------------
  // Test control
  //------------------------------------------------------------------------------
  integer test_failures = 0;
  integer test_count = 0;

  

  //------------------------------------------------------------------------------
  // DUT parameters and signals
  //------------------------------------------------------------------------------
  localparam logic[10:0] DVSR = 11'h16;  
  localparam unsigned BIT_PERIOD = (DVSR + 1) * 16 * 10;  
  
  logic clk = 0;
  logic rst_n;
  logic rx;
  logic valid;
  logic [7:0] data;

  //------------------------------------------------------------------------------
  // Clock generation
  //------------------------------------------------------------------------------
  always #5 clk = ~clk;

  // always @(posedge clk) if(valid) $display("[%0t]\tTB: Valid pulse received",$time);

  //------------------------------------------------------------------------------
  // Unit under test
  //------------------------------------------------------------------------------
  uart_rx uut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .div_i(DVSR),
    .rx_i(rx),
    .rx_done_o(valid),
    .data_o(data)
  );

  //------------------------------------------------------------------------------
  // Helper task to send a UART byte
  // UART format: START(0) + 8 DATA bits (LSB first) + STOP(1)
  //------------------------------------------------------------------------------
  task automatic send_uart_byte(input logic [7:0] byte_in);
    integer i;

  
    // Start bit
    @(posedge clk);    
    //$display("[%0t] TB: Sent start bit",$time);$fflush();
    rx = 0;
    repeat (BIT_PERIOD/10) @(posedge clk);
    
    // Data bits (LSB first)
    for (i = 0; i < 8; i++) begin
      rx = byte_in[i];
      //$display("[%0t] TB: DATA bit %0d shifted_out=%b",$time,i,rx);$fflush();
      repeat (BIT_PERIOD/10) @(posedge clk);
    end
    
    //$display("[%0t] TB: Sent stop bit 1",$time);$fflush();
    // Stop bit - just set high, don't wait
    rx = 1;
  endtask

  //------------------------------------------------------------------------------
  // Tests
  //------------------------------------------------------------------------------
  task automatic verify_reset_state;
    @(posedge clk);
    #1;
    
    if (valid !== 1'b0 || data !== 8'h00) begin
      $display("FAIL: verify_reset_state. Invalid starting state");
      test_failures++;
    end
  endtask

  task automatic verify_single_byte_reception;
    logic [7:0] test_byte = 8'h15;
    
    send_uart_byte(test_byte);
    
    
    // Wait for valid pulse
    wait (valid == 1'b1);
    @(posedge clk);
    #1;
    
    if (data !== test_byte) begin
      $display("FAIL: verify_single_byte_reception. Data mismatch. Expected: %h, Got: %h", test_byte, data);
      test_failures++;
    end
    
    // Verify valid returns to 0
    @(posedge clk);
    #1;
    
    if (valid !== 1'b0) begin
      $display("FAIL: verify_single_byte_reception. Valid stuck high");
      test_failures++;
    end
    test_count++;
  endtask

  task automatic verify_multiple_bytes;
    logic [7:0] test_bytes[0:3];
    integer i;
    
    test_bytes[0] = 8'h55;
    test_bytes[1] = 8'hAA;
    test_bytes[2] = 8'hF0;
    test_bytes[3] = 8'h0F;
    
    for (i = 0; i < 4; i++) begin
      send_uart_byte(test_bytes[i]);
      
      wait (valid == 1'b1);
      @(posedge clk);
      #1;
      
      if (data !== test_bytes[i]) begin
        $display("FAIL: verify_multiple_bytes. Byte %0d mismatch. Expected: %h, Got: %h", 
                 i, test_bytes[i], data);
        test_failures++;
      end
      
      // Wait for valid to go back low before next byte
      wait (valid == 1'b0);
      repeat (2) @(posedge clk);
    end
    test_count++;
  endtask

  task automatic verify_all_zeros;
    logic [7:0] test_byte = 8'h00;
    
    send_uart_byte(test_byte);
    
    wait (valid == 1'b1);
    @(posedge clk);
    #1;
    
    if (data !== test_byte) begin
      $display("FAIL: verify_all_zeros. Data mismatch. Expected: %h, Got: %h", test_byte, data);
      test_failures++;
    end
    test_count++;
  endtask

  task automatic verify_all_ones;
    logic [7:0] test_byte = 8'hFF;
    
    send_uart_byte(test_byte);
    
    wait (valid == 1'b1);
    @(posedge clk);
    #1;
    
    if (data !== test_byte) begin
      $display("FAIL: verify_all_ones. Data mismatch. Expected: %h, Got: %h", test_byte, data);
      test_failures++;
    end
    test_count++;
  endtask

  task automatic verify_back_to_back;
    logic [7:0] byte1 = 8'h12;
    logic [7:0] byte2 = 8'h34;
    
    // Send first byte
    send_uart_byte(byte1);
    wait (valid == 1'b1);
    @(posedge clk);
    #1;
    
    if (data !== byte1) begin
      $display("FAIL: verify_back_to_back. First byte mismatch. Expected: %h, Got: %h", byte1, data);
      test_failures++;
    end
    
    // Send second byte immediately
    send_uart_byte(byte2);
    wait (valid == 1'b1);
    @(posedge clk);
    #1;
    
    if (data !== byte2) begin
      $display("FAIL: verify_back_to_back. Second byte mismatch. Expected: %h, Got: %h", byte2, data);
      test_failures++;
    end
    test_count++;
  endtask

  //------------------------------------------------------------------------------
  // Test executor
  //------------------------------------------------------------------------------
  initial begin
    $dumpfile("uart_rx.fst");
    $dumpvars(0, uart_rx_tb);
    $display("TESTBENCH: uart_rx_tb");

    // Initialize
    rst_n = 0;
    rx = 1;  // UART idle state is high
    #50;
    rst_n = 1;
    
    // Wait for stable state
    repeat (2) @(posedge clk);

    verify_reset_state();
    verify_single_byte_reception();

    verify_multiple_bytes();
    verify_all_zeros();
    verify_all_ones();
    verify_back_to_back();

    repeat (5) @(posedge clk);

    if (test_failures == 0) $display("PASS: All %0d tests passed.",test_count);
    else $fatal(1, "FAIL: uart_rx_tb. %0d test(s) failed.", test_failures);

    $finish;
  end

endmodule

`default_nettype wire