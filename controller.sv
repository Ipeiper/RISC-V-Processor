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


);(

)

endmodule