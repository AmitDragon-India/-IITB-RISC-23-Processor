module if_stage #(
    parameter int IM_DEPTH = 4096,
    parameter string IM_FILE = ""
)(
    input  logic        clk,
    input  logic        rst_n,

    // control (for now you can tie them in top)
    input  logic        pc_we,
    input  logic        redirect_en,
    input  logic [15:0] redirect_pc,

    // outputs to IF/ID pipe
    output logic [15:0] pc_f,
    output logic [15:0] pc2_f,
    output logic [15:0] instr_f
);

    logic [15:0] pc_q, pc_next;

    assign pc_f  = pc_q;
    assign pc2_f = pc_q + 16'd2;

    always_comb begin
        pc_next = pc2_f;
        if (redirect_en) pc_next = redirect_pc;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) pc_q <= 16'h0000;
        else if (pc_we) pc_q <= pc_next;
    end

    instr_mem #(
        .DEPTH(IM_DEPTH),
        .IM_FILE(IM_FILE)
    ) u_imem (
        .pc_byte(pc_q),
        .instr(instr_f)
    );

endmodule
