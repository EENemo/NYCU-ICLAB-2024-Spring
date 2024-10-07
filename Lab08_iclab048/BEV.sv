module BEV(input clk, INF.BEV_inf inf);
import usertype::*;
// This file contains the definition of several state machines used in the BEV (Beverage) System RTL design.
// The state machines are defined using SystemVerilog enumerated types.
// The state machines are:
// - state_t: used to represent the overall state of the BEV system
//
// Each enumerated type defines a set of named states that the corresponding process can be in.
//================================================================
// verion: new V5 (small change for V4)(warn fix)(this is new submit)
//
// Area:    BEV:29876 bridge:9265
// CC:      715696 (random)
// Period:  2.0
//
// Do what:
// 1. reuse BEV DFF hard
// 2. no_exp stop cal
// 3. box_no_valid come assert C_in_valid
//
// 4. reuse bridge DFF hard(data & addr)
// 5. AW & W valid high same time
// 6. c_out_valid -1T #
// 7. (fix warn)
//================================================================
//================================================================
// logic 
//================================================================
typedef enum logic [1:0]{
    IDLE,
    READ,
    PREPARE,
    OUT_WRITE
} state_teashop;

state_teashop state_cs, state_ns;

//input data from patt
Action act_r, act_w;
Bev_Type type_r, type_w;
Bev_Size size_r, size_w;
Date date_r, date_w;
Barrel_No box_no_r, box_no_w;
ING material_r [3:0];
ING material_w [3:0];
logic [2:0] material_cnt_r, material_cnt_w;//0~3
logic box_no_finish_r, box_no_finish_w;

//input output data to bridge
logic [63:0] bridge_data_r, bridge_data_w;
logic C_in_valid_w, C_r_wb_w;
logic C_out_valid_r, C_out_valid_w;

//err flag
Error_Msg exp_flg;
Error_Msg no_ing_of_flag;

//output data to patt
Error_Msg err_msg_w;
logic complete_w, out_valid_w;

//adder
logic [12:0] black_tea_addout, green_tea_addout, milk_need_addout, pineapple_need_addout;
logic [63:0] bev_C_data;
//================================================================
// design
//================================================================
//FSM
always_comb begin
    case (state_cs)
        IDLE: begin
            if(inf.date_valid)    state_ns = READ;
            else                  state_ns = IDLE;
        end
        READ: begin
            if((C_out_valid_r || inf.C_out_valid) && (box_no_finish_r || inf.box_no_valid))     state_ns = PREPARE;
            else                                                                                state_ns = READ;                                   
        end
        PREPARE: begin
            if((act_r == 0 && C_out_valid_r && exp_flg == 1) || (act_r == 2 && C_out_valid_r))                               state_ns = IDLE;
            else if((act_r == 0 && C_out_valid_r && exp_flg == 0) || (act_r == 1 && C_out_valid_r && material_cnt_r == 5))   state_ns = OUT_WRITE;
            else                                                                                                                  state_ns = PREPARE;
        end
        OUT_WRITE: begin
            state_ns = IDLE;
        end
    endcase
end

always_ff @(posedge clk, negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        state_cs <= IDLE;
    end
    else begin
        state_cs <= state_ns;
    end
end

//input data
assign act_w = (inf.sel_action_valid) ? inf.D.d_act[0]    : act_r;
assign type_w = (inf.type_valid)      ? inf.D.d_type[0]   : type_r;
assign size_w = (inf.size_valid)      ? inf.D.d_size[0]   : size_r;
assign date_w = (inf.date_valid)      ? inf.D.d_date[0]   : date_r;
assign box_no_w = (inf.box_no_valid)  ? inf.D.d_box_no[0] : box_no_r;

always_comb begin
    if(inf.box_no_valid) begin
        box_no_finish_w = 1;
    end
    else if(state_cs == IDLE) begin
        box_no_finish_w = 0;
    end
    else begin
        box_no_finish_w = box_no_finish_r;
    end
end 

always_comb begin
    for(int i=0; i<4; i=i+1) material_w[i] = material_r[i];
    if(inf.box_sup_valid) begin
        material_w[material_cnt_r[1:0]] = inf.D.d_ing[0];
    end
end 

always_comb begin
    if(inf.box_sup_valid || material_cnt_r == 4) begin
        material_cnt_w = material_cnt_r + 1; 
    end
    else if(state_cs == IDLE) begin
        material_cnt_w = 0;
    end
    else begin
         material_cnt_w = material_cnt_r;
    end
end 

always_ff @(posedge clk, negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        act_r <= Make_drink;
        type_r <= Black_Tea;
        size_r <= L;
        date_r <= 0;
        box_no_r <= 0;
        box_no_finish_r <= 0;
        for(int i=0; i<4; i=i+1) material_r[i] <= 0;
        material_cnt_r <= 0;
    end
    else begin
        act_r <= act_w;
        type_r <= type_w;
        size_r <= size_w;
        date_r <= date_w;
        box_no_r <= box_no_w;
        box_no_finish_r <= box_no_finish_w;
        for(int i=0; i<4; i=i+1) material_r[i] <= material_w[i];
        material_cnt_r <= material_cnt_w;
    end
end

//read write bridge
assign inf.C_addr = box_no_r;
always_comb begin
    if( ( state_cs == READ && ((C_out_valid_r || inf.C_out_valid) && (box_no_finish_r || inf.box_no_valid)) ) || (state_cs == OUT_WRITE && ((act_r == 0 && err_msg_w == No_Err) || (act_r == 1)) ) ) begin
        C_in_valid_w = 1;
    end
    else begin
        C_in_valid_w = 0;
    end
end

always_comb begin
    if(state_cs == OUT_WRITE) begin
        C_r_wb_w = 0;
    end
    else begin
        C_r_wb_w = 1;
    end
end

always_comb begin
    if(state_cs == OUT_WRITE) begin
        bridge_data_w = bev_C_data;
    end
    else if(C_out_valid_r) begin
        bridge_data_w = bridge_data_r;
    end
    else begin
        bridge_data_w = inf.C_data_r;
    end
end
assign inf.C_data_w = bridge_data_r;

always_comb begin
    if(inf.C_out_valid && ( state_cs != READ || (state_cs == READ && !box_no_finish_r && !inf.box_no_valid) ) ) begin
        C_out_valid_w = inf.C_out_valid;
    end
    else if(C_out_valid_r && ( (state_cs == READ && (box_no_finish_r || inf.box_no_valid)) || (state_cs == OUT_WRITE && ((act_r == 0 && err_msg_w == No_Err) || (act_r == 1))) )) begin
        C_out_valid_w = 0;
    end
    else begin
        C_out_valid_w = C_out_valid_r;
    end
end

always_ff @(posedge clk, negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.C_in_valid <= 0;
        inf.C_r_wb <= 0;
        C_out_valid_r <= 1;
        bridge_data_r <= 0;

    end
    else begin
        inf.C_in_valid <= C_in_valid_w;
        inf.C_r_wb <= C_r_wb_w;
        C_out_valid_r <= C_out_valid_w;
        bridge_data_r <= bridge_data_w;
    end
end

//cal==================================
//NO_EXP
always_comb begin   //make & ckeck use it
    if( act_r != 1 && ((date_r[8:5] > bridge_data_r[35:32]) || (date_r[8:5] == bridge_data_r[35:32] && date_r[4:0] > bridge_data_r[4:0])) ) begin
        exp_flg = No_Exp;
    end
    else begin
        exp_flg = No_Err;
    end
end

logic [10:0] black_tea_need, green_tea_need, milk_need, pineapple_need;
/*11bit
-960 = 1088
-720 = 1328
-480 = 1568
-240 = 1808
-540 = 1508
-180 = 1868
-360 = 1688
-120 = 1928
*/
always_comb begin
    case({type_r, size_r}) 
    {Black_Tea, L}: begin
        black_tea_need = 1088;
        green_tea_need = 0;
        milk_need = 0;
        pineapple_need = 0;
    end
    {Black_Tea, M}: begin
        black_tea_need = 1328;
        green_tea_need = 0;
        milk_need = 0;
        pineapple_need = 0;
    end
    {Black_Tea, S}: begin
        black_tea_need = 1568;
        green_tea_need = 0;
        milk_need = 0;
        pineapple_need = 0;
    end
    {Milk_Tea, L}: begin
        black_tea_need = 1328;
        green_tea_need = 0;
        milk_need = 1808;
        pineapple_need = 0;
    end
    {Milk_Tea, M}: begin
        black_tea_need = 1508;
        green_tea_need = 0;
        milk_need = 1868;
        pineapple_need = 0;
    end
    {Milk_Tea, S}: begin
        black_tea_need = 1688;
        green_tea_need = 0;
        milk_need = 1928;
        pineapple_need = 0;
    end
    {Extra_Milk_Tea, L}: begin
        black_tea_need = 1568;
        green_tea_need = 0;
        milk_need = 1568;
        pineapple_need = 0;
    end
    {Extra_Milk_Tea, M}: begin
        black_tea_need = 1688;
        green_tea_need = 0;
        milk_need = 1688;
        pineapple_need = 0;
    end
    {Extra_Milk_Tea, S}: begin
        black_tea_need = 1808;
        green_tea_need = 0;
        milk_need = 1808;
        pineapple_need = 0;
    end
    {Green_Tea, L}: begin
        black_tea_need = 0;
        green_tea_need = 1088;
        milk_need = 0;
        pineapple_need = 0;
    end
    {Green_Tea, M}: begin
        black_tea_need = 0;
        green_tea_need = 1328;
        milk_need = 0;
        pineapple_need = 0;
    end
    {Green_Tea, S}: begin
        black_tea_need = 0;
        green_tea_need = 1568;
        milk_need = 0;
        pineapple_need = 0;
    end
    {Green_Milk_Tea, L}: begin
        black_tea_need = 0;
        green_tea_need = 1568;
        milk_need = 1568;
        pineapple_need = 0;
    end
    {Green_Milk_Tea, M}: begin
        black_tea_need = 0;
        green_tea_need = 1688;
        milk_need = 1688;
        pineapple_need = 0;
    end
    {Green_Milk_Tea, S}: begin
        black_tea_need = 0;
        green_tea_need = 1808;
        milk_need = 1808;
        pineapple_need = 0;
    end
    {Pineapple_Juice, L}: begin
        black_tea_need = 0;
        green_tea_need = 0;
        milk_need = 0;
        pineapple_need= 1088;
    end
    {Pineapple_Juice, M}: begin
        black_tea_need = 0;
        green_tea_need = 0;
        milk_need = 0;
        pineapple_need = 1328;
    end
    {Pineapple_Juice, S}: begin
        black_tea_need = 0;
        green_tea_need = 0;
        milk_need = 0;
        pineapple_need = 1568;
    end
    {Super_Pineapple_Tea, L}: begin
        black_tea_need = 1568;
        green_tea_need = 0;
        milk_need = 0;
        pineapple_need = 1568;
    end
    {Super_Pineapple_Tea, M}: begin
        black_tea_need = 1688;
        green_tea_need = 0;
        milk_need = 0;
        pineapple_need = 1688;
    end
    {Super_Pineapple_Tea, S}: begin
        black_tea_need = 1808;
        green_tea_need = 0;
        milk_need = 0;
        pineapple_need = 1808;
    end
    {Super_Pineapple_Milk_Tea, L}: begin
        black_tea_need = 1568;
        green_tea_need = 0;
        milk_need = 1808;
        pineapple_need = 1808;
    end
    {Super_Pineapple_Milk_Tea, M}: begin
        black_tea_need = 1688;
        green_tea_need = 0;
        milk_need = 1868;
        pineapple_need = 1868;
    end
    {Super_Pineapple_Milk_Tea, S}: begin
        black_tea_need = 1808;
        green_tea_need = 0;
        milk_need = 1928;
        pineapple_need = 1928;
    end
    default: begin
        black_tea_need = 0;
        green_tea_need = 0;
        milk_need = 0;
        pineapple_need = 0;
    end
    endcase
end

logic [12:0] black_tea_add1_w, green_tea_add1_w, milk_add1_w, pineapple_add1_w;
logic [12:0] black_tea_add1_r, green_tea_add1_r, milk_add1_r, pineapple_add1_r;
always_comb begin
    
    if(state_cs == PREPARE && ((act_r == 0 && C_out_valid_r) || (act_r == 1 && C_out_valid_r && material_cnt_r == 5))) begin
        black_tea_add1_w = black_tea_addout;
        green_tea_add1_w = green_tea_addout;
        milk_add1_w = milk_need_addout;
        pineapple_add1_w = pineapple_need_addout;
    end
    else begin
        if(act_r[0]) begin //supply
            black_tea_add1_w = {1'b0, material_r[0]};
            green_tea_add1_w = {1'b0, material_r[1]};
            milk_add1_w = {1'b0, material_r[2]};
            pineapple_add1_w = {1'b0, material_r[3]};
        end
        else begin  //make
            black_tea_add1_w = {{2{black_tea_need[10]}}, black_tea_need};
            green_tea_add1_w = {{2{green_tea_need[10]}}, green_tea_need};
            milk_add1_w = {{2{milk_need[10]}}, milk_need};
            pineapple_add1_w = {{2{pineapple_need[10]}}, pineapple_need};
        end
    end
end

always_ff @(posedge clk) begin
    if(!inf.rst_n) begin
        black_tea_add1_r <= 0;
        green_tea_add1_r <= 0;
        milk_add1_r <= 0;
        pineapple_add1_r <= 0;
    end
    else begin
        black_tea_add1_r <= black_tea_add1_w;
        green_tea_add1_r <= green_tea_add1_w;
        milk_add1_r <= milk_add1_w;
        pineapple_add1_r <= pineapple_add1_w;
    end
end


//adder
assign black_tea_addout = black_tea_add1_r + {1'b0, bridge_data_r[63:52]};
assign green_tea_addout = green_tea_add1_r + {1'b0, bridge_data_r[51:40]};
assign milk_need_addout =  milk_add1_r + {1'b0, bridge_data_r[31:20]};
assign pineapple_need_addout = pineapple_add1_r + {1'b0, bridge_data_r[19:8]};

//write back dram
always_comb begin
    if(black_tea_add1_r[12]) begin
        bev_C_data[63:52] = 4095;
    end
    else begin
        bev_C_data[63:52] = black_tea_add1_r[11:0];
    end

    if(green_tea_add1_r[12]) begin
        bev_C_data[51:40] = 4095;
    end
    else begin
        bev_C_data[51:40] = green_tea_add1_r[11:0];
    end

    if(milk_add1_r[12]) begin
        bev_C_data[31:20] = 4095;
    end
    else begin
        bev_C_data[31:20] = milk_add1_r[11:0];
    end

    if(pineapple_add1_r[12]) begin
        bev_C_data[19:8] = 4095;
    end
    else begin
        bev_C_data[19:8] = pineapple_add1_r[11:0];
    end

    if(act_r[0]) begin  //supply
        bev_C_data[39:32] = date_r[8:5];
        bev_C_data[7:0] = date_r[4:0];
    end
    else begin
        bev_C_data[39:32] = bridge_data_r[39:32];
        bev_C_data[7:0] = bridge_data_r[7:0];
    end
end

//Err
always_comb begin
    if(state_cs == PREPARE) begin
        err_msg_w = exp_flg;
    end
    else begin
        if((black_tea_add1_r[12] || green_tea_add1_r[12] || milk_add1_r[12] || pineapple_add1_r[12])) begin
            case(act_r)
                0: err_msg_w = No_Ing;
                1: err_msg_w = Ing_OF;
                default: err_msg_w = No_Err;
            endcase
        end
        else begin
            err_msg_w = No_Err;
        end
    end
end

always_comb begin
    if(err_msg_w == No_Err) begin
        complete_w = 1;
    end
    else begin
        complete_w = 0;
    end
end

always_comb begin
    if(( state_cs == PREPARE && ((act_r == 0 && C_out_valid_r && exp_flg == 1) || (act_r == 2 && C_out_valid_r)) ) || state_cs == OUT_WRITE) begin
        out_valid_w = 1;
    end
    else begin
        out_valid_w = 0;
    end
end

//output
always_ff @(posedge clk, negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.err_msg <= No_Err;
        inf.complete <= 0;
        inf.out_valid <= 0;
    end
    else begin
        inf.err_msg <= err_msg_w;
        inf.complete <= complete_w;
        inf.out_valid <= out_valid_w;
    end
end

endmodule
