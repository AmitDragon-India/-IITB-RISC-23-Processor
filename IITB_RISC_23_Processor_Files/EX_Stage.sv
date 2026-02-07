module ex_stage (
    // =========================
    // Inputs from RF/EX pipe
    // =========================
    input  logic [15:0] opA_in,
    input  logic [15:0] opB_in,
    input  logic [15:0] store_data_in,
	 input  logic [15:0] imm_eff_in,

    input  logic [15:0] pc_in,
    input  logic [15:0] pc2_in,
	 
	 // =========================
    // Forwarding control + data
    // =========================
    input  logic [1:0]  fwdA_sel,
    input  logic [1:0]  fwdB_sel,
    input  logic [1:0]  fwdS_sel,          // store-data forwarding
    input  logic [15:0] exmem_fwd_data,    // EX/MEM forwarding value (ALU result)
    input  logic [15:0] memwb_fwd_data,     // MEM/WB forwarding value (final WB data)

    // ALU control
    input  logic [2:0]  alu_op_in,
    input  logic        invert_b_in,
    input  logic        use_carry_in_in,

    // Predication control (R-type)
    input  logic        pred_en_in,
    input  logic [1:0]  pred_cz_in,
    input  logic        pred_is_w_in,

    // Side effects (candidates from ID)
    input  logic        rf_we_cand_in,
    input  logic [2:0]  rf_waddr_in,
    input  logic [1:0]  wb_sel_in,

    input  logic        mem_rd_cand_in,
    input  logic        mem_wr_cand_in,

    input  logic        ccr_we_C_cand_in,
    input  logic        ccr_we_Z_cand_in,

    // Control-flow intent
    input  logic        is_branch_in,
    input  logic [1:0]  br_type_in,        // 00 BEQ, 01 BLT, 10 BLE
    input  logic        is_jump_in,         // JAL/JLR/JRI
    input  logic        is_link_in,         // JAL/JLR write PC+2
    input  logic        jump_is_reg_in,     // 1 JLR, 0 JAL/JRI

    // CCR current flags (from CCR reg)
    input  logic        ccr_C_in,
    input  logic        ccr_Z_in,

    // =========================
    // Outputs to EX/MEM pipe
    // =========================
    output logic [15:0] alu_res_out,
    output logic [15:0] store_data_out,     // forward store data
    output logic [15:0] pc2_out,            // needed for WB_PC2
	 output  logic [15:0] imm_eff_out,

    // Gated side-effects (execute_enable applied)
    output logic        rf_we_out,
    output logic [2:0]  rf_waddr_out,
    output logic [1:0]  wb_sel_out,

    output logic        mem_rd_out,
    output logic        mem_wr_out,

    output logic        ccr_we_C_out,
    output logic        ccr_we_Z_out,
    output logic        ccr_C_next,
    output logic        ccr_Z_next,

    // Redirect back to IF
    output logic        redirect_en,
    output logic [15:0] redirect_pc
);

    // -----------------------------------
    // Local encodings (match ID stage)
    // -----------------------------------
    localparam logic [2:0] ALU_ADD  = 3'd0;
    localparam logic [2:0] ALU_NAND = 3'd1;
    localparam logic [2:0] ALU_PASS = 3'd2;

    // br_type
    localparam logic [1:0] BR_BEQ = 2'd0;
    localparam logic [1:0] BR_BLT = 2'd1;
    localparam logic [1:0] BR_BLE = 2'd2;
	 
	 
	 assign imm_eff_out = imm_eff_in;
	 
	     // -----------------------------------
    // Forwarded operands
    // -----------------------------------
    logic [15:0] opA_fwd, opB_fwd, store_data_fwd;

    // 00 = no fwd (use pipe input)
    // 10 = from EX/MEM
    // 01 = from MEM/WB
    always_comb begin
        // defaults
        opA_fwd = opA_in;
        opB_fwd = opB_in;
        store_data_fwd = store_data_in;

        unique case (fwdA_sel)
            2'b10: opA_fwd = exmem_fwd_data;
            2'b01: opA_fwd = memwb_fwd_data;
            default: /* 00 */ ;
        endcase

        unique case (fwdB_sel)
            2'b10: opB_fwd = exmem_fwd_data;
            2'b01: opB_fwd = memwb_fwd_data;
            default: /* 00 */ ;
        endcase

        unique case (fwdS_sel)
            2'b10: store_data_fwd = exmem_fwd_data;
            2'b01: store_data_fwd = memwb_fwd_data;
            default: /* 00 */ ;
        endcase
    end
 

    // -----------------------------------
    // 1) Execute enable (predication)
    // -----------------------------------
    logic execute_en;

    always_comb begin
        if (!pred_en_in) begin
            execute_en = 1'b1;                 // non-R-type (and unconditional ops)
        end
        else if (pred_is_w_in) begin
            execute_en = 1'b1;                 // "W" case executes always (AWC/ACW)
        end
        else begin
            unique case (pred_cz_in)
                2'b00: execute_en = 1'b1;      // always
                2'b10: execute_en = ccr_C_in;  // if C
                2'b01: execute_en = ccr_Z_in;  // if Z
                default: execute_en = 1'b1;    // reserved -> treat as always
            endcase
        end
    end

    // -----------------------------------
    // 2) ALU computation
    // -----------------------------------
    logic [15:0] b_eff;
    logic        cin;
    logic [16:0] add_ext; // carry in MSB

    always_comb begin
        b_eff = invert_b_in ? ~opB_fwd : opB_fwd;
        cin   = (use_carry_in_in) ? ccr_C_in : 1'b0;

        unique case (alu_op_in)
            ALU_ADD:  begin
                add_ext     = {1'b0, opA_fwd} + {1'b0, b_eff} + {16'b0, cin};
                alu_res_out = add_ext[15:0];
            end
            ALU_NAND: begin
                add_ext     = 17'd0;
                alu_res_out = ~(opA_fwd & b_eff);
            end
            ALU_PASS: begin
                add_ext     = 17'd0;
                alu_res_out = b_eff;
            end
            default: begin
                add_ext     = 17'd0;
                alu_res_out = 16'h0000;
            end
        endcase
    end

    // -----------------------------------
    // 3) Next CCR flags (computed from ALU result)
    // -----------------------------------
    logic z_calc;
    logic c_calc;

    always_comb begin
        z_calc = (alu_res_out == 16'h0000);

        // Carry meaningful only for ADD; for other ops, we still compute but only write if enabled
        c_calc = (alu_op_in == ALU_ADD) ? add_ext[16] : 1'b0;

        ccr_C_next = c_calc;
        ccr_Z_next = z_calc;
    end

    // Gate CCR writes with execute_en
    always_comb begin
        ccr_we_C_out = execute_en & ccr_we_C_cand_in;
        ccr_we_Z_out = execute_en & ccr_we_Z_cand_in;
    end

    // -----------------------------------
    // 4) Gate RF + MEM side effects with execute_en
    // -----------------------------------
    always_comb begin
        rf_we_out     = execute_en & rf_we_cand_in;
        rf_waddr_out  = rf_waddr_in;
        wb_sel_out    = wb_sel_in;

        mem_rd_out    = execute_en & mem_rd_cand_in;
        mem_wr_out    = execute_en & mem_wr_cand_in;

        store_data_out = store_data_fwd;
        pc2_out        = pc2_in;
    end

    // -----------------------------------
    // 5) Branch / Jump resolution (redirect)
    // -----------------------------------
    logic branch_taken;
    logic [15:0] br_target;
    logic [15:0] j_target;

    always_comb begin
        // default
        branch_taken = 1'b0;
        br_target    = 16'h0000;
        j_target     = 16'h0000;

        // Branch target: PC + (imm6 << 1)
        br_target = pc_in + ($signed(imm_eff_in) <<< 1);

        // Jump targets:
        // JAL: PC + (imm9 << 1)
        // JRI: RA + (imm9 << 1)  => opA_in should be RA for JRI
        // JLR: RB                => opA_in should be RB for JLR (you routed srcA_sel = A_RB)
        if (jump_is_reg_in) begin
            j_target = opA_fwd; // JLR
        end else begin
            // for JAL and JRI:
            // - JAL base = PC
            // - JRI base = RA
            // We distinguish using is_link_in:
            //   JAL sets is_link_in=1, JRI sets is_link_in=0
            if (is_link_in) begin
                j_target = pc_in + ($signed(imm_eff_in) <<< 1);    // JAL
            end else begin
                j_target = opA_fwd + ($signed(imm_eff_in) <<< 1);   // JRI
            end
        end

        // Branch decision uses opA/opB compare
        if (is_branch_in) begin
            unique case (br_type_in)
                BR_BEQ: branch_taken = (opA_fwd == opB_fwd);
                BR_BLT: branch_taken = ($signed(opA_fwd) <  $signed(opB_fwd));
                BR_BLE: branch_taken = ($signed(opA_fwd) <= $signed(opB_fwd));
                default: branch_taken = 1'b0;
            endcase
        end
    end

    // Redirect generation:
    // - Jumps always redirect (no predication on jumps in your ISA)
    // - Branch redirects only if taken
    always_comb begin
        redirect_en = 1'b0;
        redirect_pc = 16'h0000;

        if (is_jump_in) begin
            redirect_en = 1'b1;
            redirect_pc = j_target;
        end
        else if (is_branch_in && branch_taken) begin
            redirect_en = 1'b1;
            redirect_pc = br_target;
        end
    end

endmodule
