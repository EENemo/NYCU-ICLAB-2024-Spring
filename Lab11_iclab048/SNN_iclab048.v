// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on

//==============================================
//       Version 8 subnew
//       do
//			1. conv combanation swing
//			2. 2. jg/0102 pass
//       perf
//       	1. 5.673e-03  
//       	2. 117676
//          3. 28%
//==============================================

module SNN(
	// Input signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	img,
	ker,
	weight,

	// Output signals
	out_valid,
	out_data
);

input clk;
input rst_n;
input in_valid;
input cg_en;
input [7:0] img;
input [7:0] ker;
input [7:0] weight;

output reg out_valid;
output reg [9:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
integer i;
genvar j;

//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [6:0] fsm_cnt_r, fsm_cnt_w;

reg [7:0] img_r [0:17];
reg [7:0] img_w [0:17];
reg [7:0] ker_r [0:8];
reg [7:0] ker_w [0:8];
reg [7:0] weight_r [0:3];
reg [7:0] weight_w [0:3];
reg [4:0] in_img_pr;

//==============================================//
//                  design                      //
//==============================================//
//FSM counter
always @(*) begin
	if(fsm_cnt_r == 75) begin
		fsm_cnt_w = 0;
	end
	else if(in_valid || fsm_cnt_r != 0) begin
		fsm_cnt_w = fsm_cnt_r + 1;
	end
	else begin 
		fsm_cnt_w = fsm_cnt_r;
	end
end

always @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		fsm_cnt_r <= 0;
	end
	else begin
		fsm_cnt_r <= fsm_cnt_w;
	end
end

//store input
always @(*) begin
	case(fsm_cnt_r)
		0, 18, 36, 54: in_img_pr = 0;
		1, 19, 37, 55: in_img_pr = 1;
		2, 20, 38, 56: in_img_pr = 2;
		3, 21, 39, 57: in_img_pr = 3;
		4, 22, 40, 58: in_img_pr = 4;
		5, 23, 41, 59: in_img_pr = 5;
		6, 24, 42, 60: in_img_pr = 6;
		7, 25, 43, 61: in_img_pr = 7;
		8, 26, 44, 62: in_img_pr = 8;
		9, 27, 45, 63: in_img_pr = 9;
		10, 28, 46, 64: in_img_pr = 10;
		11, 29, 47, 65: in_img_pr = 11;
		12, 30, 48, 66: in_img_pr = 12;
		13, 31, 49, 67: in_img_pr = 13;
		14, 32, 50, 68: in_img_pr = 14;
		15, 33, 51, 69: in_img_pr = 15;
		16, 34, 52, 70: in_img_pr = 16;
		17, 35, 53, 71: in_img_pr = 17;
		default:  in_img_pr = 0;
	endcase
end

always @(*) begin
	for(i=0; i<18; i=i+1) img_w[i] = img_r[i];

	if(in_valid) begin
		img_w[in_img_pr] = img;
	end
end

always @(*) begin
	for(i=0; i<9; i=i+1) begin
		if(fsm_cnt_r == i && in_valid) begin
			ker_w[i] = ker;
		end
		else begin
			ker_w[i] = ker_r[i];
		end
	end
end

always @(*) begin
	for(i=0; i<4; i=i+1) begin
		if(fsm_cnt_r == i && in_valid) begin
			weight_w[i] = weight;
		end
		else begin
			weight_w[i] = weight_r[i];
		end
	end
end

// Clock Gate
generate
for(j=0; j<18; j=j+1) begin
	wire img_clk;
	wire img_sleep;
	assign img_sleep = (~(in_img_pr == j) && (cg_en));
	GATED_OR GATED_img (
		.CLOCK(clk),
		.SLEEP_CTRL(img_sleep),	
		.RST_N(rst_n),
		.CLOCK_GATED(img_clk)
	);

	always @(posedge img_clk, negedge rst_n) begin
		if(!rst_n) begin
			img_r[j] <= 0;
		end
		else begin
			img_r[j] <= img_w[j];
		end
	end
end

endgenerate

generate
for(j=0; j<9; j=j+1) begin
	wire ker_clk;
	wire ker_sleep;
	assign ker_sleep = (~(fsm_cnt_r == j) && (cg_en));
	GATED_OR GATED_ker (
		.CLOCK(clk),
		.SLEEP_CTRL(ker_sleep),	
		.RST_N(rst_n),
		.CLOCK_GATED(ker_clk)
	);

	always @(posedge ker_clk, negedge rst_n) begin
		if(!rst_n) begin
			ker_r[j] <= 0;
		end
		else begin
			ker_r[j] <= ker_w[j];
		end
	end
end

endgenerate

generate
for(j=0; j<4; j=j+1) begin
	wire weight_clk;
	wire weight_sleep;
	assign weight_sleep = (~(fsm_cnt_r == j) && (cg_en));
	GATED_OR GATED_weight (
		.CLOCK(clk),
		.SLEEP_CTRL(weight_sleep),	
		.RST_N(rst_n),
		.CLOCK_GATED(weight_clk)
	);

	always @(posedge weight_clk, negedge rst_n) begin
		if(!rst_n) begin
			weight_r[j] <= 0;
		end
		else begin
			weight_r[j] <= weight_w[j];
		end
	end
end

endgenerate


//conv
reg [4:0] conv_pr;
reg [7:0] conv_multi_in [0:8];
wire [15:0] conv_multi [0:8];
wire [16:0] conv_add_1 [0:3];
wire [17:0] conv_add_2 [0:1];
wire [18:0] conv_add_3;
reg [19:0] conv_r, conv_w;
reg [2:0] conv_cnt6_r, conv_cnt6_w;
reg conv_flg_r;
wire conv_flg_w;

always @(*) begin
	if(fsm_cnt_r > 49) begin
		conv_pr =  fsm_cnt_r - 50;
	end
	else begin
		conv_pr = fsm_cnt_r - 14;
	end
end

wire conv_noswing;
assign conv_noswing = (cg_en);

always @(*) begin
    case(conv_pr) 
		0: conv_multi_in[0] = img_r[0];
        1: conv_multi_in[0] = img_r[1];
        2: conv_multi_in[0] = img_r[2];
        3: conv_multi_in[0] = img_r[3];
        6: conv_multi_in[0] = img_r[6];
        7: conv_multi_in[0] = img_r[7];
        8: conv_multi_in[0] = img_r[8];
        9: conv_multi_in[0] = img_r[9];
        12: conv_multi_in[0] = img_r[12];
        13: conv_multi_in[0] = img_r[13];
        14: conv_multi_in[0] = img_r[14];
        15: conv_multi_in[0] = img_r[15];
		18: conv_multi_in[0] = img_r[0];
        19: conv_multi_in[0] = img_r[1];
        20: conv_multi_in[0] = img_r[2];
        21: conv_multi_in[0] = img_r[3];

		22: conv_multi_in[0] = conv_noswing ? 0 :img_r[0];
		23: conv_multi_in[0] = conv_noswing ? 0 :img_r[1];
		24: conv_multi_in[0] = conv_noswing ? 0 :img_r[0];
		25: conv_multi_in[0] = conv_noswing ? 0 :img_r[1];
		26: conv_multi_in[0] = conv_noswing ? 0 :img_r[0];
		27: conv_multi_in[0] = conv_noswing ? 0 :img_r[1];
		28: conv_multi_in[0] = conv_noswing ? 0 :img_r[0];
		29: conv_multi_in[0] = conv_noswing ? 0 :img_r[1];
		30: conv_multi_in[0] = conv_noswing ? 0 :img_r[0];
		31: conv_multi_in[0] = conv_noswing ? 0 :img_r[1];
		default: conv_multi_in[0] = 0;
    endcase
end

always @(*) begin
    case(conv_pr) 
		0: conv_multi_in[1] = img_r[1];
        1: conv_multi_in[1] = img_r[2];
        2: conv_multi_in[1] = img_r[3];
        3: conv_multi_in[1] = img_r[4];
        6: conv_multi_in[1] = img_r[7];
        7: conv_multi_in[1] = img_r[8];
        8: conv_multi_in[1] = img_r[9];
        9: conv_multi_in[1] = img_r[10];
        12: conv_multi_in[1] = img_r[13];
        13: conv_multi_in[1] = img_r[14];
        14: conv_multi_in[1] = img_r[15];
        15: conv_multi_in[1] = img_r[16];
		18: conv_multi_in[1] = img_r[1];
        19: conv_multi_in[1] = img_r[2];
        20: conv_multi_in[1] = img_r[3];
        21: conv_multi_in[1] = img_r[4];

		22: conv_multi_in[1] = conv_noswing ? 0 :img_r[1];
		23: conv_multi_in[1] = conv_noswing ? 0 :img_r[2];
		24: conv_multi_in[1] = conv_noswing ? 0 :img_r[1];
		25: conv_multi_in[1] = conv_noswing ? 0 :img_r[2];
		26: conv_multi_in[1] = conv_noswing ? 0 :img_r[1];
		27: conv_multi_in[1] = conv_noswing ? 0 :img_r[2];
		28: conv_multi_in[1] = conv_noswing ? 0 :img_r[1];
		29: conv_multi_in[1] = conv_noswing ? 0 :img_r[2];
		30: conv_multi_in[1] = conv_noswing ? 0 :img_r[1];
		31: conv_multi_in[1] = conv_noswing ? 0 :img_r[2];
		default: conv_multi_in[1] = 0;
    endcase
end

always @(*) begin
    case(conv_pr) 
		0: conv_multi_in[2] = img_r[2];
        1: conv_multi_in[2] = img_r[3];
        2: conv_multi_in[2] = img_r[4];
        3: conv_multi_in[2] = img_r[5];
        6: conv_multi_in[2] = img_r[8];
        7: conv_multi_in[2] = img_r[9];
        8: conv_multi_in[2] = img_r[10];
        9: conv_multi_in[2] = img_r[11];
        12: conv_multi_in[2] = img_r[14];
        13: conv_multi_in[2] = img_r[15];
        14: conv_multi_in[2] = img_r[16];
        15: conv_multi_in[2] = img_r[17];
		18: conv_multi_in[2] = img_r[2];
        19: conv_multi_in[2] = img_r[3];
        20: conv_multi_in[2] = img_r[4];
        21: conv_multi_in[2] = img_r[5];

		22: conv_multi_in[2] = conv_noswing ? 0 :img_r[2];
		23: conv_multi_in[2] = conv_noswing ? 0 :img_r[3];
		24: conv_multi_in[2] = conv_noswing ? 0 :img_r[2];
		25: conv_multi_in[2] = conv_noswing ? 0 :img_r[3];
		26: conv_multi_in[2] = conv_noswing ? 0 :img_r[2];
		27: conv_multi_in[2] = conv_noswing ? 0 :img_r[3];
		28: conv_multi_in[2] = conv_noswing ? 0 :img_r[2];
		29: conv_multi_in[2] = conv_noswing ? 0 :img_r[3];
		30: conv_multi_in[2] = conv_noswing ? 0 :img_r[2];
		31: conv_multi_in[2] = conv_noswing ? 0 :img_r[3];
		default: conv_multi_in[2] = 0;
    endcase
end

always @(*) begin
    case(conv_pr) 
		0: conv_multi_in[3] = img_r[6];
        1: conv_multi_in[3] = img_r[7];
        2: conv_multi_in[3] = img_r[8];
        3: conv_multi_in[3] = img_r[9];
        6: conv_multi_in[3] = img_r[12];
        7: conv_multi_in[3] = img_r[13];
        8: conv_multi_in[3] = img_r[14];
        9: conv_multi_in[3] = img_r[15];
        12: conv_multi_in[3] = img_r[0];
        13: conv_multi_in[3] = img_r[1];
        14: conv_multi_in[3] = img_r[2];
        15: conv_multi_in[3] = img_r[3];
		18: conv_multi_in[3] = img_r[6];
        19: conv_multi_in[3] = img_r[7];
        20: conv_multi_in[3] = img_r[8];
        21: conv_multi_in[3] = img_r[9];

		22: conv_multi_in[3] = conv_noswing ? 0 :img_r[6];
		23: conv_multi_in[3] = conv_noswing ? 0 :img_r[7];
		24: conv_multi_in[3] = conv_noswing ? 0 :img_r[6];
		25: conv_multi_in[3] = conv_noswing ? 0 :img_r[7];
		26: conv_multi_in[3] = conv_noswing ? 0 :img_r[6];
		27: conv_multi_in[3] = conv_noswing ? 0 :img_r[7];
		28: conv_multi_in[3] = conv_noswing ? 0 :img_r[6];
		29: conv_multi_in[3] = conv_noswing ? 0 :img_r[7];
		30: conv_multi_in[3] = conv_noswing ? 0 :img_r[6];
		31: conv_multi_in[3] = conv_noswing ? 0 :img_r[7];
		default: conv_multi_in[3] = 0;
    endcase
end

always @(*) begin
    case(conv_pr) 
		0: conv_multi_in[4] = img_r[7];
        1: conv_multi_in[4] = img_r[8];
        2: conv_multi_in[4] = img_r[9];
        3: conv_multi_in[4] = img_r[10];
        6: conv_multi_in[4] = img_r[13];
        7: conv_multi_in[4] = img_r[14];
        8: conv_multi_in[4] = img_r[15];
        9: conv_multi_in[4] = img_r[16];
        12: conv_multi_in[4] = img_r[1];
        13: conv_multi_in[4] = img_r[2];
        14: conv_multi_in[4] = img_r[3];
        15: conv_multi_in[4] = img_r[4];
		18: conv_multi_in[4] = img_r[7];
        19: conv_multi_in[4] = img_r[8];
        20: conv_multi_in[4] = img_r[9];
        21: conv_multi_in[4] = img_r[10];

		22: conv_multi_in[4] = conv_noswing ? 0 :img_r[7];
		23: conv_multi_in[4] = conv_noswing ? 0 :img_r[8];
		24: conv_multi_in[4] = conv_noswing ? 0 :img_r[7];
		25: conv_multi_in[4] = conv_noswing ? 0 :img_r[8];
		26: conv_multi_in[4] = conv_noswing ? 0 :img_r[7];
		27: conv_multi_in[4] = conv_noswing ? 0 :img_r[8];
		28: conv_multi_in[4] = conv_noswing ? 0 :img_r[7];
		29: conv_multi_in[4] = conv_noswing ? 0 :img_r[8];
		30: conv_multi_in[4] = conv_noswing ? 0 :img_r[7];
		31: conv_multi_in[4] = conv_noswing ? 0 :img_r[8];
		default: conv_multi_in[4] = 0;
    endcase
end

always @(*) begin
    case(conv_pr) 
		0: conv_multi_in[5] = img_r[8];
        1: conv_multi_in[5] = img_r[9];
        2: conv_multi_in[5] = img_r[10];
        3: conv_multi_in[5] = img_r[11];
        6: conv_multi_in[5] = img_r[14];
        7: conv_multi_in[5] = img_r[15];
        8: conv_multi_in[5] = img_r[16];
        9: conv_multi_in[5] = img_r[17];
        12: conv_multi_in[5] = img_r[2];
        13: conv_multi_in[5] = img_r[3];
        14: conv_multi_in[5] = img_r[4];
        15: conv_multi_in[5] = img_r[5];
		18: conv_multi_in[5] = img_r[8];
        19: conv_multi_in[5] = img_r[9];
        20: conv_multi_in[5] = img_r[10];
        21: conv_multi_in[5] = img_r[11];

		22: conv_multi_in[5] = conv_noswing ? 0 :img_r[8];
		23: conv_multi_in[5] = conv_noswing ? 0 :img_r[9];
		24: conv_multi_in[5] = conv_noswing ? 0 :img_r[8];
		25: conv_multi_in[5] = conv_noswing ? 0 :img_r[9];
		26: conv_multi_in[5] = conv_noswing ? 0 :img_r[8];
		27: conv_multi_in[5] = conv_noswing ? 0 :img_r[9];
		28: conv_multi_in[5] = conv_noswing ? 0 :img_r[8];
		29: conv_multi_in[5] = conv_noswing ? 0 :img_r[9];
		30: conv_multi_in[5] = conv_noswing ? 0 :img_r[8];
		31: conv_multi_in[5] = conv_noswing ? 0 :img_r[9];
		default: conv_multi_in[5] = 0;

    endcase
end

always @(*) begin
    case(conv_pr) 
		0: conv_multi_in[6] = img_r[12];
        1: conv_multi_in[6] = img_r[13];
        2: conv_multi_in[6] = img_r[14];
        3: conv_multi_in[6] = img_r[15];
        6: conv_multi_in[6] = img_r[0];
        7: conv_multi_in[6] = img_r[1];
        8: conv_multi_in[6] = img_r[2];
        9: conv_multi_in[6] = img_r[3];
        12: conv_multi_in[6] = img_r[6];
        13: conv_multi_in[6] = img_r[7];
        14: conv_multi_in[6] = img_r[8];
        15: conv_multi_in[6] = img_r[9];
		18: conv_multi_in[6] = img_r[12];
        19: conv_multi_in[6] = img_r[13];
        20: conv_multi_in[6] = img_r[14];
        21: conv_multi_in[6] = img_r[15];

		22: conv_multi_in[6] = conv_noswing ? 0 :img_r[12];
		23: conv_multi_in[6] = conv_noswing ? 0 :img_r[13];
		24: conv_multi_in[6] = conv_noswing ? 0 :img_r[12];
		25: conv_multi_in[6] = conv_noswing ? 0 :img_r[13];
		26: conv_multi_in[6] = conv_noswing ? 0 :img_r[12];
		27: conv_multi_in[6] = conv_noswing ? 0 :img_r[13];
		28: conv_multi_in[6] = conv_noswing ? 0 :img_r[12];
		29: conv_multi_in[6] = conv_noswing ? 0 :img_r[13];
		30: conv_multi_in[6] = conv_noswing ? 0 :img_r[12];
		31: conv_multi_in[6] = conv_noswing ? 0 :img_r[13];
		default: conv_multi_in[6] = 0;
    endcase
end

always @(*) begin
    case(conv_pr) 
		0: conv_multi_in[7] = img_r[13];
        1: conv_multi_in[7] = img_r[14];
        2: conv_multi_in[7] = img_r[15];
        3: conv_multi_in[7] = img_r[16];
        6: conv_multi_in[7] = img_r[1];
        7: conv_multi_in[7] = img_r[2];
        8: conv_multi_in[7] = img_r[3];
        9: conv_multi_in[7] = img_r[4];
        12: conv_multi_in[7] = img_r[7];
        13: conv_multi_in[7] = img_r[8];
        14: conv_multi_in[7] = img_r[9];
        15: conv_multi_in[7] = img_r[10];
		18: conv_multi_in[7] = img_r[13];
        19: conv_multi_in[7] = img_r[14];
        20: conv_multi_in[7] = img_r[15];
        21: conv_multi_in[7] = img_r[16];

		22: conv_multi_in[7] = conv_noswing ? 0 :img_r[13];
		23: conv_multi_in[7] = conv_noswing ? 0 :img_r[14];
		24: conv_multi_in[7] = conv_noswing ? 0 :img_r[13];
		25: conv_multi_in[7] = conv_noswing ? 0 :img_r[14];
		26: conv_multi_in[7] = conv_noswing ? 0 :img_r[13];
		27: conv_multi_in[7] = conv_noswing ? 0 :img_r[14];
		28: conv_multi_in[7] = conv_noswing ? 0 :img_r[13];
		29: conv_multi_in[7] = conv_noswing ? 0 :img_r[14];
		30: conv_multi_in[7] = conv_noswing ? 0 :img_r[13];
		31: conv_multi_in[7] = conv_noswing ? 0 :img_r[14];
		default: conv_multi_in[7] = 0;
    endcase
end

always @(*) begin
	conv_multi_in[8] = img;
end

assign conv_multi[0] = conv_multi_in[0] * ker_r[0];
assign conv_multi[1] = conv_multi_in[1] * ker_r[1];
assign conv_multi[2] = conv_multi_in[2] * ker_r[2];
assign conv_multi[3] = conv_multi_in[3] * ker_r[3];
assign conv_multi[4] = conv_multi_in[4] * ker_r[4];
assign conv_multi[5] = conv_multi_in[5] * ker_r[5];
assign conv_multi[6] = conv_multi_in[6] * ker_r[6];
assign conv_multi[7] = conv_multi_in[7] * ker_r[7];
assign conv_multi[8] = conv_multi_in[8] * ker_r[8];

assign conv_add_1[0] = conv_multi[0] + conv_multi[1];
assign conv_add_1[1] = conv_multi[2] + conv_multi[3];
assign conv_add_1[2] = conv_multi[4] + conv_multi[5];
assign conv_add_1[3] = conv_multi[6] + conv_multi[7];

assign conv_add_2[0] = conv_add_1[0] + conv_add_1[1];
assign conv_add_2[1] = conv_add_1[2] + conv_add_1[3];

assign conv_add_3    = conv_add_2[0] + conv_add_2[1];

always @(*) begin
	if(conv_cnt6_r == 5) begin
		conv_cnt6_w = 0;
	end
	else if(in_valid) begin
		conv_cnt6_w = conv_cnt6_r + 1;
	end
	else begin
		conv_cnt6_w = conv_cnt6_r;
	end
end

assign conv_flg_w = (conv_cnt6_r == 2 || conv_cnt6_r == 3 || conv_cnt6_r == 4 || conv_cnt6_r == 5);

always @(*) begin
	if(((fsm_cnt_r > 13 && fsm_cnt_r < 36) || (fsm_cnt_r > 49 && fsm_cnt_r < 72)) && (conv_cnt6_r == 2 || conv_cnt6_r == 3 || conv_cnt6_r == 4 || conv_cnt6_r == 5)) begin
		conv_w = conv_add_3 + conv_multi[8];
	end
	else begin
		conv_w = conv_r;
	end
end

//CG
always @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		conv_cnt6_r <= 0;
		conv_flg_r <= 0;
	end
	else begin
		conv_cnt6_r <= conv_cnt6_w;
		conv_flg_r <= conv_flg_w;
	end
end

wire conv_clk;
wire conv_sleep;
assign conv_sleep = (~((fsm_cnt_r > 13 && fsm_cnt_r < 36) || (fsm_cnt_r > 49 && fsm_cnt_r < 72)) && (cg_en));
GATED_OR GATED_conv (
	.CLOCK(clk),
	.SLEEP_CTRL(conv_sleep),	
	.RST_N(rst_n),
	.CLOCK_GATED(conv_clk)
);

always @(posedge conv_clk, negedge rst_n) begin
	if(!rst_n) begin
		conv_r <= 0;
	end
	else begin
		conv_r <= conv_w;
	end
end

//====================Sub Desgin=====================//
//Quantization_1 + max pooling 
wire [7:0] quan_div_1;
reg [2:0] pool_cnt_r, pool_cnt_w;
reg [7:0] pool_r [0:1];
reg [7:0] pool_w [0:1];
reg pool_flg_r, pool_flg_w;

//Quantization_1
assign quan_div_1 = conv_r / 2295;

//max pooling 
always @(*) begin
	if(conv_flg_r) begin
		pool_cnt_w = pool_cnt_r + 1;
	end
	else begin
		pool_cnt_w = pool_cnt_r;
	end
end

always @(*) begin
	for(i=0; i<2; i=i+1) pool_w[i] = pool_r[i];
	if((fsm_cnt_r > 14 && fsm_cnt_r < 38) || (fsm_cnt_r > 50 && fsm_cnt_r < 74)) begin
		case(pool_cnt_r)
			0: begin
				if(pool_flg_r == 0)  begin
					pool_w[0] = quan_div_1;
				end
			end 
			2: pool_w[1] = quan_div_1;
			1, 4, 5: begin
				if(conv_flg_r && (quan_div_1 > pool_r[0])) begin
					pool_w[0] = quan_div_1;
				end
			end
			3, 6, 7: begin
				if(quan_div_1 > pool_r[1]) begin
					pool_w[1] = quan_div_1;
				end
			end
		endcase
	end
end

always @(*) begin
	if(pool_cnt_r == 5 || pool_cnt_r == 6 || pool_cnt_r == 7 || (pool_cnt_r == 0 && (conv_cnt6_r == 1 || fsm_cnt_r == 73))) begin
		pool_flg_w = 1;
	end
	else begin
		pool_flg_w = 0;
	end
end

//CG
wire pool_cnt_clk;
wire pool_cnt_sleep;
assign pool_cnt_sleep = (~(conv_flg_r) && (cg_en));
GATED_OR GATED_pool_cnt (
	.CLOCK(clk),
	.SLEEP_CTRL(pool_cnt_sleep),	
	.RST_N(rst_n),
	.CLOCK_GATED(pool_cnt_clk)
);

always @(posedge pool_cnt_clk, negedge rst_n) begin
	if(!rst_n) begin
		pool_cnt_r <= 0;
	end
	else begin
		pool_cnt_r <= pool_cnt_w;
	end
end

wire pool_clk;
wire pool_sleep;
assign pool_sleep = (~((fsm_cnt_r > 14 && fsm_cnt_r < 38) || (fsm_cnt_r > 50 && fsm_cnt_r < 74)) && (cg_en));
GATED_OR GATED_pool (
	.CLOCK(clk),
	.SLEEP_CTRL(pool_sleep),	
	.RST_N(rst_n),
	.CLOCK_GATED(pool_clk)
);

always @(posedge pool_clk, negedge rst_n) begin
	if(!rst_n) begin
		for(i=0; i<2; i=i+1) pool_r[i] <= 0;
	end
	else begin
		for(i=0; i<2; i=i+1) pool_r[i] <= pool_w[i];
	end
end

always @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		pool_flg_r <= 0;
	end
	else begin
		pool_flg_r <= pool_flg_w;
	end
end

//FC + Quantization_2 + L1 Distance
//FC
reg [2:0] fc_cnt_r, fc_cnt_w;
reg [7:0] fc_multi_in1, fc_multi_in2;
wire [15:0] fc_add_in1;
reg [15:0] fc_add_in2;
wire [16:0] fc_add;
reg [16:0] fc_tmp_r [0:1];
reg [16:0] fc_tmp_w [0:1];

always @(*) begin
	if(((fsm_cnt_r > 15 && fsm_cnt_r < 39) || fsm_cnt_r > 58) && pool_flg_r) begin
		fc_cnt_w = fc_cnt_r + 1;
	end
	else begin
		fc_cnt_w = fc_cnt_r;
	end
end

always @(*) begin
	case(fc_cnt_r)
		0, 1, 4, 5: fc_multi_in1 = pool_r[0];
		2, 3, 6, 7: fc_multi_in1 = pool_r[1];
	endcase
end

always @(*) begin
	case(fc_cnt_r)
		0, 4: fc_multi_in2 = weight_r[0];
		1, 5: fc_multi_in2 = weight_r[1];
		2, 6: fc_multi_in2 = weight_r[2];
		3, 7: fc_multi_in2 = weight_r[3];
	endcase
end

assign fc_add_in1 = fc_multi_in1 * fc_multi_in2;

always @(*) begin
	case(fc_cnt_r)
		0, 1, 4, 5: fc_add_in2 = 0;
		2, 6: fc_add_in2 = fc_tmp_r[0];
		3, 7: fc_add_in2 = fc_tmp_r[1];
	endcase
end
assign fc_add = fc_add_in1 + fc_add_in2;

always @(*) begin
	for(i=0; i<2; i=i+1) fc_tmp_w[i] = fc_tmp_r[i];
	case(fc_cnt_r)
		0, 2, 4, 6: fc_tmp_w[0] = fc_add;
		1, 3, 5, 7: fc_tmp_w[1] = fc_add;
	endcase
end

always @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		fc_cnt_r <= 0;
		for(i=0; i<2; i=i+1) fc_tmp_r[i] <= 0;
	end
	else begin
		fc_cnt_r <= fc_cnt_w;
		for(i=0; i<2; i=i+1) fc_tmp_r[i] <= fc_tmp_w[i];
	end
end

//Quantization_2
wire [7:0] quan_div_2;
reg [1:0] quan2_cnt_r, quan2_cnt_w;
reg [7:0] sub_1_r [0:3];
reg [7:0] sub_1_w [0:3];

assign quan_div_2 = fc_add / 510;

always @(*) begin
	case(fc_cnt_r)
		2, 3, 6, 7: quan2_cnt_w = quan2_cnt_r + 1;
		0, 1, 4, 5: quan2_cnt_w = quan2_cnt_r;
	endcase
end

always @(*) begin
	for(i=0; i<4; i=i+1) sub_1_w[i] = sub_1_r[i];
	if(fsm_cnt_r < 39) begin
		sub_1_w[quan2_cnt_r] = quan_div_2;
	end
end

always @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		quan2_cnt_r <= 0;
		for(i=0; i<4; i=i+1) sub_1_r[i] <= 0;
	end
	else begin
		quan2_cnt_r <= quan2_cnt_w;
		for(i=0; i<4; i=i+1) sub_1_r[i] <= sub_1_w[i];
	end
end

//L1 Distance
reg [7:0] dist_cmp_in1, dist_cmp_in2;
reg [7:0] dist_sub_in1, dist_sub_in2;
wire [7:0] dist_sub;
wire [9:0] dist_add;
reg [9:0] dist_tmp_r, dist_tmp_w;

always @(*) begin
	case(fc_cnt_r)
		2: dist_cmp_in1 = sub_1_r[0];
		3: dist_cmp_in1 = sub_1_r[1];
		6: dist_cmp_in1 = sub_1_r[2];
		7: dist_cmp_in1 = sub_1_r[3];
		default: dist_cmp_in1 = sub_1_r[0];
	endcase
end

always @(*) begin
	dist_cmp_in2 = quan_div_2;
end

always @(*) begin
	if(dist_cmp_in1 > dist_cmp_in2) begin
		dist_sub_in1 = dist_cmp_in1;
		dist_sub_in2 = dist_cmp_in2;
	end
	else begin
		dist_sub_in1 = dist_cmp_in2;
		dist_sub_in2 = dist_cmp_in1;
	end
end

assign dist_sub = dist_sub_in1 - dist_sub_in2;
assign dist_add = dist_sub + dist_tmp_r;

always @(*) begin
	case(fc_cnt_r)
		7: dist_tmp_w = 0;
		2, 3, 6: dist_tmp_w = dist_add;
		default: dist_tmp_w = dist_tmp_r;
	endcase
end

always @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		dist_tmp_r <= 0;
	end
	else begin
		dist_tmp_r <= dist_tmp_w;
	end
end

//======================output=======================//
reg [9:0] act_tmp;
reg out_valid_w;
reg [9:0] out_data_w;

//Relu
always @(*) begin
	if(dist_add < 16) begin
		act_tmp = 0;
	end
	else begin
		act_tmp = dist_add;
	end
end

always @(*) begin
	if(fsm_cnt_r == 74) begin
		out_valid_w = 1;
		out_data_w = act_tmp;
	end
	else begin
		out_valid_w = 0;
		out_data_w = 0;
	end
end

wire out_clk;
wire out_sleep;
assign out_sleep = (~(fsm_cnt_r == 74 || fsm_cnt_r == 75) && (cg_en));
GATED_OR GATED_out (
	.CLOCK(clk),
	.SLEEP_CTRL(out_sleep),	
	.RST_N(rst_n),
	.CLOCK_GATED(out_clk)
);

always @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
		out_data <= 0;
	end
	else begin
		out_valid <= out_valid_w;
		out_data <= out_data_w;
	end
end

endmodule