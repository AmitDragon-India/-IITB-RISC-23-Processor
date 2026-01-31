module forwarding_unit (
    // ----------------------------
    // Source regs in EX stage
    // ----------------------------
    input  logic [2:0] ex_ra,
    input  logic [2:0] ex_rb,

    // Always-on use flags (for now)
    input  logic       ex_use_ra,
    input  logic       ex_use_rb,
    input  logic       ex_use_store,   // store data uses RA in your design

    // ----------------------------
    // EX/MEM stage destination
    // ----------------------------
    input  logic       exmem_rf_we,
    input  logic [2:0] exmem_rf_waddr,

    // ----------------------------
    // MEM/WB stage destination
    // ----------------------------
    input  logic       memwb_rf_we,
    input  logic [2:0] memwb_rf_waddr,

    // ----------------------------
    // Forward select outputs
    // 00: no forward (use regfile value)
    // 10: forward from EX/MEM
    // 01: forward from MEM/WB
    // ----------------------------
    output logic [1:0] fwdA_sel,
    output logic [1:0] fwdB_sel,
    output logic [1:0] fwdS_sel
);

    always_comb begin
        // defaults
        fwdA_sel = 2'b00;
        fwdB_sel = 2'b00;
        fwdS_sel = 2'b00;

        // ----------------------------
        // Forward for opA (uses ex_ra)
        // ----------------------------
        if (ex_use_ra && exmem_rf_we && (exmem_rf_waddr == ex_ra) && (exmem_rf_waddr != 3'd0)) begin
            fwdA_sel = 2'b10; // EX/MEM
        end
        else if (ex_use_ra && memwb_rf_we && (memwb_rf_waddr == ex_ra) && (memwb_rf_waddr != 3'd0)) begin
            fwdA_sel = 2'b01; // MEM/WB
        end

        // ----------------------------
        // Forward for opB (uses ex_rb)
        // ----------------------------
        if (ex_use_rb && exmem_rf_we && (exmem_rf_waddr == ex_rb) && (exmem_rf_waddr != 3'd0)) begin
            fwdB_sel = 2'b10; // EX/MEM
        end
        else if (ex_use_rb && memwb_rf_we && (memwb_rf_waddr == ex_rb) && (memwb_rf_waddr != 3'd0)) begin
            fwdB_sel = 2'b01; // MEM/WB
        end

        // ----------------------------
        // Forward for store_data (uses ex_ra in your design)
        // ----------------------------
        if (ex_use_store && exmem_rf_we && (exmem_rf_waddr == ex_ra) && (exmem_rf_waddr != 3'd0)) begin
            fwdS_sel = 2'b10; // EX/MEM
        end
        else if (ex_use_store && memwb_rf_we && (memwb_rf_waddr == ex_ra) && (memwb_rf_waddr != 3'd0)) begin
            fwdS_sel = 2'b01; // MEM/WB
        end
    end

endmodule
