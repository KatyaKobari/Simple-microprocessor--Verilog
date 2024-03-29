//Katya Kobari - 1201478
//-----------------ALU--------------------------
module alu (opcode, a, b, result );
  input [5:0] opcode; 
  input  signed[31:0] a, b; 
  output reg signed [31:0] result; 
  always @(opcode, a, b)
   begin
  if (opcode == 6'b000001) begin   // 1-->add
    result = a + b;
  end 
//------------------------------------------------
  else if (opcode == 6'b000110) begin // 6-->sub
    result = a - b;
  end	
//------------------------------------------------
  else if (opcode == 6'b001101) begin  // 13 --> abs a
    if (a[31] == 1'b1) begin //MSB=1 means a is neg num
      result = -a;
    end
    else begin
      result = a;
    end
  end	  
//------------------------------------------------
  else if (opcode == 6'b001000) begin // 8-->-a
    result = -a;
  end		 
//---------------------------------------------------
  else if (opcode == 6'b000111) begin  // 7-->max(a,b)
   	 if (a>b) begin
      result = a;
    end
    else begin
      result = b;
    end
  end  
//---------------------------------------------------
  else if (opcode == 6'b000100) begin  // 4-->min(a,b)
   	 if (a<b) begin
      result = a;
    end
    else begin
      result = b;
    end
  end  
//------------------------------------------------------
   else if (opcode == 6'b001011) begin // 11-->avg(a,b)
    result = (a+b) >>> 1; //shift right by 1 means /2 and take the int part only
   end	

//------------------------------------------------------ 
   else if (opcode == 6'b001111) begin // 15--> ~a
    result = ~a;
   end	 
//-----------------------------------------------------
  else if (opcode == 6'b000011) begin // 3--> a or b
    result = a | b;
   end
//------------------------------------------------------
  else if (opcode == 6'b000101) begin // 5--> a and b
    result = a & b;
   end
//--------------------------------------------------------
  else if (opcode == 6'b000010) begin // 2--> a xor b
    result = a ^ b;
   end
//--------------------------------------------------------
 else begin
    result = 32'b0;	 // invalid op code
  end
end
endmodule	
//--------------------Reg File-----------------------------
module reg_file (clk, valid_opcode, addr1, addr2, addr3, in , out1, out2);
input clk;
 input valid_opcode;
input [4:0] addr1, addr2, addr3; 
input signed [31:0] in; 
output reg signed [31:0] out1, out2;
reg signed [31:0] ram [0:31];  // Ram to store the Values 
initial begin
  ram = '{32'h0, 32'h3ABA, 32'h2296, 32'hAA,
                            32'h1C3A, 32'h1180, 32'h22E0, 32'h1C86,
                            32'h22DA, 32'h414, 32'h1A32, 32'h102,
                            32'h1CBA, 32'hCDE, 32'h3994, 32'h1984, 
							32'h28C4, 32'h2E7C, 32'h3966, 32'h227E, 32'h2208, 32'h11B4,
							32'h237C, 32'h360E, 32'h2722, 32'h500, 32'h16B6, 32'h29E,
							32'h2280, 32'h3852, 32'h11A0, 32'h0}; 
	end
// Perform the operations on the RAM at the positive edge of the clock
always @(posedge clk) 
	begin  
    if (valid_opcode == 1'b1) begin		 // Only do if the op code is valid.
    out1 <= ram[addr1];
    out2 <= ram[addr2];
    ram[addr3] <= in;
	end
  end
endmodule	 													 
//--------------32 bit regester------------------------------------------------	
module instruction_format(clk,instruction, opcode, addr1, addr2 ,addr3, valid);
  input [31:0] instruction;
  input clk;	 
  output reg valid;
  output reg  [5:0] opcode;
  output reg [4:0] addr1, addr2, addr3;
  always @(posedge clk) 
   begin
    opcode <= instruction[5:0];     // first 6 bit for the opcode
    addr1  <= instruction[10:6];    // next 5 bits identify first source register 
    addr2  <= instruction[15:11];   // next 5 bits identify second source register
    addr3  <= instruction[20:16];  // next 5 bits identify destination register	
	// Check if the op code is valid or not
	if(opcode ==  6'b000001 || opcode == 6'b000110 || opcode == 6'b001101 || opcode ==  6'b001000	|| opcode ==  6'b000111	 ||opcode ==  6'b000100	|| 
		opcode == 6'b001011	 ||  opcode ==  6'b001111 || opcode ==  6'b000011 || opcode ==  6'b000101 || opcode ==  6'b000010)	
		begin
		 valid =1'b1 ;
		end
   else	 
	   begin  
		valid =1'b0  ;
	   end
   end	
endmodule
//-----------------Top----------------------------------------------------
module mp_top (clk, instruction , result );
input clk;
input [31:0] instruction; 
output reg [31:0] result; 
wire valid;
wire [4:0] addr1, addr2, addr3;
wire [5:0] opcode; 
wire [31:0] out1, out2 ;
reg  [5:0] store_opcode;  // Register to store the opcode
instruction_format m1(clk,instruction, opcode, addr1, addr2 ,addr3, valid);	  // Instantiate the instruction format module
reg_file m2 (clk, valid, addr1, addr2, addr3, result , out1, out2);		 
always @(posedge clk) begin
    if (valid) begin
      store_opcode <= opcode;   // Store the opcode for later use
    end
  end

alu m3(store_opcode, out1, out2, result);

endmodule
//-----------------------Test Bench for the whole Sysytem----------------------------------------  
module test_bench;
  reg clk;
  reg [31:0] instruction;
  wire signed[31:0] result;
  mp_top m1 (.clk(clk), .instruction(instruction), .result(result));

  // Define an array of instructions , expected values and operation names
  bit [31:0] instructions [11:0];
  int expected_values [0:11];
  string operation_names [0:11];   
  int sysFlag=1;
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    instructions[0] = 32'b000110001000001000001; // add
    instructions[1] = 32'b000110001000001000110; // sub
    instructions[2] = 32'b000110001000001001101; // abs
    instructions[3] = 32'b000110001000001001000; // -a
    instructions[4] = 32'b000110001000001000111; // max(a, b)
    instructions[5] = 32'b000110001000001000100; // min(a, b)						  
    instructions[6] = 32'b000110001000001001011; // avg(a, b)
    instructions[7] = 32'b000110001000001001111; // ~a
    instructions[8] = 32'b000110001000001000011; // a or b
    instructions[9] = 32'b000110001000001000101; // a and b
    instructions[10] = 32'b000110001000001000010; // a xor b   
	instructions[11] = 32'b00011000100000110010; // invalid instruction  
    expected_values = '{23888, 6180, 15034, 4294952262, 15034, 8854, 11944, 4294952261, 15038, 8850, 6188, 0};
    operation_names = '{"add", "sub", "abs", "-a", "max(A,B)", "min(A,B)", "avg(A,B)", "~a", "a or b", "a and b", "a xor b" ,"Invalid"};
	 $display("----------------------------- microprocessor start runing----------------------------------------") ;
   	 $display("----------------------------- A = 15034 , B = 8854 ------------------------------------------------")  ;

    // Iterate over the array of instructions
    for (int i = 0; i <= 11; i = i + 1) begin
      instruction = instructions[i];
      #20ns;
      // Check if the test case pass or fail
      if (result == expected_values[i]) begin 
        $display("----PASS---- for test case %0d (%s)." ,i, operation_names[i])  ;   
		$display("Expected: %d, Result: %d", expected_values[i], result);
		$display("-------------------------------------------------------------------------------------------------------------------");	
      	end
	  else begin 
		 sysFlag=0;
        $display("----FAIL---- for test case %0d (%s)." ,i, operation_names[i])  ;   
		$display("Expected: %d, Result: %d", expected_values[i], result);
		$display("-------------------------------------------------------------------------------------------------------------------");	
		 end
    end	 
	  if (sysFlag) begin  // Check if the system Pass or fail depend on the value of the system flag.
      $display("********************System Pass********************");
    end
    else begin
      $display("********************System Fail********************");
    end
    $finish;
  end
endmodule