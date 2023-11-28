module mips_with_fwd (clk1, clk2);
  input clk1, clk2; 

 
  reg [31:0] PC, IF_ID_IR, IF_ID_NPC;
  reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;
  reg [2:0] ID_EX_type, EX_MEM_type, MEM_WB_type;
  reg [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;
  reg EX_MEM_cond;
  reg [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;
  reg [31:0] Reg [0:31]; 
  reg [31:0] Mem [0:1023];
  reg HALTED; 
  reg TAKEN_BRANCH; 
  reg [31:0] forwardA, forwardB; 

  
  parameter ADD=6'b000000, SUB=6'b000001, AND=6'b000010, OR=6'b000011,
            SLT=6'b000100, HLT=6'b111111, LW=6'b001000,
            SW=6'b001001, ADDI=6'b001010, SUBI=6'b001011, SLTI=6'b001100,
            BNEQZ=6'b001101, BEQZ=6'b001110;
  parameter RR_ALU=3'b000, RM_ALU=3'b001, LOAD=3'b010, STORE=3'b011,
            BRANCH=3'b100, HALT=3'b101;

  // IF Stage
  always @(posedge clk1)
    if (HALTED == 0)
      if (TAKEN_BRANCH)
        begin
          IF_ID_IR <= Mem[PC]; // Fetch the instruction at the branch target
          TAKEN_BRANCH <= 0; // Reset the TAKEN_BRANCH flag
          IF_ID_NPC <= PC + 1; 
          PC <= PC + 1;
        end
      else
        begin
          IF_ID_IR <= Mem[PC];
          IF_ID_NPC <= PC + 1;
          PC <= PC + 1;
        end

  // ID Stage
  always @(posedge clk2)
    if (HALTED == 0)
      begin
        ID_EX_A <= (IF_ID_IR[25:21] == 5'b00000) ? 0 : Reg[IF_ID_IR[25:21]]; // "rs"
        ID_EX_B <= (IF_ID_IR[20:16] == 5'b00000) ? 0 : Reg[IF_ID_IR[20:16]]; // "rt"
        ID_EX_NPC <= IF_ID_NPC;
        ID_EX_IR <= IF_ID_IR;
        ID_EX_Imm <= {{16{IF_ID_IR[15]}}, IF_ID_IR[15:0]};
        // Determine operation type
        case (IF_ID_IR[31:26])
          ADD, SUB, AND, OR, SLT: ID_EX_type <= RR_ALU;
          ADDI, SUBI, SLTI: ID_EX_type <= RM_ALU;
          LW: ID_EX_type <= LOAD;
          SW: ID_EX_type <= STORE;
          BNEQZ, BEQZ: ID_EX_type <= BRANCH;
          HLT: ID_EX_type <= HALT;
          default: ID_EX_type <= HALT; // Invalid opcode
        endcase
      end

  // EX Stage
  always @(posedge clk1)
    if (HALTED == 0)
      begin
        // Forwarding for A
        if (MEM_WB_IR[15:11] == ID_EX_IR[25:21] && MEM_WB_type == RR_ALU) 
          forwardA = MEM_WB_ALUOut; // Forward from WB stage
        else if (EX_MEM_IR[15:11] == ID_EX_IR[25:21] && EX_MEM_type == RR_ALU)
          forwardA = EX_MEM_ALUOut; // Forward from MEM stage
        else 
          forwardA = ID_EX_A; // No forwarding

        // Forwarding for B
        if (MEM_WB_IR[15:11] == ID_EX_IR[20:16] && MEM_WB_type == RR_ALU) 
          forwardB = MEM_WB_ALUOut; // Forward from WB stage
        else if (EX_MEM_IR[15:11] == ID_EX_IR[20:16] && EX_MEM_type == RR_ALU)
          forwardB = EX_MEM_ALUOut; // Forward from MEM stage
        else 
          forwardB = ID_EX_B; // No forwarding

        EX_MEM_type <= ID_EX_type;
        EX_MEM_IR <= ID_EX_IR;
        TAKEN_BRANCH <= 0;

        case (ID_EX_type)
          RR_ALU: // RR-ALU operations
            case (ID_EX_IR[31:26]) // "opcode"
              ADD: EX_MEM_ALUOut <= forwardA + forwardB;
              SUB: EX_MEM_ALUOut <= forwardA - forwardB;
              AND: EX_MEM_ALUOut <= forwardA & forwardB;
              OR: EX_MEM_ALUOut <= forwardA | forwardB;
              SLT: EX_MEM_ALUOut <= forwardA < forwardB;
              default: EX_MEM_ALUOut <= 32'hxxxxxxxx;
            endcase

          RM_ALU: // RM-ALU operations
            case (ID_EX_IR[31:26]) // "opcode"
              ADDI: EX_MEM_ALUOut <= forwardA + ID_EX_Imm;
              SUBI: EX_MEM_ALUOut <= forwardA - ID_EX_Imm;
              SLTI: EX_MEM_ALUOut <= forwardA < ID_EX_Imm;
              default: EX_MEM_ALUOut <= 32'hxxxxxxxx;
            endcase

          LOAD, STORE: 
            begin
              EX_MEM_ALUOut <= forwardA + ID_EX_Imm;
              EX_MEM_B <= forwardB;
            end

          BRANCH: 
            begin
              EX_MEM_ALUOut <= ID_EX_NPC + ID_EX_Imm;
              EX_MEM_cond <= (forwardA == 0);
            end
        endcase;
      end

  // MEM Stage
  always @(posedge clk2)
    if (HALTED == 0) 
      begin
        MEM_WB_type <= EX_MEM_type;
        MEM_WB_IR <= EX_MEM_IR;

        case (EX_MEM_type)
          RR_ALU, RM_ALU: MEM_WB_ALUOut <= EX_MEM_ALUOut;
          LOAD: MEM_WB_LMD <= Mem[EX_MEM_ALUOut];
          STORE: if (TAKEN_BRANCH == 0) Mem[EX_MEM_ALUOut] <= EX_MEM_B;
        endcase;
      end

  // WB Stage
  always @(posedge clk1)
    if (HALTED == 0 && TAKEN_BRANCH == 0) 
      begin
        case (MEM_WB_type)
          RR_ALU: Reg[MEM_WB_IR[15:11]] <= MEM_WB_ALUOut; // "rd"
          RM_ALU: Reg[MEM_WB_IR[20:16]] <= MEM_WB_ALUOut; // "rt"
          LOAD: Reg[MEM_WB_IR[20:16]] <= MEM_WB_LMD; // "rt"
          HALT: HALTED <= 1'b1;
        endcase;
      end
endmodule
