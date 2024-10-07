//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Spring
//   Lab02 Exercise		: Enigma
//   Author     		: Yi-Xuan, Ran
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : ENIGMA.v
//   Module Name : ENIGMA
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
 
module ENIGMA(
	// Input Ports
	clk, 
	rst_n, 
	in_valid, 
	in_valid_2, 
	crypt_mode, 
	code_in, 
	// Output Ports
	out_code, 
	out_valid
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
	input clk;              		// clock input
	input rst_n;            		// asynchronous reset (active low)
	input in_valid;         		// code_in valid signal for rotor (level sensitive). 0/1: inactive/active
	input in_valid_2;       		// code_in valid signal for code  (level sensitive). 0/1: inactive/active
	input crypt_mode;       		// 0: encrypt; 1:decrypt; only valid for 1 cycle when in_valid is active

	input [6-1:0] code_in;			// When in_valid   is active, then code_in is input of rotors. 
									// When in_valid_2 is active, then code_in is input of code words.
								
	output reg out_valid;       	// 0: out_code is not valid; 1: out_code is valid
	output reg [6-1:0] out_code;	// encrypted/decrypted code word
// ===============================================================
// wire/reg
// ===============================================================
	//DFF	
	integer i, k, n, m, p;	
	reg [5:0] rotor_A [0:63];
	reg [5:0] rotor_B [0:63];
	reg crypt_mode_r, in_valid_2_r;
	wire crypt_mode_w;
	reg [5:0] counter_r;
	wire [5:0] counter_w;
	reg [2:0] mode_flag_r [0:7];
	reg [2:0] mode_flag_w [0:7];
	reg [5:0] code_in_r;
	wire out_valid_w;
	wire [5:0] out_code_w;
	reg [5:0] acc_shift_r;
	wire [5:0] acc_shift_w;
	//stage: roter A
	wire [5:0] roA_value, inv_roB_out, acc;
	reg signed [6:0] in_shift;
	reg [5:0] roA_sel, roA_out;
	//stage: roter B
	reg [5:0] roB_out;
	wire [5:0] roB_offset;
	reg [2:0] roB_mode;
	wire [2:0] roB_value;
	wire [5:0] roB_sel;
	reg [2:0] mode_flag_tmp [0:7];
	//stage: reflector
	wire [5:0] re_out;
	//stage: inv roter B
	reg [5:0] inv_roB_flag;
	wire [5:0] inv_roB_offset;
	reg [2:0] inv_roB_mode;
	//stage: inv roter B
	wire [6:0] inv_roA_out;
	reg [5:0] inv_roA_flag;

	wire in_valid_A, in_valid_B, counter_1_w;
	reg counter_1_r;

// ===============================================================
// Design
// ===============================================================
//stage: roter A
	//for calculate rotor B table Mux select
	assign roA_value = (crypt_mode_r) ? {3'd0, inv_roB_out[1:0]} : {3'd0, roA_out[1:0]};	//1:DE 0:EN
	assign acc = acc_shift_r + roA_value;													//accumulator for calculate shift time
	assign acc_shift_w = (in_valid_2_r) ? acc : 6'd0;										//shift pointer 

	always @(*) begin //if in_shift is out of boundry, need to compensate
		in_shift = $signed({1'd0, code_in_r}) - $signed({1'd0, acc_shift_r});			//code_in do shift
		if(in_shift < 0) begin
			roA_sel = 64 + in_shift ;
		end
		else begin
			roA_sel = in_shift[5:0];
		end
	end

	// rotor A table Mux
	always @(*) begin	
		case(roA_sel)
			6'h00: roA_out = rotor_A[0];
			6'h01: roA_out = rotor_A[1];
			6'h02: roA_out = rotor_A[2];
			6'h03: roA_out = rotor_A[3];
			6'h04: roA_out = rotor_A[4];
			6'h05: roA_out = rotor_A[5];
			6'h06: roA_out = rotor_A[6];
			6'h07: roA_out = rotor_A[7];
			6'h08: roA_out = rotor_A[8];
			6'h09: roA_out = rotor_A[9];
			6'h0A: roA_out = rotor_A[10];
			6'h0B: roA_out = rotor_A[11];
			6'h0C: roA_out = rotor_A[12];
			6'h0D: roA_out = rotor_A[13];
			6'h0E: roA_out = rotor_A[14];
			6'h0F: roA_out = rotor_A[15];
			6'h10: roA_out = rotor_A[16];
			6'h11: roA_out = rotor_A[17];
			6'h12: roA_out = rotor_A[18];
			6'h13: roA_out = rotor_A[19];
			6'h14: roA_out = rotor_A[20];
			6'h15: roA_out = rotor_A[21];
			6'h16: roA_out = rotor_A[22];
			6'h17: roA_out = rotor_A[23];
			6'h18: roA_out = rotor_A[24];
			6'h19: roA_out = rotor_A[25];
			6'h1A: roA_out = rotor_A[26];
			6'h1B: roA_out = rotor_A[27];
			6'h1C: roA_out = rotor_A[28];
			6'h1D: roA_out = rotor_A[29];
			6'h1E: roA_out = rotor_A[30];
			6'h1F: roA_out = rotor_A[31];
			6'h20: roA_out = rotor_A[32];
			6'h21: roA_out = rotor_A[33];
			6'h22: roA_out = rotor_A[34];
			6'h23: roA_out = rotor_A[35];
			6'h24: roA_out = rotor_A[36];
			6'h25: roA_out = rotor_A[37];
			6'h26: roA_out = rotor_A[38];
			6'h27: roA_out = rotor_A[39];
			6'h28: roA_out = rotor_A[40];
			6'h29: roA_out = rotor_A[41];
			6'h2A: roA_out = rotor_A[42];
			6'h2B: roA_out = rotor_A[43];
			6'h2C: roA_out = rotor_A[44];
			6'h2D: roA_out = rotor_A[45];
			6'h2E: roA_out = rotor_A[46];
			6'h2F: roA_out = rotor_A[47];
			6'h30: roA_out = rotor_A[48];
			6'h31: roA_out = rotor_A[49];
			6'h32: roA_out = rotor_A[50];
			6'h33: roA_out = rotor_A[51];
			6'h34: roA_out = rotor_A[52];
			6'h35: roA_out = rotor_A[53];
			6'h36: roA_out = rotor_A[54];
			6'h37: roA_out = rotor_A[55];
			6'h38: roA_out = rotor_A[56];
			6'h39: roA_out = rotor_A[57];
			6'h3A: roA_out = rotor_A[58];
			6'h3B: roA_out = rotor_A[59];
			6'h3C: roA_out = rotor_A[60];
			6'h3D: roA_out = rotor_A[61];
			6'h3E: roA_out = rotor_A[62];
			6'h3F: roA_out = rotor_A[63];
		endcase
	end

//stage: roter B 
	//for calculate rotor B table Mux select
	assign roB_sel = roB_offset + {3'd0, roB_mode};		//mode flag + offset --> real location
	assign roB_offset = roA_out - roA_out[2:0];

	always @(*) begin	//stage: roter B -- mode flag
		case(roA_out[2:0])
			3'd0: roB_mode = mode_flag_r[0];
			3'd1: roB_mode = mode_flag_r[1];
			3'd2: roB_mode = mode_flag_r[2];
			3'd3: roB_mode = mode_flag_r[3];
			3'd4: roB_mode = mode_flag_r[4];
			3'd5: roB_mode = mode_flag_r[5];
			3'd6: roB_mode = mode_flag_r[6];
			3'd7: roB_mode = mode_flag_r[7];
		endcase
	end

	//for update mode flag
	assign roB_value = (crypt_mode_r) ? re_out[2:0] : roB_out[2:0];	//1:DE 0:EN

	always @(*) begin	//8 mode case
		case(roB_value)
			3'd0: {mode_flag_tmp[0], mode_flag_tmp[1], mode_flag_tmp[2], mode_flag_tmp[3], mode_flag_tmp[4], mode_flag_tmp[5], mode_flag_tmp[6], mode_flag_tmp[7]} = {mode_flag_r[0], mode_flag_r[1], mode_flag_r[2], mode_flag_r[3], mode_flag_r[4], mode_flag_r[5], mode_flag_r[6], mode_flag_r[7]};
			3'd1: {mode_flag_tmp[0], mode_flag_tmp[1], mode_flag_tmp[2], mode_flag_tmp[3], mode_flag_tmp[4], mode_flag_tmp[5], mode_flag_tmp[6], mode_flag_tmp[7]} = {mode_flag_r[1], mode_flag_r[0], mode_flag_r[3], mode_flag_r[2], mode_flag_r[5], mode_flag_r[4], mode_flag_r[7], mode_flag_r[6]};
			3'd2: {mode_flag_tmp[0], mode_flag_tmp[1], mode_flag_tmp[2], mode_flag_tmp[3], mode_flag_tmp[4], mode_flag_tmp[5], mode_flag_tmp[6], mode_flag_tmp[7]} = {mode_flag_r[2], mode_flag_r[3], mode_flag_r[0], mode_flag_r[1], mode_flag_r[6], mode_flag_r[7], mode_flag_r[4], mode_flag_r[5]};
			3'd3: {mode_flag_tmp[0], mode_flag_tmp[1], mode_flag_tmp[2], mode_flag_tmp[3], mode_flag_tmp[4], mode_flag_tmp[5], mode_flag_tmp[6], mode_flag_tmp[7]} = {mode_flag_r[0], mode_flag_r[4], mode_flag_r[5], mode_flag_r[6], mode_flag_r[1], mode_flag_r[2], mode_flag_r[3], mode_flag_r[7]};
			3'd4: {mode_flag_tmp[0], mode_flag_tmp[1], mode_flag_tmp[2], mode_flag_tmp[3], mode_flag_tmp[4], mode_flag_tmp[5], mode_flag_tmp[6], mode_flag_tmp[7]} = {mode_flag_r[4], mode_flag_r[5], mode_flag_r[6], mode_flag_r[7], mode_flag_r[0], mode_flag_r[1], mode_flag_r[2], mode_flag_r[3]};
			3'd5: {mode_flag_tmp[0], mode_flag_tmp[1], mode_flag_tmp[2], mode_flag_tmp[3], mode_flag_tmp[4], mode_flag_tmp[5], mode_flag_tmp[6], mode_flag_tmp[7]} = {mode_flag_r[5], mode_flag_r[6], mode_flag_r[7], mode_flag_r[3], mode_flag_r[4], mode_flag_r[0], mode_flag_r[1], mode_flag_r[2]};
			3'd6: {mode_flag_tmp[0], mode_flag_tmp[1], mode_flag_tmp[2], mode_flag_tmp[3], mode_flag_tmp[4], mode_flag_tmp[5], mode_flag_tmp[6], mode_flag_tmp[7]} = {mode_flag_r[6], mode_flag_r[7], mode_flag_r[3], mode_flag_r[2], mode_flag_r[5], mode_flag_r[4], mode_flag_r[0], mode_flag_r[1]};
			3'd7: {mode_flag_tmp[0], mode_flag_tmp[1], mode_flag_tmp[2], mode_flag_tmp[3], mode_flag_tmp[4], mode_flag_tmp[5], mode_flag_tmp[6], mode_flag_tmp[7]} = {mode_flag_r[7], mode_flag_r[6], mode_flag_r[5], mode_flag_r[4], mode_flag_r[3], mode_flag_r[2], mode_flag_r[1], mode_flag_r[0]};
		endcase
	end

	always @(*) begin	//for mode flag reset
		if(in_valid_2_r) begin
			{mode_flag_w[0], mode_flag_w[1], mode_flag_w[2], mode_flag_w[3], mode_flag_w[4], mode_flag_w[5], mode_flag_w[6], mode_flag_w[7]} = {mode_flag_tmp[0], mode_flag_tmp[1], mode_flag_tmp[2], mode_flag_tmp[3], mode_flag_tmp[4], mode_flag_tmp[5], mode_flag_tmp[6], mode_flag_tmp[7]};
		end
		else begin
			{mode_flag_w[0], mode_flag_w[1], mode_flag_w[2], mode_flag_w[3], mode_flag_w[4], mode_flag_w[5], mode_flag_w[6], mode_flag_w[7]} = {3'd0, 3'd1, 3'd2, 3'd3, 3'd4, 3'd5, 3'd6, 3'd7};
		end
	end

	//rotor B table Mux

	always @(*) begin	
		case(roB_sel)
			6'h00: roB_out = rotor_B[0];
			6'h01: roB_out = rotor_B[1];
			6'h02: roB_out = rotor_B[2];
			6'h03: roB_out = rotor_B[3];
			6'h04: roB_out = rotor_B[4];
			6'h05: roB_out = rotor_B[5];
			6'h06: roB_out = rotor_B[6];
			6'h07: roB_out = rotor_B[7];
			6'h08: roB_out = rotor_B[8];
			6'h09: roB_out = rotor_B[9];
			6'h0A: roB_out = rotor_B[10];
			6'h0B: roB_out = rotor_B[11];
			6'h0C: roB_out = rotor_B[12];
			6'h0D: roB_out = rotor_B[13];
			6'h0E: roB_out = rotor_B[14];
			6'h0F: roB_out = rotor_B[15];
			6'h10: roB_out = rotor_B[16];
			6'h11: roB_out = rotor_B[17];
			6'h12: roB_out = rotor_B[18];
			6'h13: roB_out = rotor_B[19];
			6'h14: roB_out = rotor_B[20];
			6'h15: roB_out = rotor_B[21];
			6'h16: roB_out = rotor_B[22];
			6'h17: roB_out = rotor_B[23];
			6'h18: roB_out = rotor_B[24];
			6'h19: roB_out = rotor_B[25];
			6'h1A: roB_out = rotor_B[26];
			6'h1B: roB_out = rotor_B[27];
			6'h1C: roB_out = rotor_B[28];
			6'h1D: roB_out = rotor_B[29];
			6'h1E: roB_out = rotor_B[30];
			6'h1F: roB_out = rotor_B[31];
			6'h20: roB_out = rotor_B[32];
			6'h21: roB_out = rotor_B[33];
			6'h22: roB_out = rotor_B[34];
			6'h23: roB_out = rotor_B[35];
			6'h24: roB_out = rotor_B[36];
			6'h25: roB_out = rotor_B[37];
			6'h26: roB_out = rotor_B[38];
			6'h27: roB_out = rotor_B[39];
			6'h28: roB_out = rotor_B[40];
			6'h29: roB_out = rotor_B[41];
			6'h2A: roB_out = rotor_B[42];
			6'h2B: roB_out = rotor_B[43];
			6'h2C: roB_out = rotor_B[44];
			6'h2D: roB_out = rotor_B[45];
			6'h2E: roB_out = rotor_B[46];
			6'h2F: roB_out = rotor_B[47];
			6'h30: roB_out = rotor_B[48];
			6'h31: roB_out = rotor_B[49];
			6'h32: roB_out = rotor_B[50];
			6'h33: roB_out = rotor_B[51];
			6'h34: roB_out = rotor_B[52];
			6'h35: roB_out = rotor_B[53];
			6'h36: roB_out = rotor_B[54];
			6'h37: roB_out = rotor_B[55];
			6'h38: roB_out = rotor_B[56];
			6'h39: roB_out = rotor_B[57];
			6'h3A: roB_out = rotor_B[58];
			6'h3B: roB_out = rotor_B[59];
			6'h3C: roB_out = rotor_B[60];
			6'h3D: roB_out = rotor_B[61];
			6'h3E: roB_out = rotor_B[62];
			6'h3F: roB_out = rotor_B[63];
		endcase
	end

//stage: reflector
	assign re_out = roB_out ^ 6'd63;

//stage: inv roter B
	//for find where re_out is in rotor B table 
	always @(*) begin
			inv_roB_flag = 6'd41;	//better Area for me
		if(re_out == rotor_B[0])
			inv_roB_flag = 6'd0;		
		if(re_out == rotor_B[1])
			inv_roB_flag = 6'd1;
		if(re_out == rotor_B[2])
			inv_roB_flag = 6'd2;
		if(re_out == rotor_B[3])
			inv_roB_flag = 6'd3;
		if(re_out == rotor_B[4])
			inv_roB_flag = 6'd4;
		if(re_out == rotor_B[5])
			inv_roB_flag = 6'd5;
		if(re_out == rotor_B[6])
			inv_roB_flag = 6'd6;
		if(re_out == rotor_B[7])
			inv_roB_flag = 6'd7;
		if(re_out == rotor_B[8])
			inv_roB_flag = 6'd8;
		if(re_out == rotor_B[9])
			inv_roB_flag = 6'd9;
		if(re_out == rotor_B[10])
			inv_roB_flag = 6'd10;
		if(re_out == rotor_B[11])
			inv_roB_flag = 6'd11;
		if(re_out == rotor_B[12])
			inv_roB_flag = 6'd12;
		if(re_out == rotor_B[13])
			inv_roB_flag = 6'd13;
		if(re_out == rotor_B[14])
			inv_roB_flag = 6'd14;
		if(re_out == rotor_B[15])
			inv_roB_flag = 6'd15;
		if(re_out == rotor_B[16])
			inv_roB_flag = 6'd16;
		if(re_out == rotor_B[17])
			inv_roB_flag = 6'd17;
		if(re_out == rotor_B[18])
			inv_roB_flag = 6'd18;
		if(re_out == rotor_B[19])
			inv_roB_flag = 6'd19;
		if(re_out == rotor_B[20])
			inv_roB_flag = 6'd20;
		if(re_out == rotor_B[21])
			inv_roB_flag = 6'd21;
		if(re_out == rotor_B[22])
			inv_roB_flag = 6'd22;
		if(re_out == rotor_B[23])
			inv_roB_flag = 6'd23;
		if(re_out == rotor_B[24])
			inv_roB_flag = 6'd24;
		if(re_out == rotor_B[25])
			inv_roB_flag = 6'd25;
		if(re_out == rotor_B[26])
			inv_roB_flag = 6'd26;
		if(re_out == rotor_B[27])
			inv_roB_flag = 6'd27;
		if(re_out == rotor_B[28])
			inv_roB_flag = 6'd28;
		if(re_out == rotor_B[29])
			inv_roB_flag = 6'd29;
		if(re_out == rotor_B[30])
			inv_roB_flag = 6'd30;
		if(re_out == rotor_B[31])
			inv_roB_flag = 6'd31;
		if(re_out == rotor_B[32])
			inv_roB_flag = 6'd32;
		if(re_out == rotor_B[33])
			inv_roB_flag = 6'd33;
		if(re_out == rotor_B[34])
			inv_roB_flag = 6'd34;
		if(re_out == rotor_B[35])
			inv_roB_flag = 6'd35;
		if(re_out == rotor_B[36])
			inv_roB_flag = 6'd36;
		if(re_out == rotor_B[37])
			inv_roB_flag = 6'd37;
		if(re_out == rotor_B[38])
			inv_roB_flag = 6'd38;
		if(re_out == rotor_B[39])
			inv_roB_flag = 6'd39;
		if(re_out == rotor_B[40])
			inv_roB_flag = 6'd40;
		if(re_out == rotor_B[42])
			inv_roB_flag = 6'd42;
		if(re_out == rotor_B[43])
			inv_roB_flag = 6'd43;
		if(re_out == rotor_B[44])
			inv_roB_flag = 6'd44;
		if(re_out == rotor_B[45])
			inv_roB_flag = 6'd45;
		if(re_out == rotor_B[46])
			inv_roB_flag = 6'd46;
		if(re_out == rotor_B[47])
			inv_roB_flag = 6'd47;
		if(re_out == rotor_B[48])
			inv_roB_flag = 6'd48;
		if(re_out == rotor_B[49])
			inv_roB_flag = 6'd49;
		if(re_out == rotor_B[50])
			inv_roB_flag = 6'd50;
		if(re_out == rotor_B[51])
			inv_roB_flag = 6'd51;
		if(re_out == rotor_B[52])
			inv_roB_flag = 6'd52;
		if(re_out == rotor_B[53])
			inv_roB_flag = 6'd53;
		if(re_out == rotor_B[54])
			inv_roB_flag = 6'd54;
		if(re_out == rotor_B[55])
			inv_roB_flag = 6'd55;
		if(re_out == rotor_B[56])
			inv_roB_flag = 6'd56;
		if(re_out == rotor_B[57])
			inv_roB_flag = 6'd57;
		if(re_out == rotor_B[58])
			inv_roB_flag = 6'd58;
		if(re_out == rotor_B[59])
			inv_roB_flag = 6'd59;
		if(re_out == rotor_B[60])
			inv_roB_flag = 6'd60;
		if(re_out == rotor_B[61])
			inv_roB_flag = 6'd61;
		if(re_out == rotor_B[62])
			inv_roB_flag = 6'd62;
		if(re_out == rotor_B[63])
			inv_roB_flag = 6'd63;
	end

	//for real re_out location --> because rotor B table can move
	assign inv_roB_out = inv_roB_offset + {3'd0, inv_roB_mode};	//real re_out location
	assign inv_roB_offset = inv_roB_flag - inv_roB_flag[2:0];

	always @(*) begin
			inv_roB_mode = 0;
		if(inv_roB_flag[2:0] == mode_flag_r[0])
			inv_roB_mode = 0;
		if(inv_roB_flag[2:0] == mode_flag_r[1])
			inv_roB_mode = 1;
		if(inv_roB_flag[2:0] == mode_flag_r[2])
			inv_roB_mode = 2;
		if(inv_roB_flag[2:0] == mode_flag_r[3])
			inv_roB_mode = 3;
		if(inv_roB_flag[2:0] == mode_flag_r[4])
			inv_roB_mode = 4;
		if(inv_roB_flag[2:0] == mode_flag_r[5])
			inv_roB_mode = 5;
		if(inv_roB_flag[2:0] == mode_flag_r[6])
			inv_roB_mode = 6;
		if(inv_roB_flag[2:0] == mode_flag_r[7])
			inv_roB_mode = 7;	
	end

//stage: inv roter A
	//for find where re_out is in rotor B table 
	always @(*) begin
			inv_roA_flag = 6'd0;
		if(inv_roB_out == rotor_A[0])
			inv_roA_flag = 6'd0;
		if(inv_roB_out == rotor_A[1])
			inv_roA_flag = 6'd1;
		if(inv_roB_out == rotor_A[2])
			inv_roA_flag = 6'd2;
		if(inv_roB_out == rotor_A[3])
			inv_roA_flag = 6'd3;
		if(inv_roB_out == rotor_A[4])
			inv_roA_flag = 6'd4;
		if(inv_roB_out == rotor_A[5])
			inv_roA_flag = 6'd5;
		if(inv_roB_out == rotor_A[6])
			inv_roA_flag = 6'd6;
		if(inv_roB_out == rotor_A[7])
			inv_roA_flag = 6'd7;
		if(inv_roB_out == rotor_A[8])
			inv_roA_flag = 6'd8;
		if(inv_roB_out == rotor_A[9])
			inv_roA_flag = 6'd9;
		if(inv_roB_out == rotor_A[10])
			inv_roA_flag = 6'd10;
		if(inv_roB_out == rotor_A[11])
			inv_roA_flag = 6'd11;
		if(inv_roB_out == rotor_A[12])
			inv_roA_flag = 6'd12;
		if(inv_roB_out == rotor_A[13])
			inv_roA_flag = 6'd13;
		if(inv_roB_out == rotor_A[14])
			inv_roA_flag = 6'd14;
		if(inv_roB_out == rotor_A[15])
			inv_roA_flag = 6'd15;
		if(inv_roB_out == rotor_A[16])
			inv_roA_flag = 6'd16;
		if(inv_roB_out == rotor_A[17])
			inv_roA_flag = 6'd17;
		if(inv_roB_out == rotor_A[18])
			inv_roA_flag = 6'd18;
		if(inv_roB_out == rotor_A[19])
			inv_roA_flag = 6'd19;
		if(inv_roB_out == rotor_A[20])
			inv_roA_flag = 6'd20;
		if(inv_roB_out == rotor_A[21])
			inv_roA_flag = 6'd21;
		if(inv_roB_out == rotor_A[22])
			inv_roA_flag = 6'd22;
		if(inv_roB_out == rotor_A[23])
			inv_roA_flag = 6'd23;
		if(inv_roB_out == rotor_A[24])
			inv_roA_flag = 6'd24;
		if(inv_roB_out == rotor_A[25])
			inv_roA_flag = 6'd25;
		if(inv_roB_out == rotor_A[26])
			inv_roA_flag = 6'd26;
		if(inv_roB_out == rotor_A[27])
			inv_roA_flag = 6'd27;
		if(inv_roB_out == rotor_A[28])
			inv_roA_flag = 6'd28;
		if(inv_roB_out == rotor_A[29])
			inv_roA_flag = 6'd29;
		if(inv_roB_out == rotor_A[30])
			inv_roA_flag = 6'd30;
		if(inv_roB_out == rotor_A[31])
			inv_roA_flag = 6'd31;
		if(inv_roB_out == rotor_A[32])
			inv_roA_flag = 6'd32;
		if(inv_roB_out == rotor_A[33])
			inv_roA_flag = 6'd33;
		if(inv_roB_out == rotor_A[34])
			inv_roA_flag = 6'd34;
		if(inv_roB_out == rotor_A[35])
			inv_roA_flag = 6'd35;
		if(inv_roB_out == rotor_A[36])
			inv_roA_flag = 6'd36;
		if(inv_roB_out == rotor_A[37])
			inv_roA_flag = 6'd37;
		if(inv_roB_out == rotor_A[38])
			inv_roA_flag = 6'd38;
		if(inv_roB_out == rotor_A[39])
			inv_roA_flag = 6'd39;
		if(inv_roB_out == rotor_A[40])
			inv_roA_flag = 6'd40;
		if(inv_roB_out == rotor_A[41])
			inv_roA_flag = 6'd41;
		if(inv_roB_out == rotor_A[42])
			inv_roA_flag = 6'd42;
		if(inv_roB_out == rotor_A[43])
			inv_roA_flag = 6'd43;
		if(inv_roB_out == rotor_A[44])
			inv_roA_flag = 6'd44;
		if(inv_roB_out == rotor_A[45])
			inv_roA_flag = 6'd45;
		if(inv_roB_out == rotor_A[46])
			inv_roA_flag = 6'd46;
		if(inv_roB_out == rotor_A[47])
			inv_roA_flag = 6'd47;
		if(inv_roB_out == rotor_A[48])
			inv_roA_flag = 6'd48;
		if(inv_roB_out == rotor_A[49])
			inv_roA_flag = 6'd49;
		if(inv_roB_out == rotor_A[50])
			inv_roA_flag = 6'd50;
		if(inv_roB_out == rotor_A[51])
			inv_roA_flag = 6'd51;
		if(inv_roB_out == rotor_A[52])
			inv_roA_flag = 6'd52;
		if(inv_roB_out == rotor_A[53])
			inv_roA_flag = 6'd53;
		if(inv_roB_out == rotor_A[54])
			inv_roA_flag = 6'd54;
		if(inv_roB_out == rotor_A[55])
			inv_roA_flag = 6'd55;
		if(inv_roB_out == rotor_A[56])
			inv_roA_flag = 6'd56;
		if(inv_roB_out == rotor_A[57])
			inv_roA_flag = 6'd57;
		if(inv_roB_out == rotor_A[58])
			inv_roA_flag = 6'd58;
		if(inv_roB_out == rotor_A[59])
			inv_roA_flag = 6'd59;
		if(inv_roB_out == rotor_A[60])
			inv_roA_flag = 6'd60;
		if(inv_roB_out == rotor_A[61])
			inv_roA_flag = 6'd61;
		if(inv_roB_out == rotor_A[62])
			inv_roA_flag = 6'd62;
		if(inv_roB_out == rotor_A[63])
			inv_roA_flag = 6'd63;
	end

	assign inv_roA_out = inv_roA_flag + acc_shift_r;
//DFF
	//crypt_mode
	assign crypt_mode_w = (counter_r == 0 && in_valid_A) ? crypt_mode : crypt_mode_r;	//crypt_mode
	assign out_valid_w = in_valid_2_r;												//execution time 1		
	assign out_code_w = (in_valid_2_r) ?  inv_roA_out : 6'd0;	

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin			
			crypt_mode_r <= 1'd0;
			counter_r <= 6'd0;
			acc_shift_r <= 6'd0;
			mode_flag_r[0] <= 3'd0;
			mode_flag_r[1] <= 3'd1;
			mode_flag_r[2] <= 3'd2;
			mode_flag_r[3] <= 3'd3;
			mode_flag_r[4] <= 3'd4;
			mode_flag_r[5] <= 3'd5;
			mode_flag_r[6] <= 3'd6;
			mode_flag_r[7] <= 3'd7;	

			in_valid_2_r <= 1'd0;
			code_in_r <= 6'd0;
			out_valid <= 1'd0;
			out_code <= 6'd0;	

			counter_1_r <= 1'b0;
		end
		else begin
			crypt_mode_r <= crypt_mode_w;
			counter_r <= counter_w;
			for(p=0; p<8; p=p+1) mode_flag_r[p] <= mode_flag_w[p];
			acc_shift_r <= acc_shift_w;

			in_valid_2_r <= in_valid_2;
			code_in_r <= code_in;
			out_valid <= out_valid_w;
			out_code <= out_code_w;

			counter_1_r <= counter_1_w;
		end
	end

//rotor A B table
	assign counter_w = (in_valid) ? (counter_r + 6'd1) : counter_r;
	assign counter_1_w = (counter_r == 63) ? (counter_1_r + 1'b1) : counter_1_r;
	assign in_valid_A = in_valid & !counter_1_r;
	assign in_valid_B = in_valid & counter_1_r;

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			for(i=0; i<64; i=i+1) rotor_A[i] <= 6'd0;
		end
		else begin
			if(in_valid_A) begin
				rotor_A[counter_r] <= code_in;
			end
			else begin
				for(k=0; k<64; k=k+1) rotor_A[k] <= rotor_A[k];				
			end
		end
	end

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			for(m=0; m<64; m=m+1) rotor_B[m] <= 6'd0;
		end
		else begin
			if(in_valid_B) begin
				rotor_B[counter_r] <= code_in;
			end
			else begin
				for(n=0; n<64; n=n+1) rotor_B[n] <= rotor_B[n];				
			end
		end
	end
endmodule

