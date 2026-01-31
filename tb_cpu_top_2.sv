`timescale 1ns/1ps

module tb_cpu_top_2;

  logic clk;
  logic rst_n;
  
  // Debug ports from DUT
  logic        rf_we_commit_dbg;
  logic [2:0]  rf_waddr_commit_dbg;
  logic [15:0] rf_wdata_commit_dbg;

  // 100 MHz clock
  initial clk = 1'b0;
  always #5 clk = ~clk;

  cpu_top #(
    .IM_DEPTH(4096),
    .IM_FILE ("prog2_load_use.mem")   // <-- change to prog2_load_use.mem
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


  // Flags for checking
  bit saw_r1, saw_r2, saw_r3, saw_r4;
  bit fail;
  
 always @(posedge clk) begin
    if (rst_n && rf_we_commit_dbg) begin
      $display("[%0t] WB: R%0d <= 0x%04h",
               $time, rf_waddr_commit_dbg, rf_wdata_commit_dbg);

      // ✅ check using commit bus (NOT dut.u_rf.waddr)
      case (rf_waddr_commit_dbg)
        3'd1: begin saw_r1 = 1; if (rf_wdata_commit_dbg !== 16'd5)  begin $error("R1 expected 5");  fail=1; end end
        3'd2: begin saw_r2 = 1; if (rf_wdata_commit_dbg !== 16'd0)  begin $error("R2 expected 0");  fail=1; end end
        3'd3: begin saw_r3 = 1; if (rf_wdata_commit_dbg !== 16'd5)  begin $error("R3 expected 5 (LW)"); fail=1; end end
        3'd4: begin saw_r4 = 1; if (rf_wdata_commit_dbg !== 16'd10) begin $error("R4 expected 10 (R3+R1)"); fail=1; end end
        default: ;
      endcase

      if (fail) $fatal(1, "FAIL: mismatch detected"); // stop immediately
    end
  end

  initial begin
    saw_r1=0; saw_r2=0; saw_r3=0; saw_r4=0; fail=0;

    repeat (600) begin
      @(posedge clk);
      if (rst_n && saw_r1 && saw_r2 && saw_r3 && saw_r4) begin
        $display("[%0t] PASS", $time);
        $stop;
      end
    end

    $fatal(1, "TIMEOUT: did not see all expected commits");
  end

endmodule