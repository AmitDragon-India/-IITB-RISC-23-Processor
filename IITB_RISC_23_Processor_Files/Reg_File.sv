module reg_file (
    input  logic        clk,
    input  logic        rst_n,

    // -------- Read ports --------
    input  logic [2:0]  raddr_a,   // RA
    input  logic [2:0]  raddr_b,   // RB
    output logic [15:0] rdata_a,
    output logic [15:0] rdata_b,

    // -------- Write port --------
    input  logic        we,         // write enable
    input  logic [2:0]  waddr,      // destination register
    input  logic [15:0] wdata
);

    // 8 x 16-bit register file
    logic [15:0] regs [0:7];

    // ----------------------------
    // Read: combinational
    // ----------------------------
    //always_comb begin
      //  rdata_a = regs[raddr_a];
        //rdata_b = regs[raddr_b];
    //end
	 
	 always_comb begin
    rdata_a = regs[raddr_a];
    rdata_b = regs[raddr_b];

    // If reading the same register being written this cycle, return new data
    if (we && (waddr == raddr_a)) rdata_a = wdata;
    if (we && (waddr == raddr_b)) rdata_b = wdata;
	 end

    // ----------------------------
    // Write: synchronous
    // ----------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            integer i;
            for (i = 0; i < 8; i = i + 1)
                regs[i] <= 16'h0000;
        end
        else if (we) begin
            regs[waddr] <= wdata;
        end
    end

endmodule
