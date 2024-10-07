//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : SORT_IP.v
//   	Module Name : SORT_IP
//      V2_V2_1stdemo
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module SORT_IP #(parameter IP_WIDTH = 8) (
    // Input signals
    IN_character, IN_weight,
    // Output signals
    OUT_character
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_WIDTH*4-1:0]  IN_character;
input [IP_WIDTH*5-1:0]  IN_weight;

output [IP_WIDTH*4-1:0] OUT_character;

// ===============================================================
// Design
// ===============================================================
// bubble sort

genvar i;
generate

    if(IP_WIDTH == 3) begin //bubble
        wire [3:0] tmp_0_c0, tmp_0_c1, tmp_1_c0, tmp_1_c1, tmp_3_c0, tmp_3_c1;
        wire [4:0] tmp_0_w0, tmp_0_w1, tmp_1_w0, tmp_1_w1, tmp_3_w0, tmp_3_w1;
        //1
        compar compar_0 (.in_c0(IN_character[11:8]), .in_c1(IN_character[7:4]), .in_w0(IN_weight[14:10]), .in_w1(IN_weight[9:5]), 
                         .out_c0(tmp_0_c0), .out_c1(tmp_0_c1), .out_w0(tmp_0_w0), .out_w1(tmp_0_w1));

        compar compar_1 (.in_c0(tmp_0_c1), .in_c1(IN_character[3:0]), .in_w0(tmp_0_w1), .in_w1(IN_weight[4:0]), 
                         .out_c0(tmp_1_c0), .out_c1(tmp_1_c1), .out_w0(tmp_1_w0), .out_w1(tmp_1_w1));

        compar compar_2 (.in_c0(tmp_0_c0), .in_c1(tmp_1_c0), .in_w0(tmp_0_w0), .in_w1(tmp_1_w0), 
                         .out_c0(tmp_3_c0), .out_c1(tmp_3_c1), .out_w0(tmp_3_w0), .out_w1(tmp_3_w1));

        assign OUT_character = {tmp_3_c0, tmp_3_c1, tmp_1_c1};
    end

    if(IP_WIDTH == 4) begin
        wire [3:0] tmp_0_c0, tmp_0_c1, tmp_1_c0, tmp_1_c1, tmp_2_c0, tmp_2_c1;
        wire [4:0] tmp_0_w0, tmp_0_w1, tmp_1_w0, tmp_1_w1, tmp_2_w0, tmp_2_w1;

        wire [3:0] tmp_3_c0, tmp_3_c1, tmp_4_c0, tmp_4_c1, tmp_5_c0, tmp_5_c1;
        wire [4:0] tmp_3_w0, tmp_3_w1, tmp_4_w0, tmp_4_w1, tmp_5_w0, tmp_5_w1;
        //1
        compar compar_0 (.in_c0(IN_character[15:12]), .in_c1(IN_character[11:8]), .in_w0(IN_weight[19:15]), .in_w1(IN_weight[14:10]), 
                         .out_c0(tmp_0_c0), .out_c1(tmp_0_c1), .out_w0(tmp_0_w0), .out_w1(tmp_0_w1));
        compar compar_1 (.in_c0(tmp_0_c1), .in_c1(IN_character[7:4]), .in_w0(tmp_0_w1), .in_w1(IN_weight[9:5]), 
                         .out_c0(tmp_1_c0), .out_c1(tmp_1_c1), .out_w0(tmp_1_w0), .out_w1(tmp_1_w1));
        compar compar_2 (.in_c0(tmp_1_c1), .in_c1(IN_character[3:0]), .in_w0(tmp_1_w1), .in_w1(IN_weight[4:0]), 
                         .out_c0(tmp_2_c0), .out_c1(tmp_2_c1), .out_w0(tmp_2_w0), .out_w1(tmp_2_w1));

        compar compar_3 (.in_c0(tmp_0_c0), .in_c1(tmp_1_c0), .in_w0(tmp_0_w0), .in_w1(tmp_1_w0), 
                         .out_c0(tmp_3_c0), .out_c1(tmp_3_c1), .out_w0(tmp_3_w0), .out_w1(tmp_3_w1));
        compar compar_4 (.in_c0(tmp_3_c1), .in_c1(tmp_2_c0), .in_w0(tmp_3_w1), .in_w1(tmp_2_w0), 
                         .out_c0(tmp_4_c0), .out_c1(tmp_4_c1), .out_w0(tmp_4_w0), .out_w1(tmp_4_w1));

        compar compar_5 (.in_c0(tmp_3_c0), .in_c1(tmp_4_c0), .in_w0(tmp_3_w0), .in_w1(tmp_4_w0), 
                         .out_c0(tmp_5_c0), .out_c1(tmp_5_c1), .out_w0(tmp_5_w0), .out_w1(tmp_5_w1));

        assign OUT_character = {tmp_5_c0, tmp_5_c1, tmp_4_c1, tmp_2_c1};
    end

    if(IP_WIDTH == 5) begin //bubble
        wire [3:0] tmp_0_c0, tmp_0_c1, tmp_1_c0, tmp_1_c1, tmp_2_c0, tmp_2_c1, tmp_3_c0, tmp_3_c1;
        wire [4:0] tmp_0_w0, tmp_0_w1, tmp_1_w0, tmp_1_w1, tmp_2_w0, tmp_2_w1, tmp_3_w0, tmp_3_w1;

        wire [3:0] tmp_4_c0, tmp_4_c1, tmp_5_c0, tmp_5_c1, tmp_6_c0, tmp_6_c1;
        wire [4:0] tmp_4_w0, tmp_4_w1, tmp_5_w0, tmp_5_w1, tmp_6_w0, tmp_6_w1;

        wire [3:0] tmp_7_c0, tmp_7_c1, tmp_8_c0, tmp_8_c1, tmp_9_c0, tmp_9_c1;
        wire [4:0] tmp_7_w0, tmp_7_w1, tmp_8_w0, tmp_8_w1, tmp_9_w0, tmp_9_w1;

        compar compar_0 (.in_c0(IN_character[19:16]), .in_c1(IN_character[15:12]), .in_w0(IN_weight[24:20]), .in_w1(IN_weight[19:15]), 
                         .out_c0(tmp_0_c0), .out_c1(tmp_0_c1), .out_w0(tmp_0_w0), .out_w1(tmp_0_w1));
        compar compar_1 (.in_c0(tmp_0_c1), .in_c1(IN_character[11:8]), .in_w0(tmp_0_w1), .in_w1(IN_weight[14:10]), 
                         .out_c0(tmp_1_c0), .out_c1(tmp_1_c1), .out_w0(tmp_1_w0), .out_w1(tmp_1_w1));
        compar compar_2 (.in_c0(tmp_1_c1), .in_c1(IN_character[7:4]), .in_w0(tmp_1_w1), .in_w1(IN_weight[9:5]), 
                         .out_c0(tmp_2_c0), .out_c1(tmp_2_c1), .out_w0(tmp_2_w0), .out_w1(tmp_2_w1));
        compar compar_3 (.in_c0(tmp_2_c1), .in_c1(IN_character[3:0]), .in_w0(tmp_2_w1), .in_w1(IN_weight[4:0]), 
                         .out_c0(tmp_3_c0), .out_c1(tmp_3_c1), .out_w0(tmp_3_w0), .out_w1(tmp_3_w1));

        compar compar_4 (.in_c0(tmp_0_c0), .in_c1(tmp_1_c0), .in_w0(tmp_0_w0), .in_w1(tmp_1_w0), 
                         .out_c0(tmp_4_c0), .out_c1(tmp_4_c1), .out_w0(tmp_4_w0), .out_w1(tmp_4_w1));
        compar compar_5 (.in_c0(tmp_4_c1), .in_c1(tmp_2_c0), .in_w0(tmp_4_w1), .in_w1(tmp_2_w0), 
                         .out_c0(tmp_5_c0), .out_c1(tmp_5_c1), .out_w0(tmp_5_w0), .out_w1(tmp_5_w1));
        compar compar_6 (.in_c0(tmp_5_c1), .in_c1(tmp_3_c0), .in_w0(tmp_5_w1), .in_w1(tmp_3_w0), 
                         .out_c0(tmp_6_c0), .out_c1(tmp_6_c1), .out_w0(tmp_6_w0), .out_w1(tmp_6_w1));

        compar compar_7 (.in_c0(tmp_4_c0), .in_c1(tmp_5_c0), .in_w0(tmp_4_w0), .in_w1(tmp_5_w0), 
                         .out_c0(tmp_7_c0), .out_c1(tmp_7_c1), .out_w0(tmp_7_w0), .out_w1(tmp_7_w1));
        compar compar_8 (.in_c0(tmp_7_c1), .in_c1(tmp_6_c0), .in_w0(tmp_7_w1), .in_w1(tmp_6_w0), 
                         .out_c0(tmp_8_c0), .out_c1(tmp_8_c1), .out_w0(tmp_8_w0), .out_w1(tmp_8_w1));

        compar compar_9 (.in_c0(tmp_7_c0), .in_c1(tmp_8_c0), .in_w0(tmp_7_w0), .in_w1(tmp_8_w0), 
                         .out_c0(tmp_9_c0), .out_c1(tmp_9_c1), .out_w0(tmp_9_w0), .out_w1(tmp_9_w1));

        assign OUT_character = {tmp_9_c0, tmp_9_c1, tmp_8_c1, tmp_6_c1, tmp_3_c1};
    end

    if(IP_WIDTH == 6) begin //bubble
        wire [3:0] tmp_0_c0, tmp_0_c1, tmp_1_c0, tmp_1_c1, tmp_2_c0, tmp_2_c1, tmp_3_c0, tmp_3_c1, tmp_4_c0, tmp_4_c1;
        wire [4:0] tmp_0_w0, tmp_0_w1, tmp_1_w0, tmp_1_w1, tmp_2_w0, tmp_2_w1, tmp_3_w0, tmp_3_w1, tmp_4_w0, tmp_4_w1;

        wire [3:0] tmp_5_c0, tmp_5_c1, tmp_6_c0, tmp_6_c1, tmp_7_c0, tmp_7_c1, tmp_8_c0, tmp_8_c1;
        wire [4:0] tmp_5_w0, tmp_5_w1, tmp_6_w0, tmp_6_w1, tmp_7_w0, tmp_7_w1, tmp_8_w0, tmp_8_w1;

        wire [3:0] tmp_9_c0, tmp_9_c1, tmp_10_c0, tmp_10_c1, tmp_11_c0, tmp_11_c1;
        wire [4:0] tmp_9_w0, tmp_9_w1, tmp_10_w0, tmp_10_w1, tmp_11_w0, tmp_11_w1;
        wire [3:0] tmp_12_c0, tmp_12_c1, tmp_13_c0, tmp_13_c1, tmp_14_c0, tmp_14_c1;
        wire [4:0] tmp_12_w0, tmp_12_w1, tmp_13_w0, tmp_13_w1, tmp_14_w0, tmp_14_w1;

        compar compar_0 (.in_c0(IN_character[23:20]), .in_c1(IN_character[19:16]), .in_w0(IN_weight[29:25]), .in_w1(IN_weight[24:20]), 
                         .out_c0(tmp_0_c0), .out_c1(tmp_0_c1), .out_w0(tmp_0_w0), .out_w1(tmp_0_w1));
        compar compar_1 (.in_c0(tmp_0_c1), .in_c1(IN_character[15:12]), .in_w0(tmp_0_w1), .in_w1(IN_weight[19:15]), 
                         .out_c0(tmp_1_c0), .out_c1(tmp_1_c1), .out_w0(tmp_1_w0), .out_w1(tmp_1_w1));
        compar compar_2 (.in_c0(tmp_1_c1), .in_c1(IN_character[11:8]), .in_w0(tmp_1_w1), .in_w1(IN_weight[14:10]), 
                         .out_c0(tmp_2_c0), .out_c1(tmp_2_c1), .out_w0(tmp_2_w0), .out_w1(tmp_2_w1));
        compar compar_3 (.in_c0(tmp_2_c1), .in_c1(IN_character[7:4]), .in_w0(tmp_2_w1), .in_w1(IN_weight[9:5]), 
                         .out_c0(tmp_3_c0), .out_c1(tmp_3_c1), .out_w0(tmp_3_w0), .out_w1(tmp_3_w1));
        compar compar_4 (.in_c0(tmp_3_c1), .in_c1(IN_character[3:0]), .in_w0(tmp_3_w1), .in_w1(IN_weight[4:0]), 
                         .out_c0(tmp_4_c0), .out_c1(tmp_4_c1), .out_w0(tmp_4_w0), .out_w1(tmp_4_w1));

        compar compar_5 (.in_c0(tmp_0_c0), .in_c1(tmp_1_c0), .in_w0(tmp_0_w0), .in_w1(tmp_1_w0), 
                         .out_c0(tmp_5_c0), .out_c1(tmp_5_c1), .out_w0(tmp_5_w0), .out_w1(tmp_5_w1));
        compar compar_6 (.in_c0(tmp_5_c1), .in_c1(tmp_2_c0), .in_w0(tmp_5_w1), .in_w1(tmp_2_w0), 
                         .out_c0(tmp_6_c0), .out_c1(tmp_6_c1), .out_w0(tmp_6_w0), .out_w1(tmp_6_w1));
        compar compar_7 (.in_c0(tmp_6_c1), .in_c1(tmp_3_c0), .in_w0(tmp_6_w1), .in_w1(tmp_3_w0), 
                         .out_c0(tmp_7_c0), .out_c1(tmp_7_c1), .out_w0(tmp_7_w0), .out_w1(tmp_7_w1));
        compar compar_8 (.in_c0(tmp_7_c1), .in_c1(tmp_4_c0), .in_w0(tmp_7_w1), .in_w1(tmp_4_w0), 
                         .out_c0(tmp_8_c0), .out_c1(tmp_8_c1), .out_w0(tmp_8_w0), .out_w1(tmp_8_w1));

        compar compar_9 (.in_c0(tmp_5_c0), .in_c1(tmp_6_c0), .in_w0(tmp_5_w0), .in_w1(tmp_6_w0), 
                         .out_c0(tmp_9_c0), .out_c1(tmp_9_c1), .out_w0(tmp_9_w0), .out_w1(tmp_9_w1));
        compar compar_10 (.in_c0(tmp_9_c1), .in_c1(tmp_7_c0), .in_w0(tmp_9_w1), .in_w1(tmp_7_w0), 
                          .out_c0(tmp_10_c0), .out_c1(tmp_10_c1), .out_w0(tmp_10_w0), .out_w1(tmp_10_w1));
        compar compar_11 (.in_c0(tmp_10_c1), .in_c1(tmp_8_c0), .in_w0(tmp_10_w1), .in_w1(tmp_8_w0), 
                          .out_c0(tmp_11_c0), .out_c1(tmp_11_c1), .out_w0(tmp_11_w0), .out_w1(tmp_11_w1));

        compar compar_12 (.in_c0(tmp_9_c0), .in_c1(tmp_10_c0), .in_w0(tmp_9_w0), .in_w1(tmp_10_w0), 
                          .out_c0(tmp_12_c0), .out_c1(tmp_12_c1), .out_w0(tmp_12_w0), .out_w1(tmp_12_w1));
        compar compar_13 (.in_c0(tmp_12_c1), .in_c1(tmp_11_c0), .in_w0(tmp_12_w1), .in_w1(tmp_11_w0), 
                          .out_c0(tmp_13_c0), .out_c1(tmp_13_c1), .out_w0(tmp_13_w0), .out_w1(tmp_13_w1));

        compar compar_14 (.in_c0(tmp_12_c0), .in_c1(tmp_13_c0), .in_w0(tmp_12_w0), .in_w1(tmp_13_w0), 
                          .out_c0(tmp_14_c0), .out_c1(tmp_14_c1), .out_w0(tmp_14_w0), .out_w1(tmp_14_w1));
        
        assign OUT_character = {tmp_14_c0, tmp_14_c1, tmp_13_c1, tmp_11_c1, tmp_8_c1, tmp_4_c1};
    end

    if(IP_WIDTH == 7) begin //bubble
        wire [3:0] tmp_0_c0, tmp_0_c1, tmp_1_c0, tmp_1_c1, tmp_2_c0, tmp_2_c1, tmp_3_c0, tmp_3_c1, tmp_4_c0, tmp_4_c1, tmp_5_c0, tmp_5_c1;
        wire [4:0] tmp_0_w0, tmp_0_w1, tmp_1_w0, tmp_1_w1, tmp_2_w0, tmp_2_w1, tmp_3_w0, tmp_3_w1, tmp_4_w0, tmp_4_w1, tmp_5_w0, tmp_5_w1;

        wire [3:0] tmp_6_c0, tmp_6_c1, tmp_7_c0, tmp_7_c1, tmp_8_c0, tmp_8_c1, tmp_9_c0, tmp_9_c1, tmp_10_c0, tmp_10_c1;
        wire [4:0] tmp_6_w0, tmp_6_w1, tmp_7_w0, tmp_7_w1, tmp_8_w0, tmp_8_w1, tmp_9_w0, tmp_9_w1, tmp_10_w0, tmp_10_w1;

        wire [3:0] tmp_11_c0, tmp_11_c1, tmp_12_c0, tmp_12_c1, tmp_13_c0, tmp_13_c1, tmp_14_c0, tmp_14_c1;
        wire [4:0] tmp_11_w0, tmp_11_w1, tmp_12_w0, tmp_12_w1, tmp_13_w0, tmp_13_w1, tmp_14_w0, tmp_14_w1;
        wire [3:0] tmp_15_c0, tmp_15_c1, tmp_16_c0, tmp_16_c1, tmp_17_c0, tmp_17_c1;
        wire [4:0] tmp_15_w0, tmp_15_w1, tmp_16_w0, tmp_16_w1, tmp_17_w0, tmp_17_w1;
        wire [3:0] tmp_18_c0, tmp_18_c1, tmp_19_c0, tmp_19_c1, tmp_20_c0, tmp_20_c1;
        wire [4:0] tmp_18_w0, tmp_18_w1, tmp_19_w0, tmp_19_w1, tmp_20_w0, tmp_20_w1;

        compar compar_0 (.in_c0(IN_character[27:24]), .in_c1(IN_character[23:20]), .in_w0(IN_weight[34:30]), .in_w1(IN_weight[29:25]), 
                         .out_c0(tmp_0_c0), .out_c1(tmp_0_c1), .out_w0(tmp_0_w0), .out_w1(tmp_0_w1));

        compar compar_1 (.in_c0(tmp_0_c1), .in_c1(IN_character[19:16]), .in_w0(tmp_0_w1), .in_w1(IN_weight[24:20]), 
                         .out_c0(tmp_1_c0), .out_c1(tmp_1_c1), .out_w0(tmp_1_w0), .out_w1(tmp_1_w1));
        compar compar_2 (.in_c0(tmp_1_c1), .in_c1(IN_character[15:12]), .in_w0(tmp_1_w1), .in_w1(IN_weight[19:15]), 
                         .out_c0(tmp_2_c0), .out_c1(tmp_2_c1), .out_w0(tmp_2_w0), .out_w1(tmp_2_w1));
        compar compar_3 (.in_c0(tmp_2_c1), .in_c1(IN_character[11:8]), .in_w0(tmp_2_w1), .in_w1(IN_weight[14:10]), 
                         .out_c0(tmp_3_c0), .out_c1(tmp_3_c1), .out_w0(tmp_3_w0), .out_w1(tmp_3_w1));
        compar compar_4 (.in_c0(tmp_3_c1), .in_c1(IN_character[7:4]), .in_w0(tmp_3_w1), .in_w1(IN_weight[9:5]), 
                         .out_c0(tmp_4_c0), .out_c1(tmp_4_c1), .out_w0(tmp_4_w0), .out_w1(tmp_4_w1));
        compar compar_5 (.in_c0(tmp_4_c1), .in_c1(IN_character[3:0]), .in_w0(tmp_4_w1), .in_w1(IN_weight[4:0]), 
                         .out_c0(tmp_5_c0), .out_c1(tmp_5_c1), .out_w0(tmp_5_w0), .out_w1(tmp_5_w1));

        compar compar_6 (.in_c0(tmp_0_c0), .in_c1(tmp_1_c0), .in_w0(tmp_0_w0), .in_w1(tmp_1_w0), 
                         .out_c0(tmp_6_c0), .out_c1(tmp_6_c1), .out_w0(tmp_6_w0), .out_w1(tmp_6_w1));
        compar compar_7 (.in_c0(tmp_6_c1), .in_c1(tmp_2_c0), .in_w0(tmp_6_w1), .in_w1(tmp_2_w0), 
                         .out_c0(tmp_7_c0), .out_c1(tmp_7_c1), .out_w0(tmp_7_w0), .out_w1(tmp_7_w1));
        compar compar_8 (.in_c0(tmp_7_c1), .in_c1(tmp_3_c0), .in_w0(tmp_7_w1), .in_w1(tmp_3_w0), 
                         .out_c0(tmp_8_c0), .out_c1(tmp_8_c1), .out_w0(tmp_8_w0), .out_w1(tmp_8_w1));
        compar compar_9 (.in_c0(tmp_8_c1), .in_c1(tmp_4_c0), .in_w0(tmp_8_w1), .in_w1(tmp_4_w0), 
                         .out_c0(tmp_9_c0), .out_c1(tmp_9_c1), .out_w0(tmp_9_w0), .out_w1(tmp_9_w1));
        compar compar_10 (.in_c0(tmp_9_c1), .in_c1(tmp_5_c0), .in_w0(tmp_9_w1), .in_w1(tmp_5_w0), 
                         .out_c0(tmp_10_c0), .out_c1(tmp_10_c1), .out_w0(tmp_10_w0), .out_w1(tmp_10_w1));

        compar compar_11 (.in_c0(tmp_6_c0), .in_c1(tmp_7_c0), .in_w0(tmp_6_w0), .in_w1(tmp_7_w0), 
                         .out_c0(tmp_11_c0), .out_c1(tmp_11_c1), .out_w0(tmp_11_w0), .out_w1(tmp_11_w1));
        compar compar_12 (.in_c0(tmp_11_c1), .in_c1(tmp_8_c0), .in_w0(tmp_11_w1), .in_w1(tmp_8_w0), 
                         .out_c0(tmp_12_c0), .out_c1(tmp_12_c1), .out_w0(tmp_12_w0), .out_w1(tmp_12_w1));
        compar compar_13 (.in_c0(tmp_12_c1), .in_c1(tmp_9_c0), .in_w0(tmp_12_w1), .in_w1(tmp_9_w0), 
                         .out_c0(tmp_13_c0), .out_c1(tmp_13_c1), .out_w0(tmp_13_w0), .out_w1(tmp_13_w1));
        compar compar_14 (.in_c0(tmp_13_c1), .in_c1(tmp_10_c0), .in_w0(tmp_13_w1), .in_w1(tmp_10_w0), 
                         .out_c0(tmp_14_c0), .out_c1(tmp_14_c1), .out_w0(tmp_14_w0), .out_w1(tmp_14_w1));

        compar compar_15 (.in_c0(tmp_11_c0), .in_c1(tmp_12_c0), .in_w0(tmp_11_w0), .in_w1(tmp_12_w0), 
                         .out_c0(tmp_15_c0), .out_c1(tmp_15_c1), .out_w0(tmp_15_w0), .out_w1(tmp_15_w1));
        compar compar_16 (.in_c0(tmp_15_c1), .in_c1(tmp_13_c0), .in_w0(tmp_15_w1), .in_w1(tmp_13_w0), 
                         .out_c0(tmp_16_c0), .out_c1(tmp_16_c1), .out_w0(tmp_16_w0), .out_w1(tmp_16_w1));
        compar compar_17 (.in_c0(tmp_16_c1), .in_c1(tmp_14_c0), .in_w0(tmp_16_w1), .in_w1(tmp_14_w0), 
                         .out_c0(tmp_17_c0), .out_c1(tmp_17_c1), .out_w0(tmp_17_w0), .out_w1(tmp_17_w1));

        compar compar_18 (.in_c0(tmp_15_c0), .in_c1(tmp_16_c0), .in_w0(tmp_15_w0), .in_w1(tmp_16_w0), 
                         .out_c0(tmp_18_c0), .out_c1(tmp_18_c1), .out_w0(tmp_18_w0), .out_w1(tmp_18_w1));
        compar compar_19 (.in_c0(tmp_18_c1), .in_c1(tmp_17_c0), .in_w0(tmp_18_w1), .in_w1(tmp_17_w0), 
                         .out_c0(tmp_19_c0), .out_c1(tmp_19_c1), .out_w0(tmp_19_w0), .out_w1(tmp_19_w1));

        compar compar_20 (.in_c0(tmp_18_c0), .in_c1(tmp_19_c0), .in_w0(tmp_18_w0), .in_w1(tmp_19_w0), 
                         .out_c0(tmp_20_c0), .out_c1(tmp_20_c1), .out_w0(tmp_20_w0), .out_w1(tmp_20_w1));

        assign OUT_character = {tmp_20_c0, tmp_20_c1, tmp_19_c1, tmp_17_c1, tmp_14_c1, tmp_10_c1, tmp_5_c1};
    end

    if(IP_WIDTH == 8) begin
        wire [3:0] tmp_0_c0, tmp_0_c1, tmp_1_c0, tmp_1_c1, tmp_2_c0, tmp_2_c1, tmp_3_c0, tmp_3_c1, tmp_4_c0, tmp_4_c1, tmp_5_c0, tmp_5_c1, tmp_6_c0, tmp_6_c1;
        wire [4:0] tmp_0_w0, tmp_0_w1, tmp_1_w0, tmp_1_w1, tmp_2_w0, tmp_2_w1, tmp_3_w0, tmp_3_w1, tmp_4_w0, tmp_4_w1, tmp_5_w0, tmp_5_w1, tmp_6_w0, tmp_6_w1;

        wire [3:0] tmp_7_c0, tmp_7_c1, tmp_8_c0, tmp_8_c1, tmp_9_c0, tmp_9_c1, tmp_10_c0, tmp_10_c1, tmp_11_c0, tmp_11_c1, tmp_12_c0, tmp_12_c1;
        wire [4:0] tmp_7_w0, tmp_7_w1, tmp_8_w0, tmp_8_w1, tmp_9_w0, tmp_9_w1, tmp_10_w0, tmp_10_w1, tmp_11_w0, tmp_11_w1, tmp_12_w0, tmp_12_w1;

        wire [3:0] tmp_13_c0, tmp_13_c1, tmp_14_c0, tmp_14_c1, tmp_15_c0, tmp_15_c1, tmp_16_c0, tmp_16_c1, tmp_17_c0, tmp_17_c1;
        wire [4:0] tmp_13_w0, tmp_13_w1, tmp_14_w0, tmp_14_w1, tmp_15_w0, tmp_15_w1, tmp_16_w0, tmp_16_w1, tmp_17_w0, tmp_17_w1;

        wire [3:0] tmp_18_c0, tmp_18_c1, tmp_19_c0, tmp_19_c1, tmp_20_c0, tmp_20_c1, tmp_21_c0, tmp_21_c1;
        wire [4:0] tmp_18_w0, tmp_18_w1, tmp_19_w0, tmp_19_w1, tmp_20_w0, tmp_20_w1, tmp_21_w0, tmp_21_w1;

        wire [3:0] tmp_22_c0, tmp_22_c1, tmp_23_c0, tmp_23_c1, tmp_24_c0, tmp_24_c1, tmp_25_c0, tmp_25_c1, tmp_26_c0, tmp_26_c1, tmp_27_c0, tmp_27_c1;
        wire [4:0] tmp_22_w0, tmp_22_w1, tmp_23_w0, tmp_23_w1, tmp_24_w0, tmp_24_w1, tmp_25_w0, tmp_25_w1, tmp_26_w0, tmp_26_w1, tmp_27_w0, tmp_27_w1;

        compar compar_0 (.in_c0(IN_character[31:28]), .in_c1(IN_character[27:24]), .in_w0(IN_weight[39:35]), .in_w1(IN_weight[34:30]), 
                        .out_c0(tmp_0_c0), .out_c1(tmp_0_c1), .out_w0(tmp_0_w0), .out_w1(tmp_0_w1));
        compar compar_1 (.in_c0(tmp_0_c1), .in_c1(IN_character[23:20]), .in_w0(tmp_0_w1), .in_w1(IN_weight[29:25]), 
                        .out_c0(tmp_1_c0), .out_c1(tmp_1_c1), .out_w0(tmp_1_w0), .out_w1(tmp_1_w1));
        compar compar_2 (.in_c0(tmp_1_c1), .in_c1(IN_character[19:16]), .in_w0(tmp_1_w1), .in_w1(IN_weight[24:20]), 
                        .out_c0(tmp_2_c0), .out_c1(tmp_2_c1), .out_w0(tmp_2_w0), .out_w1(tmp_2_w1));
        compar compar_3 (.in_c0(tmp_2_c1), .in_c1(IN_character[15:12]), .in_w0(tmp_2_w1), .in_w1(IN_weight[19:15]), 
                        .out_c0(tmp_3_c0), .out_c1(tmp_3_c1), .out_w0(tmp_3_w0), .out_w1(tmp_3_w1));
        compar compar_4 (.in_c0(tmp_3_c1), .in_c1(IN_character[11:8]), .in_w0(tmp_3_w1), .in_w1(IN_weight[14:10]), 
                        .out_c0(tmp_4_c0), .out_c1(tmp_4_c1), .out_w0(tmp_4_w0), .out_w1(tmp_4_w1));
        compar compar_5 (.in_c0(tmp_4_c1), .in_c1(IN_character[7:4]), .in_w0(tmp_4_w1), .in_w1(IN_weight[9:5]), 
                        .out_c0(tmp_5_c0), .out_c1(tmp_5_c1), .out_w0(tmp_5_w0), .out_w1(tmp_5_w1));
        compar compar_6 (.in_c0(tmp_5_c1), .in_c1(IN_character[3:0]), .in_w0(tmp_5_w1), .in_w1(IN_weight[4:0]), 
                        .out_c0(tmp_6_c0), .out_c1(tmp_6_c1), .out_w0(tmp_6_w0), .out_w1(tmp_6_w1));

        compar compar_7 (.in_c0(tmp_0_c0), .in_c1(tmp_1_c0), .in_w0(tmp_0_w0), .in_w1(tmp_1_w0), 
                        .out_c0(tmp_7_c0), .out_c1(tmp_7_c1), .out_w0(tmp_7_w0), .out_w1(tmp_7_w1));
        compar compar_8 (.in_c0(tmp_7_c1), .in_c1(tmp_2_c0), .in_w0(tmp_7_w1), .in_w1(tmp_2_w0), 
                        .out_c0(tmp_8_c0), .out_c1(tmp_8_c1), .out_w0(tmp_8_w0), .out_w1(tmp_8_w1));
        compar compar_9 (.in_c0(tmp_8_c1), .in_c1(tmp_3_c0), .in_w0(tmp_8_w1), .in_w1(tmp_3_w0), 
                        .out_c0(tmp_9_c0), .out_c1(tmp_9_c1), .out_w0(tmp_9_w0), .out_w1(tmp_9_w1));
        compar compar_10 (.in_c0(tmp_9_c1), .in_c1(tmp_4_c0), .in_w0(tmp_9_w1), .in_w1(tmp_4_w0), 
                        .out_c0(tmp_10_c0), .out_c1(tmp_10_c1), .out_w0(tmp_10_w0), .out_w1(tmp_10_w1));
        compar compar_11 (.in_c0(tmp_10_c1), .in_c1(tmp_5_c0), .in_w0(tmp_10_w1), .in_w1(tmp_5_w0), 
                        .out_c0(tmp_11_c0), .out_c1(tmp_11_c1), .out_w0(tmp_11_w0), .out_w1(tmp_11_w1));
        compar compar_12 (.in_c0(tmp_11_c1), .in_c1(tmp_6_c0), .in_w0(tmp_11_w1), .in_w1(tmp_6_w0), 
                        .out_c0(tmp_12_c0), .out_c1(tmp_12_c1), .out_w0(tmp_12_w0), .out_w1(tmp_12_w1));

        compar compar_13 (.in_c0(tmp_7_c0), .in_c1(tmp_8_c0), .in_w0(tmp_7_w0), .in_w1(tmp_8_w0), 
                        .out_c0(tmp_13_c0), .out_c1(tmp_13_c1), .out_w0(tmp_13_w0), .out_w1(tmp_13_w1));
        compar compar_14 (.in_c0(tmp_13_c1), .in_c1(tmp_9_c0), .in_w0(tmp_13_w1), .in_w1(tmp_9_w0), 
                        .out_c0(tmp_14_c0), .out_c1(tmp_14_c1), .out_w0(tmp_14_w0), .out_w1(tmp_14_w1));
        compar compar_15 (.in_c0(tmp_14_c1), .in_c1(tmp_10_c0), .in_w0(tmp_14_w1), .in_w1(tmp_10_w0), 
                        .out_c0(tmp_15_c0), .out_c1(tmp_15_c1), .out_w0(tmp_15_w0), .out_w1(tmp_15_w1));
        compar compar_16 (.in_c0(tmp_15_c1), .in_c1(tmp_11_c0), .in_w0(tmp_15_w1), .in_w1(tmp_11_w0), 
                        .out_c0(tmp_16_c0), .out_c1(tmp_16_c1), .out_w0(tmp_16_w0), .out_w1(tmp_16_w1));
        compar compar_17 (.in_c0(tmp_16_c1), .in_c1(tmp_12_c0), .in_w0(tmp_16_w1), .in_w1(tmp_12_w0), 
                        .out_c0(tmp_17_c0), .out_c1(tmp_17_c1), .out_w0(tmp_17_w0), .out_w1(tmp_17_w1));

        compar compar_18 (.in_c0(tmp_13_c0), .in_c1(tmp_14_c0), .in_w0(tmp_13_w0), .in_w1(tmp_14_w0), 
                        .out_c0(tmp_18_c0), .out_c1(tmp_18_c1), .out_w0(tmp_18_w0), .out_w1(tmp_18_w1));
        compar compar_19 (.in_c0(tmp_18_c1), .in_c1(tmp_15_c0), .in_w0(tmp_18_w1), .in_w1(tmp_15_w0), 
                        .out_c0(tmp_19_c0), .out_c1(tmp_19_c1), .out_w0(tmp_19_w0), .out_w1(tmp_19_w1));
        compar compar_20 (.in_c0(tmp_19_c1), .in_c1(tmp_16_c0), .in_w0(tmp_19_w1), .in_w1(tmp_16_w0), 
                        .out_c0(tmp_20_c0), .out_c1(tmp_20_c1), .out_w0(tmp_20_w0), .out_w1(tmp_20_w1));
        compar compar_21 (.in_c0(tmp_20_c1), .in_c1(tmp_17_c0), .in_w0(tmp_20_w1), .in_w1(tmp_17_w0), 
                        .out_c0(tmp_21_c0), .out_c1(tmp_21_c1), .out_w0(tmp_21_w0), .out_w1(tmp_21_w1));

        compar compar_22 (.in_c0(tmp_18_c0), .in_c1(tmp_19_c0), .in_w0(tmp_18_w0), .in_w1(tmp_19_w0), 
                        .out_c0(tmp_22_c0), .out_c1(tmp_22_c1), .out_w0(tmp_22_w0), .out_w1(tmp_22_w1));
        compar compar_23 (.in_c0(tmp_22_c1), .in_c1(tmp_20_c0), .in_w0(tmp_22_w1), .in_w1(tmp_20_w0), 
                        .out_c0(tmp_23_c0), .out_c1(tmp_23_c1), .out_w0(tmp_23_w0), .out_w1(tmp_23_w1));
        compar compar_24 (.in_c0(tmp_23_c1), .in_c1(tmp_21_c0), .in_w0(tmp_23_w1), .in_w1(tmp_21_w0), 
                        .out_c0(tmp_24_c0), .out_c1(tmp_24_c1), .out_w0(tmp_24_w0), .out_w1(tmp_24_w1));

        compar compar_25 (.in_c0(tmp_22_c0), .in_c1(tmp_23_c0), .in_w0(tmp_22_w0), .in_w1(tmp_23_w0), 
                        .out_c0(tmp_25_c0), .out_c1(tmp_25_c1), .out_w0(tmp_25_w0), .out_w1(tmp_25_w1));
        compar compar_26 (.in_c0(tmp_25_c1), .in_c1(tmp_24_c0), .in_w0(tmp_25_w1), .in_w1(tmp_24_w0), 
                        .out_c0(tmp_26_c0), .out_c1(tmp_26_c1), .out_w0(tmp_26_w0), .out_w1(tmp_26_w1));
        compar compar_27 (.in_c0(tmp_25_c0), .in_c1(tmp_26_c0), .in_w0(tmp_25_w0), .in_w1(tmp_26_w0), 
                         .out_c0(tmp_27_c0), .out_c1(tmp_27_c1), .out_w0(tmp_27_w0), .out_w1(tmp_27_w1));
                

        assign OUT_character = {tmp_27_c0, tmp_27_c1, tmp_26_c1, tmp_24_c1, tmp_21_c1, tmp_17_c1, tmp_12_c1, tmp_6_c1};

    end

endgenerate

endmodule

module compar(
    input [3:0] in_c0, in_c1,
    input [4:0] in_w0, in_w1,
    output reg [3:0] out_c0, out_c1,
    output reg [4:0] out_w0, out_w1
);

    always @(*) begin
        if(in_w0 < in_w1) begin
            out_c0 = in_c1;
            out_c1 = in_c0;
            out_w0 = in_w1;
            out_w1 = in_w0;
        end
        else begin
            out_c0 = in_c0;
            out_c1 = in_c1;
            out_w0 = in_w0;
            out_w1 = in_w1;
        end
    end
endmodule

