module id_rf_pipe (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        we,        // write enable (stall support later)
    input  logic        flush,     // convert this stage to NOP on flush

    // ---------- from ID stage ----------
    input  logic [15:0] pc_in,
    input  logic [15:0] pc2_in,

    input  logic [2:0]  ra_in,
    input  logic [2:0]  rb_in,
    input  logic [2:0]  rc_in,

    input  logic        r_comp_in,
    input  logic [1:0]  r_cz_in,

    input  logic [15:0] imm6_sext_in,
    input  logic [15:0] imm9_sext_in,
    input  logic [15:0] imm9_zext_in,

    // control
    input  logic [1:0]  srcA_sel_in,
    input  logic [1:0]  srcB_sel_in,
    input  logic [1:0]  imm_sel_in,

    input  logic [2:0]  alu_op_in,
    input  logic        invert_b_in,
    input  logic        use_carry_in_in,

    input  logic        pred_en_in,
    input  logic [1:0]  pred_cz_in,
    input  logic        pred_is_w_in,

    input  logic        rf_we_cand_in,
    input  logic [2:0]  rf_waddr_in,
    input  logic [1:0]  wb_sel_in,

    input  logic        mem_rd_in,
    input  logic        mem_wr_in,

    input  logic        ccr_we_C_cand_in,
    input  logic        ccr_we_Z_cand_in,

    input  logic        is_branch_in,
    input  logic [1:0]  br_type_in,
    input  logic        is_jump_in,
    input  logic        is_link_in,
    input  logic        jump_is_reg_in,

    input  logic        illegal_in,

    // ---------- to RF stage ----------
    output logic [15:0] pc_out,
    output logic [15:0] pc2_out,

    output logic [2:0]  ra_out,
    output logic [2:0]  rb_out,
    output logic [2:0]  rc_out,

    output logic        r_comp_out,
    output logic [1:0]  r_cz_out,

    output logic [15:0] imm6_sext_out,
    output logic [15:0] imm9_sext_out,
    output logic [15:0] imm9_zext_out,

    output logic [1:0]  srcA_sel_out,
    output logic [1:0]  srcB_sel_out,
    output logic [1:0]  imm_sel_out,

    output logic [2:0]  alu_op_out,
    output logic        invert_b_out,
    output logic        use_carry_in_out,

    output logic        pred_en_out,
    output logic [1:0]  pred_cz_out,
    output logic        pred_is_w_out,

    output logic        rf_we_cand_out,
    output logic [2:0]  rf_waddr_out,
    output logic [1:0]  wb_sel_out,

    output logic        mem_rd_out,
    output logic        mem_wr_out,

    output logic        ccr_we_C_cand_out,
    output logic        ccr_we_Z_cand_out,

    output logic        is_branch_out,
    output logic [1:0]  br_type_out,
    output logic        is_jump_out,
    output logic        is_link_out,
    output logic        jump_is_reg_out,

    output logic        illegal_out
);


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
				  pc_out              <= 16'h0000;
				  pc2_out             <= 16'h0000;
				  ra_out              <= 3'd0;
				  rb_out              <= 3'd0;
				  rc_out              <= 3'd0;
				  r_comp_out          <= 1'b0;
				  r_cz_out            <= 2'b00;
				  imm6_sext_out       <= 16'h0000;
				  imm9_sext_out       <= 16'h0000;
				  imm9_zext_out       <= 16'h0000;
				  srcA_sel_out        <= 2'd0;
				  srcB_sel_out        <= 2'd0;
				  imm_sel_out         <= 2'd0;
				  alu_op_out          <= 3'd0;
				  invert_b_out        <= 1'b0;
				  use_carry_in_out    <= 1'b0;
				  pred_en_out         <= 1'b0;
				  pred_cz_out         <= 2'b00;
				  pred_is_w_out       <= 1'b0;
				  rf_we_cand_out      <= 1'b0;
				  rf_waddr_out        <= 3'd0;
				  wb_sel_out          <= 2'd0;
				  mem_rd_out          <= 1'b0;
				  mem_wr_out          <= 1'b0;
				  ccr_we_C_cand_out   <= 1'b0;
				  ccr_we_Z_cand_out   <= 1'b0;
				  is_branch_out       <= 1'b0;
				  br_type_out         <= 2'b00;
				  is_jump_out         <= 1'b0;
				  is_link_out         <= 1'b0;
				  jump_is_reg_out     <= 1'b0;
				  illegal_out         <= 1'b0;
        end else if (flush) begin
				  pc_out              <= 16'h0000;
				  pc2_out             <= 16'h0000;
				  ra_out              <= 3'd0;
				  rb_out              <= 3'd0;
				  rc_out              <= 3'd0;
				  r_comp_out          <= 1'b0;
				  r_cz_out            <= 2'b00;
				  imm6_sext_out       <= 16'h0000;
				  imm9_sext_out       <= 16'h0000;
				  imm9_zext_out       <= 16'h0000;
				  srcA_sel_out        <= 2'd0;
				  srcB_sel_out        <= 2'd0;
				  imm_sel_out         <= 2'd0;
				  alu_op_out          <= 3'd0;
				  invert_b_out        <= 1'b0;
				  use_carry_in_out    <= 1'b0;
				  pred_en_out         <= 1'b0;
				  pred_cz_out         <= 2'b00;
				  pred_is_w_out       <= 1'b0;
				  rf_we_cand_out      <= 1'b0;
				  rf_waddr_out        <= 3'd0;
				  wb_sel_out          <= 2'd0;
				  mem_rd_out          <= 1'b0;
				  mem_wr_out          <= 1'b0;
				  ccr_we_C_cand_out   <= 1'b0;
				  ccr_we_Z_cand_out   <= 1'b0;
				  is_branch_out       <= 1'b0;
				  br_type_out         <= 2'b00;
				  is_jump_out         <= 1'b0;
				  is_link_out         <= 1'b0;
				  jump_is_reg_out     <= 1'b0;
				  illegal_out         <= 1'b0;
        end else if (we) begin
            pc_out            <= pc_in;
            pc2_out           <= pc2_in;

            ra_out            <= ra_in;
            rb_out            <= rb_in;
            rc_out            <= rc_in;

            r_comp_out        <= r_comp_in;
            r_cz_out          <= r_cz_in;

            imm6_sext_out     <= imm6_sext_in;
            imm9_sext_out     <= imm9_sext_in;
            imm9_zext_out     <= imm9_zext_in;

            srcA_sel_out      <= srcA_sel_in;
            srcB_sel_out      <= srcB_sel_in;
            imm_sel_out       <= imm_sel_in;

            alu_op_out        <= alu_op_in;
            invert_b_out      <= invert_b_in;
            use_carry_in_out  <= use_carry_in_in;

            pred_en_out       <= pred_en_in;
            pred_cz_out       <= pred_cz_in;
            pred_is_w_out     <= pred_is_w_in;

            rf_we_cand_out    <= rf_we_cand_in;
            rf_waddr_out      <= rf_waddr_in;
            wb_sel_out        <= wb_sel_in;

            mem_rd_out        <= mem_rd_in;
            mem_wr_out        <= mem_wr_in;

            ccr_we_C_cand_out <= ccr_we_C_cand_in;
            ccr_we_Z_cand_out <= ccr_we_Z_cand_in;

            is_branch_out     <= is_branch_in;
            br_type_out       <= br_type_in;
            is_jump_out       <= is_jump_in;
            is_link_out       <= is_link_in;
            jump_is_reg_out   <= jump_is_reg_in;

            illegal_out       <= illegal_in;
        end
        // else: hold state (stall)
    end

endmodule
