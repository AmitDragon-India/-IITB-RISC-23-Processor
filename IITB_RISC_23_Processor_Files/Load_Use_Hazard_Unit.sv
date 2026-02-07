module load_use_hazard_unit (
    // ----------------------------
    // Producer in EX stage (from RF_EX outputs)
    // ----------------------------
    input  logic       ex_mem_rd,        // 1 when EX instruction is a load
    input  logic       ex_rf_we,          // optional safety (can be tied 1 for loads)
    input  logic [2:0] ex_rf_waddr,       // destination register of the load

    // ----------------------------
    // Consumer in RF stage (current instruction before RF_EX)
    // ----------------------------
    input  logic [2:0] rf_ra,
    input  logic [2:0] rf_rb,

    // If you don't have decode-based use flags yet, tie these to 1'b1 for now.
    input  logic       rf_use_ra,
    input  logic       rf_use_rb,
    input  logic       rf_use_store,      // store data uses RA in your design

    // ----------------------------
    // Outputs: stall / flush controls
    // ----------------------------
    output logic       stall_pc,          // stop PC update
    output logic       stall_if_id,        // hold IF/ID reg
	 output logic       stall_id_rf,
    output logic       flush_id_rf,        // insert bubble into ID/RF (or RF/EX depending on your scheme)
    output logic       flush_rf_ex         // (recommended) bubble the RF_EX pipe
);

    logic hazard_ra, hazard_rb, hazard_store;
    logic load_in_ex;

    always_comb begin
        // defaults
        stall_pc    = 1'b0;
        stall_if_id = 1'b0;
		  stall_id_rf = 1'b0;
        flush_id_rf = 1'b0;
        flush_rf_ex = 1'b0;

        hazard_ra    = 1'b0;
        hazard_rb    = 1'b0;
        hazard_store = 1'b0;

        // "EX instruction is a load" condition (use ex_rf_we for extra safety)
        load_in_ex = ex_mem_rd & ex_rf_we & (ex_rf_waddr != 3'd0);

        // compare destination against RF sources
        if (load_in_ex) begin
            if (rf_use_ra    && (ex_rf_waddr == rf_ra)) hazard_ra    = 1'b1;
            if (rf_use_rb    && (ex_rf_waddr == rf_rb)) hazard_rb    = 1'b1;
            if (rf_use_store && (ex_rf_waddr == rf_ra)) hazard_store = 1'b1;
        end

        if (hazard_ra || hazard_rb || hazard_store) begin
            // Classic 1-cycle load-use stall:
            stall_pc    = 1'b1;
            stall_if_id = 1'b1;
				
				stall_id_rf = 1'b1;

            // Bubble the instruction entering EX (so load can proceed, consumer waits)
            flush_rf_ex = 1'b1;

            // If your design prefers flushing ID/RF instead, you can use this.
            // Typically you'd flush RF_EX, not ID_RF.
            flush_id_rf = 1'b0;
        end
    end

endmodule
