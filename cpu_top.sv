module cpu_top #(
    parameter int IM_DEPTH = 4096,
    parameter string IM_FILE = ""
)(
    input  logic clk,
    input  logic rst_n,
	 
	 // ---- DEBUG / TEST PORTS ----
    output logic        rf_we_commit_dbg,
    output logic [2:0]  rf_waddr_commit_dbg,
    output logic [15:0] rf_wdata_commit_dbg
);

    // ------------------------------------------------------------
    // Control placeholders (no hazards yet)
    // ------------------------------------------------------------
    logic pc_we;
    logic if_id_we;
	 logic id_rf_we;
    logic if_id_flush;
	 logic id_rf_flush;

    // Redirect will come from EX stage later
    logic redirect_en;
    logic [15:0] redirect_pc;
	 
	 // Redirect from EX
	 logic        redirect_en_x;
	 logic [15:0] redirect_pc_x;
	 
	 		 // ------------------------------------------------------------
	// Regfile wires
	// ------------------------------------------------------------
	 logic [15:0] rf_rdata_a, rf_rdata_b;
	 
	
	 		 // ------------------------------------------------------------
	// Forwarding Unit
	// ------------------------------------------------------------ 
	
	 logic [1:0] fwdA_sel, fwdB_sel, fwdS_sel;
	
	

	 // Forward data sources
	 logic [15:0] exmem_fwd_data;
	 logic [15:0] memwb_fwd_data;
	 
	 

	// You must define these use signals.
	// If you don’t have them yet, set them to 1 for now.
	 logic ex_use_ra, ex_use_rb, ex_use_store;
	 assign ex_use_ra = 1'b1;
	 assign ex_use_rb = 1'b1;
	 assign ex_use_store = 1'b1;


	 

    // When redirect happens, kill the wrong-path instruction entering ID
	 assign redirect_en = redirect_en_x;
    assign redirect_pc = redirect_pc_x;
	 
    assign if_id_flush = redirect_en;
	 assign id_rf_flush = redirect_en;
	 



    // ------------------------------------------------------------
    // IF stage outputs  >> IF Input
    // ------------------------------------------------------------
    logic [15:0] pc_f, pc2_f, instr_f;

    // ------------------------------------------------------------
    // IF_ID Pipeline outputs (inputs to ID stage later)
    // ------------------------------------------------------------
    logic [15:0] if_id_pc, if_id_pc2, if_id_instr;


    // ------------------------------------------------------------
    // IF stage
    // ------------------------------------------------------------
    if_stage #(
        .IM_DEPTH(IM_DEPTH),
        .IM_FILE (IM_FILE)
    ) u_if (
        .clk         (clk),
        .rst_n       (rst_n),
        .pc_we       (pc_we),
        .redirect_en (redirect_en),
        .redirect_pc (redirect_pc),
        .pc_f        (pc_f),
        .pc2_f       (pc2_f),
        .instr_f     (instr_f)
    );

    // ------------------------------------------------------------
    // IF_ID pipeline
    // ------------------------------------------------------------
    if_id_pipe u_ifid (
        .clk      (clk),
        .rst_n    (rst_n),
        .we       (if_id_we),
        .flush    (if_id_flush),
        .pc_in    (pc_f),
        .pc2_in   (pc2_f),
        .instr_in (instr_f),
        .pc_out   (if_id_pc),
        .pc2_out  (if_id_pc2),
        .instr_out(if_id_instr)
    );
	 
	 // ------------------------------------------------------------
    // ID Stage Outputs  >> ID_RF Input
    // ------------------------------------------------------------
	 
		 // decoded fields
	 logic [3:0]opcode_d;
	 logic [2:0] ra_d, rb_d, rc_d;
	 logic       r_comp_d;
	 logic [1:0] r_cz_d;

	 logic [5:0] imm6_d;
	 logic [8:0] imm9_d;

	 logic [15:0] imm6_sext_d;
	 logic [15:0] imm9_sext_d;
	 logic [15:0] imm9_zext_d;

	 // control signals
	 logic [1:0] srcA_sel_d;
	 logic [1:0] srcB_sel_d;
	 logic [1:0] imm_sel_d;

	 logic [2:0] alu_op_d;
	 logic       invert_b_d;
	 logic       use_carry_in_d;

	 logic       pred_en_d;
	 logic [1:0] pred_cz_d;
	 logic       pred_is_w_d;

	 logic       rf_we_cand_d;
	 logic [2:0] rf_waddr_d;
	 logic [1:0] wb_sel_d;

	 logic       mem_rd_d;
	 logic       mem_wr_d;

	 logic       ccr_we_C_cand_d;
	 logic       ccr_we_Z_cand_d;

	 logic       is_branch_d;
	 logic [1:0] br_type_d;

	 logic       is_jump_d;
	 logic       is_link_d;
	 logic       jump_is_reg_d;

	 logic       illegal_d;
	 
	 

	 // ------------------------------------------------------------
    // ID Stage
    // ------------------------------------------------------------
	 
	 id_stage u_id (
    // from IF/ID pipe
    .pc_in      (if_id_pc),
    .pc2_in     (if_id_pc2),
    .instr_in  (if_id_instr),

    // decoded fields
    .opcode    (opcode_d),
    .ra        (ra_d),
    .rb        (rb_d),
    .rc        (rc_d),

    .r_comp    (r_comp_d),
    .r_cz      (r_cz_d),

    .imm6      (imm6_d),
    .imm9      (imm9_d),

    .imm6_sext (imm6_sext_d),
    .imm9_sext (imm9_sext_d),
    .imm9_zext (imm9_zext_d),

    // EX operand select
    .srcA_sel  (srcA_sel_d),
    .srcB_sel  (srcB_sel_d),
    .imm_sel   (imm_sel_d),

    // ALU control
    .alu_op        (alu_op_d),
    .invert_b      (invert_b_d),
    .use_carry_in  (use_carry_in_d),

    // predication
    .pred_en    (pred_en_d),
    .pred_cz    (pred_cz_d),
    .pred_is_w  (pred_is_w_d),

    // writeback
    .rf_we_cand (rf_we_cand_d),
    .rf_waddr   (rf_waddr_d),
    .wb_sel     (wb_sel_d),

    // memory
    .mem_rd     (mem_rd_d),
    .mem_wr     (mem_wr_d),

    // CCR
    .ccr_we_C_cand (ccr_we_C_cand_d),
    .ccr_we_Z_cand (ccr_we_Z_cand_d),

    // control flow
    .is_branch   (is_branch_d),
    .br_type     (br_type_d),
    .is_jump     (is_jump_d),
    .is_link     (is_link_d),
    .jump_is_reg (jump_is_reg_d),

    // validity
    .illegal     (illegal_d)
);

// ------------------------------------------------------------
    // ID_RF outputs -> RF inputs (declare all)
    // ------------------------------------------------------------
    logic [15:0] id_rf_pc, id_rf_pc2;

    logic [2:0]  id_rf_ra, id_rf_rb, id_rf_rc;

    logic        id_rf_r_comp;
    logic [1:0]  id_rf_r_cz;

    logic [15:0] id_rf_imm6_sext;
    logic [15:0] id_rf_imm9_sext;
    logic [15:0] id_rf_imm9_zext;

    logic [1:0]  id_rf_srcA_sel;
    logic [1:0]  id_rf_srcB_sel;
    logic [1:0]  id_rf_imm_sel;

    logic [2:0]  id_rf_alu_op;
    logic        id_rf_invert_b;
    logic        id_rf_use_carry_in;

    logic        id_rf_pred_en;
    logic [1:0]  id_rf_pred_cz;
    logic        id_rf_pred_is_w;

    logic        id_rf_rf_we_cand;
    logic [2:0]  id_rf_rf_waddr;
    logic [1:0]  id_rf_wb_sel;

    logic        id_rf_mem_rd;
    logic        id_rf_mem_wr;

    logic        id_rf_ccr_we_C_cand;
    logic        id_rf_ccr_we_Z_cand;

    logic        id_rf_is_branch;
    logic [1:0]  id_rf_br_type;

    logic        id_rf_is_jump;
    logic        id_rf_is_link;
    logic        id_rf_jump_is_reg;

    logic        id_rf_illegal;
	 
	 


// ------------------------------------------------------------
    // ID_RF pipeline
    // ------------------------------------------------------------
    id_rf_pipe u_idrf (
        .clk      (clk),
        .rst_n    (rst_n),
        .we       (id_rf_we),
        .flush    (id_rf_flush),

        .pc_in    (if_id_pc),
        .pc2_in   (if_id_pc2),

        .ra_in    (ra_d),
        .rb_in    (rb_d),
        .rc_in    (rc_d),

        .r_comp_in (r_comp_d),
        .r_cz_in   (r_cz_d),

        .imm6_sext_in (imm6_sext_d),
        .imm9_sext_in (imm9_sext_d),
        .imm9_zext_in (imm9_zext_d),

        .srcA_sel_in (srcA_sel_d),
        .srcB_sel_in (srcB_sel_d),
        .imm_sel_in  (imm_sel_d),

        .alu_op_in       (alu_op_d),
        .invert_b_in     (invert_b_d),
        .use_carry_in_in (use_carry_in_d),

        .pred_en_in   (pred_en_d),
        .pred_cz_in   (pred_cz_d),
        .pred_is_w_in (pred_is_w_d),

        .rf_we_cand_in (rf_we_cand_d),
        .rf_waddr_in   (rf_waddr_d),
        .wb_sel_in     (wb_sel_d),

        .mem_rd_in (mem_rd_d),
        .mem_wr_in (mem_wr_d),

        .ccr_we_C_cand_in (ccr_we_C_cand_d),
        .ccr_we_Z_cand_in (ccr_we_Z_cand_d),

        .is_branch_in   (is_branch_d),
        .br_type_in     (br_type_d),
        .is_jump_in     (is_jump_d),
        .is_link_in     (is_link_d),
        .jump_is_reg_in (jump_is_reg_d),

        .illegal_in (illegal_d),

        // outputs
        .pc_out    (id_rf_pc),
        .pc2_out   (id_rf_pc2),

        .ra_out    (id_rf_ra),
        .rb_out    (id_rf_rb),
        .rc_out    (id_rf_rc),

        .r_comp_out (id_rf_r_comp),
        .r_cz_out   (id_rf_r_cz),

        .imm6_sext_out (id_rf_imm6_sext),
        .imm9_sext_out (id_rf_imm9_sext),
        .imm9_zext_out (id_rf_imm9_zext),

        .srcA_sel_out (id_rf_srcA_sel),
        .srcB_sel_out (id_rf_srcB_sel),
        .imm_sel_out  (id_rf_imm_sel),

        .alu_op_out       (id_rf_alu_op),
        .invert_b_out     (id_rf_invert_b),
        .use_carry_in_out (id_rf_use_carry_in),

        .pred_en_out   (id_rf_pred_en),
        .pred_cz_out   (id_rf_pred_cz),
        .pred_is_w_out (id_rf_pred_is_w),

        .rf_we_cand_out (id_rf_rf_we_cand),
        .rf_waddr_out   (id_rf_rf_waddr),
        .wb_sel_out     (id_rf_wb_sel),

        .mem_rd_out (id_rf_mem_rd),
        .mem_wr_out (id_rf_mem_wr),

        .ccr_we_C_cand_out (id_rf_ccr_we_C_cand),
        .ccr_we_Z_cand_out (id_rf_ccr_we_Z_cand),

        .is_branch_out   (id_rf_is_branch),
        .br_type_out     (id_rf_br_type),

        .is_jump_out     (id_rf_is_jump),
        .is_link_out     (id_rf_is_link),
        .jump_is_reg_out (id_rf_jump_is_reg),

        .illegal_out (id_rf_illegal)
    );
	 
// ------------------------------------------------------------
	// RF stage outputs -> to RF_EX pipe later
	// ------------------------------------------------------------
	logic [15:0] rf_opA, rf_opB, rf_store_data, rf_imm_eff;

	logic [15:0] rf_pc, rf_pc2;
	logic [2:0]  rf_ra, rf_rb, rf_rc;
	logic        rf_r_comp;
	logic [1:0]  rf_r_cz;

	logic [2:0]  rf_alu_op;
	logic        rf_invert_b;
	logic        rf_use_carry_in;

	logic        rf_pred_en;
	logic [1:0]  rf_pred_cz;
	logic        rf_pred_is_w;

	logic        rf_rf_we_cand;
	logic [2:0]  rf_rf_waddr;
	logic [1:0]  rf_wb_sel;

	logic        rf_mem_rd;
	logic        rf_mem_wr;

	logic        rf_ccr_we_C_cand;
	logic        rf_ccr_we_Z_cand;

	logic        rf_is_branch;
	logic [1:0]  rf_br_type;

	logic        rf_is_jump;
	logic        rf_is_link;
	logic        rf_jump_is_reg;

	logic        rf_illegal;	 
	 
	 
	 
	 // ------------------------------------------------------------
    // RF Stage
    // ------------------------------------------------------------
	 

	 rf_stage u_rf_stage (
    .pc_in   (id_rf_pc),
    .pc2_in  (id_rf_pc2),

    .ra_in   (id_rf_ra),
    .rb_in   (id_rf_rb),
    .rc_in   (id_rf_rc),

    .r_comp_in (id_rf_r_comp),
    .r_cz_in   (id_rf_r_cz),

    .imm6_sext_in (id_rf_imm6_sext),
    .imm9_sext_in (id_rf_imm9_sext),
    .imm9_zext_in (id_rf_imm9_zext),

    .srcA_sel_in (id_rf_srcA_sel),
    .srcB_sel_in (id_rf_srcB_sel),
    .imm_sel_in  (id_rf_imm_sel),

    .alu_op_in       (id_rf_alu_op),
    .invert_b_in     (id_rf_invert_b),
    .use_carry_in_in (id_rf_use_carry_in),

    .pred_en_in   (id_rf_pred_en),
    .pred_cz_in   (id_rf_pred_cz),
    .pred_is_w_in (id_rf_pred_is_w),

    .rf_we_cand_in (id_rf_rf_we_cand),
    .rf_waddr_in   (id_rf_rf_waddr),
    .wb_sel_in     (id_rf_wb_sel),

    .mem_rd_in (id_rf_mem_rd),
    .mem_wr_in (id_rf_mem_wr),

    .ccr_we_C_cand_in (id_rf_ccr_we_C_cand),
    .ccr_we_Z_cand_in (id_rf_ccr_we_Z_cand),

    .is_branch_in (id_rf_is_branch),
    .br_type_in   (id_rf_br_type),
    .is_jump_in   (id_rf_is_jump),
    .is_link_in   (id_rf_is_link),
    .jump_is_reg_in (id_rf_jump_is_reg),

    .illegal_in (id_rf_illegal),

    // regfile read data
    .rf_rdata_a (rf_rdata_a),
    .rf_rdata_b (rf_rdata_b),

    // outputs to next pipe
    .opA_out        (rf_opA),
    .opB_out        (rf_opB),
    .store_data_out (rf_store_data),

    .pc_out   (rf_pc),
    .pc2_out  (rf_pc2),

    .ra_out   (rf_ra),
    .rb_out   (rf_rb),
    .rc_out   (rf_rc),

    .r_comp_out (rf_r_comp),
    .r_cz_out   (rf_r_cz),

    .imm_eff_out (rf_imm_eff),

    .alu_op_out       (rf_alu_op),
    .invert_b_out     (rf_invert_b),
    .use_carry_in_out (rf_use_carry_in),

    .pred_en_out   (rf_pred_en),
    .pred_cz_out   (rf_pred_cz),
    .pred_is_w_out (rf_pred_is_w),

    .rf_we_cand_out (rf_rf_we_cand),
    .rf_waddr_out   (rf_rf_waddr),
    .wb_sel_out     (rf_wb_sel),

    .mem_rd_out (rf_mem_rd),
    .mem_wr_out (rf_mem_wr),

    .ccr_we_C_cand_out (rf_ccr_we_C_cand),
    .ccr_we_Z_cand_out (rf_ccr_we_Z_cand),

    .is_branch_out (rf_is_branch),
    .br_type_out   (rf_br_type),
    .is_jump_out   (rf_is_jump),
    .is_link_out   (rf_is_link),
    .jump_is_reg_out (rf_jump_is_reg),

    .illegal_out (rf_illegal)
);


// ------------------------------------------------------------
// RF_EX pipeline outputs (inputs to EX stage later)
// ------------------------------------------------------------
logic [15:0] ex_opA, ex_opB, ex_store_data, ex_imm_eff;
logic [15:0] ex_pc, ex_pc2;

logic [2:0] ex_ra, ex_rb, ex_rc;

logic [2:0]  ex_alu_op;
logic        ex_invert_b;
logic        ex_use_carry_in;

logic        ex_pred_en;
logic [1:0]  ex_pred_cz;
logic        ex_pred_is_w;

logic        ex_rf_we_cand;
logic [2:0]  ex_rf_waddr;
logic [1:0]  ex_wb_sel;

logic        ex_mem_rd;
logic        ex_mem_wr;

logic        ex_ccr_we_C_cand;
logic        ex_ccr_we_Z_cand;

logic        ex_is_branch;
logic [1:0]  ex_br_type;

logic        ex_is_jump;
logic        ex_is_link;
logic        ex_jump_is_reg;

logic rf_ex_stall;
logic rf_ex_flush;



	



// ------------------------------------------------------------
    // RF_EX Pipeline
    // ------------------------------------------------------------
	 

rf_ex_pipe u_rf_ex (
    .clk   (clk),
    .rst_n (rst_n),

    .stall (rf_ex_stall),
    .flush (rf_ex_flush),

    // from RF stage
    .opA_in        (rf_opA),
    .opB_in        (rf_opB),
    .store_data_in(rf_store_data),
    .imm_eff_in   (rf_imm_eff),

    .pc_in  (rf_pc),
    .pc2_in (rf_pc2),
	 
	 .ra_in (rf_ra),
	 .rb_in (rf_rb),
	 .rc_in (rf_rc),

    // control
    .alu_op_in       (rf_alu_op),
    .invert_b_in     (rf_invert_b),
    .use_carry_in_in (rf_use_carry_in),

    .pred_en_in   (rf_pred_en),
    .pred_cz_in   (rf_pred_cz),
    .pred_is_w_in (rf_pred_is_w),

    .rf_we_cand_in (rf_rf_we_cand),
    .rf_waddr_in   (rf_rf_waddr),
    .wb_sel_in     (rf_wb_sel),

    .mem_rd_in (rf_mem_rd),
    .mem_wr_in (rf_mem_wr),

    .ccr_we_C_cand_in (rf_ccr_we_C_cand),
    .ccr_we_Z_cand_in (rf_ccr_we_Z_cand),

    .is_branch_in (rf_is_branch),
    .br_type_in   (rf_br_type),

    .is_jump_in     (rf_is_jump),
    .is_link_in     (rf_is_link),
    .jump_is_reg_in (rf_jump_is_reg),

    // to EX stage
    .opA_out        (ex_opA),
    .opB_out        (ex_opB),
    .store_data_out(ex_store_data),
    .imm_eff_out   (ex_imm_eff),

    .pc_out  (ex_pc),
    .pc2_out (ex_pc2),
	 
	 .ra_out (ex_ra),
	 .rb_out (ex_rb),
	 .rc_out (ex_rc),

    .alu_op_out       (ex_alu_op),
    .invert_b_out     (ex_invert_b),
    .use_carry_in_out (ex_use_carry_in),

    .pred_en_out   (ex_pred_en),
    .pred_cz_out   (ex_pred_cz),
    .pred_is_w_out (ex_pred_is_w),

    .rf_we_cand_out (ex_rf_we_cand),
    .rf_waddr_out   (ex_rf_waddr),
    .wb_sel_out     (ex_wb_sel),

    .mem_rd_out (ex_mem_rd),
    .mem_wr_out (ex_mem_wr),

    .ccr_we_C_cand_out (ex_ccr_we_C_cand),
    .ccr_we_Z_cand_out (ex_ccr_we_Z_cand),

    .is_branch_out (ex_is_branch),
    .br_type_out   (ex_br_type),

    .is_jump_out     (ex_is_jump),
    .is_link_out     (ex_is_link),
    .jump_is_reg_out (ex_jump_is_reg)
);


// ------------------------------------------------------------
// EX stage outputs -> EX_MEM pipe inputs later
// ------------------------------------------------------------
logic [15:0] alu_res_x;
logic [15:0] store_data_x;
logic [15:0] pc2_x;
logic [15:0] imm_eff_x;

logic        rf_we_x;
logic [2:0]  rf_waddr_x;
logic [1:0]  wb_sel_x;

logic        mem_rd_x, mem_wr_x;

logic        ccr_we_C_x, ccr_we_Z_x;
logic        ccr_C_next_x, ccr_Z_next_x;



// ------------------------------------------------------------
// CCR regs in TOP (for now)
// ------------------------------------------------------------
logic ccr_C_q, ccr_Z_q;


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ccr_C_q <= 1'b0;
        ccr_Z_q <= 1'b0;
    end else begin
        if (ccr_we_C_x) ccr_C_q <= ccr_C_next_x;
        if (ccr_we_Z_x) ccr_Z_q <= ccr_Z_next_x;
    end
end



ex_stage u_ex (
    .opA_in              (ex_opA),
    .opB_in              (ex_opB),
    .store_data_in       (ex_store_data),
    .imm_eff_in          (ex_imm_eff),

    .pc_in               (ex_pc),
    .pc2_in              (ex_pc2),

    .alu_op_in           (ex_alu_op),
    .invert_b_in         (ex_invert_b),
    .use_carry_in_in     (ex_use_carry_in),

    .pred_en_in          (ex_pred_en),
    .pred_cz_in          (ex_pred_cz),
    .pred_is_w_in        (ex_pred_is_w),

    .rf_we_cand_in       (ex_rf_we_cand),
    .rf_waddr_in         (ex_rf_waddr),
    .wb_sel_in           (ex_wb_sel),

    .mem_rd_cand_in      (ex_mem_rd),
    .mem_wr_cand_in      (ex_mem_wr),

    .ccr_we_C_cand_in    (ex_ccr_we_C_cand),
    .ccr_we_Z_cand_in    (ex_ccr_we_Z_cand),

    .is_branch_in        (ex_is_branch),
    .br_type_in          (ex_br_type),
    .is_jump_in          (ex_is_jump),
    .is_link_in          (ex_is_link),
    .jump_is_reg_in      (ex_jump_is_reg),

    .ccr_C_in            (ccr_C_q),
    .ccr_Z_in            (ccr_Z_q),
	 
	 // --------- ADD THESE (forwarding) ----------
    .fwdA_sel            (fwdA_sel),
    .fwdB_sel            (fwdB_sel),
    .fwdS_sel            (fwdS_sel),
    .exmem_fwd_data      (exmem_fwd_data),
    .memwb_fwd_data      (memwb_fwd_data),
    // ------------------------------------------


    .alu_res_out         (alu_res_x),
    .store_data_out      (store_data_x),
    .pc2_out             (pc2_x),
    .imm_eff_out         (imm_eff_x),

    .rf_we_out           (rf_we_x),
    .rf_waddr_out        (rf_waddr_x),
    .wb_sel_out          (wb_sel_x),

    .mem_rd_out          (mem_rd_x),
    .mem_wr_out          (mem_wr_x),

    .ccr_we_C_out        (ccr_we_C_x),
    .ccr_we_Z_out        (ccr_we_Z_x),
    .ccr_C_next          (ccr_C_next_x),
    .ccr_Z_next          (ccr_Z_next_x),

    .redirect_en         (redirect_en_x),
    .redirect_pc         (redirect_pc_x)
);









// ------------------------------------------------------------
// EX_MEM pipeline outputs (inputs to MEM stage)
// ------------------------------------------------------------
logic [15:0] mem_alu_res;
logic [15:0] mem_store_data;
logic [15:0] mem_pc2;
logic [15:0] mem_imm_eff;

logic        mem_rf_we;
logic [2:0]  mem_rf_waddr;
logic [1:0]  mem_wb_sel;

logic        mem_mem_rd;
logic        mem_mem_wr;


// ------------------------------------------------------------
// EX_MEM pipeline stage
// ------------------------------------------------------------
ex_mem_pipe u_exmem (
    .clk            (clk),
    .rst_n          (rst_n),

    .stall          (1'b0),              // later connect hazard stall
    .flush          (redirect_en_x),      // bubble on redirect

    // ----- from EX stage -----
    .alu_res_in     (alu_res_x),
    .store_data_in  (store_data_x),
    .pc2_in         (pc2_x),
    .imm_eff_in     (imm_eff_x),

    .rf_we_in       (rf_we_x),
    .rf_waddr_in    (rf_waddr_x),
    .wb_sel_in      (wb_sel_x),

    .mem_rd_in      (mem_rd_x),
    .mem_wr_in      (mem_wr_x),

    // ----- to MEM stage -----
    .alu_res_out    (mem_alu_res),
    .store_data_out (mem_store_data),
    .pc2_out        (mem_pc2),
    .imm_eff_out    (mem_imm_eff),

    .rf_we_out      (mem_rf_we),
    .rf_waddr_out   (mem_rf_waddr),
    .wb_sel_out     (mem_wb_sel),

    .mem_rd_out     (mem_mem_rd),
    .mem_wr_out     (mem_mem_wr)
);

// ----------------------------
// MEM stage outputs to MEM/WB inputs
// ----------------------------
logic [15:0] wb_alu_res;
logic [15:0] wb_mem_rdata;
logic [15:0] wb_pc2;
logic [15:0] wb_imm_eff;

logic        wb_rf_we;
logic [2:0]  wb_rf_waddr;
logic [1:0]  wb_wb_sel;

// ----------------------------
// MEM stage <-> data memory wires
// ----------------------------
logic        dm_rd, dm_wr;
logic [15:0] dm_addr, dm_wdata, dm_rdata;




// ------------------------------------------------------------
// MEM  stage
// ------------------------------------------------------------


mem_stage u_mem_stage (
    // from EX/MEM pipe
    .alu_res_in     (mem_alu_res),
    .store_data_in  (mem_store_data),
    .pc2_in         (mem_pc2),
    .imm_eff_in     (mem_imm_eff),

    .mem_rd_in      (mem_mem_rd),
    .mem_wr_in      (mem_mem_wr),

    .rf_we_in       (mem_rf_we),
    .rf_waddr_in    (mem_rf_waddr),
    .wb_sel_in      (mem_wb_sel),

    // from data memory
    .mem_rdata_in   (dm_rdata),

    // to data memory
    .mem_rd_out     (dm_rd),
    .mem_wr_out     (dm_wr),
    .mem_addr_out   (dm_addr),
    .mem_wdata_out  (dm_wdata),

    // to MEM/WB
    .alu_res_out    (wb_alu_res),
    .mem_rdata_out  (wb_mem_rdata),
    .pc2_out        (wb_pc2),
    .imm_eff_out    (wb_imm_eff),

    .rf_we_out      (wb_rf_we),
    .rf_waddr_out   (wb_rf_waddr),
    .wb_sel_out     (wb_wb_sel)
);



// ----------------------------
// Data memory
// ----------------------------

data_memory #(
    .DEPTH(4096),
	 .MEMFILE("dmem_init.mem")
) u_dmem (
    .clk    (clk),
    .mem_rd (dm_rd),
    .mem_wr (dm_wr),
    .addr   (dm_addr),
    .wdata  (dm_wdata),
    .rdata  (dm_rdata)
);


// ----------------------------
// MEM/WB outputs -> WB inputs
// ----------------------------
logic        rf_we_wb;
logic [2:0]  rf_waddr_wb;
logic [1:0]  wb_sel_wb;

logic [15:0] alu_res_wb;
logic [15:0] mem_rdata_wb;
logic [15:0] pc2_wb;
logic [15:0] imm_eff_wb;


// ----------------------------
// Mem_WB Pipeline
// ----------------------------

mem_wb_pipe u_mem_wb (
    .clk          (clk),
    .rst_n        (rst_n),
    .stall        (1'b0),          // no hazards yet
    .flush        (1'b0),          // flush later if needed

    // from MEM stage
    .rf_we_in     (wb_rf_we),
    .rf_waddr_in  (wb_rf_waddr),
    .wb_sel_in    (wb_wb_sel),

    .alu_res_in   (wb_alu_res),
    .mem_rdata_in (wb_mem_rdata),
    .pc2_in       (wb_pc2),
    .imm_eff_in   (wb_imm_eff),

    // to WB stage
    .rf_we_out    (rf_we_wb),
    .rf_waddr_out (rf_waddr_wb),
    .wb_sel_out   (wb_sel_wb),

    .alu_res_out  (alu_res_wb),
    .mem_rdata_out(mem_rdata_wb),
    .pc2_out      (pc2_wb),
    .imm_eff_out  (imm_eff_wb)
);


// ----------------------------
// WB → Register File
// ----------------------------
logic        rf_we_commit;
logic [2:0]  rf_waddr_commit;
logic [15:0] rf_wdata_commit;


// ----------------------------
// WB Stage
// ----------------------------


wb_stage u_wb (
    // from MEM/WB
    .rf_we_in     (rf_we_wb),
    .rf_waddr_in  (rf_waddr_wb),
    .wb_sel_in    (wb_sel_wb),

    .alu_res_in   (alu_res_wb),
    .mem_rdata_in (mem_rdata_wb),
    .pc2_in       (pc2_wb),
    .imm_eff_in   (imm_eff_wb),

    // to register file
    .rf_we_out    (rf_we_commit),
    .rf_waddr_out (rf_waddr_commit),
    .rf_wdata_out (rf_wdata_commit)
);




reg_file u_rf (
    .clk    (clk),
    .rst_n  (rst_n),

    // Read addresses come from ID/RF pipe
    .raddr_a (id_rf_ra),
    .raddr_b (id_rf_rb),
    .rdata_a (rf_rdata_a),
    .rdata_b (rf_rdata_b),

    // write port from WB
    .we       (rf_we_commit),
    .waddr    (rf_waddr_commit),
    .wdata    (rf_wdata_commit)
);


//assign exmem_fwd_data = mem_alu_res;       // EX/MEM value to forward

// ------------------------------------------------------------
// EX/MEM forwarding data select (must match WB encoding)
// ------------------------------------------------------------
localparam logic [1:0] WB_ALU = 2'd0;
localparam logic [1:0] WB_MEM = 2'd1;
localparam logic [1:0] WB_PC2 = 2'd2;
localparam logic [1:0] WB_IMM = 2'd3;

always_comb begin
    unique case (mem_wb_sel)
        WB_IMM: exmem_fwd_data = mem_imm_eff;  // LLI
        WB_PC2: exmem_fwd_data = mem_pc2;      // JAL/JLR
        default: exmem_fwd_data = mem_alu_res; // ALU
    endcase
end
assign memwb_fwd_data = rf_wdata_commit;   // MEM/WB value to forward (final WB mux output)


forwarding_unit u_fwd (
    .ex_ra        (ex_ra),
    .ex_rb        (ex_rb),

    .ex_use_ra    (ex_use_ra),
    .ex_use_rb    (ex_use_rb),
    .ex_use_store (ex_use_store),

    .exmem_rf_we    (mem_rf_we),
    .exmem_rf_waddr (mem_rf_waddr),

    .memwb_rf_we    (rf_we_wb),
    .memwb_rf_waddr (rf_waddr_wb),

    .fwdA_sel (fwdA_sel),
    .fwdB_sel (fwdB_sel),
    .fwdS_sel (fwdS_sel)
);

logic stall_pc, stall_if_id, stall_id_rf, flush_id_rf, flush_rf_ex;
logic rf_use_ra, rf_use_rb, rf_use_store;

assign rf_use_ra    = 1'b1;
assign rf_use_rb    = 1'b1;
assign rf_use_store = 1'b1;

load_use_hazard_unit u_lu (
    .ex_mem_rd    (ex_mem_rd),
    .ex_rf_we     (ex_rf_we_cand),
    .ex_rf_waddr  (ex_rf_waddr),

    .rf_ra        (rf_ra),
    .rf_rb        (rf_rb),

    .rf_use_ra    (rf_use_ra),
    .rf_use_rb    (rf_use_rb),
    .rf_use_store (rf_use_store),

    .stall_pc     (stall_pc),
    .stall_if_id  (stall_if_id),
	 .stall_id_rf  (stall_id_rf),
    .flush_id_rf  (flush_id_rf),
    .flush_rf_ex  (flush_rf_ex)
);

// Apply stalls to your enables
assign pc_we    = ~stall_pc;
assign if_id_we = ~stall_if_id;
assign id_rf_we    = ~stall_id_rf;
assign rf_ex_stall = 1'b0;

// Apply bubble to RF_EX pipe
assign rf_ex_flush = flush_rf_ex | redirect_en;  // keep your redirect flush too

	 assign rf_we_commit_dbg    = rf_we_commit;
	 assign rf_waddr_commit_dbg = rf_waddr_commit;
	 assign rf_wdata_commit_dbg = rf_wdata_commit;




endmodule
