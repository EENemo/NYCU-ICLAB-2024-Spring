//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Convolution Neural Network 
//   Author     		: Cheng-Te Chang (chengdez.ee12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CNN.v
//   Module Name : CNN
//   Release version : V1.0 (Release Date: 2024-02)
//   new one
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 3'd0;
parameter inst_extra_prec = 0; 

//other parameter
parameter PAD_ZERO = 32'd0;
parameter IS_ONE = 32'h3f800000;

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel, Weight;
input [1:0] Opt;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   reg/wire
//---------------------------------------------------------------------
//general
integer i;
reg [6:0] counter_r, counter_w;
reg [1:0] Opt_r, Opt_w;

//IEEE FP
reg [inst_sig_width+inst_exp_width:0] Img_r [0:15];
reg [inst_sig_width+inst_exp_width:0] Img_w [0:15];
reg [inst_sig_width+inst_exp_width:0] Kernel_r [0:26];
reg [inst_sig_width+inst_exp_width:0] Kernel_w [0:26];
reg [inst_sig_width+inst_exp_width:0] Weight_r [0:3];
reg [inst_sig_width+inst_exp_width:0] Weight_w [0:3];
reg [inst_sig_width+inst_exp_width:0] convo_r [0:15];
reg [inst_sig_width+inst_exp_width:0] convo_w [0:15];
reg [inst_sig_width+inst_exp_width:0] pool_r;
reg [inst_sig_width+inst_exp_width:0] pool_w;
reg [inst_sig_width+inst_exp_width:0] fc_r [0:3];
reg [inst_sig_width+inst_exp_width:0] fc_w [0:3];

//---------------------------------------------------------------------
//   FSM & input array
//---------------------------------------------------------------------
//Counter as FSM
always @(*) begin
    if(Opt_r == 0 && counter_r == 66) begin
        counter_w = 0;
    end
    else if(counter_r == 70) begin //cycle count
        counter_w = 0;
    end
    else if(in_valid || counter_r != 0) begin
        counter_w = counter_r + 1; 
    end
    else begin
        counter_w = 0;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        counter_r <= 0;
    end
    else begin
        counter_r <= counter_w;
    end
end

//Img & weight  & Opt
always @(*) begin
    for(i=0; i<16;i=i+1) begin
        if(counter_r[3:0] == i && in_valid) begin //rewrite 0~15
            Img_w[i] = Img;
        end
        else begin
            Img_w[i] = Img_r[i];
        end
    end
end

always @(*) begin
    for(i=0; i<27;i=i+1) Kernel_w[i] = Kernel_r[i];
    for(i=0; i<27;i=i+1) begin
        if(counter_r[5:0] == i && in_valid) begin 
            Kernel_w[i] = Kernel;
        end
    end
    if(counter_r == 16) begin
        Kernel_w[0] = Kernel_r[9];
    end
    if(counter_r == 17) begin
        Kernel_w[1] = Kernel_r[10];
    end
    if(counter_r == 18) begin
        Kernel_w[2] = Kernel_r[11];
    end
    if(counter_r == 19) begin
        Kernel_w[3] = Kernel_r[12];
    end
    if(counter_r == 20) begin
        Kernel_w[4] = Kernel_r[13];
    end
    if(counter_r == 21) begin
        Kernel_w[5] = Kernel_r[14];
    end
    if(counter_r == 22) begin
        Kernel_w[6] = Kernel_r[15];
    end
    if(counter_r == 23) begin
        Kernel_w[7] = Kernel_r[16];
    end
        if(counter_r == 24) begin
        Kernel_w[8] = Kernel_r[17];
    end

    if(counter_r == 32) begin
        Kernel_w[0] = Kernel_r[18];
    end
    if(counter_r == 33) begin
        Kernel_w[1] = Kernel_r[19];
    end
    if(counter_r == 34) begin
        Kernel_w[2] = Kernel_r[20];
    end
    if(counter_r == 35) begin
        Kernel_w[3] = Kernel_r[21];
    end
    if(counter_r == 36) begin
        Kernel_w[4] = Kernel_r[22];
    end
    if(counter_r == 37) begin
        Kernel_w[5] = Kernel_r[23];
    end
    if(counter_r == 38) begin
        Kernel_w[6] = Kernel_r[24];
    end
    if(counter_r == 39) begin
        Kernel_w[7] = Kernel_r[25];
    end
    if(counter_r == 40) begin
        Kernel_w[8] = Kernel_r[26];
    end
end

always @(*) begin
    for(i=0; i<4;i=i+1) begin
        if(counter_r[6:0] == i && in_valid) begin
            Weight_w[i] = Weight;
        end
        else begin
            Weight_w[i] = Weight_r[i];
        end
    end
end

always @(*) begin
    if(counter_r == 0 && in_valid) begin
        Opt_w = Opt;
    end
    else begin
        Opt_w = Opt_r;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<16;i=i+1) Img_r[i] <= 0;
        for(i=0; i<27;i=i+1) Kernel_r[i] <= 0;
        for(i=0; i<4;i=i+1) Weight_r[i] <= 0;
        Opt_r <= 0;
    end
    else begin
        for(i=0; i<16;i=i+1) Img_r[i] <= Img_w[i];
        for(i=0; i<27;i=i+1) Kernel_r[i] <= Kernel_w[i];
        for(i=0; i<4;i=i+1) Weight_r[i] <= Weight_w[i];
        Opt_r <= Opt_w;
    end
end

//---------------------------------------------------------------------
//   PE
//---------------------------------------------------------------------
//sel pipeline_PE input
wire [3:0] pipe_pe_out_pr, pipe_pe_psum_pr;
reg [inst_sig_width+inst_exp_width:0] pipe_pe_m0, pipe_pe_m1, pipe_pe_m2, pipe_pe_m3, pipe_pe_m4, pipe_pe_m5;
reg [inst_sig_width+inst_exp_width:0] pipe_pe_m6, pipe_pe_m7, pipe_pe_m8;
wire [inst_sig_width+inst_exp_width:0] pad_idx0, pad_idx1, pad_idx2, pad_idx3, pad_idx4, pad_idx7, pad_idx8, pad_idx11, pad_idx12, pad_idx13, pad_idx14, pad_idx15; 
reg [inst_sig_width+inst_exp_width:0] pine_pe_r [0:7];
wire [inst_sig_width+inst_exp_width:0] pine_pe_w [0:7];
wire [inst_sig_width+inst_exp_width:0] pipe_pe_out;

assign pad_idx0 = Opt_r[1] ? Img_r[0] : PAD_ZERO;
assign pad_idx1 = Opt_r[1] ? Img_r[1] : PAD_ZERO;
assign pad_idx2 = Opt_r[1] ? Img_r[2] : PAD_ZERO;
assign pad_idx3 = Opt_r[1] ? Img_r[3] : PAD_ZERO;
assign pad_idx4 = Opt_r[1] ? Img_r[4] : PAD_ZERO;
assign pad_idx7 = Opt_r[1] ? Img_r[7] : PAD_ZERO;
assign pad_idx8 = Opt_r[1] ? Img_r[8] : PAD_ZERO;
assign pad_idx11 = Opt_r[1] ? Img_r[11] : PAD_ZERO;
assign pad_idx12 = Opt_r[1] ? Img_r[12] : PAD_ZERO;
assign pad_idx13 = Opt_r[1] ? Img_r[13] : PAD_ZERO;
assign pad_idx14 = Opt_r[1] ? Img_r[14] : PAD_ZERO;
assign pad_idx15 = Opt_r[1] ? Img_r[15] : PAD_ZERO;
always @(*) begin
    case(counter_r[3:0]) 
        1: pipe_pe_m0 = pad_idx0;
        2: pipe_pe_m0 = pad_idx0;
        3: pipe_pe_m0 = pad_idx1;
        4: pipe_pe_m0 = pad_idx2;
        5: pipe_pe_m0 = pad_idx0;
        6: pipe_pe_m0 = Img_r[0];
        7: pipe_pe_m0 = Img_r[1];
        8: pipe_pe_m0 = Img_r[2];
        9: pipe_pe_m0 = pad_idx4;
        10: pipe_pe_m0 = Img_r[4];
        11: pipe_pe_m0 = Img_r[5];
        12: pipe_pe_m0 = Img_r[6];
        13: pipe_pe_m0 = pad_idx8;
        14: pipe_pe_m0 = Img_r[8];
        15: pipe_pe_m0 = Img_r[9];
        0: pipe_pe_m0 = Img_r[10];
    endcase
end
always @(*) begin
    case(counter_r[3:0]) 
        2: pipe_pe_m1 = pad_idx0;
        3: pipe_pe_m1 = pad_idx1;
        4: pipe_pe_m1 = pad_idx2;
        5: pipe_pe_m1 = pad_idx3;
        6: pipe_pe_m1 = Img_r[0];
        7: pipe_pe_m1 = Img_r[1];
        8: pipe_pe_m1 = Img_r[2];
        9: pipe_pe_m1 = Img_r[3];
        10: pipe_pe_m1 = Img_r[4];
        11: pipe_pe_m1 = Img_r[5];
        12: pipe_pe_m1 = Img_r[6];
        13: pipe_pe_m1 = Img_r[7];        
        14: pipe_pe_m1 =Img_r[8];
        15: pipe_pe_m1 = Img_r[9];
        0: pipe_pe_m1 = Img_r[10];
        1: pipe_pe_m1 = Img_r[11];
    endcase
end
always @(*) begin
    case(counter_r[3:0]) 
        3: pipe_pe_m2 = pad_idx1;
        4: pipe_pe_m2 = pad_idx2;
        5: pipe_pe_m2 = pad_idx3;
        6: pipe_pe_m2 = pad_idx3;
        7: pipe_pe_m2 = Img_r[1];
        8: pipe_pe_m2 = Img_r[2];
        9: pipe_pe_m2 = Img_r[3];
        10: pipe_pe_m2 = pad_idx3;
        11: pipe_pe_m2 = Img_r[5];
        12: pipe_pe_m2 = Img_r[6];
        13: pipe_pe_m2 = Img_r[7];
        14: pipe_pe_m2 = pad_idx7;       
        15: pipe_pe_m2 = Img_r[9];
        0: pipe_pe_m2 = Img_r[10];
        1: pipe_pe_m2 = Img_r[11];
        2: pipe_pe_m2 = pad_idx11;
    endcase
end
always @(*) begin
    case(counter_r[3:0]) 
        4: pipe_pe_m3 = pad_idx0;
        5: pipe_pe_m3 = Img_r[0];
        6: pipe_pe_m3 = Img_r[1];
        7: pipe_pe_m3 = Img_r[2];
        8: pipe_pe_m3 = pad_idx4;
        9: pipe_pe_m3 = Img_r[4];
        10: pipe_pe_m3 = Img_r[5];
        11: pipe_pe_m3 = Img_r[6];
        12: pipe_pe_m3 = pad_idx8;
        13: pipe_pe_m3 = Img_r[8];
        14: pipe_pe_m3 = Img_r[9];
        15: pipe_pe_m3 = Img_r[10];
        0: pipe_pe_m3 = pad_idx12;
        1: pipe_pe_m3 = Img_r[12];
        2: pipe_pe_m3 = Img_r[13];
        3: pipe_pe_m3 = Img_r[14];
    endcase
end
always @(*) begin
    case(counter_r[3:0]) 
        5: pipe_pe_m4 = Img_r[0];
        6: pipe_pe_m4 = Img_r[1];
        7: pipe_pe_m4 = Img_r[2];
        8: pipe_pe_m4 = Img_r[3];
        9: pipe_pe_m4 = Img_r[4];
        10: pipe_pe_m4 = Img_r[5];
        11: pipe_pe_m4 = Img_r[6];
        12: pipe_pe_m4 = Img_r[7];
        13: pipe_pe_m4 = Img_r[8];
        14: pipe_pe_m4 = Img_r[9];
        15: pipe_pe_m4 = Img_r[10];
        0: pipe_pe_m4 = Img_r[11];
        1: pipe_pe_m4 = Img_r[12];
        2: pipe_pe_m4 = Img_r[13];
        3: pipe_pe_m4 = Img_r[14];
        4: pipe_pe_m4 = Img_r[15];
    endcase
end
always @(*) begin
    case(counter_r[3:0]) 
        6: pipe_pe_m5 = Img_r[1];
        7: pipe_pe_m5 = Img_r[2];
        8: pipe_pe_m5 = Img_r[3];
        9: pipe_pe_m5 = pad_idx3;
        10: pipe_pe_m5 = Img_r[5];
        11: pipe_pe_m5 = Img_r[6];
        12: pipe_pe_m5 = Img_r[7];
        13: pipe_pe_m5 = pad_idx7;
        14: pipe_pe_m5 = Img_r[9];
        15: pipe_pe_m5 = Img_r[10];
        0: pipe_pe_m5 = Img_r[11];
        1: pipe_pe_m5 = pad_idx11;     
        2: pipe_pe_m5 = Img_r[13];
        3: pipe_pe_m5 = Img_r[14];
        4: pipe_pe_m5 = Img_r[15];
        5: pipe_pe_m5 = pad_idx15;
    endcase
end
always @(*) begin
    case(counter_r[3:0]) 
        7: pipe_pe_m6 = pad_idx4;
        8: pipe_pe_m6 = Img_r[4];
        9: pipe_pe_m6 = Img_r[5];
        10: pipe_pe_m6 = Img_r[6];
        11: pipe_pe_m6 = pad_idx8;
        12: pipe_pe_m6 = Img_r[8];
        13: pipe_pe_m6 = Img_r[9];
        14: pipe_pe_m6 = Img_r[10];
        15: pipe_pe_m6 = pad_idx12;
        0: pipe_pe_m6 = Img_r[12];
        1: pipe_pe_m6 = Img_r[13];
        2: pipe_pe_m6 = Img_r[14];
        3: pipe_pe_m6 = pad_idx12;
        4: pipe_pe_m6 = pad_idx12;
        5: pipe_pe_m6 = pad_idx13;
        6: pipe_pe_m6 = pad_idx14;
    endcase
end
always @(*) begin
    case(counter_r[3:0]) 
        8: pipe_pe_m7 = Img_r[4];
        9: pipe_pe_m7 = Img_r[5];
        10: pipe_pe_m7 = Img_r[6];
        11: pipe_pe_m7 = Img_r[7];
        12: pipe_pe_m7 = Img_r[8];
        13: pipe_pe_m7 = Img_r[9];
        14: pipe_pe_m7 = Img_r[10];
        15: pipe_pe_m7 = Img_r[11];
        0: pipe_pe_m7 = Img_r[12];
        1: pipe_pe_m7 = Img_r[13];
        2: pipe_pe_m7 = Img_r[14];
        3: pipe_pe_m7 = Img_r[15];
        4: pipe_pe_m7 = pad_idx12;
        5: pipe_pe_m7 = pad_idx13;
        6: pipe_pe_m7 = pad_idx14;
        7: pipe_pe_m7 = pad_idx15;
    endcase
end
always @(*) begin
    case(counter_r[3:0]) 
        9: pipe_pe_m8 = Img_r[5];
        10: pipe_pe_m8 = Img_r[6];
        11: pipe_pe_m8 = Img_r[7];
        12: pipe_pe_m8 = pad_idx7;
        13: pipe_pe_m8 = Img_r[9];
        14: pipe_pe_m8 = Img_r[10];
        15: pipe_pe_m8 = Img_r[11];
        0: pipe_pe_m8 = pad_idx11;
        1: pipe_pe_m8 = Img_r[13];
        2: pipe_pe_m8 = Img_r[14];
        3: pipe_pe_m8 = Img_r[15];
        4: pipe_pe_m8 = pad_idx15;
        5: pipe_pe_m8 = pad_idx13;
        6: pipe_pe_m8 = pad_idx14;
        7: pipe_pe_m8 = pad_idx15;
        8: pipe_pe_m8 = pad_idx15;
    endcase
end

//Pipeline_PE
assign pipe_pe_out_pr = counter_r[3:0];
assign pipe_pe_psum_pr = (counter_r != 0) ? counter_r + 8 : 0;

PE U0_PE ( .a(pipe_pe_m0), .b(Kernel_r[0]), .part_sum(convo_r[pipe_pe_psum_pr]), .PE_out(pine_pe_w[0]) );
PE U1_PE ( .a(pipe_pe_m1), .b(Kernel_r[1]), .part_sum(pine_pe_r[0]), .PE_out(pine_pe_w[1]) );
PE U2_PE ( .a(pipe_pe_m2), .b(Kernel_r[2]), .part_sum(pine_pe_r[1]), .PE_out(pine_pe_w[2]) );

PE U3_PE ( .a(pipe_pe_m3), .b(Kernel_r[3]), .part_sum(pine_pe_r[2]), .PE_out(pine_pe_w[3]) );
PE U4_PE ( .a(pipe_pe_m4), .b(Kernel_r[4]), .part_sum(pine_pe_r[3]), .PE_out(pine_pe_w[4]) );
PE U5_PE ( .a(pipe_pe_m5), .b(Kernel_r[5]), .part_sum(pine_pe_r[4]), .PE_out(pine_pe_w[5]) );

PE U6_PE ( .a(pipe_pe_m6), .b(Kernel_r[6]), .part_sum(pine_pe_r[5]), .PE_out(pine_pe_w[6]) );
PE U7_PE ( .a(pipe_pe_m7), .b(Kernel_r[7]), .part_sum(pine_pe_r[6]), .PE_out(pine_pe_w[7]) );
PE U8_PE ( .a(pipe_pe_m8), .b(Kernel_r[8]), .part_sum(pine_pe_r[7]), .PE_out(pipe_pe_out) );

always @(*) begin
    for(i=0; i<16;i=i+1) convo_w[i] = convo_r[i];
    if(counter_r == 0) begin
        for(i=0; i<16;i=i+1) convo_w[i] = 0;
    end
    else if(counter_r > 8) begin
        convo_w[pipe_pe_out_pr] = pipe_pe_out;
    end
    else begin
        for(i=0; i<16;i=i+1) convo_w[i] = convo_r[i];
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<8;i=i+1) pine_pe_r[i] <= 0;
    end
    else begin
        for(i=0; i<8;i=i+1) pine_pe_r[i] <= pine_pe_w[i];
    end
end
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<16;i=i+1) convo_r[i] <= 0;
    end
    else begin
        for(i=0; i<16;i=i+1) convo_r[i] <= convo_w[i];
    end
end

//---------------------------------------------------------------------
//   Comparator network && Max pooling 
//---------------------------------------------------------------------
reg [inst_sig_width+inst_exp_width:0] comp_in_0, comp_in_1, comp_in_2, comp_in_3;
wire [inst_sig_width+inst_exp_width:0] comp_max_out, comp_min_out;
reg [inst_sig_width+inst_exp_width:0] fc_min_r, fc_min_w;
//sel Comparator network input
always @(*) begin
    comp_in_0 = fc_r[0];
    comp_in_1 = fc_r[1];
    comp_in_2 = fc_r[2];
    comp_in_3 = fc_r[3];
    if(counter_r == 47 || counter_r == 48) begin//Top-left
        comp_in_0 = convo_r[9];//0
        comp_in_1 = convo_r[10];//1
        comp_in_2 = convo_r[13];//4
        comp_in_3 = convo_r[14];//5
    end
    if(counter_r == 49 || counter_r == 50) begin//Top-right
        comp_in_0 = convo_r[11];//2
        comp_in_1 = convo_r[12];//3
        comp_in_2 = convo_r[15];//4
        comp_in_3 = convo_r[0];//5
    end
    if(counter_r == 55 || counter_r == 56) begin//Down-left
        comp_in_0 = convo_r[1];//8
        comp_in_1 = convo_r[2];//9
        comp_in_2 = convo_r[5];//12
        comp_in_3 = convo_r[6];//13
    end
    if(counter_r == 57 || counter_r == 58) begin//Down-right
        comp_in_0 = convo_r[3];//10
        comp_in_1 = convo_r[4];//11
        comp_in_2 = convo_r[7];//14
        comp_in_3 = convo_r[8];//15
    end
end
//Comparator network
Comparator_network U_Comparator_network(
    .a(comp_in_0), .b(comp_in_1), .c(comp_in_2), .d(comp_in_3), 
    .max_out(comp_max_out), .min_out(comp_min_out) 
    );

//sel Comparator network output DFF
always @(*) begin
    pool_w = comp_max_out;
end
always @(*) begin
        fc_min_w = comp_min_out;
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<4;i=i+1) fc_r[i] <= 0;
        pool_r <= 0;
    end
    else begin
        for(i=0; i<4;i=i+1) fc_r[i] <= fc_w[i];
        pool_r <= pool_w;
    end
end

//for Normalization
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        fc_min_r <= 0;
    end
    else begin
        fc_min_r <= fc_min_w;
    end
end

//---------------------------------------------------------------------
//   FC 
//---------------------------------------------------------------------
reg [inst_sig_width+inst_exp_width:0] fc_pe_in, fc_pe_psum;
wire [inst_sig_width+inst_exp_width:0] fc_pe_out;
//sel FC input
always @(*) begin
    if(counter_r == 48 || counter_r == 56) begin
        fc_pe_in = Weight_r[0];
    end
    else if(counter_r == 49 || counter_r == 57) begin
        fc_pe_in = Weight_r[1];
    end
    else if(counter_r == 50 || counter_r == 58) begin
        fc_pe_in = Weight_r[2];
    end
    else begin
        fc_pe_in = Weight_r[3];
    end
end
always @(*) begin
    if(counter_r == 48 || counter_r == 50) begin
        fc_pe_psum = fc_r[0];
    end
    else if(counter_r == 49 || counter_r == 51) begin
        fc_pe_psum = fc_r[1];
    end
    else if(counter_r == 56 || counter_r == 58) begin
        fc_pe_psum = fc_r[2];
    end
    else begin
        fc_pe_psum = fc_r[3];
    end
end
//FC PE
PE U9_PE ( .a(pool_r), .b(fc_pe_in), .part_sum(fc_pe_psum), .PE_out(fc_pe_out) );

//sel fc DFF
always @(*) begin
    if(counter_r == 0) begin
        fc_w[0] = 0;
    end
    else if(counter_r == 48 || counter_r == 50) begin
        fc_w[0] = fc_pe_out;
    end
    else begin
        fc_w[0] = fc_r[0];
    end
end
always @(*) begin
    if(counter_r == 0) begin
        fc_w[1] = 0;
    end
    else if(counter_r == 49 || counter_r == 51) begin
        fc_w[1] = fc_pe_out;
    end
    else begin
        fc_w[1] = fc_r[1];
    end
end
always @(*) begin
    if(counter_r == 0) begin
        fc_w[2] = 0;
    end
    else if(counter_r == 56 || counter_r == 58) begin
        fc_w[2] = fc_pe_out;
    end
    else begin
        fc_w[2] = fc_r[2];
    end
end
always @(*) begin
    if(counter_r == 0) begin
        fc_w[3] = 0;
    end
    else if(counter_r == 57 || counter_r == 59) begin
        fc_w[3] = fc_pe_out;
    end
    else begin
        fc_w[3] = fc_r[3];
    end
end
//---------------------------------------------------------------------
//   Normalization & Activation
//---------------------------------------------------------------------
reg [inst_sig_width+inst_exp_width:0] addsub_0_in0, addsub_0_in1, addsub_1_in0, addsub_1_in1;
reg addsub_0_op, addsub_1_op;
reg [inst_sig_width+inst_exp_width:0] addsub_0_out_r, addsub_0_out_w, addsub_1_out_r, addsub_1_out_w;
reg [inst_sig_width+inst_exp_width:0] div_out_r, div_out_w, ln_out_r, ln_out_w;
reg [inst_sig_width+inst_exp_width:0] exp_out_r [0:1]; 
reg [inst_sig_width+inst_exp_width:0] exp_out_w [0:1]; 
reg [inst_sig_width+inst_exp_width:0] exp_in;
wire [inst_sig_width+inst_exp_width:0] exp_out, multi_2Z;
reg [inst_sig_width+inst_exp_width:0] relu_out;
reg [inst_sig_width+inst_exp_width:0] out_w;
reg out_valid_w;

//sel Hardware input
//numerator(分子)
always @(*) begin
    if(counter_r > 64) begin //65 66 67 68
        if(Opt_r == 2) begin
            addsub_0_in0 = IS_ONE;          //sigmoid_2
            addsub_0_in1 = PAD_ZERO;        //(1+0
        end
        else begin 
            addsub_0_in0 = exp_out_r[1];    //tanh_1          //Softplus_3
            addsub_0_in1 = IS_ONE;          //(+2Z) - 1       //1 + (+Z)
        end
    end
    else begin //counter 61 62 63 64
        addsub_0_in1 = fc_min_r;
        case(counter_r[1:0])//X - Xmin
            0:  addsub_0_in0 = fc_r[3];//64
            1:  addsub_0_in0 = fc_r[0];//61
            2:  addsub_0_in0 = fc_r[1];//62
            3:  addsub_0_in0 = fc_r[2];//63
        endcase
    end

end
//denominator(分母)
always @(*) begin
    if(counter_r > 64) begin //65 66 67 68  
        addsub_1_in0 = exp_out_r[1];        //sigmoid_2   //tanh_1      //softplus_3
        addsub_1_in1 = IS_ONE;              //1+(-Z)      //(+Z)+1      //dont care
    end
    else begin //counter 61 62 63 64
        addsub_1_in0 = pool_r; 
        addsub_1_in1 = fc_min_r;
    end
end
//addsub op
always @(*) begin
    if(counter_r > 64) begin  //65 66 67 68
        if(Opt_r == 1) begin  //tanh_1
            addsub_0_op = 1;  //(+2Z) - 1
            addsub_1_op = 0;  //(+2Z) + 1
        end
        else begin            //sigmoid_2     //Softplus_3    
            addsub_0_op = 0;  //1+0           //1 + (+Z)
            addsub_1_op = 0;  //1+(-Z)        //dont care
        end
    end
    else begin //counter 61 62 63 64
        addsub_0_op = 1; 
        addsub_1_op = 1;
    end
end

//exp 
always @(*) begin 
    if(Opt_r == 1) begin //+2Z tanh_1
        exp_in = multi_2Z;
    end
    else if(Opt_r == 2) begin //-Z sigmoid_2
        exp_in = {~div_out_r[31], div_out_r[30:0]};
    end
    else begin //+Z softplus_3
        exp_in = div_out_r;
    end
end

always @(*) begin
    exp_out_w[0] = exp_out;
    exp_out_w[1] = exp_out_r[0];
end

//Relu
always @(*) begin
    relu_out = (div_out_r[31]) ? 0 : div_out_r;
end

// output mux
always @(*) begin
    if(Opt_r == 0 && (counter_r == 63 || counter_r == 64 || counter_r == 65 || counter_r == 66))begin//63 64 65 66
        out_w = relu_out;
    end
    else if(counter_r > 66) begin//67 68 69 70 
        if(Opt_r == 3) begin//Softplus_3
            out_w = ln_out_r;  
        end
        else begin //sigmoid_2 & tanh_1
            out_w = div_out_r;   
        end
    end
    else begin 
        out_w = 0; 
    end
end
always @(*) begin
    if(Opt_r == 0 && (counter_r == 63 || counter_r == 64 || counter_r == 65 || counter_r == 66))begin//63 64 65 66
        out_valid_w = 1;
    end
    else if(counter_r > 66) begin
        out_valid_w = 1;
    end
    else begin
        out_valid_w = 0;
    end
end

//Normalization & Activation together use hardware
DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U0_addsub
              ( .a(addsub_0_in0), .b(addsub_0_in1), .rnd(inst_faithful_round), .op(addsub_0_op), .z(addsub_0_out_w), .status() );

DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U1_addsub 
              ( .a(addsub_1_in0), .b(addsub_1_in1), .rnd(inst_faithful_round), .op(addsub_1_op), .z(addsub_1_out_w), .status() );

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) U0_div
           ( .a(addsub_0_out_r), .b(addsub_1_out_r), .rnd(inst_faithful_round), .z(div_out_w), .status() );

DW_fp_ln #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_extra_prec, inst_arch) U0_ln 
         ( .a(addsub_0_out_r), .z(ln_out_w), .status() );

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U0_add
           ( .a(div_out_r), .b(div_out_r), .rnd(inst_faithful_round), .z(multi_2Z), .status() );//generate +2Z

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U0_exp 
           ( .a(exp_in), .z(exp_out), .status() );//+2Z or -Z or +Z

//DFF
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        addsub_0_out_r <= 0;
        addsub_1_out_r <= 0;
        div_out_r <= 0;
        ln_out_r <= 0;
        for(i=0; i<2; i=i+1) exp_out_r[i] <= 0;
    end
    else begin
        addsub_0_out_r <= addsub_0_out_w;
        addsub_1_out_r <= addsub_1_out_w;
        div_out_r <= div_out_w;
        ln_out_r <= ln_out_w;
        for(i=0; i<2; i=i+1) exp_out_r[i] <= exp_out_w[i];
    end
end       
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out <= 0;
    end
    else begin
        out_valid <= out_valid_w;
        out <= out_w;
    end
end

endmodule

module PE(
    a,
    b,
    part_sum,
    PE_out
);
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 3'd0;

input [inst_sig_width+inst_exp_width:0] a;
input [inst_sig_width+inst_exp_width:0] b;
input [inst_sig_width+inst_exp_width:0] part_sum;
output [inst_sig_width+inst_exp_width:0] PE_out;

wire [inst_sig_width+inst_exp_width:0] mult_out;

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_mult 
            ( .a(a), .b(b), .rnd(inst_faithful_round), .z(mult_out), .status() );

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_add
           ( .a(mult_out), .b(part_sum), .rnd(inst_faithful_round), .z(PE_out), .status() );

endmodule

module Comparator_network(
    a,
    b,
    c,
    d, 
    max_out,
    min_out
);
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 3'd0;

input [inst_sig_width+inst_exp_width:0] a;
input [inst_sig_width+inst_exp_width:0] b;
input [inst_sig_width+inst_exp_width:0] c;
input [inst_sig_width+inst_exp_width:0] d; 
output [inst_sig_width+inst_exp_width:0] max_out;
output [inst_sig_width+inst_exp_width:0] min_out;

wire [inst_sig_width+inst_exp_width:0] min0, min1, max0, max1;

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U0_cmp 
           ( .a(a), .b(b), .zctr(1'b0), 
             .aeqb(), .altb(), .agtb(), .unordered(), 
             .z0(min0), .z1(max0), .status0(), .status1() );

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U1_cmp 
           ( .a(c), .b(d), .zctr(1'b0), 
             .aeqb(), .altb(), .agtb(), .unordered(), 
             .z0(min1), .z1(max1), .status0(), .status1() );   

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U2_cmp 
            ( .a(min0), .b(min1), .zctr(1'b0), 
            .aeqb(), .altb(), .agtb(), .unordered(), 
            .z0(min_out), .z1(), .status0(), .status1() );

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U3_cmp 
            ( .a(max0), .b(max1), .zctr(1'b0), 
            .aeqb(), .altb(), .agtb(), .unordered(), 
            .z0(), .z1(max_out), .status0(), .status1() );       
endmodule
