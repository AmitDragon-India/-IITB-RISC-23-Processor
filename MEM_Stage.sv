module mem_stage (
    // from EX/MEM
    input  logic [15:0] alu_res_in,
    input  logic [15:0] store_data_in,
    input  logic [15:0] pc2_in,
    input  logic [15:0] imm_eff_in,

    input  logic        mem_rd_in,
    input  logic        mem_wr_in,

    input  logic        rf_we_in,
    input  logic [2:0]  rf_waddr_in,
    input  logic [1:0]  wb_sel_in,

    // from data memory
    input  logic [15:0] mem_rdata_in,

    // to data memory
    output logic        mem_rd_out,
    output logic        mem_wr_out,
    output logic [15:0] mem_addr_out,
    output logic [15:0] mem_wdata_out,

    // to MEM/WB
    output logic [15:0] alu_res_out,
    output logic [15:0] mem_rdata_out,
    output logic [15:0] pc2_out,
    output logic [15:0] imm_eff_out,

    output logic        rf_we_out,
    output logic [2:0]  rf_waddr_out,
    output logic [1:0]  wb_sel_out
);

    // Drive memory
    assign mem_rd_out    = mem_rd_in;
    assign mem_wr_out    = mem_wr_in;
    assign mem_addr_out  = alu_res_in;
    assign mem_wdata_out = store_data_in;

    // Forward to WB
    assign alu_res_out   = alu_res_in;
    assign mem_rdata_out = mem_rdata_in;
    assign pc2_out       = pc2_in;
    assign imm_eff_out   = imm_eff_in;

    assign rf_we_out     = rf_we_in;
    assign rf_waddr_out  = rf_waddr_in;
    assign wb_sel_out    = wb_sel_in;

endmodule
