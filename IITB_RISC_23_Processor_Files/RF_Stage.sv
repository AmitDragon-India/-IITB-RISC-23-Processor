module rf_stage (
    // -------- from ID/RF pipeline --------
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

    // -------- register file read data --------
    input  logic [15:0] rf_rdata_a,   // data at address ra_in
    input  logic [15:0] rf_rdata_b,   // data at address rb_in

    // -------- outputs to EX stage --------
    output logic [15:0] opA_out,
    output logic [15:0] opB_out,
    output logic [15:0] store_data_out, // for SW (data to write to memory)

    // pass-through signals to EX (keep for now)
    output logic [15:0] pc_out,
    output logic [15:0] pc2_out,

    output logic [2:0]  ra_out,
    output logic [2:0]  rb_out,
    output logic [2:0]  rc_out,

    output logic        r_comp_out,
    output logic [1:0]  r_cz_out,
	 
	 output logic [15:0] imm_eff_out,

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

    // ----------------------------
    // local encodings (match ID stage)
    // ----------------------------
    localparam logic [1:0] A_RA      = 2'd0;
    localparam logic [1:0] A_RB      = 2'd1;
    localparam logic [1:0] A_PC      = 2'd2;

    localparam logic [1:0] B_REG     = 2'd0;
    localparam logic [1:0] B_IMM     = 2'd1;
    localparam logic [1:0] B_CONST2  = 2'd2;

    localparam logic [1:0] IMM6_SEXT = 2'd0;
    localparam logic [1:0] IMM9_SEXT = 2'd1;
    localparam logic [1:0] IMM9_ZEXT = 2'd2;

    // ----------------------------
    // pass-through (combinational)
    // ----------------------------
    always_comb begin
        pc_out  = pc_in;
        pc2_out = pc2_in;

        ra_out     = ra_in;
        rb_out     = rb_in;
        rc_out     = rc_in;

        r_comp_out = r_comp_in;
        r_cz_out   = r_cz_in;


        alu_op_out        = alu_op_in;
        invert_b_out      = invert_b_in;
        use_carry_in_out  = use_carry_in_in;

        pred_en_out   = pred_en_in;
        pred_cz_out   = pred_cz_in;
        pred_is_w_out = pred_is_w_in;

        rf_we_cand_out = rf_we_cand_in;
        rf_waddr_out   = rf_waddr_in;
        wb_sel_out     = wb_sel_in;

        mem_rd_out = mem_rd_in;
        mem_wr_out = mem_wr_in;

        ccr_we_C_cand_out = ccr_we_C_cand_in;
        ccr_we_Z_cand_out = ccr_we_Z_cand_in;

        is_branch_out   = is_branch_in;
        br_type_out     = br_type_in;
        is_jump_out     = is_jump_in;
        is_link_out     = is_link_in;
        jump_is_reg_out = jump_is_reg_in;

        illegal_out = illegal_in;
    end

    // ----------------------------
    // immediate select
    // ----------------------------
    logic [15:0] imm_eff;

    always_comb begin
        unique case (imm_sel_in)
            IMM6_SEXT: imm_eff = imm6_sext_in;
            IMM9_SEXT: imm_eff = imm9_sext_in;
            IMM9_ZEXT: imm_eff = imm9_zext_in;
            default:  imm_eff = 16'h0000;
        endcase
    end
	 
	 assign imm_eff_out = imm_eff;

    // ----------------------------
    // store data for SW
    // SW format: sw ra, rb, imm6 -> store RA value
    // ----------------------------
    always_comb begin
        store_data_out = rf_rdata_a;  // RA data always available
    end

    // ----------------------------
    // operand muxes for EX
    // ----------------------------
    always_comb begin
        // opA mux
        unique case (srcA_sel_in)
            A_RA: opA_out = rf_rdata_a;
            A_RB: opA_out = rf_rdata_b;
            A_PC: opA_out = pc_in;
            default: opA_out = 16'h0000;
        endcase

        // opB mux
        unique case (srcB_sel_in)
            B_REG:    opB_out = rf_rdata_b;
            B_IMM:    opB_out = imm_eff;
            B_CONST2: opB_out = 16'd2;     // because instruction width = 2 bytes
            default:  opB_out = 16'h0000;
        endcase
    end

endmodule
