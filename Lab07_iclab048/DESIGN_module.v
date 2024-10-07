module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
	in_matrix_A,
    in_matrix_B,
    out_idle,
    handshake_sready,
    handshake_din,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

	fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    out_matrix,

    flag_clk1_to_fifo,
    flag_fifo_to_clk1
);
input clk;
input rst_n;
input in_valid;
input [3:0] in_matrix_A;
input [3:0] in_matrix_B;
input out_idle;
output reg handshake_sready;
output reg [7:0] handshake_din;
// You can use the the custom flag ports for your design
input  flag_handshake_to_clk1;
output flag_clk1_to_handshake;

input fifo_empty;
input [7:0] fifo_rdata;
output wire fifo_rinc;
output reg out_valid;
output reg [7:0] out_matrix;
// You can use the the custom flag ports for your design
output flag_clk1_to_fifo;
input flag_fifo_to_clk1;

//---------------------------------------------------------------------
//   reg_wire                         
//   V5 lastst back
//   1 optimize clk1 module FSM 
//   2 optimize clk2 module read array
//   3 fifo read signale cut
//---------------------------------------------------------------------	
integer i;
parameter IDLE = 0, SEND = 1, WAIT_NB = 2;
reg [3:0] in_cnt_r, in_cnt_w;
reg [3:0] hand_cnt_r, hand_cnt_w;
reg [3:0] matrix_A_r [0:15]; 
reg [3:0] matrix_A_w [0:15]; 
reg [3:0] matrix_B_r [0:15]; 
reg [3:0] matrix_B_w [0:15]; 

reg [7:0] out_cnt_r, out_cnt_w;
reg out_valid_w;
reg rinc_shift2_r;
reg [1:0] state_cs, state_ns;
reg handshake_sready_w;
reg [7:0] handshake_din_w;
//---------------------------------------------------------------------
//   design                         
//---------------------------------------------------------------------	
//FSM
always @(*) begin
    case(state_cs)
    IDLE: begin
        if(in_valid)    state_ns = SEND;
        else            state_ns = IDLE;
    end
    SEND: begin
        if(out_idle) state_ns = WAIT_NB;
        else         state_ns = SEND; 
    end
    WAIT_NB: begin
        if(!out_idle && hand_cnt_r!=0)   state_ns = SEND;
        else if((&out_cnt_r))            state_ns = IDLE;
        else                             state_ns = WAIT_NB;
    end
    default: state_ns = IDLE;
    endcase
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        state_cs <= 0;
    end
    else begin
        state_cs <= state_ns;
    end
end 

//input
always @(*) begin
    if(in_valid) begin
        in_cnt_w = in_cnt_r + 1;
    end
    else begin
        in_cnt_w = in_cnt_r;
    end
end

always @(*) begin
    for(i=0; i<16; i=i+1) begin
        if(in_cnt_r == i && in_valid) begin
            matrix_A_w[i] = in_matrix_A;
        end
        else begin
            matrix_A_w[i] = matrix_A_r[i];
        end
    end
end

always @(*) begin
    for(i=0; i<16; i=i+1) begin
        if(in_cnt_r == i && in_valid) begin
            matrix_B_w[i] = in_matrix_B;
        end
        else begin
            matrix_B_w[i] = matrix_B_r[i];
        end
    end
end

//output to handshake
always @(*) begin
    if(state_cs == SEND && out_idle) begin
        hand_cnt_w = hand_cnt_r + 1;
    end
    else begin
        hand_cnt_w = hand_cnt_r;
    end
end

always @(*) begin
    if(state_cs == SEND && out_idle) begin
        handshake_sready_w = 1;
        handshake_din_w = {matrix_A_r[hand_cnt_r], matrix_B_r[hand_cnt_r]};
    end
    else begin
        handshake_sready_w = 0;
        handshake_din_w = handshake_din;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        in_cnt_r <= 0;
        hand_cnt_r <= 0;
        for(i=0; i<16; i=i+1) matrix_A_r[i] <= 0;
        for(i=0; i<16; i=i+1) matrix_B_r[i] <= 0;
        handshake_sready <= 0;
        handshake_din <= 0;
    end
    else begin
        in_cnt_r <= in_cnt_w;
        hand_cnt_r <= hand_cnt_w;
        for(i=0; i<16; i=i+1) matrix_A_r[i] <= matrix_A_w[i];
        for(i=0; i<16; i=i+1) matrix_B_r[i] <= matrix_B_w[i];
        handshake_sready <= handshake_sready_w;
        handshake_din <= handshake_din_w;
    end
end

//output to pattern
assign fifo_rinc = (state_cs != IDLE && !in_valid && !fifo_empty) ? 1 : 0;
always @(*) begin
    if(rinc_shift2_r) begin
        out_cnt_w = out_cnt_r + 1;
    end
    else begin
        out_cnt_w = out_cnt_r;
    end
end

always @(*) begin
    if(rinc_shift2_r) begin
        out_matrix = fifo_rdata;
    end
    else begin
        out_matrix = 0;
    end
end

always @(*) begin
    if(flag_fifo_to_clk1) begin
        out_valid_w = 1;
    end
    else begin
        out_valid_w = 0;
    end
end


always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        out_cnt_r <= 0;
        out_valid <= 0;
        rinc_shift2_r <= 0;
    end
    else begin
        out_cnt_r <= out_cnt_w;
        out_valid <= out_valid_w;
        rinc_shift2_r <= flag_fifo_to_clk1;
    end
end

endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    in_matrix,
    out_valid,
    out_matrix,
    busy,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [7:0] in_matrix;
output reg out_valid;
output reg [7:0] out_matrix;
output wire busy;

// You can use the the custom flag ports for your design
input  flag_handshake_to_clk2;
output flag_clk2_to_handshake;

input  flag_fifo_to_clk2;
output flag_clk2_to_fifo;

//---------------------------------------------------------------------
//   reg_wire                         
//---------------------------------------------------------------------	
integer i;
reg [3:0] cal_A_r [0:15]; 
reg [3:0] cal_A_w [0:15]; 
reg [3:0] cal_B_r [0:15]; 
reg [3:0] cal_B_w [0:15]; 
reg [3:0] rec_cnt_r, rec_cnt_w;
reg store_flag_r, store_flag_w;
reg [3:0] A_cnt_r, A_cnt_w;
reg [3:0] B_cnt_r, B_cnt_w;
reg in_valid_shift_r;

//---------------------------------------------------------------------
//   design                         
//---------------------------------------------------------------------	
//receive handshake
assign busy = 0;

always @(*) begin
    if((&rec_cnt_r) && in_valid) begin
        store_flag_w = 1;
    end
    else if((&A_cnt_r) && (&B_cnt_r) && (!fifo_full)) begin
        store_flag_w = 0;
    end
    else begin
        store_flag_w = store_flag_r;
    end
end

always @(*) begin
    for(i=0; i<16; i=i+1) begin
        if(rec_cnt_r == i && in_valid) begin
            cal_A_w[i] = in_matrix[7:4];
        end
        else begin
            cal_A_w[i] = cal_A_r[i];
        end
    end
end

always @(*) begin
    for(i=0; i<16; i=i+1) begin
        if(rec_cnt_r == i && in_valid) begin
            cal_B_w[i] = in_matrix[3:0];
        end
        else begin
            cal_B_w[i] = cal_B_r[i];
        end
    end
end

always @(*) begin
    if(in_valid) begin
        rec_cnt_w = rec_cnt_r + 1;
    end
    else begin
        rec_cnt_w = rec_cnt_r;
    end
end

//cal
always @(*) begin
    if(((!store_flag_r && in_valid_shift_r) || store_flag_r ) && (!fifo_full)) begin
        out_valid = 1;
        B_cnt_w = B_cnt_r + 1;
    end
    else begin
        B_cnt_w = B_cnt_r;
        out_valid = 0;
    end
end

always @(*) begin
    if(store_flag_r && !fifo_full && (&B_cnt_r)) begin
        A_cnt_w = A_cnt_r + 1;
    end
    else begin
        A_cnt_w = A_cnt_r;
    end
end

always @(*) begin
    out_matrix = cal_A_r[A_cnt_r] * cal_B_r[B_cnt_r];
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<16; i=i+1) cal_A_r[i] <= 0;
        for(i=0; i<16; i=i+1) cal_B_r[i] <= 0;
        rec_cnt_r <= 0;
        store_flag_r <= 0;
        in_valid_shift_r <= 0;
        A_cnt_r <= 0;
        B_cnt_r <= 0;
    end
    else begin
        for(i=0; i<16; i=i+1) cal_A_r[i] <= cal_A_w[i];
        for(i=0; i<16; i=i+1) cal_B_r[i] <= cal_B_w[i];
        rec_cnt_r <= rec_cnt_w;
        store_flag_r <= store_flag_w;
        in_valid_shift_r <= in_valid;
        A_cnt_r <= A_cnt_w;
        B_cnt_r <= B_cnt_w;
    end
end

endmodule