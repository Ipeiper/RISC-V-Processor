//This is the controller
// it should be controlled by a FSM that defines the phases of the multi cycle processor
// needs to know when to go back to start and cycle
// should go to the next phase each 
//Ian

module controller (
    input logic clk,
    //Instruction is the 32 bit long instruction coming from the instruction register
    //It will get pared down into its sub parts based on a number of factors
    input logic instruction,
    //The Zero flag from the ALU, used for operations like branch and comparison
    input logic ALUZero,

    //Outputs
    //controls whether to write current ALU output signal to micro arch register ALUout
    output logic ALUout,
    //Controls what type of opperation the ALU does
    output logic ALUctrl,
    //controls whether we use alu value held in ALUout or the new alu value
    output logic ALUsel,
    //write enable for the register file
    output logic regwren
    //write enable for the dmem file
    output logic DMEMwren
    //control signal for the immediate control
    // [Insert format here when we design it]
    output logic immextctrl
    //selector for where to source the input of PC from
    output logic PCsrc
    //controls when the instruction register should accept and hold the new input
    output logic IRctrl
    //selector for the multiplexer that controls the source for the ALU A channel
    output logic ALUsrcA
    //selector for the multiplexer that controls the source for the ALU B channel
    output logic ALUscrB
    //controls the write register destination multiplexer 
    output logic rdsel
    //outputs field func 3 from the instruction for use in the DMEM
    output logic func3
);

//pulls the opcode out of the instruciton
logic [6:0] opcode;
logic [2:0] funct3;
logic [6:0] funct7;

assign opcode = instruction[6:0];
assign funct3 = instr[14:12];
assign funct7 = instr[31:25];
//The numerical versions of the type words
localparam RTYPE = 3'b000
localparam JTYPE = 3'b001
localparam STYPE = 3'b010
localparam ITYPE = 3'b011
localparam BTYPE = 3'b100
localparam UTYPE = 3'b101
//variable defining instruction type
logic [2:0]type;
//new type to define the current instruction
typedef enum logic [5:0] {
    LUI, AUIPC, JAL, JALR,
    BEQ, BNE, BLT, BGE, BLTU, BGEU,
    LB, LH, LW, LBU, LHU,
    SB, SH, SW,
    ADDI, SLTI, SLTIU, XORI, ORI, ANDI,
    SLLI, SRLI, SRAI,
    ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND,
    ILLEGAL
} instruction_t;
//defines the current instruction using the new type
instruction_t curinst;

//Phase is the main variable behind the state of the FSM
logic [2:0]phase <=0;

//Main FSM that controls the processor
//seperated into different phases that are the cycles used by the processor
unique case (phase)
    : 0 begin // the very first phase. [insert what it does]

    end
    : 1 begin // the second phase
        
    end
    : 2 begin // the third phase

    end
    : 3 begin // the fourth phase

    end
endcase


//combinational that determines the instruction type from the instruction
always_comb begin
    case(opcode[6:2])
        :5'b0 1 1 0 0 1 1 begin // R-type
            type = RTYPE;
        end
        :5'b1 1 0 1 1 1 1 begin // J-type
            type = JTYPE;
        end
        :5'b0 1 0 0 0 1 1 begin //S-type
            type = STYPE;
        end
        :5'b1 1 0 0 1 1 1,5'b0 0 0 0 0 1 1,5'b0 0 1 0 0 1 1 begin //I-type
            type = ITYPE;
        end
        :5'b1 1 0 0 0 1 1 begin //B-type
            type = BTYPE;
        end
        :5'b0 1 1 0 1 1 1,5'b0 0 1 0 1 1 1 begin //U-type
            type = UTYPE;
        end

    endcase
    
end
//combinational that decodes the instruction and assigns it to curinst
always_comb begin

    curinst = ILLEGAL;

    case (opcode)
        
        7'b0110111: curinst = LUI;
        7'b0010111: curinst = AUIPC;

        7'b1101111: curinst = JAL;

        7'b1100111:
            if (funct3 == 3'b000)
                curinst = JALR;

        7'b1100011:
            case (funct3)
                3'b000: curinst = BEQ;
                3'b001: curinst = BNE;
                3'b100: curinst = BLT;
                3'b101: curinst = BGE;
                3'b110: curinst = BLTU;
                3'b111: curinst = BGEU;
            endcase

        7'b0000011:
            case (funct3)
                3'b000: curinst = LB;
                3'b001: curinst = LH;
                3'b010: curinst = LW;
                3'b100: curinst = LBU;
                3'b101: curinst = LHU;
            endcase

        7'b0100011:
            case (funct3)
                3'b000: curinst = SB;
                3'b001: curinst = SH;
                3'b010: curinst = SW;
            endcase

        7'b0010011:
            case (funct3)

                3'b000: curinst = ADDI;
                3'b010: curinst = SLTI;
                3'b011: curinst = SLTIU;
                3'b100: curinst = XORI;
                3'b110: curinst = ORI;
                3'b111: curinst = ANDI;

                3'b001:
                    if (funct7 == 7'b0000000)
                        curinst = SLLI;

                3'b101:
                    case (funct7)
                        7'b0000000: curinst = SRLI;
                        7'b0100000: curinst = SRAI;
                    endcase

            endcase

        7'b0110011:
            case (funct3)

                3'b000:
                    case (funct7)
                        7'b0000000: curinst = ADD;
                        7'b0100000: curinst = SUB;
                    endcase

                3'b001:
                    if (funct7 == 7'b0000000)
                        curinst = SLL;

                3'b010:
                    if (funct7 == 7'b0000000)
                        curinst = SLT;

                3'b011:
                    if (funct7 == 7'b0000000)
                        curinst = SLTU;

                3'b100:
                    if (funct7 == 7'b0000000)
                        curinst = XOR;

                3'b101:
                    case (funct7)
                        7'b0000000: curinst = SRL;
                        7'b0100000: curinst = SRA;
                    endcase

                3'b110:
                    if (funct7 == 7'b0000000)
                        curinst = OR;

                3'b111:
                    if (funct7 == 7'b0000000)
                        curinst = AND;

            endcase
    endcase

end

endmodule