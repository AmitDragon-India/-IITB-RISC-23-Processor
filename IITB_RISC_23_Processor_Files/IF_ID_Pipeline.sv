module if_id_pipe (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        we,
    input  logic        flush,

    input  logic [15:0] pc_in,
    input  logic [15:0] pc2_in,
    input  logic [15:0] instr_in,

    output logic [15:0] pc_out,
    output logic [15:0] pc2_out,
    output logic [15:0] instr_out
);
    localparam logic [15:0] NOP = 16'h0000;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out    <= 16'h0000;
            pc2_out   <= 16'h0000;
            instr_out <= NOP;
        end else if (flush) begin
            pc_out    <= pc_in;
            pc2_out   <= pc2_in;
            instr_out <= NOP;
        end else if (we) begin
            pc_out    <= pc_in;
            pc2_out   <= pc2_in;
            instr_out <= instr_in;
        end
    end
endmodule
