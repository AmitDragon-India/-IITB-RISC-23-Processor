module mem_wb_pipe (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        stall,
    input  logic        flush,

    // =====================
    // From MEM stage
    // =====================
    input  logic        rf_we_in,
    input  logic [2:0]  rf_waddr_in,
    input  logic [1:0]  wb_sel_in,

    input  logic [15:0] alu_res_in,
    input  logic [15:0] mem_rdata_in,
    input  logic [15:0] pc2_in,
    input  logic [15:0] imm_eff_in,

    // =====================
    // To WB stage
    // =====================
    output logic        rf_we_out,
    output logic [2:0]  rf_waddr_out,
    output logic [1:0]  wb_sel_out,

    output logic [15:0] alu_res_out,
    output logic [15:0] mem_rdata_out,
    output logic [15:0] pc2_out,
    output logic [15:0] imm_eff_out
);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rf_we_out     <= 1'b0;
        rf_waddr_out  <= 3'd0;
        wb_sel_out    <= 2'd0;

        alu_res_out   <= 16'd0;
        mem_rdata_out <= 16'd0;
        pc2_out       <= 16'd0;
        imm_eff_out   <= 16'd0;
    end
    else if (!stall) begin
        if (flush) begin
            // convert to NOP
            rf_we_out <= 1'b0;
				rf_waddr_out  <= 3'd0;
				wb_sel_out    <= 2'd0;

				alu_res_out   <= 16'd0;
				mem_rdata_out <= 16'd0;
				pc2_out       <= 16'd0;
				imm_eff_out   <= 16'd0;
        end
        else begin
            rf_we_out     <= rf_we_in;
            rf_waddr_out  <= rf_waddr_in;
            wb_sel_out    <= wb_sel_in;

            alu_res_out   <= alu_res_in;
            mem_rdata_out <= mem_rdata_in;
            pc2_out       <= pc2_in;
            imm_eff_out   <= imm_eff_in;
        end
    end
end

endmodule
