//This is where the process counter goes and associated hardware

module pc_unit (
    input  logic        clk,
    input  logic        reset,
    input  logic        wren,
    input  logic        pc_sel,
    input  logic [31:0] alu_target, // from ALUOut mux

    output logic [31:0] pc,
    output logic [31:0] pc_plus_4   // to Rdsel mux input 2
);

    logic [31:0] pc_next;

    assign pc_plus_4 = pc + 32'd4;
    assign pc_next = pc_sel ? alu_target : pc_plus_4;

    always_ff @(posedge clk) begin
        if (reset) begin
            pc <= 32'h0000_0000;
        end
        else if (wren) begin
            pc <= pc_next;
        end
    end
endmodule