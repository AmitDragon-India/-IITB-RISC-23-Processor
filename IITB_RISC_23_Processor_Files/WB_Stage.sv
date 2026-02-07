module wb_stage (
    // =====================
    // Inputs from MEM/WB
    // =====================
    input  logic        rf_we_in,
    input  logic [2:0]  rf_waddr_in,
    input  logic [1:0]  wb_sel_in,

    input  logic [15:0] alu_res_in,
    input  logic [15:0] mem_rdata_in,
    input  logic [15:0] pc2_in,
    input  logic [15:0] imm_eff_in,

    // =====================
    // Outputs to Reg File
    // =====================
    output logic        rf_we_out,
    output logic [2:0]  rf_waddr_out,
    output logic [15:0] rf_wdata_out
);

    // WB select encodings
    localparam logic [1:0] WB_ALU = 2'd0;
    localparam logic [1:0] WB_MEM = 2'd1;
    localparam logic [1:0] WB_PC2 = 2'd2;
    localparam logic [1:0] WB_IMM = 2'd3;

    // -------------------------
    // Writeback data select
    // -------------------------
    always_comb begin
        rf_we_out    = rf_we_in;
        rf_waddr_out = rf_waddr_in;

        unique case (wb_sel_in)
            WB_ALU: rf_wdata_out = alu_res_in;
            WB_MEM: rf_wdata_out = mem_rdata_in;
            WB_PC2: rf_wdata_out = pc2_in;
            WB_IMM: rf_wdata_out = imm_eff_in;   // LLI
            default: rf_wdata_out = 16'h0000;
        endcase
    end

endmodule
