module instr_mem #(
    parameter int DEPTH = 4096,
    parameter string IM_FILE = "prog2_load_use.mem"
)(
    input  logic [15:0] pc_byte,     // byte address
    output logic [15:0] instr
);
    logic [15:0] mem [0:DEPTH-1];

    // 16-bit instruction => word address = pc_byte >> 1
    logic [$clog2(DEPTH)-1:0] waddr;
    assign waddr = pc_byte[$clog2(DEPTH):1];

    always_comb begin
        instr = mem[waddr];
    end


    `ifndef SYNTHESIS
		initial $readmemh("prog2_load_use.mem", mem);
	 `endif
    
endmodule
