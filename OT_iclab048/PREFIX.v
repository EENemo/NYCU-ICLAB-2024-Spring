//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
reg signed [4:0] rpe_r [0:18];
reg signed [4:0] rpe_w [0:18];
reg signed [4:0] stack_r [0:18];
reg signed [4:0] stack_w [0:18];
reg [5:0] rpe_cnt_r, rpe_cnt_w, stack_cnt_r, stack_cnt_w;
reg [94:0] opt1_out;
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
        OPT1: begin
            if(data_r[18] == 0) begin
                state_ns = OUT;
            end
            else begin
                state_ns = OPT1;
            end
        end
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
wire [4:0] nnnk;
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
    else if(state_cs == OPT1) begin
        if(data_r[18][4] == 0) begin
            for(i=1; i<19; i=i+1) begin
                data_w[i] = data_r[i-1];
            end
            data_w[0] = 0;
        end
        else begin
            if( (data_r[18] == 16 && nnnk == 18) || (data_r[18] == 16 && nnnk == 19) || (data_r[18] == 17 && nnnk == 18) || (data_r[18] == 17 && nnnk == 19)) begin
                if(stack_cnt_r == 0) begin
                    for(i=1; i<19; i=i+1) begin
                        data_w[i] = data_r[i-1];
                    end
                    data_w[0] = 0;
                end
                else begin
                    for(i=0; i<19; i=i+1) data_w[i] = data_r[i];
                end
            end
            else begin
                for(i=1; i<19; i=i+1) begin
                    data_w[i] = data_r[i-1];
                end
                data_w[0] = 0;
            end
        end
    end
end
assign nnnk = stack_r[stack_cnt_r-1];

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

//rpe 放數字
always @(*) begin
    for(i=0; i<19; i=i+1) rpe_w[i] = rpe_r[i];
    if(state_cs == IDLE) begin
        for(i=0; i<19; i=i+1) rpe_w[i] = 0;
    end
    else if(state_cs == OPT1) begin
        if(data_r[18][4] == 0) begin
            rpe_w[rpe_cnt_r] = data_r[18];
        end
        else begin
            if( (data_r[18] == 16 && nnnk == 18) || (data_r[18] == 16 && nnnk == 19) || (data_r[18] == 17 && nnnk == 18) || (data_r[18] == 17 && nnnk == 19)) begin
                if(stack_cnt_r == 0) begin
                    for(i=0; i<19; i=i+1) rpe_w[i] = rpe_r[i];
                end
                else begin
                    rpe_w[rpe_cnt_r] = stack_r[stack_cnt_r-1];
                end
            end
            else begin
                for(i=0; i<19; i=i+1) rpe_w[i] = rpe_r[i];
            end
        end
    end
    else begin
        for(i=0; i<19; i=i+1) rpe_w[i] = rpe_r[i];
    end
end

always @(*) begin
    for(i=0; i<19; i=i+1) rpe_cnt_w[i] = rpe_cnt_r[i];
    if(state_cs == IDLE) begin
        rpe_cnt_w = 0;
    end
    else if(state_cs == OPT1) begin
        if(data_r[18][4] == 0) begin
            rpe_cnt_w = rpe_cnt_r + 1;
        end
        else begin
            if( (data_r[18] == 16 && nnnk == 18) || (data_r[18] == 16 && nnnk == 19) || (data_r[18] == 17 && nnnk == 18) || (data_r[18] == 17 && nnnk == 19)) begin
                if(stack_cnt_r == 0) begin
                    rpe_cnt_w = rpe_cnt_r;
                end
                else begin
                    rpe_cnt_w = rpe_cnt_r + 1;
                end
            end
            else begin
                for(i=0; i<19; i=i+1) rpe_cnt_w[i] = rpe_cnt_r[i];
            end
        end
    end
    else begin
        rpe_cnt_w = rpe_cnt_r;
    end
end

//stack
always @(*) begin
    for(i=0; i<19; i=i+1) stack_w[i] = stack_r[i];
    if(state_cs == IDLE) begin
        for(i=0; i<19; i=i+1) stack_w[i] = 0;
    end
    else if(state_cs == OPT1) begin
        if(data_r[18][4] == 0) begin
            for(i=0; i<19; i=i+1) stack_w[i] = stack_r[i];
        end
        else begin
            if( (data_r[18] == 16 && nnnk == 18) || (data_r[18] == 16 && nnnk == 19) || (data_r[18] == 17 && nnnk == 18) || (data_r[18] == 17 && nnnk == 19)) begin
                stack_w[stack_cnt_r-1] = 0;
                if(stack_cnt_r == 0) begin
                    stack_w[0] = data_r[18];
                end
            end
            else begin
                stack_w[stack_cnt_r] = data_r[18];
            end
        end
    end
    else begin
        for(i=0; i<19; i=i+1) stack_w[i] = stack_r[i];
    end
end

always @(*) begin
    if(state_cs == IDLE) begin
        stack_cnt_w = 0;
    end
    else if(state_cs == OPT1) begin
        if(data_r[18][4] == 0) begin
            stack_cnt_w = stack_cnt_r;
        end
        else begin
            if( (data_r[18] == 16 && nnnk == 18) || (data_r[18] == 16 && nnnk == 19) || (data_r[18] == 17 && nnnk == 18) || (data_r[18] == 17 && nnnk == 19)) begin
                if(stack_cnt_r > 0) begin
                    stack_cnt_w = stack_cnt_r - 1;
                end
                else begin
                    stack_cnt_w = stack_cnt_r + 1;
                end
            end
            else begin
                stack_cnt_w = stack_cnt_r + 1;
            end
        end
    end
    else begin
        stack_cnt_w = stack_cnt_r;
    end
end

always @(*) begin
    case (stack_cnt_r)
        0: opt1_out = {rpe_r[0], rpe_r[1], rpe_r[2], rpe_r[3], rpe_r[4], rpe_r[5], rpe_r[6], rpe_r[7], rpe_r[8], rpe_r[9], rpe_r[10], rpe_r[11], rpe_r[12], rpe_r[13], rpe_r[14], rpe_r[15], rpe_r[16], rpe_r[17], rpe_r[18]};
        1: opt1_out = {rpe_r[0], rpe_r[1], rpe_r[2], rpe_r[3], rpe_r[4], rpe_r[5], rpe_r[6], rpe_r[7], rpe_r[8], rpe_r[9], rpe_r[10], rpe_r[11], rpe_r[12], rpe_r[13], rpe_r[14], rpe_r[15], rpe_r[16], rpe_r[17], stack_r[0]};
        2: opt1_out = {rpe_r[0], rpe_r[1], rpe_r[2], rpe_r[3], rpe_r[4], rpe_r[5], rpe_r[6], rpe_r[7], rpe_r[8], rpe_r[9], rpe_r[10], rpe_r[11], rpe_r[12], rpe_r[13], rpe_r[14], rpe_r[15], rpe_r[16], stack_r[1], stack_r[0]};
        3: opt1_out = {rpe_r[0], rpe_r[1], rpe_r[2], rpe_r[3], rpe_r[4], rpe_r[5], rpe_r[6], rpe_r[7], rpe_r[8], rpe_r[9], rpe_r[10], rpe_r[11], rpe_r[12], rpe_r[13], rpe_r[14], rpe_r[15], stack_r[2], stack_r[1], stack_r[0]};
        4: opt1_out = {rpe_r[0], rpe_r[1], rpe_r[2], rpe_r[3], rpe_r[4], rpe_r[5], rpe_r[6], rpe_r[7], rpe_r[8], rpe_r[9], rpe_r[10], rpe_r[11], rpe_r[12], rpe_r[13], rpe_r[14], stack_r[3], stack_r[2], stack_r[1], stack_r[0]};
        5: opt1_out = {rpe_r[0], rpe_r[1], rpe_r[2], rpe_r[3], rpe_r[4], rpe_r[5], rpe_r[6], rpe_r[7], rpe_r[8], rpe_r[9], rpe_r[10], rpe_r[11], rpe_r[12], rpe_r[13], stack_r[4], stack_r[3], stack_r[2], stack_r[1], stack_r[0]};
        6: opt1_out = {rpe_r[0], rpe_r[1], rpe_r[2], rpe_r[3], rpe_r[4], rpe_r[5], rpe_r[6], rpe_r[7], rpe_r[8], rpe_r[9], rpe_r[10], rpe_r[11], rpe_r[12], stack_r[5], stack_r[4], stack_r[3], stack_r[2], stack_r[1], stack_r[0]};
        7: opt1_out = {rpe_r[0], rpe_r[1], rpe_r[2], rpe_r[3], rpe_r[4], rpe_r[5], rpe_r[6], rpe_r[7], rpe_r[8], rpe_r[9], rpe_r[10], rpe_r[11], stack_r[6], stack_r[5], stack_r[4], stack_r[3], stack_r[2], stack_r[1], stack_r[0]};
        8: opt1_out = {rpe_r[0], rpe_r[1], rpe_r[2], rpe_r[3], rpe_r[4], rpe_r[5], rpe_r[6], rpe_r[7], rpe_r[8], rpe_r[9], rpe_r[10], stack_r[7], stack_r[6], stack_r[5], stack_r[4], stack_r[3], stack_r[2], stack_r[1], stack_r[0]};
        9: opt1_out = {rpe_r[0], rpe_r[1], rpe_r[2], rpe_r[3], rpe_r[4], rpe_r[5], rpe_r[6], rpe_r[7], rpe_r[8], rpe_r[9], stack_r[8], stack_r[7], stack_r[6], stack_r[5], stack_r[4], stack_r[3], stack_r[2], stack_r[1], stack_r[0]};
        10: opt1_out = {rpe_r[0], rpe_r[1], rpe_r[2], rpe_r[3], rpe_r[4], rpe_r[5], rpe_r[6], rpe_r[7], rpe_r[8], stack_r[9], stack_r[8], stack_r[7], stack_r[6], stack_r[5], stack_r[4], stack_r[3], stack_r[2], stack_r[1], stack_r[0]};
        11:opt1_out = {rpe_r[0], rpe_r[1], rpe_r[2], rpe_r[3], rpe_r[4], rpe_r[5], rpe_r[6], rpe_r[7], stack_r[10], stack_r[9], stack_r[8], stack_r[7], stack_r[6], stack_r[5], stack_r[4], stack_r[3], stack_r[2], stack_r[1], stack_r[0]};
        default: opt1_out = 0;
    endcase
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        rpe_cnt_r <= 0;
        stack_cnt_r <= 0;
        for(i=0; i<19; i=i+1) rpe_r[i] <= 0;
        for(i=0; i<19; i=i+1) stack_r[i] <= 0;
    end
    else begin
        rpe_cnt_r <= rpe_cnt_w;
        stack_cnt_r <= stack_cnt_w;
        for(i=0; i<19; i=i+1) rpe_r[i] <= rpe_w[i];
        for(i=0; i<19; i=i+1) stack_r[i] <= stack_w[i];
    end
end

//=====================================
//          out
//=====================================
reg out_valid_w;
reg signed [94:0] out_w;

always @(*) begin
    if(state_cs == OUT) begin
        if(opt_r) begin
            out_valid_w = 1;
            out_w = opt1_out;
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
