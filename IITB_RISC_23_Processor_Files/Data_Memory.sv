module data_memory #(
    parameter int DEPTH   = 4096,
    parameter string MEMFILE = "dmem_init.mem"   // optional init file
)(
    input  logic        clk,
    input  logic        mem_rd,
    input  logic        mem_wr,
    input  logic [15:0] addr,
    input  logic [15:0] wdata,
    output logic [15:0] rdata
);

    logic [15:0] mem [0:DEPTH-1];

    // word address (16-bit words)
    logic [$clog2(DEPTH)-1:0] waddr;
    assign waddr = addr[$clog2(DEPTH):1];

    // async read (simple)
    always_comb begin
        if (mem_rd) rdata = mem[waddr];
        else        rdata = 16'h0000;
    end

    // sync write
    always_ff @(posedge clk) begin
        if (mem_wr) mem[waddr] <= wdata;
    end

    // init
    ///integer i;
    //initial begin
    //    for (i = 0; i < DEPTH; i++) mem[i] = 16'h0000;
     //   $readmemh("dmem_init.mem", mem);   // <-- always
   // end
	
	initial begin
        $readmemh("dmem_init.mem", mem);
    end
endmodule
