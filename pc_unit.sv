//This is where the process counter goes and associated hardware

module pc_unit (
    input  logic        clk,
    input  logic        reset,
    input  logic        wren,
    input  logic        pc_sel, // signal from controller module
    input  logic [31:0] alu_target, // from ALUOut mux

    output logic [31:0] pc, // address of the current instruction
    output logic [31:0] pc_plus_4 // address of next sequential instruction
);

    logic [31:0] pc_next;

    assign pc_plus_4 = pc + 32'd4;
    // If pc_sel is 1, pc_next is the address given by alu_target (for jumps and branches)
    // If pc_sel is 0, pc_next is just pc + 4
    assign pc_next = pc_sel ? alu_target : pc_plus_4;

    always_ff @(posedge clk) begin
        // Reset pc if reset is true (or 1)
        if (reset) begin
            pc <= 32'h0000_0000;
        end
        // Move onto the next instruction
        else if (wren) begin
            pc <= pc_next;
        end
    end
endmodule