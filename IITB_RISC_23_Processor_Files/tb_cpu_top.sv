`timescale 1ns/1ps

module tb_cpu_top;

  logic clk;
  logic rst_n;

  // Debug ports from DUT
  logic        rf_we_commit_dbg;
  logic [2:0]  rf_waddr_commit_dbg;
  logic [15:0] rf_wdata_commit_dbg;

  // 100 MHz clock (10 ns period)
  initial clk = 1'b0;
  always #5 clk = ~clk;

  cpu_top #(
    .IM_DEPTH(4096),
    .IM_FILE ("prog1_independent.mem")
  ) dut (
    .clk  (clk),
    .rst_n(rst_n),

    .rf_we_commit_dbg    (rf_we_commit_dbg),
    .rf_waddr_commit_dbg (rf_waddr_commit_dbg),
    .rf_wdata_commit_dbg (rf_wdata_commit_dbg)
  );

  // Reset
  initial begin
    rst_n = 1'b0;
    repeat (5) @(posedge clk);
    rst_n = 1'b1;
  end

  bit saw_r1, saw_r2, saw_r3, saw_r4, saw_r5;

  // Watch WB commits
  always @(posedge clk) begin
    if (rst_n && rf_we_commit_dbg) begin
      $display("[%0t] WB: R%0d <= 0x%04h",
               $time, rf_waddr_commit_dbg, rf_wdata_commit_dbg);

      case (rf_waddr_commit_dbg)
        3'd1: begin saw_r1 = 1; if (rf_wdata_commit_dbg !== 16'd5) $error("R1 expected 5"); end
        3'd2: begin saw_r2 = 1; if (rf_wdata_commit_dbg !== 16'd3) $error("R2 expected 3"); end
        3'd3: begin saw_r3 = 1; if (rf_wdata_commit_dbg !== 16'd7) $error("R3 expected 7"); end
        3'd4: begin saw_r4 = 1; if (rf_wdata_commit_dbg !== 16'd9) $error("R4 expected 9"); end
		  3'd5: begin saw_r5 = 1; if (rf_wdata_commit_dbg !== 16'd8) $error("R5 expected 8"); end
        default: ;
      endcase
    end
  end

  // Stop condition / timeout
  initial begin
    saw_r1 = 0; saw_r2 = 0; saw_r3 = 0; saw_r4 = 0; saw_r5 = 0;

    repeat (10000) begin
      @(posedge clk);
      if (rst_n && saw_r1 && saw_r2 && saw_r3 && saw_r4 && saw_r5) begin
        $display("[%0t] PASS: observed correct commits for R1..R4", $time);
        $stop;
      end
    end

    $error("TIMEOUT: did not see all expected commits");
    $stop;
  end

endmodule
