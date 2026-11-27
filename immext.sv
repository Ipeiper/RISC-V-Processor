//This is the immediate value extender
//it should do sign extention

module immext (
    input  logic [31:0] inst, // from the memory module, same thing as instruction
    input  logic [2:0]  imm_src, // signal from controller module

    output logic [31:0] imm_ext // extended 32-bit immediate value
);
    always_comb begin
        unique case (imm_src)
            3'b000: imm_ext = {{20{inst[31]}}, inst[31:20]}; // I-type
            3'b001: imm_ext = {{20{inst[31]}}, inst[31:25], inst[11:7]}; // S-type
            3'b010: imm_ext = {{19{inst[31]}}, inst[31], 
                                inst[7], inst[30:25], inst[11:8], 1'b0}; // B-type
            3'b011: imm_ext = {inst[31:12], 12'b0}; // U-type
            3'b100: imm_ext = {{11{inst[31]}}, inst[31], inst[19:12], 
                                inst[20], inst[30:21], 1'b0}; // J-type
            // R-type does not have immediate values and is thus DNC
            default: imm_ext = 32'd0;
        endcase
    end
endmodule