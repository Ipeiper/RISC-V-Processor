//This is the controller
// it should be controlled by a FSM that defines the phases of the multi cycle processor
// needs to know when to go back to start and cycle
// should go to the next phase each 
//Ian

module controller (
    input logic clk,
    //Instruction is the 32 bit long instruction coming from the instruction register
    //It will get pared down into its sub parts based on a number of factors
    input logic [31:0] instruction,
    //The Zero flag from the ALU, used for operations like branch and comparison
    input logic ALUZero,
    // the Negative flag from the ALU, tells us if the output is negative
    input logic ALUNeg,
    // the Carry flag from the ALU, tells us if the alu overflowed when it did an unsigned operation
    input logic ALUCarry,
    // the Overflow flag from the ALU, tells us if the alu overflowed when it did a signed operation
    input logic ALUOver,

    //Outputs
    //1' controls whether to write current ALU output signal to micro arch register ALUout
    output logic [0:0] ALUout,
    //4' Controls what type of opperation the ALU does
    output logic [3:0] ALUctrl,
    //1' controls whether we use alu value held in ALUout or the new alu value
    output logic [0:0] ALUsel,
    //1' write enable for the register file
    output logic [0:0] regwren,
    //1' write enable for the dmem file
    output logic [0:0] DMEMwren,
    //control signal for the immediate control
    // [Insert format here when we design it]
    output logic [2:0] immextctrl,
    //selector for where to source the input of PC from
    output logic [0:0] PCsrc,
    //Write enable for the pc counter
    output logic [0:0] PCwren,
    //controls when the instruction register should accept and hold the new input
    output logic [0:0] IRctrl,
    //selector for the multiplexer that controls the source for the ALU A channel
    output logic [0:0] ALUsrcA,
    //selector for the multiplexer that controls the source for the ALU B channel
    output logic [0:0] ALUscrB,
    //controls the write register destination multiplexer 
    output logic [1:0] rdsrc,
    //outputs field func 3 from the instruction for use in the DMEM
    output logic [2:0] func3
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

//defines exception for when we try and decode an invalid instruction, throws it high
logic [0:0] exception = 1'b0;

//Phase is the main variable behind the state of the FSM
logic [2:0]phase <=0;

//Var that is enabled when the instruction is done, sending 

//Main FSM that controls the processor
//seperated into different phases that are the cycles used by the processor
always_ff (@posedge clk) begin
    //creates local temporary variable that represents when the FSM should end and return to 

    unique case (phase)
        : 0  // the very first phase. this is where we fetch the instruction. therefore, we have no clue what the instruction is and cannot use it
            //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=1,IRctrl=1,rdsrc=00
            assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000000000001100;
            phase <= 1;
        : 1 // the second phase. this is where we let the instruction flow into the register and the fsm to decode the instruction
            //therefore, all the controler has to do is wait and turn the instruction control off.
            // this is where we compute the branch target and record it in ALU out for use in instrucitons like beq
            //sets ALUout=1,ALUctrl=0000,ALUsel=0,ALUsrcA=1,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=011,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
            assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100000110001100000;
            phase <= 2;
        : 2  // the third phase. this is where things start getting executed. we already have the register values and the instruction decoded
            unique case (curinst)
                : LUI  // Load Upper Immmediate
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000000000000000;
                : AUIPC  // Add Upper Immediate to PC
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 12'b000000000000;
                : JAL  // Jump And Link
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 12'b000000000000;
                : JALR  // Jump And Link Register
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 12'b000000000000;
                : BEQ  // Branch Equal
                //sets ALUout=0,ALUctrl=0001,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100000000000000000;
                phase <= 3; // sets to 3 not for memory access, but to evaluate what to do now that we have the zero flag
                : BNE  // Branch Not Equal
                //sets ALUout=0,ALUctrl=0001,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100000000000000000;
                phase <= 3; // sets to 3 not for memory access, but to evaluate what to do now that we have the zero flag
                : BLT  // Branch Less Than
                //sets ALUout=0,ALUctrl=0001,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100000000000000000;
                phase <= 3; // sets to 3 not for memory access, but to evaluate what to do now that we have the zero flag
                : BGE  // Branch Greater or Equal
                //sets ALUout=0,ALUctrl=0001,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100000000000000000;
                phase <= 3; // sets to 3 not for memory access, but to evaluate what to do now that we have the zero flag
                : BLTU  // Branch Less Than Unsigned
                //sets ALUout=0,ALUctrl=0001,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100000000000000000;
                phase <= 3; // sets to 3 not for memory access, but to evaluate what to do now that we have the zero flag
                : BGEU  // Branch Greater or Equal Unsigned
                //sets ALUout=0,ALUctrl=0001,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100000000000000000;
                phase <= 3; // sets to 3 not for memory access, but to evaluate what to do now that we have the zero flag
                : LB  // Load Byte
                //sets ALUout=1,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100000010000000000;
                phase <=3;
                : LH  // Load Halfword
                //sets ALUout=1,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100000010000000000;
                phase <=3;
                : LW  // Load Word
                //sets ALUout=1,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100000010000000000;
                phase <=3;
                : LBU  // Load Byte Unsigned
                //sets ALUout=1,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100000010000000000;
                phase <=3;
                : LHU  // Load Halfword Unsigned
                //sets ALUout=1,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100000010000000000;
                phase <=3;
                : SB  // Store Byte
                //sets ALUout=1,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100000010000000000;
                phase <=3;
                : SH  // Store Halfword
                //sets ALUout=1,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100000010000000000;
                phase <=3;
                : SW  // Store Word
                //sets ALUout=1,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100000010000000000;
                phase <=3;
                : ADDI  // Add Immediate
                //sets ALUout=1,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100000000000000000;
                phase <=4;
                : SLTI  // Set Less Than Immediate
                //sets ALUout=1,ALUctrl=1000,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b110000010000000000;
                phase <=4;
                : SLTIU  // Set Less Than Immediate Unsigned
                //sets ALUout=1,ALUctrl=1001,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b110010010000000000;
                phase <=4;
                : XORI  // Exclusive Or Immediate
                //sets ALUout=1,ALUctrl=0100,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b101000010000000000;
                phase <=4;
                : ORI  // Or Immediate
                //sets ALUout=1,ALUctrl=0011,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100110010000000000;
                phase <=4;
                : ANDI  // And Immediate
                //sets ALUout=1,ALUctrl=0010,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100100010000000000;
                phase <=4;
                : SLLI  // Shift Left Logical Immediate
                //sets ALUout=1,ALUctrl=0101,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b101010010000000000;
                phase <=4;
                : SRLI  // Shift Right Logical Immediate
                //sets ALUout=1,ALUctrl=0110,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b101100010000000000;
                phase <=4;
                : SRAI  // Shift Right Arithmetic Immediate
                //sets ALUout=1,ALUctrl=0111,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b101110010000000000;
                phase <=4;
                : ADD  // Add
                //sets ALUout=1,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100000000000000000;
                phase <=4;
                : SUB  // Subtract
                //sets ALUout=1,ALUctrl=0001,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100010000000000000;
                phase <=4;
                : SLL  // Shift Left Logical
                //sets ALUout=1,ALUctrl=0101,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b101010000000000000;
                phase <=4;
                : SLT  // Set Less Than
                //sets ALUout=1,ALUctrl=1000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b110000000000000000;
                phase <=4;
                : SLTU  // Set Less Than Unsigned
                //sets ALUout=1,ALUctrl=1001,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b110010000000000000;
                phase <=4;
                : XOR  // Exclusive Or
                //sets ALUout=1,ALUctrl=0100,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b101000000000000000;
                phase <=4;
                : SRL  // Shift Right Logical
                //sets ALUout=1,ALUctrl=0110,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b101100000000000000;
                phase <=4;
                : SRA  // Shift Right Arithmetic
                //sets ALUout=1,ALUctrl=0111,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b101110000000000000;
                phase <=4;
                : OR  // Or
                //sets ALUout=1,ALUctrl=0011,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100110000000000000;
                phase <=4;
                : AND  // And
                //sets ALUout=1,ALUctrl=0010,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b100100000000000000;
                phase <=4;
                : ILLEGAL  // an illegal state that shouldnt exist and only arrises from improperly decoded instrucitons
                assign exception = 1'b1;
                
            endcase
        : 3  // the fourth phase. memory access the dmem
            unique case (curinst)
                : LUI  // Load Upper Immmediate
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 12'b000000000000;
                : AUIPC  // Add Upper Immediate to PC
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 12'b000000000000;
                : JAL  // Jump And Link
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 12'b000000000000;
                : JALR  // Jump And Link Register
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 12'b000000000000;
                : BEQ  // Branch Equal
                if (ALUZero == 1) begin
                    //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=1,PCwren=1,IRctrl=0,rdsrc=00
                    assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000000000011000;
                    phase<=0;
                end
                else begin
                    //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                    assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000000000000000;
                    phase<=0;
                end
                : BNE  // Branch Not Equal
                if (ALUZero == 0) begin
                    //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=1,PCwren=1,IRctrl=0,rdsrc=00
                    assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000000000011000;
                    phase<=0;
                end
                else begin
                    //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                    assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000000000000000;
                    phase<=0;
                end
                : BLT  // Branch Less Than
                if (ALUNeg ^ ALUOver) begin
                    //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=1,PCwren=1,IRctrl=0,rdsrc=00
                    assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000000000011000;
                    phase<=0;
                end
                else begin
                    //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                    assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000000000000000;
                    phase<=0;
                end
                : BGE  // Branch Greater or Equal
                if (!(ALUNeg ^ ALUOver)) begin
                    //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=1,PCwren=1,IRctrl=0,rdsrc=00
                    assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000000000011000;
                    phase<=0;
                end
                else begin
                    //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                    assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000000000000000;
                    phase<=0;
                end
                : BLTU  // Branch Less Than Unsigned
                if (!ALUCarry) begin
                    //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=1,PCwren=1,IRctrl=0,rdsrc=00
                    assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000000000011000;
                    phase<=0;
                end
                else begin
                    //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                    assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000000000000000;
                    phase<=0;
                end
                : BGEU  // Branch Greater or Equal Unsigned
                if (ALUCarry) begin
                    //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=1,PCwren=1,IRctrl=0,rdsrc=00
                    assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000000000011000;
                    phase<=0;
                end
                else begin
                    //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                    assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000000000000000;
                    phase<=0;
                end
                : LB  // Load Byte
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000010000000000;
                phase <= 4;
                : LH  // Load Halfword
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000010000000000;
                phase <= 4;
                : LW  // Load Word
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000010000000000;
                phase <= 4;
                : LBU  // Load Byte Unsigned
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000010000000000;
                phase <= 4;
                : LHU  // Load Halfword Unsigned
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000010000000000;
                phase <= 4;
                : SB  // Store Byte
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=1,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000010000000000;
                phase <= 0;
                : SH  // Store Halfword
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=1,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000010000000000;
                phase <= 0;
                : SW  // Store Word
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=1,regwren=0,DMEMwren=1,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000010000000000;
                phase <= 0;
                : ADDI  // Add Immediate
                //should not exist
                phase <=4;
                : SLTI  // Set Less Than Immediate
                //should not exist
                phase <=4;
                : SLTIU  // Set Less Than Immediate Unsigned
                //should not exist
                phase <=4;
                : XORI  // Exclusive Or Immediate
                //should not exist
                phase <=4;
                : ORI  // Or Immediate
                //should not exist
                phase <=4;
                : ANDI  // And Immediate
                //should not exist
                phase <=4;
                : SLLI  // Shift Left Logical Immediate
                //should not exist
                phase <=4;
                : SRLI  // Shift Right Logical Immediate
                //should not exist
                phase <=4;
                : SRAI  // Shift Right Arithmetic Immediate
                //should not exist
                phase <=4;
                : ADD  // Add
                //should not exist
                phase <=4;
                : SUB  // Subtract
                //should not exist
                phase <=4;
                : SLL  // Shift Left Logical
                //should not exist
                phase <=4;
                : SLT  // Set Less Than
                //should not exist
                phase <=4;
                : SLTU  // Set Less Than Unsigned
                //should not exist
                phase <=4;
                : XOR  // Exclusive Or
                //should not exist
                phase <=4;
                : SRL  // Shift Right Logical
                //should not exist
                phase <=4;
                : SRA  // Shift Right Arithmetic
                //should not exist
                phase <=4;
                : OR  // Or
                //should not exist
                phase <=4;
                : AND  // And
                //should not exist
                phase <=4;
                : ILLEGAL  // Load Upper Immmediate
                assign exception = 1'b1;
                
            endcase
        : 4  // the fifth phase. this is where we write the data back to the register
            unique case (curinst)
                : LUI  // Load Upper Immmediate
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 12'b000000000000;
                : AUIPC  // Add Upper Immediate to PC
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 12'b000000000000;
                : JAL  // Jump And Link
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 12'b000000000000;
                : JALR  // Jump And Link Register
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 12'b000000000000;
                : BEQ  // Branch Equal
                //should not exist
                phase <=0;
                : BNE  // Branch Not Equal
                //should not exist
                phase <=0;
                : BLT  // Branch Less Than
                //should not exist
                phase <=0;
                : BGE  // Branch Greater or Equal
                //should not exist
                phase <=0;
                : BLTU  // Branch Less Than Unsigned
                //should not exist
                phase <=0;
                : BGEU  // Branch Greater or Equal Unsigned
                //should not exist
                phase <=0;
                : LB  // Load Byte
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=1,IRctrl=0,rdsrc=01
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b00000000100001001;
                phase <=0;
                : LH  // Load Halfword
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=1,IRctrl=0,rdsrc=01
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b00000000100001001;
                phase <=0;
                : LW  // Load Word
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=1,IRctrl=0,rdsrc=01
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b00000000100001001;
                phase <=0;
                : LBU  // Load Byte Unsigned
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=1,IRctrl=0,rdsrc=01
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b00000000100001001;
                phase <=0;
                : LHU  // Load Halfword Unsigned
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=1,IRctrl=0,rdsrc=01
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b00000000100001001;
                phase <=0;
                : SB  // Store Byte
                //should not exist
                phase <=0;
                : SH  // Store Halfword
                //should not exist
                phase <=0;
                : SW  // Store Word
                //should not exist
                phase <=0;
                : ADDI  // Add Immediate
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000001000000000;
                phase <=0;
                : SLTI  // Set Less Than Immediate
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000001000000000;
                phase <=0;
                : SLTIU  // Set Less Than Immediate Unsigned
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000001000000000;
                phase <=0;
                : XORI  // Exclusive Or Immediate
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000001000000000;
                phase <=0;
                : ORI  // Or Immediate
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000001000000000;
                phase <=0;
                : ANDI  // And Immediate
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000001000000000;
                phase <=0;
                : SLLI  // Shift Left Logical Immediate
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000001000000000;
                phase <=0;
                : SRLI  // Shift Right Logical Immediate
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000001000000000;
                phase <=0;
                : SRAI  // Shift Right Arithmetic Immediate
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000001000000000;
                phase <=0;
                : ADD  // Add
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000001000000000;
                phase <=0;
                : SUB  // Subtract
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000001000000000;
                phase <=0;
                : SLL  // Shift Left Logical
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000001000000000;
                phase <=0;
                : SLT  // Set Less Than
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000001000000000;
                phase <=0;
                : SLTU  // Set Less Than Unsigned
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000001000000000;
                phase <=0;
                : XOR  // Exclusive Or
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000001000000000;
                phase <=0;
                : SRL  // Shift Right Logical
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000001000000000;
                phase <=0;
                : SRA  // Shift Right Arithmetic
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000001000000000;
                phase <=0;
                : OR  // Or
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000001000000000;
                phase <=0;
                : AND  // And
                //sets ALUout=0,ALUctrl=0000,ALUsel=0,ALUsrcA=0,ALUscrB=0,regwren=1,DMEMwren=0,immextctrl=000,PCsrc=0,PCwren=0,IRctrl=0,rdsrc=00
                assign {ALUout,ALUctrl,ALUsel,ALUsrcA,ALUscrB,regwren,DMEMwren,immextctrl,PCsrc,PCwren,IRctrl,rdsrc}= 18'b000000001000000000;
                phase <=0;
                : ILLEGAL  // Load Upper Immmediate
                assign exception = 1'b1;
                
            endcase

    endcase
end

//combinational that determines the instruction type from the instruction
always_comb begin
    case(opcode[6:2])
        :5'b0 1 1 0 0 1 1  // R-type
            type = RTYPE;
        :5'b1 1 0 1 1 1 1  // J-type
            type = JTYPE;
        :5'b0 1 0 0 0 1 1  //S-type
            type = STYPE;
        :5'b1 1 0 0 1 1 1,5'b0 0 0 0 0 1 1,5'b0 0 1 0 0 1 1  //I-type
            type = ITYPE;
        :5'b1 1 0 0 0 1 1  //B-type
            type = BTYPE;
        :5'b0 1 1 0 1 1 1,5'b0 0 1 0 1 1 1  //U-type
            type = UTYPE;

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