//This is the main register file

module register (
    input  logic        clk,
    input  logic        reset,
    input  logic        r_wren, // signal from controller module
    input  logic        rdsrc, // signal from controller module
    input  logic [31:0] instruction, // from the memory module
    input  logic [31:0] pc_plus_4, // from pc_unit module
    input  logic [31:0] dout, // from the memory module
    input  logic [31:0] alu_result, // from the ALU module
    input  logic [31:0] imm_etx, // from imm_etx module
    input  logic [1:0]  rdsrc, // signal from controller module

    output logic [31:0] rs1v, // the value stored inside register rs1
    output logic [31:0] rs2v // the value stored inside register rs2
);
    logic [31:0] regs [31:0];
    
    logic [4:0] rs1, rs2, rd; // register addresses
    logic [31:0] rdv; // register value that register rd is to be updated with

    // Slicing the inputted 32-bit instruction value into rs1, rs2, and rd
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign rd = instruction[11:7];

    // Assigning rs1v and rs2v to the values of registers rs1 and rs2
    // unless the register is x0, which is always 0
    assign rs1v = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
    assign rs2v = (rs2 == 5'd0) ? 32'd0 : regs[rs2];

    // Combinational block for the 4-to-1 mux
    always_comb begin
        unique case (rdsrc)
            2'd0: rdv = alu_result;
            2'd1: rdv = dout;
            2'd2: rdv = pc_plus_4;
            2'd3: rdv = imm_etx;
        endcase
    end

    // Sequential block handling resets and updating register values
    always_ff @(posedge clk) begin
        // Reset the values of all registers to 0 if reset is true
        if (reset) begin
            for (int i = 0; i < 32; i++) begin
                regs[i] <= 32'd0;
            end
        end
        // Update the value of register rd to the rdv if rd isn't x0
        else if (r_wren && (rd != 5'd0)) begin
            regs[rd] <= rdv;
        end
    end
    
endmodule