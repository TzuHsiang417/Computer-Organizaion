`timescale 1ns / 1ps

module CPU_B(clk,PC);
input clk;
output PC;
reg [31:0]PC;
wire [31:0] ins,pc_IF,pc_ID,pc_EX,IF_ID_ins_out;
wire RegWrite,ID_EX_RegDst_in,Jump,ID_EX_ALUsrc_in,ID_EX_MemtoReg_in,ID_EX_RegWrite_in,ID_EX_MemRead_in,ID_EX_MemWrite_in,ID_EX_Branch_in;
wire ID_EX_RegDst_out,ID_EX_ALUsrc_out,ID_EX_MemtoReg_out,ID_EX_RegWrite_out,ID_EX_MemRead_out,ID_EX_MemWrite_out,ID_EX_Branch_out;
wire [1:0] ID_EX_ALUop_out,ID_EX_ALUop_in;
wire [4:0]write_reg;
wire [31:0] read_reg1,read_reg2,read_data2_in,read_data1_in,write_data ;
wire [31:0] read_data1_out,read_data2_out;
wire [31:0] t0,t1,t2,t3,t4,t5,t6,t7;
wire [15:0] address_in;
wire [31:0] address_out;
wire [4:0] ID_EX_RegisterRt_in,ID_EX_RegisterRt_out,ID_EX_RegisterRd_in,ID_EX_RegisterRd_out;
wire [31:0] sign_extend_in,sign_extend_out;
wire [3:0] alu_Ctr;
wire [31:0] alu_muxo, alu_out, address_byte, EX_ADD_branch_out;
wire [4:0] write_register_mux_out;
wire zero;
wire [31:0] PC_next;
wire [27:0] jump_28;
wire [31:0] jump_address;
wire [31:0] branch_mux_out;

wire EX_MEM_Regwrite_out,EX_MEM_MemtoReg_out,EX_MEM_Branch_out,EX_MEM_MemRead_out,EX_MEM_MemWrite_out,EX_MEM_Zero_out;
wire [31:0]EX_MEM_ALU_result_out,EX_MEM_Write_mem_out,EX_MEM_Add_branch_out;
wire [4:0] EX_MEM_Write_reg_out;
wire branch_and_out;
 wire [31:0] read_data; 
 wire [31:0] WB_Read_data_out,WB_ALU_result_out;
 wire WB_MemtoReg_out;
 wire real_jump;
//PC?n?g
initial
  begin
  PC <= 0;
  end
always@(posedge clk)
begin
    PC<=PC_next;
end


ins_memory U2(.clk(clk), .read_address(PC), .instruction(ins));

IF_ID_pipeline_register U3 (.clk(clk), .pc_4_in(pc_IF), .instruction_in(ins), .pc_4_out(pc_ID), .instruction_out(IF_ID_ins_out));

register_file U4(.clk(clk), .RegWrite(RegWrite), .read_reg1(IF_ID_ins_out[25:21]), .read_reg2(IF_ID_ins_out[20:16]),
                     .write_reg(write_reg), .write_data(write_data), .read_data1(read_data1_in), .read_data2(read_data2_in), 
                       .t0(t0),.t1(t1),.t2(t2),.t3(t3),.t4(t4),.t5(t5),.t6(t6),.t7(t7));
  
  sign_extend U5(.address_in(IF_ID_ins_out[15:0]), .address_out(address_out));
  control U6(.signal(IF_ID_ins_out[31:26]), .RegDst(ID_EX_RegDst_in), .Jump(Jump), .ALUsrc(ID_EX_ALUsrc_in), .MemtoReg(ID_EX_MemtoReg_in), 
                                .RegWrite(ID_EX_RegWrite_in), .MemRead(ID_EX_MemRead_in), .MemWrite(ID_EX_MemWrite_in), .Branch(ID_EX_Branch_in), .ALUop(ID_EX_ALUop_in));

  
   ID_EX_pipeline_register U7( .clk(clk), .ID_EX_RegDst_in(ID_EX_RegDst_in),
   .ID_EX_ALUsrc_in(ID_EX_ALUsrc_in), .ID_EX_MemtoReg_in(ID_EX_MemtoReg_in), .ID_EX_RegWrite_in(ID_EX_RegWrite_in), 
   .ID_EX_MemRead_in(ID_EX_MemRead_in), .ID_EX_MemWrite_in(ID_EX_MemWrite_in), .ID_EX_Branch_in(ID_EX_Branch_in), .ID_EX_ALUop_in(ID_EX_ALUop_in),
                               .ID_EX_RegDst_out(ID_EX_RegDst_out), .ID_EX_ALUsrc_out(ID_EX_ALUsrc_out), .ID_EX_MemtoReg_out(ID_EX_MemtoReg_out),
                               .ID_EX_RegWrite_out(ID_EX_RegWrite_out), .ID_EX_MemRead_out(ID_EX_MemRead_out), .ID_EX_MemWrite_out(ID_EX_MemWrite_out),
                               .ID_EX_Branch_out(ID_EX_Branch_out), .ID_EX_ALUop_out(ID_EX_ALUop_out),
                               .read_data1_in(read_data1_in), .read_data2_in(read_data2_in), .read_data1_out(read_data1_out), .read_data2_out(read_data2_out),
                                .ID_EX_RegisterRt_in(IF_ID_ins_out[20:16]), .ID_EX_RegisterRd_in(IF_ID_ins_out[15:11]),
                                .ID_EX_RegisterRt_out(ID_EX_RegisterRt_out), .ID_EX_RegisterRd_out(ID_EX_RegisterRd_out),
                              .sign_extend_in(address_out), .sign_extend_out(sign_extend_out),
                               .pc_in(pc_ID), .pc_out(pc_EX)
                            );
  
  alu_control U8( .func(sign_extend_out[5:0]), .aluop(ID_EX_ALUop_out), .alu_Ctr(alu_Ctr));
  
  reg2alu_mux U9(.alusrc(ID_EX_ALUsrc_out), .reg2(read_data2_out), .extended(sign_extend_out), .muxo(alu_muxo));
  
  alu U10( .alu_ctr(alu_Ctr), .a(read_data1_out), .b(alu_muxo), .alu_out(alu_out), .zero(zero));
  
  write_register_mux U11(.RegDst(ID_EX_RegDst_out), .rd(ID_EX_RegisterRd_out), .rt(ID_EX_RegisterRt_out), .write_reg(write_register_mux_out));

  shift_left_2_I_format U12 (.address_word(sign_extend_out), .address_byte(address_byte));
  
  Branch_Add U13 (.branch_byte(address_byte), .PC_4(pc_EX), .branch_out(EX_ADD_branch_out));
  

  EX_MEM_pipeline_register U14(.clk(clk), .Regwrite_in(ID_EX_RegWrite_out),
                .MemtoReg_in(ID_EX_MemtoReg_out), .Branch_in(ID_EX_Branch_out), .MemRead_in(ID_EX_MemRead_out), .MemWrite_in(ID_EX_MemWrite_out), 
                .Add_branch_in(EX_ADD_branch_out), .Zero_in(zero), .ALU_result_in(alu_out), .Write_mem_in(read_data2_out), 
                .Write_reg_in(write_register_mux_out), 
                .Regwrite_out(EX_MEM_Regwrite_out), .MemtoReg_out(EX_MEM_MemtoReg_out), .Branch_out(EX_MEM_Branch_out), 
                .MemRead_out(EX_MEM_MemRead_out), .MemWrite_out(EX_MEM_MemWrite_out), .Add_branch_out(EX_MEM_Add_branch_out), .Zero_out(EX_MEM_Zero_out), 
                 .ALU_result_out(EX_MEM_ALU_result_out), .Write_mem_out(EX_MEM_Write_mem_out), .Write_reg_out(EX_MEM_Write_reg_out));
                 
Branch_AND U15(.a(EX_MEM_Zero_out), .b(EX_MEM_Branch_out), .branch_and_out(branch_and_out));   

data_memory U16 (.clk(clk), .MemWrite(EX_MEM_MemWrite_out), .MemRead(EX_MEM_MemRead_out), .address(EX_MEM_ALU_result_out), 
                    .write_data(EX_MEM_Write_mem_out), .read_data(read_data));              
 
 
 
MEM_WB_pipeline_register U17(.clk(clk), .Regwrite_in(EX_MEM_Regwrite_out), .MemtoReg_in(EX_MEM_MemtoReg_out), 
.Read_data_in(read_data), .ALU_result_in(EX_MEM_ALU_result_out), .Write_reg_in(EX_MEM_Write_reg_out),
.Regwrite_out(RegWrite), .MemtoReg_out(WB_MemtoReg_out), .Read_data_out(WB_Read_data_out), .ALU_result_out(WB_ALU_result_out), .Write_reg_out(write_reg));
 
write_data_mux U18(.MemtoReg(WB_MemtoReg_out), .read_data(WB_Read_data_out), .ALU_result(WB_ALU_result_out), .write_data(write_data));  

 shift_left_2_jump U19 (.address_word(ins[25:0]), .address_byte(jump_28));
 
 jump_mix U20 (.pc_4_3128(pc_IF[31:28]), .address_in(jump_28), .jump_address(jump_address));
 
 branch_mux U21 (.pc_4(pc_IF), .branch_add_result(EX_MEM_Add_branch_out), .branch_and(branch_and_out), .branch_mux_out(branch_mux_out));

jump_mux U22 (.jump(real_jump), .jump_address(jump_address), .branch_mux_out(branch_mux_out), .pc_next(PC_next));

PC_Add4 U23(.PC(PC), .PC_4(pc_IF));

jump_determine U24(.instructions(ins[31:26]),.jump_or_not(real_jump));

endmodule

module ins_memory(clk,read_address,instruction);

input clk;
input [31:0]read_address; // PC
output reg[31:0]instruction;

reg [31:0] instruction_memoroy [31:0];

initial
    begin
        // Loop
        instruction_memoroy[0] = 32'b100011_01011_01001_0000000000000000;	 // lw $t1 ,0($t3)
        instruction_memoroy[1] = 32'b001000_01010_01101_0000000000000100;   // addi $t5 ,$t2 , 4
        instruction_memoroy[2] = 32'b000000_01010_01011_01110_00000_100010;   // sub $t6 ,$t2 ,$t3
        instruction_memoroy[3] = 32'b000000_01001_01100_01111_00000_100101;  // or $t7 ,$t1 ,$t4
        instruction_memoroy[4] = 32'b000000_01001_01101_01011_00000_100100;   // and $t3,$t1,$t5 
        instruction_memoroy[5] = 32'b000100_01000_01010_1111111111111010;   // beq $t0 ,$t2,LOOP
        instruction_memoroy[6] = 32'b000000_01010_01100_01010_00000_100000; // add $t2 ,$t2 ,$t4
        instruction_memoroy[7] = 32'b101011_01011_01001_0000000000010100;	// sw $t1 ,20($t3)
        instruction_memoroy[8] = 32'b000000_01000_01101_01100_00000_101010; // slt $t4,$t0,$t5
        instruction_memoroy[9] = 32'b000010_00000000000000000000000000;     // j LOOP 
    end

always@(*)
    begin
        instruction <= instruction_memoroy[read_address/4];
    end
          
endmodule

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module control(signal, RegDst,Jump,ALUsrc,MemtoReg,RegWrite,MemRead,MemWrite,Branch,ALUop);
input signal;
output RegDst,ALUsrc,Jump,MemtoReg,RegWrite,MemRead,MemWrite,Branch,ALUop;
reg[1:0] ALUop;
reg RegDst,ALUsrc,Jump,MemtoReg,RegWrite,MemRead,MemWrite,Branch;
wire[5:0] signal;

always@(signal)
begin
 case(signal)
 6'b000000:begin RegDst=1'b1; ALUsrc=1'b0 ;Jump=1'b0; MemtoReg=1'b0 ; RegWrite=1'b1 ; MemRead=1'b0 ; MemWrite=1'b0 ; Branch=1'b0;ALUop=2'b10; end//R format
 6'b100011:begin RegDst=1'b0; ALUsrc=1'b1 ;Jump=1'b0; MemtoReg=1'b1 ; RegWrite=1'b1 ; MemRead=1'b1 ; MemWrite=1'b0 ; Branch=1'b0;ALUop=2'b00; end//lw
 6'b101011:begin RegDst=1'bX; ALUsrc=1'b1 ;Jump=1'b0;  MemtoReg=1'bX ; RegWrite=1'b0 ; MemRead=1'b0 ; MemWrite=1'b1 ; Branch=1'b0;ALUop=2'b00; end//sw
 6'b000100:begin RegDst=1'bX; ALUsrc=1'b0 ;Jump=1'b0;  MemtoReg=1'bX ; RegWrite=1'b0 ; MemRead=1'b0 ; MemWrite=1'b0 ; Branch=1'b1;ALUop=2'b01; end//beq
 6'b001000:begin RegDst=1'b0; ALUsrc=1'b1 ;Jump=1'b0;  MemtoReg=1'b0 ; RegWrite=1'b1 ; MemRead=1'b0 ; MemWrite=1'b0 ; Branch=1'b0;ALUop=2'b00; end//addi
 6'b000010:begin RegDst=1'bX; ALUsrc=1'bX ;Jump=1'b1;  MemtoReg=1'bX ; RegWrite=1'b0 ; MemRead=1'b0 ; MemWrite=1'b0 ; Branch=1'b0;ALUop=2'bXX; end//jump

default: begin RegDst=1'bX; ALUsrc=1'bX ; MemtoReg=1'bX ; RegWrite=1'bX ; MemRead=1'bX ; MemWrite=1'bX ; Branch=1'bX;ALUop=2'bXX; end
 endcase
end

endmodule

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module register_file(clk,RegWrite,read_reg1,read_reg2,write_reg,write_data,read_data1,read_data2,t0,t1,t2,t3,t4,t5,t6,t7);

input clk;

input RegWrite; // Control

// read_reg1,read_reg2,write_reg ?s address
input [4:0] read_reg1; // rs
input [4:0] read_reg2; //  R-type : rt , lw : X
input [4:0] write_reg; // R-type : rd , lw : rt

// ALU operation ??n 32-bit data
input [31:0] write_data;
output reg [31:0] read_data1;
output reg [31:0] read_data2;

output reg [31:0] t0,t1,t2,t3,t4,t5,t6,t7;

initial
    begin
        t0 = 0;
        t1 = 1;
        t2 = 2;
        t3 = 3;
        t4 = 4;
        t5 = 5;
        t6 = 6;
        t7 = 7;
    end
    
always@(*)
    begin
        case(read_reg1)
        8 : read_data1 = t0;
        9 : read_data1 = t1;
        10 : read_data1 = t2;
        11 : read_data1 = t3;
        12 : read_data1 = t4;
        13 : read_data1 = t5;
        14 : read_data1 = t6;
        15 : read_data1 = t7;
        default : read_data1 = 32'dX;
        endcase
    end

always@(*)
    begin
        case(read_reg2)
        8 : read_data2 = t0;
        9 : read_data2 = t1;
        10 : read_data2 = t2;
        11 : read_data2 = t3;
        12 : read_data2 = t4;
        13 : read_data2 = t5;
        14 : read_data2 = t6;
        15 : read_data2 = t7;
        default : read_data2 = 32'dX;
        endcase 
    end
    
always@(posedge clk)
    begin
        if(RegWrite)
            begin
                case(write_reg)
                    8 : t0 <= write_data;
                    9 : t1 <= write_data;
                    10 : t2 <= write_data;
                    11 : t3 <= write_data;
                    12 : t4 <= write_data;
                    13 : t5 <= write_data;
                    14 : t6 <= write_data;
                    15 : t7 <= write_data;
                endcase    
            end
        else
            begin
                t0 <= t0;
                t1 <= t1;
                t2 <= t2;
                t3 <= t3;
                t4 <= t4;
                t5 <= t5;
                t6 <= t6;
                t7 <= t7;
            end
    end    
 
endmodule

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module sign_extend(address_in,address_out);

// address ?b MIPS code ??? 16-bit ,?? sign-extension ?? 32-bit , ?~??i??ALU?B??
input [15:0] address_in;
output [31:0] address_out;

assign address_out = { {16{address_in[15]}} , address_in}; // ?????0 ?t???1

endmodule

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module write_register_mux(RegDst,rd,rt,write_reg);

input RegDst; // Control
input [4:0] rd; // R-type destination
input [4:0] rt; // lw destination

output reg [4:0] write_reg;

always@(*)
    begin
        case(RegDst) // ??? opcode ?o?? Instruction ?? type
            0 : write_reg = rt; // lw
            1 : write_reg = rd; // R-type
            default : write_reg = 5'dX;
        endcase
    end

endmodule
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module reg2alu_mux(alusrc,reg2,extended,muxo);

input alusrc;
input [31:0]reg2,extended;
output reg [31:0] muxo;

always@(alusrc or reg2 or extended)
    begin
        if(alusrc) 
            muxo=extended;    
        else muxo=reg2;     
    end

endmodule

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module alu( alu_ctr,a,b,alu_out,zero);
    
    input [31:0] a,b;
    input[3:0] alu_ctr;
    output reg [31:0] alu_out;
    output reg zero;
    
    always@(a or b or alu_ctr)
        begin
            case (alu_ctr)
                4'b0000: alu_out = a & b;
                4'b0001: alu_out = a | b;
                4'b0010: alu_out = a + b;
                4'b0110: alu_out = a - b;
                4'b0111: alu_out = a < b;
                4'b1100: alu_out = a ~^ b;
                default: alu_out = 32'dX;
            endcase 
    end
    
    always@(alu_out)
        begin
            if (alu_out==32'b0)
                zero=1'b1;
            else 
                zero=1'b0;
            end
    
endmodule

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module alu_control( func,aluop,alu_Ctr);
input [5:0] func;
input [1:0] aluop;
output reg [3:0] alu_Ctr;


always@(func or aluop)
    begin
        case (aluop)
            2'b00: alu_Ctr=4'b0010; // lw,sw
            2'b01: alu_Ctr=4'b0110; // beq
            2'b10:
                begin     
                    if(func==6'b100000) // add
                        alu_Ctr=4'b0010;
                    else if (func==6'b100010) // sub
                        alu_Ctr=4'b0110;
                    else if (func==6'b100100) // AND
                        alu_Ctr=4'b0000;
                    else if (func==6'b100101) // OR
                        alu_Ctr=4'b0001;
                    else if (func==6'b101010) // slt
                        alu_Ctr=4'b0111;
                    else
                        alu_Ctr=4'b1111;
                end
            default: alu_Ctr=4'b1111; 
        endcase
    end


endmodule

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module data_memory(clk,MemWrite,MemRead,address,write_data,read_data);

input clk;

input MemWrite; // Control for sw
input MemRead; // Control for lw

input [31:0] address; //  rt address
input [31:0] write_data; // sw
output reg [31:0] read_data; // lw

reg [31:0] memory_data [31:0]; // 32 ?? register ?? 32-bit data 

initial
    begin
        memory_data[0] = 0;  
        memory_data[1] = 1;  
        memory_data[2] = 2;  
        memory_data[3] = 3;  
        memory_data[4] = 4; 
        memory_data[5] = 5;  
        memory_data[6] = 6;  
        memory_data[7] = 7;  
        memory_data[8] = 0;  
        memory_data[9] = 0;
        memory_data[10] = 0;  
        memory_data[11] = 0;
        memory_data[12] = 0; 
        memory_data[13] = 0;  
        memory_data[14] = 0;  
        memory_data[15] = 0;  
        memory_data[16] = 0;  
        memory_data[17] = 0;  
        memory_data[18] = 0;  
        memory_data[19] = 0;  
        memory_data[20] = 0; 
        memory_data[21] = 0;  
        memory_data[22] = 0;  
        memory_data[23] = 0;  
        memory_data[24] = 0;  
        memory_data[25] = 0;  
        memory_data[26] = 0;  
        memory_data[27] = 0;  
        memory_data[28] = 0; 
        memory_data[29] = 0;  
        memory_data[30] = 0;  
        memory_data[31] = 0;  
    end
    
always@(negedge clk)
    begin
        if(MemWrite && ! MemRead) // sw
             memory_data[address] <= write_data;    
        else 
             memory_data[address] <= memory_data[address]; 
    end
    
always@(*)
    begin
        if(MemRead && !MemWrite) // lw
            read_data = memory_data[address];    
        else 
            read_data = 32'dX; 
    end

endmodule

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module write_data_mux(MemtoReg,read_data,ALU_result,write_data);

input MemtoReg; // Control

input [31:0] read_data; // lw
input [31:0] ALU_result; // R-format

output reg [31:0] write_data;

always@(*)
    begin
        case(MemtoReg)
            0 : write_data = ALU_result; // R-format
            1 : write_data = read_data; // lw
            default : write_data = 32'dX;
        endcase
    end

endmodule

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module IF_ID_pipeline_register(clk,pc_4_in,instruction_in,pc_4_out,instruction_out);

input clk;

//input IF_ID_Write;

input [31:0] pc_4_in;
input [31:0] instruction_in;

output reg [31:0] pc_4_out;
output reg [31:0] instruction_out;

always@(posedge clk)
    begin
// ?S?? Hazard detection ??H?g?J?s??PC+4 
              pc_4_out <= pc_4_in;
              instruction_out <= instruction_in;

    end

endmodule
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module ID_EX_pipeline_register(clk,ID_EX_RegDst_in,ID_EX_ALUsrc_in,ID_EX_MemtoReg_in,ID_EX_RegWrite_in,ID_EX_MemRead_in,ID_EX_MemWrite_in,ID_EX_Branch_in,ID_EX_ALUop_in,
                               ID_EX_RegDst_out,ID_EX_ALUsrc_out,ID_EX_MemtoReg_out,ID_EX_RegWrite_out,ID_EX_MemRead_out,ID_EX_MemWrite_out,ID_EX_Branch_out,ID_EX_ALUop_out,
                               read_data1_in,read_data2_in,read_data1_out,read_data2_out,
                              ID_EX_RegisterRt_in,ID_EX_RegisterRd_in,
                              ID_EX_RegisterRt_out,ID_EX_RegisterRd_out,
                               sign_extend_in,sign_extend_out,
                               pc_in,pc_out
                            );

input clk;

// EX
input ID_EX_RegDst_in,ID_EX_ALUsrc_in;
input [1:0] ID_EX_ALUop_in;
// MEM
input ID_EX_MemRead_in,ID_EX_MemWrite_in,ID_EX_Branch_in;
//WB
input ID_EX_MemtoReg_in,ID_EX_RegWrite_in;

output reg ID_EX_RegDst_out,ID_EX_ALUsrc_out,ID_EX_MemtoReg_out,ID_EX_RegWrite_out,ID_EX_MemRead_out,ID_EX_MemWrite_out,ID_EX_Branch_out;
output reg [1:0] ID_EX_ALUop_out;

input [31:0] read_data1_in,read_data2_in;
output reg [31:0] read_data1_out,read_data2_out;

input [4:0] ID_EX_RegisterRt_in,ID_EX_RegisterRd_in;
output reg [4:0] ID_EX_RegisterRt_out,ID_EX_RegisterRd_out;

input [31:0] sign_extend_in;
output reg [31:0] sign_extend_out;

input [31:0] pc_in;
output reg[31:0] pc_out;

always@(posedge clk)
    begin
        // Control // 
        // EX 
        ID_EX_RegDst_out <= ID_EX_RegDst_in; 
        ID_EX_ALUsrc_out <= ID_EX_ALUsrc_in;
        ID_EX_ALUop_out <= ID_EX_ALUop_in; 
        // MEM
        ID_EX_MemRead_out <= ID_EX_MemRead_in;  
        ID_EX_MemWrite_out <= ID_EX_MemWrite_in;
        ID_EX_Branch_out <= ID_EX_Branch_in;
        // WB
        ID_EX_MemtoReg_out <= ID_EX_MemtoReg_in;
        ID_EX_RegWrite_out <= ID_EX_RegWrite_in;
        ////////////////////////////////////////////////////////////////////////////////////
        //ID_EX_RegisterRs_out <= ID_EX_RegisterRs_in;
        ID_EX_RegisterRt_out <= ID_EX_RegisterRt_in;
        ID_EX_RegisterRd_out <= ID_EX_RegisterRd_in;
        ////////////////////////////////////////////////////////////////////////////////////
        read_data1_out <= read_data1_in;
        read_data2_out <= read_data2_in;
        sign_extend_out <= sign_extend_in;
        pc_out <= pc_in;
    end


endmodule
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module EX_MEM_pipeline_register(clk, Regwrite_in, MemtoReg_in, Branch_in, MemRead_in, MemWrite_in, Add_branch_in, Zero_in, ALU_result_in, Write_mem_in, Write_reg_in
, Regwrite_out, MemtoReg_out, Branch_out, MemRead_out, MemWrite_out, Add_branch_out, Zero_out, ALU_result_out, Write_mem_out, Write_reg_out);

input clk, Regwrite_in, MemtoReg_in, Branch_in, MemRead_in, MemWrite_in, Zero_in;
input [31:0]Add_branch_in, ALU_result_in, Write_mem_in;
input [4:0]Write_reg_in;
output reg Regwrite_out, MemtoReg_out, Branch_out, MemRead_out, MemWrite_out, Zero_out;
output reg [31:0] Add_branch_out, ALU_result_out, Write_mem_out;
output reg [4:0]Write_reg_out;

always @(posedge clk)
begin
Regwrite_out <= Regwrite_in;
MemtoReg_out <=MemtoReg_in;
Branch_out <= Branch_in;
MemRead_out <= MemRead_in;
MemWrite_out <= MemWrite_in;
Add_branch_out <= Add_branch_in;
Zero_out <= Zero_in;
ALU_result_out <= ALU_result_in;
Write_mem_out <= Write_mem_in;
Write_reg_out <= Write_reg_in;
end

endmodule
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module MEM_WB_pipeline_register(clk, Regwrite_in, MemtoReg_in, Read_data_in, ALU_result_in, Write_reg_in,
Regwrite_out, MemtoReg_out, Read_data_out, ALU_result_out, Write_reg_out);

input clk, Regwrite_in, MemtoReg_in;
input [31:0]Read_data_in, ALU_result_in;
input [4:0]Write_reg_in;
output reg Regwrite_out, MemtoReg_out;
output reg[31:0] Read_data_out, ALU_result_out;
output reg[4:0]Write_reg_out;

always @(posedge clk)
begin
Regwrite_out <= Regwrite_in;
MemtoReg_out <= MemtoReg_in;
Read_data_out <= Read_data_in;
ALU_result_out <= ALU_result_in;
Write_reg_out <= Write_reg_in;
end

endmodule
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module Branch_Add(branch_byte, PC_4, branch_out);

input [31:0]branch_byte, PC_4;
output [31:0]branch_out;
assign branch_out = branch_byte + PC_4;

endmodule

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module shift_left_2_I_format(address_word,address_byte);

// address ?b MIPS code ?? word address ?????2 bits ?? byte
input [31:0] address_word;
output [31:0] address_byte;

assign address_byte = address_word << 2;

endmodule
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Branch_AND (a,b,branch_and_out);
input a,b;
output branch_and_out;

assign branch_and_out=a&b;
endmodule
////////////////////////////////////////////////
module shift_left_2_jump(address_word,address_byte);


input [31:0] address_word;
output [31:0] address_byte;

assign address_byte = address_word << 2;

endmodule
///////////////////////////////////
module jump_mix (pc_4_3128,address_in,jump_address);
input pc_4_3128,address_in;
output jump_address;
wire [27:0] address_in;
wire [3:0]pc_4_3128;
reg [31:0] jump_address;
always@(*)
begin
jump_address<={pc_4_3128,address_in};
end
endmodule
//////////////////////////////////////////////////////
module PC_Add4(PC, PC_4);

input [31:0]PC;
output [31:0]PC_4;
assign PC_4 = PC+4;

endmodule

/////////////////////////////
module branch_mux(pc_4,branch_add_result,branch_and,branch_mux_out);

input [31:0]pc_4,branch_add_result;
input branch_and;
output branch_mux_out;
reg [31:0] branch_mux_out;
always@(*)
begin
if(branch_and) branch_mux_out<=branch_add_result;
else
branch_mux_out<=pc_4;
end
endmodule
//////////////////////////////////////////
module jump_mux(jump,jump_address,branch_mux_out,pc_next);
input[31:0] jump_address,branch_mux_out;
input jump;
output  pc_next;
reg [31:0] pc_next;

always@(*)
begin
if(jump) pc_next<=jump_address;
else 
pc_next<=branch_mux_out;
end
endmodule

///////////////////////////////////////
module jump_determine(instructions,jump_or_not);
input instructions;
wire [5:0] instructions;
output jump_or_not;
reg jump_or_not;

always@(instructions)
begin
if(instructions==6'b000010)
jump_or_not<=1'b1;
else jump_or_not<=1'b0;
end

endmodule