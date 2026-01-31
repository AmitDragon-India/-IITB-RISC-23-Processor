module id_stage (
    // From IF/ID pipeline
    input  logic [15:0] pc_in,
    input  logic [15:0] pc2_in,
    input  logic [15:0] instr_in,

    // ---- basic decoded fields (always useful for debug) ----
    output logic [3:0]  opcode,
    output logic [2:0]  ra,
    output logic [2:0]  rb,
    output logic [2:0]  rc,

    output logic        r_comp,      // R-type only
    output logic [1:0]  r_cz,        // R-type only

    output logic [5:0]  imm6,
    output logic [8:0]  imm9,

    output logic [15:0] imm6_sext,
    output logic [15:0] imm9_sext,
    output logic [15:0] imm9_zext,

    // ---- control bundle to carry forward ----
    // Operand select for EX
    output logic [1:0]  srcA_sel,   // 00 regA, 01 regB, 10 PC, 11 reserved
    output logic [1:0]  srcB_sel,     // 00 regB, 01 imm, 10 const2, 11 reserved
	 
	 // Immediate value selection
	 output logic [1:0] imm_sel,      // 00 for imm6_sext, 01 for imm9_sext, 10 for imm9_zext 

    // ALU control
    output logic [2:0]  alu_op,       // see localparams below
    output logic        invert_b,     // for R-type complementing RB
    output logic        use_carry_in, // for AWC/ACW ("W" case in ADD family)

    // Predication control (only meaningful for R-type)
    output logic        pred_en,      // 1 only for R-type predicated ops
    output logic [1:0]  pred_cz,      // 00 always, 10 if C, 01 if Z, 11 special
    output logic        pred_is_w,    // 1 for ADD-family CZ=11 (AWC/ACW)

    // Writeback / side effects (candidates; EX will gate them with execute_enable)
    output logic        rf_we_cand,
    output logic [2:0]  rf_waddr,     // destination reg index (RB for ADI, RA for JAL/JLR/LLI, RC for R-type)
    output logic [1:0]  wb_sel,       // 00 ALU, 01 MEM, 10 PC2, 11 LLI_IMM

    output logic        mem_rd,
    output logic        mem_wr,

    output logic        ccr_we_C_cand,
    output logic        ccr_we_Z_cand,

    // Control-flow intent (EX will compute target & redirect)
    output logic        is_branch,
    output logic [1:0]  br_type,      // 00 BEQ, 01 BLT, 10 BLE
    output logic        is_jump,       // JAL/JLR/JRI
    output logic        is_link,       // JAL/JLR write PC+2
    output logic        jump_is_reg,   // 1 for JLR (target from regB), 0 for JAL/JRI (PC-relative imm)

    // validity
    output logic        illegal
);

    // ----------------------------
    // Opcode constants (from your screenshot)
    // ----------------------------
    localparam logic [3:0] OP_ADI = 4'b0000; // 00_00
    localparam logic [3:0] OP_ADD = 4'b0001; // 00_01 (ADA/ADC/ADZ/AWC + A*C via COMP)
    localparam logic [3:0] OP_NDU = 4'b0010; // 00_10 (NDU/NDC/NDZ + N*C via COMP)
    localparam logic [3:0] OP_LLI = 4'b0011; // 00_11

    localparam logic [3:0] OP_LW  = 4'b0100; // 01_00
    localparam logic [3:0] OP_SW  = 4'b0101; // 01_01

    localparam logic [3:0] OP_BEQ = 4'b1000; // 10_00
    localparam logic [3:0] OP_BLT = 4'b1001; // 10_01
    localparam logic [3:0] OP_BLE = 4'b1011; // 1011 (you confirmed)

    localparam logic [3:0] OP_JAL = 4'b1100; // 11_00
    localparam logic [3:0] OP_JLR = 4'b1101; // 11_01
    localparam logic [3:0] OP_JRI = 4'b1111; // 11_11

    // ----------------------------
    // ALU op encoding (internal)
    // ----------------------------
    localparam logic [2:0] ALU_ADD  = 3'd0;
    localparam logic [2:0] ALU_NAND = 3'd1;
    localparam logic [2:0] ALU_PASS = 3'd2; // pass B (used if needed)
    
    // wb_sel
    localparam logic [1:0] WB_ALU = 2'd0;
    localparam logic [1:0] WB_MEM = 2'd1;
    localparam logic [1:0] WB_PC2 = 2'd2;
    localparam logic [1:0] WB_IMM = 2'd3;
	 
	 // srcA_sel
	 localparam logic [1:0] A_RA = 2'd0;
	 localparam logic [1:0] A_RB = 2'd1;
	 localparam logic [1:0] A_PC = 2'd2;

    // srcB_sel
    localparam logic [1:0] B_REG  = 2'd0;
    localparam logic [1:0] B_IMM  = 2'd1;
    localparam logic [1:0] B_CONST2 = 2'd2;
	 
	 localparam logic [1:0] IMM6_SEXT = 2'd0;
	 localparam logic [1:0] IMM9_SEXT = 2'd1;
	 localparam logic [1:0] IMM9_ZEXT = 2'd2;

    // ----------------------------
    // Field extraction (all formats)
    // ----------------------------
    assign opcode = instr_in[15:12];
    assign ra     = instr_in[11:9];
    assign rb     = instr_in[8:6];
    assign rc     = instr_in[5:3];

    // R-type extras
    assign r_comp = instr_in[2];
    assign r_cz   = instr_in[1:0];

    // I-type immediate (lower 6)
    assign imm6 = instr_in[5:0];

    // J-type immediate (lower 9)
    assign imm9 = instr_in[8:0];

    // sign-extend immediates
    assign imm6_sext = {{10{imm6[5]}}, imm6};
    assign imm9_sext = {{7{imm9[8]}}, imm9};

    // zero-extend imm9 for LLI lower-bits load
    assign imm9_zext = {7'b0, imm9};

    // ----------------------------
    // Default control values
    // ----------------------------
    always_comb begin
        // Defaults: safe NOP-ish
        srcA_sel       = A_RA;
        srcB_sel       = B_REG;
		  
		  imm_sel        = IMM6_SEXT;

        alu_op         = ALU_ADD;
        invert_b       = 1'b0;
        use_carry_in   = 1'b0;

        pred_en        = 1'b0;
        pred_cz        = 2'b00;
        pred_is_w      = 1'b0;

        rf_we_cand     = 1'b0;
        rf_waddr       = 3'd0;
        wb_sel         = WB_ALU;

        mem_rd         = 1'b0;
        mem_wr         = 1'b0;

        ccr_we_C_cand  = 1'b0;
        ccr_we_Z_cand  = 1'b0;

        is_branch      = 1'b0;
        br_type        = 2'b00;

        is_jump        = 1'b0;
        is_link        = 1'b0;
        jump_is_reg    = 1'b0;

        illegal        = 1'b0;

        unique case (opcode)

            // ---------------- R-type ADD family ----------------
            OP_ADD: begin
                // ADA/ADC/ADZ/AWC and ACA/ACC/ACZ/ACW (via r_comp)
                srcA_sel    = A_RA;
                srcB_sel      = B_REG;
                alu_op        = ALU_ADD;

                invert_b      = r_comp;   // 1 => use ~RB
                pred_en       = 1'b1;
                pred_cz       = r_cz;

                // "W" case: CZ==11 means add-with-carry-in (execute always)
                if (r_cz == 2'b11) begin
                    pred_is_w    = 1'b1;
                    use_carry_in = 1'b1;  // cin = CCR.C in EX
                end

                rf_we_cand    = 1'b1;
                rf_waddr      = rc;       // dest = RC
                wb_sel        = WB_ALU;

                // ADD family modifies C and Z
                ccr_we_C_cand = 1'b1;
                ccr_we_Z_cand = 1'b1;
            end

            // ---------------- R-type NAND family ----------------
            OP_NDU: begin
                // NDU/NDC/NDZ and NCU/NCC/NCZ (via r_comp)
                srcA_sel    = A_RA;
                srcB_sel      = B_REG;
                alu_op        = ALU_NAND;

                invert_b      = r_comp;
                pred_en       = 1'b1;
                pred_cz       = r_cz;

                // CZ==11 not defined for NAND in your table => illegal
                if (r_cz == 2'b11) illegal = 1'b1;

                rf_we_cand    = 1'b1;
                rf_waddr      = rc;
                wb_sel        = WB_IMM;

                // NAND modifies Z only
                ccr_we_C_cand = 1'b0;
                ccr_we_Z_cand = 1'b1;
            end

            // ---------------- ADI (I-type) ----------------
            OP_ADI: begin
                // adi rb, ra, imm6  => RB = RA + sext(imm6)
                srcA_sel      = A_RA;
                srcB_sel      = B_IMM;
					 imm_sel       = IMM6_SEXT;
                alu_op        = ALU_ADD;

                rf_we_cand    = 1'b1;
                rf_waddr      = rb;       // dest = RB
                wb_sel        = WB_ALU;

                // modifies C and Z
                ccr_we_C_cand = 1'b1;
                ccr_we_Z_cand = 1'b1;

                // no predication in encoding => unconditional
                pred_en       = 1'b0;
                pred_cz       = 2'b00;
                pred_is_w     = 1'b0;
            end

            // ---------------- LLI (J-type) ----------------
            OP_LLI: begin
                // lli ra, imm9 => RA = {7'b0, imm9}
					 imm_sel       = IMM9_ZEXT;
                rf_we_cand    = 1'b1;
                rf_waddr      = ra;
                wb_sel        = WB_IMM;   // WB will take imm9_zext (or EX can output it)

                // no ALU needed, but keep something consistent
                alu_op        = ALU_PASS;
                srcB_sel      = B_IMM;

                // LLI does NOT mention flags in your table -> keep flags unchanged
                ccr_we_C_cand = 1'b0;
                ccr_we_Z_cand = 1'b0;
            end

            // ---------------- LW (I-type) ----------------
            OP_LW: begin
                // lw ra, rb, imm6 => RA = MEM[ RB + sext(imm6) ]
                srcA_sel      = A_RB;
                srcB_sel      = B_IMM;
					 imm_sel       = IMM6_SEXT;
                alu_op        = ALU_ADD;  // address calc

                mem_rd        = 1'b1;
                mem_wr        = 1'b0;

                rf_we_cand    = 1'b1;
                rf_waddr      = ra;
                wb_sel        = WB_MEM;

                // Your sheet says LW modifies Z flag (keep C unchanged)
                ccr_we_C_cand = 1'b0;
                ccr_we_Z_cand = 1'b1;
            end

            // ---------------- SW (I-type) ----------------
            OP_SW: begin
                // sw ra, rb, imm6 => MEM[ RB + sext(imm6) ] = RA
                srcA_sel      = A_RB;
                srcB_sel      = B_IMM;
					 imm_sel       = IMM6_SEXT;
                alu_op        = ALU_ADD;  // address calc

                mem_rd        = 1'b0;
                mem_wr        = 1'b1;

                rf_we_cand    = 1'b0;
                wb_sel        = WB_ALU;

                // Your sheet says SW modifies zero flag (we’ll compute Z from store-data or keep from addr/result later)
                ccr_we_C_cand = 1'b0;
                ccr_we_Z_cand = 1'b1;
            end

            // ---------------- Branches (I-type) ----------------
            OP_BEQ: begin
                // beq ra, rb, imm6 => if (RA == RB) PC = PC + imm6*2
                is_branch     = 1'b1;
                br_type       = 2'b00;    // BEQ
                srcA_sel      = A_RA;
                srcB_sel      = B_REG;
					 imm_sel       = IMM6_SEXT;

                // No RF write, no mem
                rf_we_cand    = 1'b0;
                mem_rd        = 1'b0;
                mem_wr        = 1'b0;

                // Branches do not modify flags
                ccr_we_C_cand = 1'b0;
                ccr_we_Z_cand = 1'b0;
            end

            OP_BLT: begin
                // blt ra, rb, imm6 => if (RA < RB) PC = PC + imm6*2
                is_branch     = 1'b1;
                br_type       = 2'b01;    // BLT
					 srcA_sel      = A_RA;
                srcB_sel      = B_REG;
					 imm_sel       = IMM6_SEXT;
					 
                rf_we_cand    = 1'b0;
                ccr_we_C_cand = 1'b0;
                ccr_we_Z_cand = 1'b0;
            end

            OP_BLE: begin
                // ble ra, rb, imm6 => if (RA <= RB) PC = PC + imm6*2
                is_branch     = 1'b1;
                br_type       = 2'b10;    // BLE
					 srcA_sel      = A_RA;
                srcB_sel      = B_REG;
					 imm_sel       = IMM6_SEXT;
					 
                rf_we_cand    = 1'b0;
                ccr_we_C_cand = 1'b0;
                ccr_we_Z_cand = 1'b0;
            end

            // ---------------- Jumps ----------------
            OP_JAL: begin
                // jal ra, imm9 => RA = PC+2; PC = PC + imm9*2
                is_jump       = 1'b1;
                is_link       = 1'b1;
                jump_is_reg   = 1'b0;
					 
					 srcA_sel      = A_PC;
					 srcB_sel      = B_IMM;
					 imm_sel       = IMM9_SEXT;
					 

                rf_we_cand    = 1'b1;
                rf_waddr      = ra;
                wb_sel        = WB_PC2;

                ccr_we_C_cand = 1'b0;
                ccr_we_Z_cand = 1'b0;
            end

            OP_JLR: begin
                // jlr ra, rb => RA = PC+2; PC = RB
                is_jump       = 1'b1;
                is_link       = 1'b1;
                jump_is_reg   = 1'b1;
					 
					 srcA_sel      = A_RB;
					 srcB_sel      = B_REG;

                rf_we_cand    = 1'b1;
                rf_waddr      = ra;
                wb_sel        = WB_PC2;

                ccr_we_C_cand = 1'b0;
                ccr_we_Z_cand = 1'b0;
            end

            OP_JRI: begin
                // jri ra, imm9 => PC = RA + imm9*2 (no link)
                is_jump       = 1'b1;
                is_link       = 1'b0;
                jump_is_reg   = 1'b0; // treated as PC-relative-like, but base is RA in EX
					 
					 srcA_sel      = A_RA;
					 srcB_sel      = B_IMM;
					 imm_sel       = IMM9_SEXT;

                rf_we_cand    = 1'b0;

                ccr_we_C_cand = 1'b0;
                ccr_we_Z_cand = 1'b0;
            end

            default: begin
                illegal = 1'b1;
            end
        endcase
    end

endmodule
