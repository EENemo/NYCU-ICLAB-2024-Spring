//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Spring
//   Lab01 Exercise		: Code Calculator
//   Author     		  : Jhan-Yi LIAO
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CC.v
//   Module Name : CC
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################


module CC(
  // Input signals
    opt,
    in_n0, in_n1, in_n2, in_n3, in_n4,  
  // Output signals
    out_n
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
	input [3:0] in_n0, in_n1, in_n2, in_n3, in_n4;
	input [2:0] opt;
	output [9:0] out_n;         					

//================================================================
//    Wire & Registers 
//================================================================
	//Sorting
	wire [3:0] sor_n0, sor_n1, sor_n2, sor_n3, sor_n4;
	//Normalization
	wire [4:0] normal_val_temp0, normal_val_temp1, normal_val;
	wire signed [4:0] normal_n0, normal_n1, normal_n2, normal_n3, normal_n4;
	wire signed [4:0] stage0_n0, stage0_n1, stage0_n2, stage0_n3, stage0_n4;
	//avg
	wire signed [5:0] avg_temp0, avg_temp1;
	wire signed [6:0] avg_temp2; 
	wire signed [7:0] avg_temp3;
	wire signed [4:0] avg;
	//opt[1]
	wire signed [4:0] n0, n1, n3;
	//Calculation
	wire signed [4:0] mult0, mult1_1, mult1_2, add1_2;
	wire signed [9:0] mult0_out, mult1_out, mult1_abs;
	wire signed [9:0] add1_1, add1_out, add1_out_div, add1_out_abs;

//================================================================
//    DESIGN
//================================================================
//high-to-low Sort
	Up_sort Up_sort_U(
		.in_n0(in_n0), .in_n1(in_n1), .in_n2(in_n2), .in_n3(in_n3), .in_n4(in_n4),
		.sor_n0(sor_n0), .sor_n1(sor_n1), .sor_n2(sor_n2), .sor_n3(sor_n3), .sor_n4(sor_n4)
	);

//Normalization
	assign normal_val_temp0 = sor_n0  +  sor_n4;
	assign normal_val_temp1 = normal_val_temp0 >> 1;	//max:15min:0//normal_val_temp/2
	assign normal_val = (~normal_val_temp1) + 1'b1;		//do it one time can reduce area
	assign normal_n0 = sor_n0 + normal_val;
	assign normal_n1 = sor_n1 + normal_val;
	assign normal_n2 = sor_n2 + normal_val;
	assign normal_n3 = sor_n3 + normal_val;
	assign normal_n4 = sor_n4 + normal_val;

	assign stage0_n0 = (!opt[0]) ? {1'b0, sor_n0} : normal_n0;	//Area: [!opt] < [opt]  
	assign stage0_n1 = (!opt[0]) ? {1'b0, sor_n1} : normal_n1;
	assign stage0_n2 = (!opt[0]) ? {1'b0, sor_n2} : normal_n2;
	assign stage0_n3 = (!opt[0]) ? {1'b0, sor_n3} : normal_n3;
	assign stage0_n4 = (!opt[0]) ? {1'b0, sor_n4} : normal_n4;

//Calculation
	//avg(Sorting or Normalization)
	assign avg_temp0 = stage0_n0 + stage0_n1;
	assign avg_temp1 = stage0_n2 + stage0_n3;
	assign avg_temp2 = avg_temp0 + avg_temp1;
	assign avg_temp3 = avg_temp2 + stage0_n4;
	// div5 lookuptable
	div_5_lookuptable div_5_lookuptable_U(
		.avg_temp3(avg_temp3),
		.avg(avg)		
	);

	//opt[1] selsect (high-to-low) or (low-to-high) sort, but not all need to selsect
	assign n0 = (opt[1]) ? stage0_n0 : stage0_n4;	//Area: [!opt] = [opt]  
	assign n1 = (opt[1]) ? stage0_n1 : stage0_n3;
	assign n3 = (opt[1]) ? stage0_n3 : stage0_n1;

	//Only  2 multiplier need to use, can use opt[2] selsect which signal deliver to multi0 and multi1.
	assign mult0   = (opt[2]) ? 3 : avg;
	assign mult1_1 = (opt[2]) ? stage0_n0 : n1;
	assign mult1_2 = (opt[2]) ? stage0_n4 : stage0_n2;
	assign mult0_out = mult0 * n3;
	assign mult1_out = mult1_1 * mult1_2;
	assign mult1_abs = (opt[2]) ? (~mult1_out) + 1 : mult1_out;

	//Only  2 adder need to use, can use opt[2] selsect which signal deliver to adder0 and adder1.
	assign add1_1 = mult0_out + mult1_abs;
	assign add1_2 = (opt[2]) ? 0 : n0;
	assign add1_out = add1_1 + add1_2;

	//div3 lookuptable
	div_3_lookuptable div_3_lookuptable_U(
		.add1_out(add1_out),
		.add1_out_div(add1_out_div)
	);	
	assign add1_out_abs = (add1_out[9]) ? (~add1_out) + 1 : add1_out;
	assign out_n = (opt[2]) ? add1_out_abs : add1_out_div;

endmodule

module Up_sort(
	input [3:0] in_n0, in_n1, in_n2, in_n3, in_n4,
	output [3:0] sor_n0, sor_n1, sor_n2, sor_n3, sor_n4
);
	wire [3:0] comp0_H, comp0_L, comp1_H, comp1_L;
	wire [3:0] comp2_H, comp2_L, comp3_H, comp3_L;
	wire [3:0] comp4_L, comp5_H, comp5_L;
	wire [3:0] comp6_L, comp7_H;
	wire comp0_result, comp1_result, comp2_result, comp3_result, comp4_result;
	wire comp5_result, comp6_result, comp7_result, comp8_result;

	assign comp0_result = (in_n0 > in_n3);
	assign comp0_H = (comp0_result) ? in_n0 : in_n3;
	assign comp0_L = (comp0_result) ? in_n3 : in_n0;

	assign comp1_result = (in_n1 > in_n4);
	assign comp1_H = (comp1_result) ? in_n1 : in_n4;
	assign comp1_L = (comp1_result) ? in_n4 : in_n1;

	assign comp2_result = (comp0_H > in_n2);
	assign comp2_H = (comp2_result) ? comp0_H : in_n2;
	assign comp2_L = (comp2_result) ? in_n2   : comp0_H;

	assign comp3_result = (comp1_H > comp0_L);
	assign comp3_H = (comp3_result) ? comp1_H : comp0_L;
	assign comp3_L = (comp3_result) ? comp0_L : comp1_H;

	assign comp4_result = (comp2_H > comp3_H);
	assign sor_n0  = (comp4_result) ? comp2_H : comp3_H;
	assign comp4_L = (comp4_result) ? comp3_H : comp2_H;

	assign comp5_result = (comp2_L > comp1_L);
	assign comp5_H = (comp5_result) ? comp2_L : comp1_L;
	assign comp5_L = (comp5_result) ? comp1_L : comp2_L;

	assign comp6_result = (comp4_L > comp5_H);
	assign sor_n1  = (comp6_result) ? comp4_L : comp5_H;
	assign comp6_L = (comp6_result) ? comp5_H : comp4_L;

	assign comp7_result = (comp3_L > comp5_L);
	assign comp7_H = (comp7_result) ? comp3_L : comp5_L;
	assign sor_n4  = (comp7_result) ? comp5_L : comp3_L;

	assign comp8_result = (comp6_L > comp7_H);
	assign sor_n2 = (comp8_result) ? comp6_L : comp7_H;
	assign sor_n3 = (comp8_result) ? comp7_H : comp6_L;

endmodule

module div_5_lookuptable(
	input [7:0] avg_temp3,
	output reg [4:0] avg
);

	always @(*) begin
		case(avg_temp3)
			8'd0, 8'd1, 8'd2, 8'd3, 8'd4: avg = 5'd0;
			8'd5, 8'd6, 8'd7, 8'd8, 8'd9: avg = 5'd1;
			8'd10, 8'd11, 8'd12, 8'd13, 8'd14: avg = 5'd2;
			8'd15, 8'd16, 8'd17, 8'd18, 8'd19: avg = 5'd3;
			8'd20, 8'd21, 8'd22, 8'd23, 8'd24: avg = 5'd4;
			8'd25, 8'd26, 8'd27, 8'd28, 8'd29: avg = 5'd5;
			8'd30, 8'd31, 8'd32, 8'd33, 8'd34: avg = 5'd6;
			8'd35, 8'd36, 8'd37, 8'd38, 8'd39: avg = 5'd7;
			8'd40, 8'd41, 8'd42, 8'd43, 8'd44: avg = 5'd8;
			8'd45, 8'd46, 8'd47, 8'd48, 8'd49: avg = 5'd9;
			8'd50, 8'd51, 8'd52, 8'd53, 8'd54: avg = 5'd10;
			8'd55, 8'd56, 8'd57, 8'd58, 8'd59: avg = 5'd11;
			8'd60, 8'd61, 8'd62, 8'd63, 8'd64: avg = 5'd12;
			8'd65, 8'd66, 8'd67, 8'd68, 8'd69: avg = 5'd13;
			8'd70, 8'd71, 8'd72, 8'd73, 8'd74: avg = 5'd14;
			8'd75, 8'd76, 8'd77, 8'd78, 8'd79: avg = 5'd15;
			-8'd0, -8'd1, -8'd2, -8'd3, -8'd4: avg = 5'd0;
			-8'd5, -8'd6, -8'd7, -8'd8, -8'd9: avg = -5'd1;
			-8'd10, -8'd11, -8'd12, -8'd13, -8'd14: avg = -5'd2;
			-8'd15, -8'd16, -8'd17, -8'd18, -8'd19: avg = -5'd3;
			-8'd20, -8'd21, -8'd22, -8'd23, -8'd24: avg = -5'd4;
			-8'd25, -8'd26, -8'd27, -8'd28, -8'd29: avg = -5'd5;
			-8'd30, -8'd31, -8'd32, -8'd33, -8'd34: avg = -5'd6;
			-8'd35, -8'd36, -8'd37, -8'd38, -8'd39: avg = -5'd7;
			-8'd40, -8'd41, -8'd42, -8'd43, -8'd44: avg = -5'd8;
			-8'd45, -8'd46, -8'd47, -8'd48, -8'd49: avg = -5'd9;
			-8'd50, -8'd51, -8'd52, -8'd53, -8'd54: avg = -5'd10;
			-8'd55, -8'd56, -8'd57, -8'd58, -8'd59: avg = -5'd11;
			-8'd60, -8'd61, -8'd62, -8'd63, -8'd64: avg = -5'd12;
			-8'd65, -8'd66, -8'd67, -8'd68, -8'd69: avg = -5'd13;
			-8'd70, -8'd71, -8'd72, -8'd73, -8'd74: avg = -5'd14;
			-8'd75, -8'd76, -8'd77, -8'd78, -8'd79: avg = -5'd15;
			-8'd80, -8'd81, -8'd82, -8'd83, -8'd84: avg = -5'd16;
			default: avg = 5'd0;
		endcase
	end
endmodule

module div_3_lookuptable(
	input [9:0] add1_out,
	output reg [9:0] add1_out_div
);

	always @(*) begin
		case(add1_out)
			10'd0, 10'd1, 10'd2: add1_out_div = 10'd0;
			10'd3, 10'd4, 10'd5: add1_out_div = 10'd1;
			10'd6, 10'd7, 10'd8: add1_out_div = 10'd2;
			10'd9, 10'd10, 10'd11: add1_out_div = 10'd3;
			10'd12, 10'd13, 10'd14: add1_out_div = 10'd4;
			10'd15, 10'd16, 10'd17: add1_out_div = 10'd5;
			10'd18, 10'd19, 10'd20: add1_out_div = 10'd6;
			10'd21, 10'd22, 10'd23: add1_out_div = 10'd7;
			10'd24, 10'd25, 10'd26: add1_out_div = 10'd8;
			10'd27, 10'd28, 10'd29: add1_out_div = 10'd9;
			10'd30, 10'd31, 10'd32: add1_out_div = 10'd10;
			10'd33, 10'd34, 10'd35: add1_out_div = 10'd11;
			10'd36, 10'd37, 10'd38: add1_out_div = 10'd12;
			10'd39, 10'd40, 10'd41: add1_out_div = 10'd13;
			10'd42, 10'd43, 10'd44: add1_out_div = 10'd14;
			10'd45, 10'd46, 10'd47: add1_out_div = 10'd15;
			10'd48, 10'd49, 10'd50: add1_out_div = 10'd16;
			10'd51, 10'd52, 10'd53: add1_out_div = 10'd17;
			10'd54, 10'd55, 10'd56: add1_out_div = 10'd18;
			10'd57, 10'd58, 10'd59: add1_out_div = 10'd19;
			10'd60, 10'd61, 10'd62: add1_out_div = 10'd20;
			10'd63, 10'd64, 10'd65: add1_out_div = 10'd21;
			10'd66, 10'd67, 10'd68: add1_out_div = 10'd22;
			10'd69, 10'd70, 10'd71: add1_out_div = 10'd23;
			10'd72, 10'd73, 10'd74: add1_out_div = 10'd24;
			10'd75, 10'd76, 10'd77: add1_out_div = 10'd25;
			10'd78, 10'd79, 10'd80: add1_out_div = 10'd26;
			10'd81, 10'd82, 10'd83: add1_out_div = 10'd27;
			10'd84, 10'd85, 10'd86: add1_out_div = 10'd28;
			10'd87, 10'd88, 10'd89: add1_out_div = 10'd29;
			10'd90, 10'd91, 10'd92: add1_out_div = 10'd30;
			10'd93, 10'd94, 10'd95: add1_out_div = 10'd31;
			10'd96, 10'd97, 10'd98: add1_out_div = 10'd32;
			10'd99, 10'd100, 10'd101: add1_out_div = 10'd33;
			10'd102, 10'd103, 10'd104: add1_out_div = 10'd34;
			10'd105, 10'd106, 10'd107: add1_out_div = 10'd35;
			10'd108, 10'd109, 10'd110: add1_out_div = 10'd36;
			10'd111, 10'd112, 10'd113: add1_out_div = 10'd37;
			10'd114, 10'd115, 10'd116: add1_out_div = 10'd38;
			10'd117, 10'd118, 10'd119: add1_out_div = 10'd39;
			10'd120, 10'd121, 10'd122: add1_out_div = 10'd40;
			10'd123, 10'd124, 10'd125: add1_out_div = 10'd41;
			10'd126, 10'd127, 10'd128: add1_out_div = 10'd42;
			10'd129, 10'd130, 10'd131: add1_out_div = 10'd43;
			10'd132, 10'd133, 10'd134: add1_out_div = 10'd44;
			10'd135, 10'd136, 10'd137: add1_out_div = 10'd45;
			10'd138, 10'd139, 10'd140: add1_out_div = 10'd46;
			10'd141, 10'd142, 10'd143: add1_out_div = 10'd47;
			10'd144, 10'd145, 10'd146: add1_out_div = 10'd48;
			10'd147, 10'd148, 10'd149: add1_out_div = 10'd49;
			10'd150, 10'd151, 10'd152: add1_out_div = 10'd50;
			10'd153, 10'd154, 10'd155: add1_out_div = 10'd51;
			10'd156, 10'd157, 10'd158: add1_out_div = 10'd52;
			10'd159, 10'd160, 10'd161: add1_out_div = 10'd53;
			10'd162, 10'd163, 10'd164: add1_out_div = 10'd54;
			10'd165, 10'd166, 10'd167: add1_out_div = 10'd55;
			10'd168, 10'd169, 10'd170: add1_out_div = 10'd56;
			10'd171, 10'd172, 10'd173: add1_out_div = 10'd57;
			10'd174, 10'd175, 10'd176: add1_out_div = 10'd58;
			10'd177, 10'd178, 10'd179: add1_out_div = 10'd59;
			10'd180, 10'd181, 10'd182: add1_out_div = 10'd60;
			10'd183, 10'd184, 10'd185: add1_out_div = 10'd61;
			10'd186, 10'd187, 10'd188: add1_out_div = 10'd62;
			10'd189, 10'd190, 10'd191: add1_out_div = 10'd63;
			10'd192, 10'd193, 10'd194: add1_out_div = 10'd64;
			10'd195, 10'd196, 10'd197: add1_out_div = 10'd65;
			10'd198, 10'd199, 10'd200: add1_out_div = 10'd66;
			10'd201, 10'd202, 10'd203: add1_out_div = 10'd67;
			10'd204, 10'd205, 10'd206: add1_out_div = 10'd68;
			10'd207, 10'd208, 10'd209: add1_out_div = 10'd69;
			10'd210, 10'd211, 10'd212: add1_out_div = 10'd70;
			10'd213, 10'd214, 10'd215: add1_out_div = 10'd71;
			10'd216, 10'd217, 10'd218: add1_out_div = 10'd72;
			10'd219, 10'd220, 10'd221: add1_out_div = 10'd73;
			10'd222, 10'd223, 10'd224: add1_out_div = 10'd74;
			10'd225, 10'd226, 10'd227: add1_out_div = 10'd75;
			10'd228, 10'd229, 10'd230: add1_out_div = 10'd76;
			10'd231, 10'd232, 10'd233: add1_out_div = 10'd77;
			10'd234, 10'd235, 10'd236: add1_out_div = 10'd78;
			10'd237, 10'd238, 10'd239: add1_out_div = 10'd79;
			10'd240, 10'd241, 10'd242: add1_out_div = 10'd80;
			10'd243, 10'd244, 10'd245: add1_out_div = 10'd81;
			10'd246, 10'd247, 10'd248: add1_out_div = 10'd82;
			10'd249, 10'd250, 10'd251: add1_out_div = 10'd83;
			10'd252, 10'd253, 10'd254: add1_out_div = 10'd84;
			10'd255, 10'd256, 10'd257: add1_out_div = 10'd85;
			10'd258, 10'd259, 10'd260: add1_out_div = 10'd86;
			10'd261, 10'd262, 10'd263: add1_out_div = 10'd87;
			10'd264, 10'd265, 10'd266: add1_out_div = 10'd88;
			10'd267, 10'd268, 10'd269: add1_out_div = 10'd89;
			10'd270, 10'd271, 10'd272: add1_out_div = 10'd90;
			10'd273, 10'd274, 10'd275: add1_out_div = 10'd91;
			10'd276, 10'd277, 10'd278: add1_out_div = 10'd92;
			10'd279, 10'd280, 10'd281: add1_out_div = 10'd93;
			10'd282, 10'd283, 10'd284: add1_out_div = 10'd94;
			10'd285, 10'd286, 10'd287: add1_out_div = 10'd95;
			10'd288, 10'd289, 10'd290: add1_out_div = 10'd96;
			10'd291, 10'd292, 10'd293: add1_out_div = 10'd97;
			10'd294, 10'd295, 10'd296: add1_out_div = 10'd98;
			10'd297, 10'd298, 10'd299: add1_out_div = 10'd99;
			10'd300, 10'd301, 10'd302: add1_out_div = 10'd100;
			10'd303, 10'd304, 10'd305: add1_out_div = 10'd101;
			10'd306, 10'd307, 10'd308: add1_out_div = 10'd102;
			10'd309, 10'd310, 10'd311: add1_out_div = 10'd103;
			10'd312, 10'd313, 10'd314: add1_out_div = 10'd104;
			10'd315, 10'd316, 10'd317: add1_out_div = 10'd105;
			10'd318, 10'd319, 10'd320: add1_out_div = 10'd106;
			10'd321, 10'd322, 10'd323: add1_out_div = 10'd107;
			10'd324, 10'd325, 10'd326: add1_out_div = 10'd108;
			10'd327, 10'd328, 10'd329: add1_out_div = 10'd109;
			10'd330, 10'd331, 10'd332: add1_out_div = 10'd110;
			10'd333, 10'd334, 10'd335: add1_out_div = 10'd111;
			10'd336, 10'd337, 10'd338: add1_out_div = 10'd112;
			10'd339, 10'd340, 10'd341: add1_out_div = 10'd113;
			10'd342, 10'd343, 10'd344: add1_out_div = 10'd114;
			10'd345, 10'd346, 10'd347: add1_out_div = 10'd115;
			10'd348, 10'd349, 10'd350: add1_out_div = 10'd116;
			10'd351, 10'd352, 10'd353: add1_out_div = 10'd117;
			10'd354, 10'd355, 10'd356: add1_out_div = 10'd118;
			10'd357, 10'd358, 10'd359: add1_out_div = 10'd119;
			10'd360, 10'd361, 10'd362: add1_out_div = 10'd120;
			10'd363, 10'd364, 10'd365: add1_out_div = 10'd121;
			10'd366, 10'd367, 10'd368: add1_out_div = 10'd122;
			10'd369, 10'd370, 10'd371: add1_out_div = 10'd123;
			10'd372, 10'd373, 10'd374: add1_out_div = 10'd124;
			10'd375, 10'd376, 10'd377: add1_out_div = 10'd125;
			10'd378, 10'd379, 10'd380: add1_out_div = 10'd126;
			10'd381, 10'd382, 10'd383: add1_out_div = 10'd127;
			10'd384, 10'd385, 10'd386: add1_out_div = 10'd128;
			10'd387, 10'd388, 10'd389: add1_out_div = 10'd129;
			10'd390, 10'd391, 10'd392: add1_out_div = 10'd130;
			10'd393, 10'd394, 10'd395: add1_out_div = 10'd131;
			10'd396, 10'd397, 10'd398: add1_out_div = 10'd132;
			10'd399, 10'd400, 10'd401: add1_out_div = 10'd133;
			10'd402, 10'd403, 10'd404: add1_out_div = 10'd134;
			10'd405, 10'd406, 10'd407: add1_out_div = 10'd135;
			10'd408, 10'd409, 10'd410: add1_out_div = 10'd136;
			10'd411, 10'd412, 10'd413: add1_out_div = 10'd137;
			10'd414, 10'd415, 10'd416: add1_out_div = 10'd138;
			10'd417, 10'd418, 10'd419: add1_out_div = 10'd139;
			10'd420, 10'd421, 10'd422: add1_out_div = 10'd140;
			10'd423, 10'd424, 10'd425: add1_out_div = 10'd141;
			10'd426, 10'd427, 10'd428: add1_out_div = 10'd142;
			10'd429, 10'd430, 10'd431: add1_out_div = 10'd143;
			10'd432, 10'd433, 10'd434: add1_out_div = 10'd144;
			10'd435, 10'd436, 10'd437: add1_out_div = 10'd145;
			10'd438, 10'd439, 10'd440: add1_out_div = 10'd146;
			10'd441, 10'd442, 10'd443: add1_out_div = 10'd147;
			10'd444, 10'd445, 10'd446: add1_out_div = 10'd148;
			10'd447, 10'd448, 10'd449: add1_out_div = 10'd149;
			10'd450, 10'd451, 10'd452: add1_out_div = 10'd150;
			10'd453, 10'd454, 10'd455: add1_out_div = 10'd151;
			10'd456, 10'd457, 10'd458: add1_out_div = 10'd152;
			10'd459, 10'd460, 10'd461: add1_out_div = 10'd153;
			10'd462, 10'd463, 10'd464: add1_out_div = 10'd154;
			10'd465, 10'd466, 10'd467: add1_out_div = 10'd155;
			10'd468, 10'd469, 10'd470: add1_out_div = 10'd156;
			10'd471, 10'd472, 10'd473: add1_out_div = 10'd157;
			10'd474, 10'd475, 10'd476: add1_out_div = 10'd158;
			10'd477, 10'd478, 10'd479: add1_out_div = 10'd159;
			10'd480, 10'd481, 10'd482: add1_out_div = 10'd160;
			10'd483, 10'd484, 10'd485: add1_out_div = 10'd161;
			10'd486, 10'd487, 10'd488: add1_out_div = 10'd162;
			10'd489, 10'd490, 10'd491: add1_out_div = 10'd163;
			10'd492, 10'd493, 10'd494: add1_out_div = 10'd164;
			10'd495, 10'd496, 10'd497: add1_out_div = 10'd165;
			10'd498, 10'd499, 10'd500: add1_out_div = 10'd166;
			10'd501, 10'd502, 10'd503: add1_out_div = 10'd167;
			10'd504, 10'd505, 10'd506: add1_out_div = 10'd168;
			10'd507, 10'd508, 10'd509: add1_out_div = 10'd169;
			10'd510, 10'd511: add1_out_div = 10'd170; 
			-10'd0, -10'd1, -10'd2: add1_out_div = 10'd0;
			-10'd3, -10'd4, -10'd5: add1_out_div = -10'd1;
			-10'd6, -10'd7, -10'd8: add1_out_div = -10'd2;
			-10'd9, -10'd10, -10'd11: add1_out_div = -10'd3;
			-10'd12, -10'd13, -10'd14: add1_out_div = -10'd4;
			-10'd15, -10'd16, -10'd17: add1_out_div = -10'd5;
			-10'd18, -10'd19, -10'd20: add1_out_div = -10'd6;
			-10'd21, -10'd22, -10'd23: add1_out_div = -10'd7;
			-10'd24, -10'd25, -10'd26: add1_out_div = -10'd8;
			-10'd27, -10'd28, -10'd29: add1_out_div = -10'd9;
			-10'd30, -10'd31, -10'd32: add1_out_div = -10'd10;
			-10'd33, -10'd34, -10'd35: add1_out_div = -10'd11;
			-10'd36, -10'd37, -10'd38: add1_out_div = -10'd12;
			-10'd39, -10'd40, -10'd41: add1_out_div = -10'd13;
			-10'd42, -10'd43, -10'd44: add1_out_div = -10'd14;
			-10'd45, -10'd46, -10'd47: add1_out_div = -10'd15;
			-10'd48, -10'd49, -10'd50: add1_out_div = -10'd16;
			-10'd51, -10'd52, -10'd53: add1_out_div = -10'd17;
			-10'd54, -10'd55, -10'd56: add1_out_div = -10'd18;
			-10'd57, -10'd58, -10'd59: add1_out_div = -10'd19;
			-10'd60, -10'd61, -10'd62: add1_out_div = -10'd20;
			-10'd63, -10'd64, -10'd65: add1_out_div = -10'd21;
			-10'd66, -10'd67, -10'd68: add1_out_div = -10'd22;
			-10'd69, -10'd70, -10'd71: add1_out_div = -10'd23;
			-10'd72, -10'd73, -10'd74: add1_out_div = -10'd24;
			-10'd75, -10'd76, -10'd77: add1_out_div = -10'd25;
			-10'd78, -10'd79, -10'd80: add1_out_div = -10'd26;
			-10'd81, -10'd82, -10'd83: add1_out_div = -10'd27;
			-10'd84, -10'd85, -10'd86: add1_out_div = -10'd28;
			-10'd87, -10'd88, -10'd89: add1_out_div = -10'd29;
			-10'd90, -10'd91, -10'd92: add1_out_div = -10'd30;
			-10'd93, -10'd94, -10'd95: add1_out_div = -10'd31;
			-10'd96, -10'd97, -10'd98: add1_out_div = -10'd32;
			-10'd99, -10'd100, -10'd101: add1_out_div = -10'd33;
			-10'd102, -10'd103, -10'd104: add1_out_div = -10'd34;
			-10'd105, -10'd106, -10'd107: add1_out_div = -10'd35;
			-10'd108, -10'd109, -10'd110: add1_out_div = -10'd36;
			-10'd111, -10'd112, -10'd113: add1_out_div = -10'd37;
			-10'd114, -10'd115, -10'd116: add1_out_div = -10'd38;
			-10'd117, -10'd118, -10'd119: add1_out_div = -10'd39;
			-10'd120, -10'd121, -10'd122: add1_out_div = -10'd40;
			-10'd123, -10'd124, -10'd125: add1_out_div = -10'd41;
			-10'd126, -10'd127, -10'd128: add1_out_div = -10'd42;
			-10'd129, -10'd130, -10'd131: add1_out_div = -10'd43;
			-10'd132, -10'd133, -10'd134: add1_out_div = -10'd44;
			-10'd135, -10'd136, -10'd137: add1_out_div = -10'd45;
			-10'd138, -10'd139, -10'd140: add1_out_div = -10'd46;
			-10'd141, -10'd142, -10'd143: add1_out_div = -10'd47;
			-10'd144, -10'd145, -10'd146: add1_out_div = -10'd48;
			-10'd147, -10'd148, -10'd149: add1_out_div = -10'd49;
			-10'd150, -10'd151, -10'd152: add1_out_div = -10'd50;
			-10'd153, -10'd154, -10'd155: add1_out_div = -10'd51;
			-10'd156, -10'd157, -10'd158: add1_out_div = -10'd52;
			-10'd159, -10'd160, -10'd161: add1_out_div = -10'd53;
			-10'd162, -10'd163, -10'd164: add1_out_div = -10'd54;
			-10'd165, -10'd166, -10'd167: add1_out_div = -10'd55;
			-10'd168, -10'd169, -10'd170: add1_out_div = -10'd56;
			-10'd171, -10'd172, -10'd173: add1_out_div = -10'd57;
			-10'd174, -10'd175, -10'd176: add1_out_div = -10'd58;
			-10'd177, -10'd178, -10'd179: add1_out_div = -10'd59;
			-10'd180, -10'd181, -10'd182: add1_out_div = -10'd60;
			-10'd183, -10'd184, -10'd185: add1_out_div = -10'd61;
			-10'd186, -10'd187, -10'd188: add1_out_div = -10'd62;
			-10'd189, -10'd190, -10'd191: add1_out_div = -10'd63;
			-10'd192, -10'd193, -10'd194: add1_out_div = -10'd64;
			-10'd195, -10'd196, -10'd197: add1_out_div = -10'd65;
			-10'd198, -10'd199, -10'd200: add1_out_div = -10'd66;
			-10'd201, -10'd202, -10'd203: add1_out_div = -10'd67;
			-10'd204, -10'd205, -10'd206: add1_out_div = -10'd68;
			-10'd207, -10'd208, -10'd209: add1_out_div = -10'd69;
			-10'd210, -10'd211, -10'd212: add1_out_div = -10'd70;
			-10'd213, -10'd214, -10'd215: add1_out_div = -10'd71;
			-10'd216, -10'd217, -10'd218: add1_out_div = -10'd72;
			-10'd219, -10'd220, -10'd221: add1_out_div = -10'd73;
			-10'd222, -10'd223, -10'd224: add1_out_div = -10'd74;
			-10'd225, -10'd226, -10'd227: add1_out_div = -10'd75;
			-10'd228, -10'd229, -10'd230: add1_out_div = -10'd76;
			-10'd231, -10'd232, -10'd233: add1_out_div = -10'd77;
			-10'd234, -10'd235, -10'd236: add1_out_div = -10'd78;
			-10'd237, -10'd238, -10'd239: add1_out_div = -10'd79;
			-10'd240, -10'd241, -10'd242: add1_out_div = -10'd80;
			-10'd243, -10'd244, -10'd245: add1_out_div = -10'd81;
			-10'd246, -10'd247, -10'd248: add1_out_div = -10'd82;
			-10'd249, -10'd250, -10'd251: add1_out_div = -10'd83;
			-10'd252, -10'd253, -10'd254: add1_out_div = -10'd84;
			-10'd255, -10'd256, -10'd257: add1_out_div = -10'd85;
			-10'd258, -10'd259, -10'd260: add1_out_div = -10'd86;
			-10'd261, -10'd262, -10'd263: add1_out_div = -10'd87;
			-10'd264, -10'd265, -10'd266: add1_out_div = -10'd88;
			-10'd267, -10'd268, -10'd269: add1_out_div = -10'd89;
			-10'd270, -10'd271, -10'd272: add1_out_div = -10'd90;
			-10'd273, -10'd274, -10'd275: add1_out_div = -10'd91;
			-10'd276, -10'd277, -10'd278: add1_out_div = -10'd92;
			-10'd279, -10'd280, -10'd281: add1_out_div = -10'd93;
			-10'd282, -10'd283, -10'd284: add1_out_div = -10'd94;
			-10'd285, -10'd286, -10'd287: add1_out_div = -10'd95;
			-10'd288, -10'd289, -10'd290: add1_out_div = -10'd96;
			-10'd291, -10'd292, -10'd293: add1_out_div = -10'd97;
			-10'd294, -10'd295, -10'd296: add1_out_div = -10'd98;
			-10'd297, -10'd298, -10'd299: add1_out_div = -10'd99;
			-10'd300, -10'd301, -10'd302: add1_out_div = -10'd100;
			-10'd303, -10'd304, -10'd305: add1_out_div = -10'd101;
			-10'd306, -10'd307, -10'd308: add1_out_div = -10'd102;
			-10'd309, -10'd310, -10'd311: add1_out_div = -10'd103;
			-10'd312, -10'd313, -10'd314: add1_out_div = -10'd104;
			-10'd315, -10'd316, -10'd317: add1_out_div = -10'd105;
			-10'd318, -10'd319, -10'd320: add1_out_div = -10'd106;
			-10'd321, -10'd322, -10'd323: add1_out_div = -10'd107;
			-10'd324, -10'd325, -10'd326: add1_out_div = -10'd108;
			-10'd327, -10'd328, -10'd329: add1_out_div = -10'd109;
			-10'd330, -10'd331, -10'd332: add1_out_div = -10'd110;
			-10'd333, -10'd334, -10'd335: add1_out_div = -10'd111;
			-10'd336, -10'd337, -10'd338: add1_out_div = -10'd112;
			-10'd339, -10'd340, -10'd341: add1_out_div = -10'd113;
			-10'd342, -10'd343, -10'd344: add1_out_div = -10'd114;
			-10'd345, -10'd346, -10'd347: add1_out_div = -10'd115;
			-10'd348, -10'd349, -10'd350: add1_out_div = -10'd116;
			-10'd351, -10'd352, -10'd353: add1_out_div = -10'd117;
			-10'd354, -10'd355, -10'd356: add1_out_div = -10'd118;
			-10'd357, -10'd358, -10'd359: add1_out_div = -10'd119;
			-10'd360, -10'd361, -10'd362: add1_out_div = -10'd120;
			-10'd363, -10'd364, -10'd365: add1_out_div = -10'd121;
			-10'd366, -10'd367, -10'd368: add1_out_div = -10'd122;
			-10'd369, -10'd370, -10'd371: add1_out_div = -10'd123;
			-10'd372, -10'd373, -10'd374: add1_out_div = -10'd124;
			-10'd375, -10'd376, -10'd377: add1_out_div = -10'd125;
			-10'd378, -10'd379, -10'd380: add1_out_div = -10'd126;
			-10'd381, -10'd382, -10'd383: add1_out_div = -10'd127;
			-10'd384, -10'd385, -10'd386: add1_out_div = -10'd128;
			-10'd387, -10'd388, -10'd389: add1_out_div = -10'd129;
			-10'd390, -10'd391, -10'd392: add1_out_div = -10'd130;
			-10'd393, -10'd394, -10'd395: add1_out_div = -10'd131;
			-10'd396, -10'd397, -10'd398: add1_out_div = -10'd132;
			-10'd399, -10'd400, -10'd401: add1_out_div = -10'd133;
			-10'd402, -10'd403, -10'd404: add1_out_div = -10'd134;
			-10'd405, -10'd406, -10'd407: add1_out_div = -10'd135;
			-10'd408, -10'd409, -10'd410: add1_out_div = -10'd136;
			-10'd411, -10'd412, -10'd413: add1_out_div = -10'd137;
			-10'd414, -10'd415, -10'd416: add1_out_div = -10'd138;
			-10'd417, -10'd418, -10'd419: add1_out_div = -10'd139;
			-10'd420, -10'd421, -10'd422: add1_out_div = -10'd140;
			-10'd423, -10'd424, -10'd425: add1_out_div = -10'd141;
			-10'd426, -10'd427, -10'd428: add1_out_div = -10'd142;
			-10'd429, -10'd430, -10'd431: add1_out_div = -10'd143;
			-10'd432, -10'd433, -10'd434: add1_out_div = -10'd144;
			-10'd435, -10'd436, -10'd437: add1_out_div = -10'd145;
			-10'd438, -10'd439, -10'd440: add1_out_div = -10'd146;
			-10'd441, -10'd442, -10'd443: add1_out_div = -10'd147;
			-10'd444, -10'd445, -10'd446: add1_out_div = -10'd148;
			-10'd447, -10'd448, -10'd449: add1_out_div = -10'd149;
			-10'd450, -10'd451, -10'd452: add1_out_div = -10'd150;
			-10'd453, -10'd454, -10'd455: add1_out_div = -10'd151;
			-10'd456, -10'd457, -10'd458: add1_out_div = -10'd152;
			-10'd459, -10'd460, -10'd461: add1_out_div = -10'd153;
			-10'd462, -10'd463, -10'd464: add1_out_div = -10'd154;
			-10'd465, -10'd466, -10'd467: add1_out_div = -10'd155;
			-10'd468, -10'd469, -10'd470: add1_out_div = -10'd156;
			-10'd471, -10'd472, -10'd473: add1_out_div = -10'd157;
			-10'd474, -10'd475, -10'd476: add1_out_div = -10'd158;
			-10'd477, -10'd478, -10'd479: add1_out_div = -10'd159;
			-10'd480, -10'd481, -10'd482: add1_out_div = -10'd160;
			-10'd483, -10'd484, -10'd485: add1_out_div = -10'd161;
			-10'd486, -10'd487, -10'd488: add1_out_div = -10'd162;
			-10'd489, -10'd490, -10'd491: add1_out_div = -10'd163;
			-10'd492, -10'd493, -10'd494: add1_out_div = -10'd164;
			-10'd495, -10'd496, -10'd497: add1_out_div = -10'd165;
			-10'd498, -10'd499, -10'd500: add1_out_div = -10'd166;
			-10'd501, -10'd502, -10'd503: add1_out_div = -10'd167;
			-10'd504, -10'd505, -10'd506: add1_out_div = -10'd168;
			-10'd507, -10'd508, -10'd509: add1_out_div = -10'd169;
			-10'd510, -10'd511, -10'd512: add1_out_div = -10'd170;
			default: add1_out_div = 10'd0;
		endcase
	end

endmodule
