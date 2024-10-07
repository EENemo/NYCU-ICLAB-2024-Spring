//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	 V2
//   description:
//   1. opt0 01 pass
//   2. continues to do opt1
//   3. 
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module PREFIX (
    // input port
    clk,
    rst_n,
    in_valid,
    opt,
    in_data,
    // output port
    out_valid,
    out
);

input clk;
input rst_n;
input in_valid;
input opt;
input [4:0] in_data;
output reg out_valid;
output reg signed [94:0] out;

//=====================================
//          reg
//=====================================
parameter IDLE = 0, WAIT_IN = 1, OPT0 = 2, OPT1 = 3, OUT = 4;
integer i;

reg [2:0] state_cs, state_ns;
reg opt_r, opt_w;
reg [4:0] data_r [0:18];
reg [5:0] data_w [0:18];
reg [5:0] in_cnt_r, in_cnt_w;
reg signed [94:0] cal_r [0:9];
reg signed [94:0] cal_w [0:9];
reg [4:0] opt0_cnt_r, opt0_cnt_w;
reg signed [79:0] tmp;
//=====================================
//          design
//=====================================
always @(*) begin
    case(state_cs)
        IDLE: begin
            if(in_valid) state_ns = WAIT_IN;
            else         state_ns = IDLE;
        end
        WAIT_IN: begin
            if(!in_valid) begin
                if(opt_r) begin
                    state_ns = OPT1;
                end
                else begin
                    state_ns = OPT0;
                end
            end
            else begin
                state_ns = WAIT_IN;
            end
        end
        OPT0: begin
            if(opt0_cnt_r == 18) begin
                state_ns = OUT;
            end
            else begin
                state_ns = OPT0;
            end
        end
        // OPT1: begin
            
        // end
        OUT: begin
            state_ns = IDLE;
        end
        default: state_ns = IDLE;
    endcase
end

always @(*) begin
    if(in_valid) begin
        in_cnt_w = in_cnt_r + 1;
    end
    else begin
        in_cnt_w = 0;
    end
end

always @(*) begin
    if(in_cnt_r == 0 && in_valid) begin
        opt_w = opt;
    end
    else begin
        opt_w = opt_r;
    end
end


always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        state_cs <= 0;
        opt_r <= 0;
        for(i=0; i<19; i=i+1) data_r[i] <= 0;
        in_cnt_r <= 0;
    end
    else begin
        state_cs <= state_ns;
        opt_r <= opt_w;
        for(i=0; i<19; i=i+1) data_r[i] <= data_w[i];
        in_cnt_r <= in_cnt_w;
    end
end

//=====================================
//          opt0
//=====================================
always @(*) begin
    for(i=0; i<19; i=i+1) data_w[i] = data_r[i];
    if(state_cs == WAIT_IN || state_cs == IDLE) begin
        for(i=0; i<19; i=i+1) begin
            if(in_cnt_r == i && in_valid) begin
                data_w[i][4:0] = in_data;
            end
        end
    end
    else if(state_cs == OPT0) begin
        for(i=1; i<19; i=i+1) begin
            data_w[i] = data_r[i-1];
        end
    end


end

always @(*) begin
    for(i=0; i<10; i=i+1) cal_w[i] = cal_r[i];
    if(state_cs == OPT0) begin
        if(data_r[18][4] == 0) begin
            cal_w[9] = data_r[18];
            for(i=0; i<9; i=i+1) begin
                cal_w[i] = cal_r[i+1];
            end
        end
        else begin
            cal_w[0] = 0;
            for(i=1; i<9; i=i+1) begin
                cal_w[i] = cal_r[i-1];
            end
            case(data_r[18][3:0])
                0: tmp = $signed(cal_r[9][39:0]) + $signed(cal_r[8][39:0]);
                1: tmp = $signed(cal_r[9][39:0]) - $signed(cal_r[8][39:0]);
                2: tmp = $signed(cal_r[9][39:0]) * $signed(cal_r[8][39:0]);
                3: tmp = $signed(cal_r[9][39:0]) / $signed(cal_r[8][39:0]);
                default: tmp = $signed(cal_r[9][39:0]) + $signed(cal_r[8][39:0]);
            endcase
            cal_w[9] = {{15{tmp[79]}}, tmp};
        end
    end
    if(state_cs == IDLE) begin
        for(i=0; i<10; i=i+1) cal_w[i] = 0;
    end
end

always @(*) begin
    if(state_cs == IDLE) begin
        opt0_cnt_w = 0;
    end
    else if(state_cs == OPT0) begin
        opt0_cnt_w = opt0_cnt_r + 1;
    end
    else begin
        opt0_cnt_w = opt0_cnt_r;
    end
end


always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        opt0_cnt_r <= 0;
        for(i=0; i<10; i=i+1) cal_r[i] <= 0;
    end
    else begin
        opt0_cnt_r <= opt0_cnt_w;
        for(i=0; i<10; i=i+1) cal_r[i] <= cal_w[i];
    end
end
//=====================================
//          opt1
//=====================================



//=====================================
//          out
//=====================================
reg out_valid_w;
reg signed [94:0] out_w;

always @(*) begin
    if(state_cs == OUT) begin
        if(opt_r) begin
            out_valid_w = 1;
            out_w = 0;
        end
        else begin
            out_valid_w = 1;
            out_w = cal_r[9];
        end
    end
    else begin
        out_valid_w = 0;
        out_w = 0;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        out <= 0;
        out_valid <= 0;
    end
    else begin
        out <= out_w;
        out_valid <= out_valid_w;
    end
end
endmodule
