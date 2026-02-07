module ex_mem_pipe (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        stall,
    input  logic        flush,

    // =====================
    // From EX stage
    // =====================
    input  logic [15:0] alu_res_in,
    input  logic [15:0] store_data_in,
    input  logic [15:0] pc2_in,
    input  logic [15:0] imm_eff_in,        // keep if you want WB_IMM later

    input  logic        rf_we_in,
    input  logic [2:0]  rf_waddr_in,
    input  logic [1:0]  wb_sel_in,

    input  logic        mem_rd_in,
    input  logic        mem_wr_in,

    // =====================
    // To MEM stage
    // =====================
    output logic [15:0] alu_res_out,
    output logic [15:0] store_data_out,
    output logic [15:0] pc2_out,
    output logic [15:0] imm_eff_out,

    output logic        rf_we_out,
    output logic [2:0]  rf_waddr_out,
    output logic [1:0]  wb_sel_out,

    output logic        mem_rd_out,
    output logic        mem_wr_out
);

    // Helper task: set NOP defaults on flush
    //task automatic set_nop();
    //    alu_res_out       <= 16'd0;
    //    store_data_out    <= 16'd0;
    //    pc2_out           <= 16'd0;
    //    imm_eff_out       <= 16'd0;

    //    rf_we_out         <= 1'b0;
    //    rf_waddr_out      <= 3'd0;
     //   wb_sel_out        <= 2'd0;
//
     //   mem_rd_out        <= 1'b0;
     //   mem_wr_out        <= 1'b0;

    //endtask

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alu_res_out       <= 16'd0;
			   store_data_out    <= 16'd0;
			   pc2_out           <= 16'd0;
			   imm_eff_out       <= 16'd0;

			   rf_we_out         <= 1'b0;
			   rf_waddr_out      <= 3'd0;
			   wb_sel_out        <= 2'd0;
 
			   mem_rd_out        <= 1'b0;
			   mem_wr_out        <= 1'b0;
        end
        else if (!stall) begin
            if (flush) begin
                alu_res_out       <= 16'd0;
				    store_data_out    <= 16'd0;
				    pc2_out           <= 16'd0;
				    imm_eff_out       <= 16'd0;

				    rf_we_out         <= 1'b0;
				    rf_waddr_out      <= 3'd0;
				    wb_sel_out        <= 2'd0;

				    mem_rd_out        <= 1'b0;
				    mem_wr_out        <= 1'b0;
            end
            else begin
                alu_res_out       <= alu_res_in;
                store_data_out    <= store_data_in;
                pc2_out           <= pc2_in;
                imm_eff_out       <= imm_eff_in;

                rf_we_out         <= rf_we_in;
                rf_waddr_out      <= rf_waddr_in;
                wb_sel_out        <= wb_sel_in;

                mem_rd_out        <= mem_rd_in;
                mem_wr_out        <= mem_wr_in;

            end
        end
        // else stall: hold state
    end

endmodule
