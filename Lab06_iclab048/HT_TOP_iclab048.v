//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : HT_TOP.v
//   	Module Name : HT_TOP
//      V2_V2_1stdemo
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "SORT_IP.v"
//synopsys translate_on

module HT_TOP(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_weight, 
	out_mode,
    // Output signals
    out_valid, 
	out_code
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid, out_mode;
input [2:0] in_weight;

output reg out_valid, out_code;

// ===============================================================
// Reg & Wire Declaration
// ===============================================================
integer i;
reg [3:0] weight_r [0:7];
reg [3:0] weight_w [0:7];
reg [3:0] char_r [0:7];
reg [3:0] char_w [0:7];
reg out_mode_r, out_mode_w;
reg [2:0] in_char_cal;
reg [5:0] counter_r, counter_w;
reg [2:0] f_counter_r, f_counter_w;
reg [2:0] o_counter_r, o_counter_w;
reg [2:0] out_pr_r, out_pr_w;
// ===============================================================
// FSM & Store Weight
// ===============================================================
always @(*) begin
    if(f_counter_r == 4 && out_pr_w == 7) begin
        counter_w = 0;
    end
    else if(in_valid || counter_r != 0) begin
        counter_w = counter_r + 1;
    end
    else begin
        counter_w = 0;
    end
end

always @(*) begin
    if(counter_r == 0 && in_valid) begin
        out_mode_w = out_mode;
    end
    else begin
        out_mode_w = out_mode_r;
    end
end
always @(*) begin
    case(counter_r[2:0])
        0: in_char_cal = 7;
        1: in_char_cal = 6;
        2: in_char_cal = 5;
        3: in_char_cal = 4;
        4: in_char_cal = 3;
        5: in_char_cal = 2;
        6: in_char_cal = 1;
        7: in_char_cal = 0;
        default:in_char_cal = 7;
    endcase
end

reg [2:0] in_sort_char [0:7];
reg [2:0] in_sort_wei [0:7];
//sort input & weight
always @(*) begin
    for(i=1; i<8; i=i+1) in_sort_char[i] = char_r[i];
    in_sort_char[0] = in_char_cal;

    if(in_weight > weight_r[1] || (in_weight == weight_r[1] && in_char_cal > char_r[1])) begin
        in_sort_char[7] = char_r[7];
        in_sort_char[6] = char_r[6];
        in_sort_char[5] = char_r[5];
        in_sort_char[4] = char_r[4];
        in_sort_char[3] = char_r[3];
        in_sort_char[2] = char_r[2];
        in_sort_char[1] = in_char_cal;
        in_sort_char[0] = char_r[1];
    end
    if(in_weight > weight_r[2] || (in_weight == weight_r[2] && in_char_cal > char_r[2])) begin
        in_sort_char[7] = char_r[7];
        in_sort_char[6] = char_r[6];
        in_sort_char[5] = char_r[5];
        in_sort_char[4] = char_r[4];
        in_sort_char[3] = char_r[3];
        in_sort_char[2] = in_char_cal;
        in_sort_char[1] = char_r[2];
        in_sort_char[0] = char_r[1];
    end
    if(in_weight > weight_r[3] || (in_weight == weight_r[3] && in_char_cal > char_r[3])) begin
        in_sort_char[7] = char_r[7];
        in_sort_char[6] = char_r[6];
        in_sort_char[5] = char_r[5];
        in_sort_char[4] = char_r[4];
        in_sort_char[3] = in_char_cal;
        in_sort_char[2] = char_r[3];
        in_sort_char[1] = char_r[2];
        in_sort_char[0] = char_r[1];
    end
    if(in_weight > weight_r[4] || (in_weight == weight_r[4] && in_char_cal > char_r[4])) begin
        in_sort_char[7] = char_r[7];
        in_sort_char[6] = char_r[6];
        in_sort_char[5] = char_r[5];
        in_sort_char[4] = in_char_cal;
        in_sort_char[3] = char_r[4];
        in_sort_char[2] = char_r[3];
        in_sort_char[1] = char_r[2];
        in_sort_char[0] = char_r[1];
    end
    if(in_weight > weight_r[5] || (in_weight == weight_r[5] && in_char_cal > char_r[5])) begin
        in_sort_char[7] = char_r[7];
        in_sort_char[6] = char_r[6];
        in_sort_char[5] = in_char_cal;
        in_sort_char[4] = char_r[5];
        in_sort_char[3] = char_r[4];
        in_sort_char[2] = char_r[3];
        in_sort_char[1] = char_r[2];
        in_sort_char[0] = char_r[1];
    end
    if(in_weight > weight_r[6] || (in_weight == weight_r[6] && in_char_cal > char_r[6])) begin
        in_sort_char[7] = char_r[7];
        in_sort_char[6] = in_char_cal;
        in_sort_char[5] = char_r[6];
        in_sort_char[4] = char_r[5];
        in_sort_char[3] = char_r[4];
        in_sort_char[2] = char_r[3];
        in_sort_char[1] = char_r[2];
        in_sort_char[0] = char_r[1];
    end
    if(in_weight > weight_r[7] || (in_weight == weight_r[7] && in_char_cal > char_r[7])) begin
        in_sort_char[7] = in_char_cal;
        in_sort_char[6] = char_r[7];
        in_sort_char[5] = char_r[6];
        in_sort_char[4] = char_r[5];
        in_sort_char[3] = char_r[4];
        in_sort_char[2] = char_r[3];
        in_sort_char[1] = char_r[2];
        in_sort_char[0] = char_r[1];
    end
end

always @(*) begin
    for(i=1; i<8; i=i+1) in_sort_wei[i] = weight_r[i];
    in_sort_wei[0] = in_weight;

    if(in_weight > weight_r[1]) begin
        in_sort_wei[7] = weight_r[7];
        in_sort_wei[6] = weight_r[6];
        in_sort_wei[5] = weight_r[5];
        in_sort_wei[4] = weight_r[4];
        in_sort_wei[3] = weight_r[3];
        in_sort_wei[2] = weight_r[2];
        in_sort_wei[1] = in_weight;
        in_sort_wei[0] = weight_r[1];
    end
    if(in_weight > weight_r[2]) begin
        in_sort_wei[7] = weight_r[7];
        in_sort_wei[6] = weight_r[6];
        in_sort_wei[5] = weight_r[5];
        in_sort_wei[4] = weight_r[4];
        in_sort_wei[3] = weight_r[3];
        in_sort_wei[2] = in_weight;
        in_sort_wei[1] = weight_r[2];
        in_sort_wei[0] = weight_r[1];
    end
    if(in_weight > weight_r[3]) begin
        in_sort_wei[7] = weight_r[7];
        in_sort_wei[6] = weight_r[6];
        in_sort_wei[5] = weight_r[5];
        in_sort_wei[4] = weight_r[4];
        in_sort_wei[3] = in_weight;
        in_sort_wei[2] = weight_r[3];
        in_sort_wei[1] = weight_r[2];
        in_sort_wei[0] = weight_r[1];
    end
    if(in_weight > weight_r[4]) begin
        in_sort_wei[7] = weight_r[7];
        in_sort_wei[6] = weight_r[6];
        in_sort_wei[5] = weight_r[5];
        in_sort_wei[4] = in_weight;
        in_sort_wei[3] = weight_r[4];
        in_sort_wei[2] = weight_r[3];
        in_sort_wei[1] = weight_r[2];
        in_sort_wei[0] = weight_r[1];
    end
    if(in_weight > weight_r[5]) begin
        in_sort_wei[7] = weight_r[7];
        in_sort_wei[6] = weight_r[6];
        in_sort_wei[5] = in_weight;
        in_sort_wei[4] = weight_r[5];
        in_sort_wei[3] = weight_r[4];
        in_sort_wei[2] = weight_r[3];
        in_sort_wei[1] = weight_r[2];
        in_sort_wei[0] = weight_r[1];
    end
    if(in_weight > weight_r[6]) begin
        in_sort_wei[7] = weight_r[7];
        in_sort_wei[6] = in_weight;
        in_sort_wei[5] = weight_r[6];
        in_sort_wei[4] = weight_r[5];
        in_sort_wei[3] = weight_r[4];
        in_sort_wei[2] = weight_r[3];
        in_sort_wei[1] = weight_r[2];
        in_sort_wei[0] = weight_r[1];
    end
    if(in_weight > weight_r[7]) begin
        in_sort_wei[7] = in_weight;
        in_sort_wei[6] = weight_r[7];
        in_sort_wei[5] = weight_r[6];
        in_sort_wei[4] = weight_r[5];
        in_sort_wei[3] = weight_r[4];
        in_sort_wei[2] = weight_r[3];
        in_sort_wei[1] = weight_r[2];
        in_sort_wei[0] = weight_r[1];
    end
end

wire [3:0] node1_char;
wire [4:0] node1_wei;
reg [3:0] node1_o_char [0:6];
reg [4:0] node1_o_wei [0:6];

assign node1_char = 4'd8;
assign node1_wei = in_sort_wei[0] + in_sort_wei[1];
//sort7
always @(*) begin 
    node1_o_char[6] = in_sort_char[7];
    node1_o_char[5] = in_sort_char[6];
    node1_o_char[4] = in_sort_char[5];
    node1_o_char[3] = in_sort_char[4];
    node1_o_char[2] = in_sort_char[3];
    node1_o_char[1] = in_sort_char[2];
    node1_o_char[0] = node1_char;

    if(node1_wei > in_sort_wei[2]) begin 
        node1_o_char[6] = in_sort_char[7];
        node1_o_char[5] = in_sort_char[6];
        node1_o_char[4] = in_sort_char[5];
        node1_o_char[3] = in_sort_char[4];
        node1_o_char[2] = in_sort_char[3];
        node1_o_char[1] = node1_char;
        node1_o_char[0] = in_sort_char[2];
    end
    if(node1_wei > in_sort_wei[3]) begin
        node1_o_char[6] = in_sort_char[7];
        node1_o_char[5] = in_sort_char[6];
        node1_o_char[4] = in_sort_char[5];
        node1_o_char[3] = in_sort_char[4];
        node1_o_char[2] = node1_char;
        node1_o_char[1] = in_sort_char[3];
        node1_o_char[0] = in_sort_char[2];
    end
    if(node1_wei > in_sort_wei[4]) begin
        node1_o_char[6] = in_sort_char[7];
        node1_o_char[5] = in_sort_char[6];
        node1_o_char[4] = in_sort_char[5];
        node1_o_char[3] = node1_char;
        node1_o_char[2] = in_sort_char[4];
        node1_o_char[1] = in_sort_char[3];
        node1_o_char[0] = in_sort_char[2];
    end
    if(node1_wei > in_sort_wei[5]) begin
        node1_o_char[6] = in_sort_char[7];
        node1_o_char[5] = in_sort_char[6];
        node1_o_char[4] = node1_char;
        node1_o_char[3] = in_sort_char[5];
        node1_o_char[2] = in_sort_char[4];
        node1_o_char[1] = in_sort_char[3];
        node1_o_char[0] = in_sort_char[2];
    end
    if(node1_wei > in_sort_wei[6]) begin
        node1_o_char[6] = in_sort_char[7];
        node1_o_char[5] = node1_char;
        node1_o_char[4] = in_sort_char[6];
        node1_o_char[3] = in_sort_char[5];
        node1_o_char[2] = in_sort_char[4];
        node1_o_char[1] = in_sort_char[3];
        node1_o_char[0] = in_sort_char[2];
    end
    if(node1_wei > in_sort_wei[7]) begin
        node1_o_char[6] = node1_char;
        node1_o_char[5] = in_sort_char[7];
        node1_o_char[4] = in_sort_char[6];
        node1_o_char[3] = in_sort_char[5];
        node1_o_char[2] = in_sort_char[4];
        node1_o_char[1] = in_sort_char[3];
        node1_o_char[0] = in_sort_char[2];
    end
end
//node 2 is B:node1_o_char[1] S:node1_o_char[0]
always @(*) begin 
    node1_o_wei[6] = in_sort_wei[7];
    node1_o_wei[5] = in_sort_wei[6];
    node1_o_wei[4] = in_sort_wei[5];
    node1_o_wei[3] = in_sort_wei[4];
    node1_o_wei[2] = in_sort_wei[3];
    node1_o_wei[1] = in_sort_wei[2];
    node1_o_wei[0] = node1_wei;

    if(node1_wei > in_sort_wei[2]) begin 
        node1_o_wei[6] = in_sort_wei[7];
        node1_o_wei[5] = in_sort_wei[6];
        node1_o_wei[4] = in_sort_wei[5];
        node1_o_wei[3] = in_sort_wei[4];
        node1_o_wei[2] = in_sort_wei[3];
        node1_o_wei[1] = node1_wei;
        node1_o_wei[0] = in_sort_wei[2];
    end
    if(node1_wei > in_sort_wei[3]) begin
        node1_o_wei[6] = in_sort_wei[7];
        node1_o_wei[5] = in_sort_wei[6];
        node1_o_wei[4] = in_sort_wei[5];
        node1_o_wei[3] = in_sort_wei[4];
        node1_o_wei[2] = node1_wei;
        node1_o_wei[1] = in_sort_wei[3];
        node1_o_wei[0] = in_sort_wei[2];
    end
    if(node1_wei > in_sort_wei[4]) begin
        node1_o_wei[6] = in_sort_wei[7];
        node1_o_wei[5] = in_sort_wei[6];
        node1_o_wei[4] = in_sort_wei[5];
        node1_o_wei[3] = node1_wei;
        node1_o_wei[2] = in_sort_wei[4];
        node1_o_wei[1] = in_sort_wei[3];
        node1_o_wei[0] = in_sort_wei[2];
    end
    if(node1_wei > in_sort_wei[5]) begin
        node1_o_wei[6] = in_sort_wei[7];
        node1_o_wei[5] = in_sort_wei[6];
        node1_o_wei[4] = node1_wei;
        node1_o_wei[3] = in_sort_wei[5];
        node1_o_wei[2] = in_sort_wei[4];
        node1_o_wei[1] = in_sort_wei[3];
        node1_o_wei[0] = in_sort_wei[2];
    end
    if(node1_wei > in_sort_wei[6]) begin
        node1_o_wei[6] = in_sort_wei[7];
        node1_o_wei[5] = node1_wei;
        node1_o_wei[4] = in_sort_wei[6];
        node1_o_wei[3] = in_sort_wei[5];
        node1_o_wei[2] = in_sort_wei[4];
        node1_o_wei[1] = in_sort_wei[3];
        node1_o_wei[0] = in_sort_wei[2];
    end
    if(node1_wei > in_sort_wei[7]) begin
        node1_o_wei[6] = node1_wei;
        node1_o_wei[5] = in_sort_wei[7];
        node1_o_wei[4] = in_sort_wei[6];
        node1_o_wei[3] = in_sort_wei[5];
        node1_o_wei[2] = in_sort_wei[4];
        node1_o_wei[1] = in_sort_wei[3];
        node1_o_wei[0] = in_sort_wei[2];
    end
end

//char_r & weight_r
always @(*) begin
    if(counter_r == 0 && !in_valid) begin
        for(i=0; i<8; i=i+1) char_w[i] = 0;
    end
    else if(counter_r < 7) begin
        for(i=0; i<8; i=i+1) char_w[i] = in_sort_char[i]; //first node is B:char_r[1] S:char_r[0] (3bit)
    end
    else if(counter_r == 7) begin
        char_w[7] = node1_o_char[6];
        char_w[6] = node1_o_char[5];
        char_w[5] = node1_o_char[4];
        char_w[4] = node1_o_char[3];
        char_w[3] = node1_o_char[2];
        char_w[2] = node1_o_char[1];
        char_w[1] = node1_o_char[0];
        char_w[0] = 0;
    end
    else begin
        for(i=0; i<8; i=i+1) char_w[i] = char_r[i];
    end
end

always @(*) begin
    if(counter_r == 0 && !in_valid) begin
        for(i=0; i<8; i=i+1) weight_w[i] = 0;
    end
    else if(counter_r < 7) begin
        for(i=0; i<8; i=i+1) weight_w[i] = in_sort_wei[i];
    end
    else if(counter_r == 7) begin
        weight_w[7] = node1_o_wei[6];
        weight_w[6] = node1_o_wei[5];
        weight_w[5] = node1_o_wei[4];
        weight_w[4] = node1_o_wei[3];
        weight_w[3] = node1_o_wei[2];
        weight_w[2] = node1_o_wei[1];
        weight_w[1] = node1_o_wei[0];
        weight_w[0] = 0;
    end
    else begin
        for(i=0; i<8; i=i+1) weight_w[i] = weight_r[i];
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<8; i=i+1) weight_r[i] <= 0;
        for(i=0; i<8; i=i+1) char_r[i] <= 0;
        out_mode_r <= 0;
        counter_r <= 0;
    end
    else begin
        for(i=0; i<8; i=i+1) weight_r[i] <= weight_w[i];
        for(i=0; i<8; i=i+1) char_r[i] <= char_w[i];
        out_mode_r <= out_mode_w;
        counter_r <= counter_w;
    end
end

// ===============================================================
// Huffman Tree
// ===============================================================
wire [3:0] node2_char;
wire [4:0] node2_wei;
reg [3:0] node2_o_char [0:5];
reg [4:0] node2_o_wei [0:5];

//node2
assign node2_char = 4'd9;
assign node2_wei = weight_r[2] + weight_r[1];
//sort6
always @(*) begin 
    node2_o_char[5] = char_r[7];
    node2_o_char[4] = char_r[6];
    node2_o_char[3] = char_r[5];
    node2_o_char[2] = char_r[4];
    node2_o_char[1] = char_r[3];
    node2_o_char[0] = node2_char;

    if(node2_wei > weight_r[3]) begin 
        node2_o_char[5] = char_r[7];
        node2_o_char[4] = char_r[6];
        node2_o_char[3] = char_r[5];
        node2_o_char[2] = char_r[4];
        node2_o_char[1] = node2_char;
        node2_o_char[0] = char_r[3];
    end
    if(node2_wei > weight_r[4]) begin
        node2_o_char[5] = char_r[7];
        node2_o_char[4] = char_r[6];
        node2_o_char[3] = char_r[5];
        node2_o_char[2] = node2_char;
        node2_o_char[1] = char_r[4];
        node2_o_char[0] = char_r[3];
    end
    if(node2_wei > weight_r[5]) begin
        node2_o_char[5] = char_r[7];
        node2_o_char[4] = char_r[6];
        node2_o_char[3] = node2_char;
        node2_o_char[2] = char_r[5];
        node2_o_char[1] = char_r[4];
        node2_o_char[0] = char_r[3];
    end
    if(node2_wei > weight_r[6]) begin
        node2_o_char[5] = char_r[7];
        node2_o_char[4] = node2_char;
        node2_o_char[3] = char_r[6];
        node2_o_char[2] = char_r[5];
        node2_o_char[1] = char_r[4];
        node2_o_char[0] = char_r[3];
    end
    if(node2_wei > weight_r[7]) begin
        node2_o_char[5] = node2_char;
        node2_o_char[4] = char_r[7];
        node2_o_char[3] = char_r[6];
        node2_o_char[2] = char_r[5];
        node2_o_char[1] = char_r[4];
        node2_o_char[0] = char_r[3];
    end
end
//node 3 is B:node2_o_char[1] S:node2_o_char[0]
always @(*) begin 
    node2_o_wei[5] = weight_r[7];
    node2_o_wei[4] = weight_r[6];
    node2_o_wei[3] = weight_r[5];
    node2_o_wei[2] = weight_r[4];
    node2_o_wei[1] = weight_r[3];
    node2_o_wei[0] = node2_wei;

    if(node2_wei > weight_r[3]) begin 
        node2_o_wei[5] = weight_r[7];
        node2_o_wei[4] = weight_r[6];
        node2_o_wei[3] = weight_r[5];
        node2_o_wei[2] = weight_r[4];
        node2_o_wei[1] = node2_wei;
        node2_o_wei[0] = weight_r[3];
    end
    if(node2_wei > weight_r[4]) begin
        node2_o_wei[5] = weight_r[7];
        node2_o_wei[4] = weight_r[6];
        node2_o_wei[3] = weight_r[5];
        node2_o_wei[2] = node2_wei;
        node2_o_wei[1] = weight_r[4];
        node2_o_wei[0] = weight_r[3];
    end
    if(node2_wei > weight_r[5]) begin
        node2_o_wei[5] = weight_r[7];
        node2_o_wei[4] = weight_r[6];
        node2_o_wei[3] = node2_wei;
        node2_o_wei[2] = weight_r[5];
        node2_o_wei[1] = weight_r[4];
        node2_o_wei[0] = weight_r[3];
    end
    if(node2_wei > weight_r[6]) begin
        node2_o_wei[5] = weight_r[7];
        node2_o_wei[4] = node2_wei;
        node2_o_wei[3] = weight_r[6];
        node2_o_wei[2] = weight_r[5];
        node2_o_wei[1] = weight_r[4];
        node2_o_wei[0] = weight_r[3];
    end
    if(node2_wei > weight_r[7]) begin
        node2_o_wei[5] = node2_wei;
        node2_o_wei[4] = weight_r[7];
        node2_o_wei[3] = weight_r[6];
        node2_o_wei[2] = weight_r[5];
        node2_o_wei[1] = weight_r[4];
        node2_o_wei[0] = weight_r[3];
    end
end

wire [3:0] node3_char;
wire [4:0] node3_wei;
reg [3:0] node3_o_char [0:4];
reg [4:0] node3_o_wei [0:4];
//node3
assign node3_char = 4'd10;
assign node3_wei = node2_o_wei[1] + node2_o_wei[0];
//sort5
always @(*) begin 
    node3_o_char[4] = node2_o_char[5];
    node3_o_char[3] = node2_o_char[4];
    node3_o_char[2] = node2_o_char[3];
    node3_o_char[1] = node2_o_char[2];
    node3_o_char[0] = node3_char;

    if(node3_wei > node2_o_wei[2]) begin
        node3_o_char[4] = node2_o_char[5];
        node3_o_char[3] = node2_o_char[4];
        node3_o_char[2] = node2_o_char[3];
        node3_o_char[1] = node3_char;
        node3_o_char[0] = node2_o_char[2];
    end
    if(node3_wei > node2_o_wei[3]) begin
        node3_o_char[4] = node2_o_char[5];
        node3_o_char[3] = node2_o_char[4];
        node3_o_char[2] = node3_char;
        node3_o_char[1] = node2_o_char[3];
        node3_o_char[0] = node2_o_char[2];
    end
    if(node3_wei > node2_o_wei[4]) begin
        node3_o_char[4] = node2_o_char[5];
        node3_o_char[3] = node3_char;
        node3_o_char[2] = node2_o_char[4];
        node3_o_char[1] = node2_o_char[3];
        node3_o_char[0] = node2_o_char[2];
    end
    if(node3_wei > node2_o_wei[5]) begin
        node3_o_char[4] = node3_char;
        node3_o_char[3] = node2_o_char[5];
        node3_o_char[2] = node2_o_char[4];
        node3_o_char[1] = node2_o_char[3];
        node3_o_char[0] = node2_o_char[2];
    end
end
//node 4 is B:node3_o_char[1] S:node3_o_char[0]
always @(*) begin 
    node3_o_wei[4] = node2_o_wei[5];
    node3_o_wei[3] = node2_o_wei[4];
    node3_o_wei[2] = node2_o_wei[3];
    node3_o_wei[1] = node2_o_wei[2];
    node3_o_wei[0] = node3_wei;

    if(node3_wei > node2_o_wei[2]) begin
        node3_o_wei[4] = node2_o_wei[5];
        node3_o_wei[3] = node2_o_wei[4];
        node3_o_wei[2] = node2_o_wei[3];
        node3_o_wei[1] = node3_wei;
        node3_o_wei[0] = node2_o_wei[2];
    end
    if(node3_wei > node2_o_wei[3]) begin
        node3_o_wei[4] = node2_o_wei[5];
        node3_o_wei[3] = node2_o_wei[4];
        node3_o_wei[2] = node3_wei;
        node3_o_wei[1] = node2_o_wei[3];
        node3_o_wei[0] = node2_o_wei[2];
    end
    if(node3_wei > node2_o_wei[4]) begin
        node3_o_wei[4] = node2_o_wei[5];
        node3_o_wei[3] = node3_wei;
        node3_o_wei[2] = node2_o_wei[4];
        node3_o_wei[1] = node2_o_wei[3];
        node3_o_wei[0] = node2_o_wei[2];
    end
    if(node3_wei > node2_o_wei[5]) begin
        node3_o_wei[4] = node3_wei;
        node3_o_wei[3] = node2_o_wei[5];
        node3_o_wei[2] = node2_o_wei[4];
        node3_o_wei[1] = node2_o_wei[3];
        node3_o_wei[0] = node2_o_wei[2];
    end
end

wire [3:0] node4_char;
wire [4:0] node4_wei;
reg [3:0] node4_o_char [0:3];
reg [4:0] node4_o_wei [0:3];
//node4
assign node4_char = 4'd11;
assign node4_wei = node3_o_wei[1] + node3_o_wei[0];
//sort4
always @(*) begin 
    node4_o_char[3] = node3_o_char[4];
    node4_o_char[2] = node3_o_char[3];
    node4_o_char[1] = node3_o_char[2];
    node4_o_char[0] = node4_char;

    if(node4_wei > node3_o_wei[2]) begin
        node4_o_char[3] = node3_o_char[4];
        node4_o_char[2] = node3_o_char[3];
        node4_o_char[1] = node4_char;
        node4_o_char[0] = node3_o_char[2];
    end
    if(node4_wei > node3_o_wei[3]) begin
        node4_o_char[3] = node3_o_char[4];
        node4_o_char[2] = node4_char;
        node4_o_char[1] = node3_o_char[3];
        node4_o_char[0] = node3_o_char[2];
    end
    if(node4_wei > node3_o_wei[4]) begin
        node4_o_char[3] = node4_char;
        node4_o_char[2] = node3_o_char[4];
        node4_o_char[1] = node3_o_char[3];
        node4_o_char[0] = node3_o_char[2];
    end
end
//node 5 is B:node4_o_char[1] S:node4_o_char[0]
always @(*) begin 
    node4_o_wei[3] = node3_o_wei[4];
    node4_o_wei[2] = node3_o_wei[3];
    node4_o_wei[1] = node3_o_wei[2];
    node4_o_wei[0] = node4_wei;

    if(node4_wei > node3_o_wei[2]) begin
        node4_o_wei[3] = node3_o_wei[4];
        node4_o_wei[2] = node3_o_wei[3];
        node4_o_wei[1] = node4_wei;
        node4_o_wei[0] = node3_o_wei[2];
    end
    if(node4_wei > node3_o_wei[3]) begin
        node4_o_wei[3] = node3_o_wei[4];
        node4_o_wei[2] = node4_wei;
        node4_o_wei[1] = node3_o_wei[3];
        node4_o_wei[0] = node3_o_wei[2];
    end
    if(node4_wei > node3_o_wei[4]) begin
        node4_o_wei[3] = node4_wei;
        node4_o_wei[2] = node3_o_wei[4];
        node4_o_wei[1] = node3_o_wei[3];
        node4_o_wei[0] = node3_o_wei[2];
    end
end

wire [3:0] node5_char;
wire [4:0] node5_wei;
reg [3:0] node5_o_char [0:2];
reg [4:0] node5_o_wei [0:2];
//node5
assign node5_char = 4'd12;
assign node5_wei = node4_o_wei[1] + node4_o_wei[0];
//sort3
always @(*) begin 
    node5_o_char[2] = node4_o_char[3];
    node5_o_char[1] = node4_o_char[2];
    node5_o_char[0] = node5_char;

    if(node5_wei > node4_o_wei[2]) begin
        node5_o_char[2] = node4_o_char[3];
        node5_o_char[1] = node5_char;
        node5_o_char[0] = node4_o_char[2];
    end
    if(node5_wei > node4_o_wei[3]) begin
        node5_o_char[2] = node5_char;
        node5_o_char[1] = node4_o_char[3];
        node5_o_char[0] = node4_o_char[2];
    end
end
//node 6 is B:node5_o_char[1] S:node5_o_char[0]
always @(*) begin 
    node5_o_wei[2] = node4_o_wei[3];
    node5_o_wei[1] = node4_o_wei[2];
    node5_o_wei[0] = node5_wei;

    if(node5_wei > node4_o_wei[2]) begin
        node5_o_wei[2] = node4_o_wei[3];
        node5_o_wei[1] = node5_wei;
        node5_o_wei[0] = node4_o_wei[2];
    end
    if(node5_wei > node4_o_wei[3]) begin
        node5_o_wei[2] = node5_wei;
        node5_o_wei[1] = node4_o_wei[3];
        node5_o_wei[0] = node4_o_wei[2];
    end
end

wire [3:0] node6_char;
wire [4:0] node6_wei;
reg [3:0] node6_o_char [0:1];
wire [11:0] in_character, out_character;
wire [14:0] in_wei_1;
//node6 - use IP
assign node6_char = 4'd13;
assign node6_wei = node5_o_wei[1] + node5_o_wei[0];

//Sort_ip - 3 input
assign in_character = {node5_o_char[2], node6_char, 4'd0};
assign in_wei_1 = {node5_o_wei[2], node6_wei, 5'd0};

SORT_IP #(.IP_WIDTH(3)) U_SORT_IP(.IN_character(in_character), .IN_weight(in_wei_1), .OUT_character(out_character)); 
assign node6_o_char[1] = out_character[11:8];
assign node6_o_char[0] = out_character[7:4];
//node 7 is B:node6_o_char[1] S:node6_o_char[0]
reg [3:0] Huff_r [0:13];
wire [3:0] Huff_w [0:13];
assign Huff_w[13] = node6_o_char[1];
assign Huff_w[12] = node6_o_char[0];
assign Huff_w[11] = node5_o_char[1];
assign Huff_w[10] = node5_o_char[0];

assign Huff_w[9] = node4_o_char[1];
assign Huff_w[8] = node4_o_char[0];

assign Huff_w[7] = node3_o_char[1];
assign Huff_w[6] = node3_o_char[0];

assign Huff_w[5] = node2_o_char[1];
assign Huff_w[4] = node2_o_char[0];

assign Huff_w[3] = char_r[2];
assign Huff_w[2] = char_r[1];

assign Huff_w[1] = (counter_r == 7) ? in_sort_char[1] :  Huff_r[1];
assign Huff_w[0] = (counter_r == 7) ? in_sort_char[0] :  Huff_r[0];

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<14; i=i+1) Huff_r[i] <= 0;
    end
    else begin
        for(i=0; i<14; i=i+1) Huff_r[i] <= Huff_w[i];
    end
end
// ===============================================================
// Huffman Coding
// ===============================================================
reg [3:0] find_value;
reg [2:0] start_all, start_8, start_9;
reg [1:0] start_10, start_11;
reg start_12;
reg  o_data_0, o_data_1, o_data_2, o_data_3, o_data_4, o_data_5, o_data_6;
reg  o_flag_1, o_flag_2, o_flag_3, o_flag_4, o_flag_5, o_flag_6;
reg out_code_w, out_valid_w, out_code_tmp;

//find who
always @(*) begin
    if(out_mode_r == 0) begin//ilove -> 32104
        case(f_counter_r)
            0: find_value = 3;
            1: find_value = 2;
            2: find_value = 1;
            3: find_value = 0;
            4: find_value = 4;
            default: find_value = 3;
        endcase
    end
    else begin//iclab -> 35276
        case(f_counter_r)
            0: find_value = 3;
            1: find_value = 5;
            2: find_value = 2;
            3: find_value = 7;
            4: find_value = 6;
        default: find_value = 3;
    endcase
    end
end

//f_counter_r
always @(*) begin
    if(counter_r == 0) begin
        f_counter_w = 0;
    end
    else if(o_counter_r == 1) begin
        f_counter_w = f_counter_r + 1;
    end
    else if(o_flag_1 == 0 && o_flag_2 == 0 && o_flag_3 == 0 && o_flag_4 == 0 && o_flag_5 == 0 && o_flag_6 == 0 && o_counter_r == 0) begin
        f_counter_w = f_counter_r + 1;
    end
    else if(counter_r == 9 && o_flag_1 == 0 && o_flag_2 == 0 && o_flag_3 == 0 && o_flag_4 == 0 && o_flag_5 == 0 && o_flag_6 == 0) begin
        f_counter_w = f_counter_r + 1;
    end
    else begin
        f_counter_w = f_counter_r;
    end
end

//find where
always @(*) begin
    if(find_value == Huff_r[0] || find_value == Huff_r[2] || find_value == Huff_r[4] || find_value == Huff_r[6] || find_value == Huff_r[8] || find_value == Huff_r[10] || find_value == Huff_r[12]) begin
        o_data_0 = 1;
    end
    else begin
        o_data_0 = 0;
    end
end
always @(*) begin
    start_all = 0; //in node 7
    if(find_value == Huff_r[0] || find_value == Huff_r[1]) begin //find 8
        start_all = 1;
    end
    if(find_value == Huff_r[2] || find_value == Huff_r[3]) begin //find 9
        start_all = 2;
    end
    if(find_value == Huff_r[4] || find_value == Huff_r[5]) begin //find 10
        start_all = 3;
    end
    if(find_value == Huff_r[6] || find_value == Huff_r[7]) begin //find 11
        start_all = 4;
    end
    if(find_value == Huff_r[8] || find_value == Huff_r[9]) begin //find 12
        start_all = 5;
    end
    if(find_value == Huff_r[10] || find_value == Huff_r[11]) begin //find 13
        start_all = 6;
    end
end
//find 8
always @(*) begin
    if(Huff_r[2] == 8 || Huff_r[4] == 8 || Huff_r[6] == 8 || Huff_r[8] == 8 || Huff_r[10] == 8 || Huff_r[12] == 8) begin
        o_data_1 = 1;
    end
    else begin
        o_data_1 = 0;
    end
end

always @(*) begin
    if(start_all == 1) begin
        o_flag_1 = 1;
    end
    else begin
        o_flag_1 = 0;
    end
end

always @(*) begin
    start_8 = 0;
    if(o_flag_1 && (Huff_r[2] == 8 || Huff_r[3] == 8)) begin //find 9
        start_8 = 1;
    end
    if(o_flag_1 && (Huff_r[4] == 8 || Huff_r[5] == 8)) begin //find 10
        start_8 = 2;
    end
    if(o_flag_1 && (Huff_r[6] == 8 || Huff_r[7] == 8)) begin //find 11
        start_8 = 3;
    end
    if(o_flag_1 && (Huff_r[8] == 8 || Huff_r[9] == 8)) begin //find 12
        start_8 = 4;
    end
    if(o_flag_1 && (Huff_r[10] == 8 || Huff_r[11] == 8)) begin //find 13
        start_8 = 5;
    end
end

//find 9
always @(*) begin
    if(Huff_r[4] == 9 || Huff_r[6] == 9 || Huff_r[8] == 9 || Huff_r[10] == 9 || Huff_r[12] == 9) begin
        o_data_2 = 1;
    end
    else begin
        o_data_2 = 0;
    end
end

always @(*) begin
    if(start_all == 2 || start_8 == 1) begin
        o_flag_2 = 1;
    end
    else begin
        o_flag_2 = 0;
    end
end

always @(*) begin
    start_9 = 0;
    if(o_flag_2 && (Huff_r[4] == 9 || Huff_r[5] == 9)) begin //find 10
        start_9 = 1;
    end
    if(o_flag_2 && (Huff_r[6] == 9 || Huff_r[7] == 9)) begin //find 11
        start_9 = 2;
    end
    if(o_flag_2 && (Huff_r[8] == 9 || Huff_r[9] == 9)) begin //find 12
        start_9 = 3;
    end
    if(o_flag_2 && (Huff_r[10] == 9 || Huff_r[11] == 9)) begin //find 13
        start_9 = 4;
    end
end

//find 10
always @(*) begin
    if(Huff_r[6] == 10 || Huff_r[8] == 10 || Huff_r[10] == 10 || Huff_r[12] == 10) begin
        o_data_3 = 1;
    end
    else begin
        o_data_3 = 0;
    end
end

always @(*) begin
    if(start_all == 3 || start_8 == 2 || start_9 == 1) begin
        o_flag_3 = 1;
    end
    else begin
        o_flag_3 = 0;
    end
end

always @(*) begin
    start_10 = 0;
    if(o_flag_3 && (Huff_r[6] == 10 || Huff_r[7] == 10)) begin //find 11
        start_10 = 1;
    end
    if(o_flag_3 && (Huff_r[8] == 10 || Huff_r[9] == 10)) begin //find 12
        start_10 = 2;
    end
    if(o_flag_3 && (Huff_r[10] == 10 || Huff_r[11] == 10)) begin //find 13
        start_10 = 3;
    end
end

//find 11
always @(*) begin
    if(Huff_r[8] == 11 || Huff_r[10] == 11|| Huff_r[12] == 11) begin
        o_data_4 = 1;
    end
    else begin
        o_data_4 = 0;
    end
end

always @(*) begin
    if(start_all == 4 || start_8 == 3 || start_9 == 2 || start_10 == 1) begin
        o_flag_4 = 1;
    end
    else begin
        o_flag_4 = 0;
    end
end

always @(*) begin
    start_11 = 0;
    if(o_flag_4 && (Huff_r[8] == 11 || Huff_r[9] == 11)) begin //find 12
        start_11 = 1;
    end
    if(o_flag_4 && (Huff_r[10] == 11 || Huff_r[11] == 11)) begin //find 13
        start_11 = 2;
    end
end


//find 12
always @(*) begin
    if(Huff_r[10] == 12 || Huff_r[12] == 12) begin
        o_data_5 = 1;
    end
    else begin
        o_data_5 = 0;
    end
end

always @(*) begin
    if(start_all == 5 || start_8 == 4 || start_9 == 3 || start_10 == 2 || start_11 == 1) begin
        o_flag_5 = 1;
    end
    else begin
        o_flag_5 = 0;
    end
end

always @(*) begin
    start_12 = 0;
    if(o_flag_5 && (Huff_r[10] == 12 || Huff_r[11] == 12)) begin //find 13
        start_12 = 1;
    end
end

//find 13
always @(*) begin
    if(Huff_r[12] == 13) begin
        o_data_6 = 1;
    end
    else begin
        o_data_6 = 0;
    end
end

always @(*) begin
    if(start_all == 6 || start_8 == 5 || start_9 == 4 || start_10 == 3 || start_11 == 2 || start_12 == 1) begin
        o_flag_6 = 1;
    end
    else begin
        o_flag_6 = 0;
    end
end

// ===============================================================
// OUT
// ===============================================================

//output counter
always @(*) begin
    if(counter_r < 9) begin
        o_counter_w = 7;
    end
    else if(counter_r == 9 || o_counter_r == 0) begin
        o_counter_w = o_flag_1 + o_flag_2 + o_flag_3 + o_flag_4 + o_flag_5 + o_flag_6;
    end
    else begin
        o_counter_w = o_counter_r - 1;
    end
end 

//output pr
always @(*) begin
    if(counter_r < 9 || out_pr_r == 1) begin
        out_pr_w = 7;
    end
    else begin
        if(o_flag_6 && out_pr_r > 6) begin
            out_pr_w = 6;
        end
        else if(o_flag_5 && out_pr_r > 5) begin
            out_pr_w = 5;
        end
        else if(o_flag_4 && out_pr_r > 4) begin
            out_pr_w = 4;
        end
        else if(o_flag_3 && out_pr_r > 3) begin
            out_pr_w = 3;
        end
        else if(o_flag_2 && out_pr_r > 2) begin
            out_pr_w = 2;
        end
        else if(o_flag_1 && out_pr_r > 1) begin
            out_pr_w = 1;
        end
        else begin
            out_pr_w = 7;
        end
    end
end

//output data
always @(*) begin
    case(o_counter_r)
        7: begin
            case(out_pr_w)
                6: out_code_tmp = o_data_6;
                5: out_code_tmp = o_data_5;
                4: out_code_tmp = o_data_4;
                3: out_code_tmp = o_data_3;
                2: out_code_tmp = o_data_2;
                1: out_code_tmp = o_data_1;
                7: out_code_tmp = o_data_0;
                default: out_code_tmp = 0;
            endcase
        end
        6: begin
            case(out_pr_w)
                6: out_code_tmp = o_data_6;
                5: out_code_tmp = o_data_5;
                4: out_code_tmp = o_data_4;
                3: out_code_tmp = o_data_3;
                2: out_code_tmp = o_data_2;
                1: out_code_tmp = o_data_1;
                7: out_code_tmp = o_data_0;
                default: out_code_tmp = 0;
            endcase
        end 
        5: begin
            case(out_pr_w)
                6: out_code_tmp = o_data_6;
                5: out_code_tmp = o_data_5;
                4: out_code_tmp = o_data_4;
                3: out_code_tmp = o_data_3;
                2: out_code_tmp = o_data_2;
                1: out_code_tmp = o_data_1;
                7: out_code_tmp = o_data_0;
                default: out_code_tmp = 0;
            endcase
        end 
        4: begin
            case(out_pr_w)
                6: out_code_tmp = o_data_6;
                5: out_code_tmp = o_data_5;
                4: out_code_tmp = o_data_4;
                3: out_code_tmp = o_data_3;
                2: out_code_tmp = o_data_2;
                1: out_code_tmp = o_data_1;
                7: out_code_tmp = o_data_0;
                default: out_code_tmp = 0;
            endcase
        end 
        3: begin
            case(out_pr_w)
                6: out_code_tmp = o_data_6;
                5: out_code_tmp = o_data_5;
                4: out_code_tmp = o_data_4;
                3: out_code_tmp = o_data_3;
                2: out_code_tmp = o_data_2;
                1: out_code_tmp = o_data_1;
                7: out_code_tmp = o_data_0;
                default: out_code_tmp = 0;
            endcase
        end 
        2: begin
            case(out_pr_w)
                6: out_code_tmp = o_data_6;
                5: out_code_tmp = o_data_5;
                4: out_code_tmp = o_data_4;
                3: out_code_tmp = o_data_3;
                2: out_code_tmp = o_data_2;
                1: out_code_tmp = o_data_1;
                7: out_code_tmp = o_data_0;
                default: out_code_tmp = 0;
            endcase
        end 
        1: begin
            case(out_pr_w)
                6: out_code_tmp = o_data_6;
                5: out_code_tmp = o_data_5;
                4: out_code_tmp = o_data_4;
                3: out_code_tmp = o_data_3;
                2: out_code_tmp = o_data_2;
                1: out_code_tmp = o_data_1;
                7: out_code_tmp = o_data_0;
                default: out_code_tmp = 0;
            endcase
        end 
        0: begin
            case(out_pr_w)
                6: out_code_tmp = o_data_6;
                5: out_code_tmp = o_data_5;
                4: out_code_tmp = o_data_4;
                3: out_code_tmp = o_data_3;
                2: out_code_tmp = o_data_2;
                1: out_code_tmp = o_data_1;
                7: out_code_tmp = o_data_0;
                default: out_code_tmp = 0;
            endcase
        end 
        default: out_code_tmp = 0;
    endcase
end

always @(*) begin
    if(counter_r > 8) begin
        out_code_w = out_code_tmp;
    end
    else if(f_counter_r == 4 && out_pr_w == 7) begin
        out_code_w = 0;
    end
    else begin
        out_code_w = 0;
    end
end

always @(*) begin
    if(counter_r > 8) begin
        out_valid_w = 1;
    end
    else if(f_counter_r == 4 && out_pr_w == 7) begin
        out_valid_w = 0;
    end
    else begin
        out_valid_w = 0;
    end
end

//DFF
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        f_counter_r <= 0;
        o_counter_r <= 0;
        out_pr_r <= 0;
        out_code <= 0;
        out_valid <= 0;
    end
    else begin
        f_counter_r <= f_counter_w;
        o_counter_r <= o_counter_w;
        out_pr_r <= out_pr_w;
        out_code <= out_code_w;
        out_valid <= out_valid_w;
    end
end

endmodule