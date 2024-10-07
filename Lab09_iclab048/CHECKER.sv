/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2024 Spring IC Design Laboratory 
Lab09: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: Apr-2024)
Author : Jui-Huang Tsai (erictsai.ee12@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/
//================================================================
// verion: V7  Ming
// 1. 782598ns back
//================================================================

`include "Usertype_BEV.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

/*
    Coverage Part
*/

Bev_Type bev_type;
Bev_Size bev_size;

always_ff @(posedge clk iff(inf.type_valid)) begin
    bev_type = inf.D.d_type[0];    
end

always_ff @(posedge clk iff(inf.size_valid)) begin
    bev_size = inf.D.d_size[0];
end


/*
1. Each case of Beverage_Type should be select at least 100 times.
*/

covergroup Conv_1 @(posedge clk);
    option.per_instance = 1;                //Keeps track of coverage for each instance when it is set true
    option.at_least = 100;                  //Minimum number of times for a bin to be hit to be considered covered 
    b_type: coverpoint bev_type{
        bins b_bev_type [] = {[Black_Tea:Super_Pineapple_Milk_Tea]};
    }
    
endgroup

/*
2.	Each case of Bererage_Size should be select at least 100 times.
3.	Create a cross bin for the SPEC1 and SPEC2. Each combination should be selected at least 100 times. 
(Black Tea, Milk Tea, Extra Milk Tea, Green Tea, Green Milk Tea, Pineapple Juice, Super Pineapple Tea, Super Pineapple Tea) x (L, M, S)
*/

covergroup Conv_23 @(posedge clk iff(inf.size_valid));
    option.per_instance = 1;    
    option.at_least = 100;       
    b_size: coverpoint inf.D.d_size[0]{
        bins b_bev_size [] = {L, M ,S};
    }
    cross b_size, bev_type;

endgroup

/*
4.	Output signal inf.err_msg should be No_Err, No_Exp, No_Ing and Ing_OF, each at least 20 times. (Sample the value when inf.out_valid is high)
*/

covergroup Conv_4 @(posedge clk iff(inf.out_valid));
    option.per_instance = 1;    
    option.at_least = 20;      
    b_errmsg: coverpoint inf.err_msg{
        bins b_bev_err [] = {[No_Err:Ing_OF]};
    }

endgroup

/*
5.	Create the transitions bin for the inf.D.act[0] signal from [0:2] to [0:2]. Each transition should be hit at least 200 times. (sample the value at posedge clk iff inf.sel_action_valid)
*/

covergroup Conv_5 @(posedge clk iff(inf.sel_action_valid));
    option.per_instance = 1;    
    option.at_least = 200;      
    b_act: coverpoint inf.D.d_act[0]{
        bins b_bev_act [] = ([Make_drink:Check_Valid_Date] => [Make_drink:Check_Valid_Date]);
    }

endgroup

/*
6.	Create a covergroup for material of supply action with auto_bin_max = 32, and each bin have to hit at least one time.
*/

covergroup Conv_6 @(posedge clk iff(inf.box_sup_valid));
    option.per_instance = 1;
    option.at_least = 1;
    option.auto_bin_max = 32;
    b_material: coverpoint inf.D.d_ing[0]; 

endgroup

/*
    Create instances of Spec1, Spec2, Spec3, Spec4, Spec5, and Spec6
*/

Conv_1 cov_spec_1 = new();
Conv_23 cov_spec_23 = new();
Conv_4 cov_spec_4 = new();
Conv_5 cov_spec_5 = new();
Conv_6 cov_spec_6 = new();

/*
    Asseration
*/

/*
    If you need, you can declare some FSM, logic, flag, and etc. here.
*/
Action bev_act;
logic [2:0] bev_supply_cnt;
logic  bev_Cinvalid_cnt;

always_ff @(posedge clk iff(inf.sel_action_valid)) begin
    bev_act = inf.D.d_act[0];

end

always_ff @(posedge clk, negedge inf.rst_n) begin
    if(bev_supply_cnt == 4 || !inf.rst_n) begin
        bev_supply_cnt = 0;
    end
    else if(inf.box_sup_valid) begin
        bev_supply_cnt = bev_supply_cnt + 1;
    end
end

always_ff @(posedge clk, negedge inf.rst_n) begin
    if(inf.C_out_valid === 1 || !inf.rst_n) begin
        bev_Cinvalid_cnt = 0;
    end
    else if(inf.C_in_valid) begin
        bev_Cinvalid_cnt = 1;
    end
end

/*
    1. All outputs signals (including BEV.sv and bridge.sv) should be zero after reset.
*/

Assertion_1: assert property (@(negedge inf.rst_n) 1 |-> @(posedge inf.rst_n) ( inf.out_valid === 0 && inf.err_msg === 0 && inf.complete === 0 && 
                                                                                inf.C_addr === 0 && inf.C_data_w === 0 && inf.C_in_valid === 0 && inf.C_r_wb === 0 &&
                                                                                inf.C_out_valid === 0 && inf.C_data_r === 0 && 
                                                                                inf.AR_VALID === 0 && inf.AR_ADDR === 0 && inf.R_READY === 0 && 
                                                                                inf.AW_VALID === 0 && inf.AW_ADDR === 0 && inf.W_VALID === 0 && inf.W_DATA === 0 && 
                                                                                inf.B_READY === 0))
                else   begin
                    $display("*************************************************************");
                    $display("                 Assertion 1 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end


/*
    2. Latency should be less than 1000 cycles for each operation.
*/

Assertion_2_makecheck: assert property (@(posedge clk)(bev_act !== Supply && inf.box_no_valid === 1) |-> (##[1:999]inf.out_valid === 1))

                else   begin
                    $display("*************************************************************");
                    $display("                  Assertion_2_makecheck                      ");
                    $display("                 Assertion 2 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end

Assertion_2_supply: assert property (@(posedge clk)(bev_act === Supply && bev_supply_cnt === 4) |-> (##[1:999]inf.out_valid === 1))

                else   begin
                    $display("*************************************************************");
                    $display("                  Assertion_2_supply                         ");
                    $display("                 Assertion 2 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end


/*
    3. If action is completed (complete=1), err_msg should be 2’b0 (no_err).
*/

Assertion_3: assert property (@(negedge clk)(inf.out_valid === 1 && inf.complete === 1) |-> (inf.err_msg === No_Err))

                else   begin
                    $display("*************************************************************");
                    $display("                 Assertion 3 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end

/*
    4. Next input valid will be valid 1-4 cycles after previous input valid fall.
*/

Assertion_4_make: assert property (@(negedge clk)(inf.sel_action_valid === 1 && inf.D.d_act[0] === Make_drink) |-> (##[1:4] inf.type_valid 
                                                                                                                    ##[1:4] inf.size_valid 
                                                                                                                    ##[1:4] inf.date_valid 
                                                                                                                    ##[1:4] inf.box_no_valid))

                else   begin
                    $display("*************************************************************");
                    $display("                  Assertion_4_make                           ");
                    $display("                 Assertion 4 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end

Assertion_4_supply: assert property (@(negedge clk)(inf.sel_action_valid === 1 && inf.D.d_act[0] === Supply) |-> (##[1:4] inf.date_valid 
                                                                                                                  ##[1:4] inf.box_no_valid 
                                                                                                                  ##[1:4] inf.box_sup_valid 
                                                                                                                  ##[1:4] inf.box_sup_valid 
                                                                                                                  ##[1:4] inf.box_sup_valid 
                                                                                                                  ##[1:4] inf.box_sup_valid))

                else   begin
                    $display("*************************************************************");
                    $display("                  Assertion_4_supply                         ");
                    $display("                 Assertion 4 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end

Assertion_4_check: assert property (@(negedge clk)(inf.sel_action_valid === 1 && inf.D.d_act[0] === Check_Valid_Date) |-> (##[1:4] inf.date_valid 
                                                                                                                           ##[1:4] inf.box_no_valid))

                else   begin
                    $display("*************************************************************");
                    $display("                  Assertion_4_check                          ");
                    $display("                 Assertion 4 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end

/*
    5. All input valid signals won't overlap with each other. 
*/

Assertion_5_1: assert property (@(negedge clk)(inf.sel_action_valid === 1)  |-> (inf.type_valid !== 1 && 
                                                                                 inf.size_valid !== 1 && 
                                                                                 inf.date_valid !== 1 && 
                                                                                 inf.box_no_valid !== 1 && 
                                                                                 inf.box_sup_valid !== 1 ))
                else   begin
                    $display("*************************************************************");
                    $display("                  Assertion_5_action                         ");
                    $display("                 Assertion 5 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end

Assertion_5_2: assert property (@(negedge clk)(inf.type_valid === 1)  |-> (inf.sel_action_valid !== 1 && 
                                                                           inf.size_valid !== 1 && 
                                                                           inf.date_valid !== 1 && 
                                                                           inf.box_no_valid !== 1 && 
                                                                           inf.box_sup_valid !== 1 ))
                else   begin
                    $display("*************************************************************");
                    $display("                  Assertion_5_type                           ");
                    $display("                 Assertion 5 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end
Assertion_5_3: assert property (@(negedge clk)(inf.size_valid === 1)  |-> (inf.sel_action_valid !== 1 && 
                                                                           inf.type_valid !== 1 && 
                                                                           inf.date_valid !== 1 && 
                                                                           inf.box_no_valid !== 1 && 
                                                                           inf.box_sup_valid !== 1 ))
                else   begin
                    $display("*************************************************************");
                    $display("                  Assertion_5_size                             ");
                    $display("                 Assertion 5 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end
Assertion_5_4: assert property (@(negedge clk)(inf.date_valid === 1)  |-> (inf.sel_action_valid !== 1 && 
                                                                           inf.type_valid !== 1 && 
                                                                           inf.size_valid !== 1 && 
                                                                           inf.box_no_valid !== 1 && 
                                                                           inf.box_sup_valid !== 1 ))
                else   begin
                    $display("*************************************************************");
                    $display("                  Assertion_5_date                           ");
                    $display("                 Assertion 5 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end
Assertion_5_5: assert property (@(negedge clk)(inf.box_no_valid === 1)  |-> (inf.type_valid !== 1 && 
                                                                             inf.size_valid !== 1 && 
                                                                             inf.date_valid !== 1 && 
                                                                             inf.sel_action_valid !== 1 && 
                                                                             inf.box_sup_valid !== 1 ))
                else   begin
                    $display("*************************************************************");
                    $display("                  Assertion_5_box_no                         ");
                    $display("                 Assertion 5 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end

Assertion_5_6: assert property (@(negedge clk)(inf.box_sup_valid === 1)  |-> (inf.type_valid !== 1 && 
                                                                              inf.size_valid !== 1 && 
                                                                              inf.date_valid !== 1 && 
                                                                              inf.box_no_valid !== 1 && 
                                                                              inf.sel_action_valid !== 1 ))
                else   begin
                    $display("*************************************************************");
                    $display("                  Assertion_5_box_sup                        ");
                    $display("                 Assertion 5 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end


/*
    6. Out_valid can only be high for exactly one cycle.
*/

Assertion_6: assert property (@(posedge clk)(inf.out_valid === 1)  |=> (inf.out_valid === 0))
                else   begin
                    $display("*************************************************************");
                    $display("                 Assertion 6 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end

/*0
    7. Next operation will be valid 1-4 cycles after out_valid fall.
*/

Assertion_7: assert property (@(posedge clk)(inf.out_valid === 1)  |=> (##[0:3]inf.sel_action_valid === 1))
                else   begin
                    $display("*************************************************************");
                    $display("                 Assertion 7 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end

/*
    8. The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases)
*/

Assertion_8_1: assert property (@(negedge clk)(inf.date_valid === 1) |-> (inf.D.d_date[0].M > 0 && inf.D.d_date[0].M < 13))
                else   begin
                    $display("*************************************************************");
                    $display("                  illegal month                              ");
                    $display("                 Assertion 8 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end

Assertion_8_2: assert property (@(negedge clk)(inf.date_valid === 1 && (inf.D.d_date[0].M === 1 || 
                                                                        inf.D.d_date[0].M === 3 || 
                                                                        inf.D.d_date[0].M === 5 || 
                                                                        inf.D.d_date[0].M === 7 || 
                                                                        inf.D.d_date[0].M === 8 || 
                                                                        inf.D.d_date[0].M === 10 || 
                                                                        inf.D.d_date[0].M === 12))  
                                                                    |-> (inf.D.d_date[0].D > 0 && inf.D.d_date[0].D < 32)) 
                else   begin
                    $display("*************************************************************");
                    $display("                 135781012 month illegal day                 ");
                    $display("                 Assertion 8 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end

Assertion_8_3: assert property (@(negedge clk)(inf.date_valid === 1 && (inf.D.d_date[0].M === 4 || 
                                                                        inf.D.d_date[0].M === 6 || 
                                                                        inf.D.d_date[0].M === 9 || 
                                                                        inf.D.d_date[0].M === 11 ))  
                                                                    |-> (inf.D.d_date[0].D > 0 && inf.D.d_date[0].D < 31))
                else   begin
                    $display("*************************************************************");
                    $display("                 46911 month illegal day                     ");
                    $display("                 Assertion 8 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end

Assertion_8_4: assert property (@(negedge clk)(inf.date_valid === 1 && (inf.D.d_date[0].M === 2))  
                                                                    |-> (inf.D.d_date[0].D > 0 && inf.D.d_date[0].D < 29)) 
                else   begin
                    $display("*************************************************************");
                    $display("                 2 month illegal day                         ");
                    $display("                 Assertion 8 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end

/*
    9. C_in_valid can only be high for one cycle and can't be pulled high again before C_out_valid
*/

Assertion_9_1: assert property (@(posedge clk)(inf.C_in_valid === 1) |=> (inf.C_in_valid === 0))
                else   begin
                    $display("*************************************************************");
                    $display("                  C_in_valid not high one cycle              ");
                    $display("                 Assertion 9 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end

Assertion_9_2: assert property (@(posedge clk)(bev_Cinvalid_cnt === 1) |-> (inf.C_in_valid === 0))
                else   begin
                    $display("*************************************************************");
                    $display("   C_in_valid can't be pulled high again before C_out_valid  ");
                    $display("                 Assertion 9 is violated                     ");
                    $display("*************************************************************");
                    $fatal;
                end

endmodule
