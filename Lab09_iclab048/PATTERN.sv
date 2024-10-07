/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2024 Spring IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : PATTERN.sv
Module Name : PATTERN
Release version : v1.0 (Release Date: Apr-2024)
Author : Jui-Huang Tsai (erictsai.ee12@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/
//================================================================
// verion: V7 Ming
// 1. 782598ns back
//================================================================

`include "Usertype_BEV.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter PATNUM = 3600;

integer ipat;
integer total_latency;
//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  // 256 box

//input
Action in_act;
Bev_Type in_type;
Bev_Size in_size;
Month in_month;
Day in_day;
Barrel_No in_box_no;
ING in_black_tea, in_grean_tea, in_milk, in_pipeapple;
logic [4:0] in_cnt;

//dram
Month Dr_month;
Day Dr_day;
ING Dr_black_tea, Dr_grean_tea, Dr_milk, Dr_pipeapple;
logic [63:0] dram_data;
logic [11:0] need_black_tee, need_green_tee, need_milk, need_pipeapple;

//gloden
Error_Msg gloden_errmsg;
logic gloden_complete;


//================================================================
// class random
//================================================================

class type_size_random ;
	randc Bev_Type beverage_type;
    randc Bev_Size beverage_size;
    randc logic [0:4] cnt;

    constraint cnt_range {
        cnt inside {[0:23]};
    }
	constraint type_range {
        beverage_type inside {[Black_Tea:Super_Pineapple_Milk_Tea]};
	}
    constraint size_range {
        beverage_size inside {L, M, S};
	}
endclass

class date_random ;
	randc Month beverage_month;
    randc Day beverage_day;

	constraint date_range {
        beverage_month inside {[1:12]};
        (beverage_month == 1 || beverage_month == 3 || beverage_month == 5 || beverage_month == 7 || beverage_month == 8 || beverage_month == 10 || beverage_month == 12) ->
        beverage_day inside {[1:31]};

        (beverage_month == 4 || beverage_month == 6 || beverage_month == 9 || beverage_month == 11) -> beverage_day inside {[1:30]};

        (beverage_month == 2) -> beverage_day inside {[1:28]};
	}
endclass

class boxno_material_random;
    randc Barrel_No beverage_box_no;
    randc ING beverage_material;

    constraint box_no_range{
        beverage_box_no inside {[0:255]};
    }
    constraint material_range{
        beverage_material inside {[0:4095]};
    }
endclass

//instances
type_size_random type_size_obj = new();
date_random date_obj = new();
boxno_material_random boxno_material_obj = new();

//================================================================
// initial
//================================================================

initial begin
    $readmemh(DRAM_p_r, golden_DRAM);
    reset_signal_task;
    total_latency = 0;

    for (ipat = 0; ipat < PATNUM; ipat = ipat + 1) begin
        input_task;
        cal_ans_task;
        wait_out_valid_task;
        check_ans_task;

        total_latency = total_latency + 1;
        $display("PASS PATTERN NO.%4d", ipat);
    end
    YOU_PASS_task;
end

//================================================================
// Global task
//================================================================
task reset_signal_task; begin
    inf.rst_n = 1;
    inf.sel_action_valid = 0;
    inf.type_valid = 0;
    inf.size_valid = 0;
    inf.date_valid = 0;
    inf.box_no_valid = 0;
    inf.box_sup_valid = 0;
    inf.D = 'dx;

    #(15) inf.rst_n = 0;
    #(15) inf.rst_n = 1;
end 
endtask

task input_task; begin

    if(ipat >= 1800) begin
        in_act = Make_drink;
    end
    else begin
        case(ipat%9)
            0, 1, 6: in_act = Make_drink;
            2, 3, 8: in_act = Supply;
            4, 5, 7: in_act = Check_Valid_Date;
        endcase
    end

        // $display ("in_act: %d", in_act);
        //================================================================
        // action
        //================================================================    
            input_act_task;

    case(in_act)
        Make_drink: begin
            //================================================================
            // (type & size) -> date -> box no
            //================================================================    
                input_typesize_task;
                input_date_task;
                input_boxno_task; 
        end
        Supply: begin
            //================================================================
            // date -> box no -> material
            //================================================================ 
                input_date_task;    
                input_boxno_task;    
                input_meterial_task;
        end
        Check_Valid_Date: begin
            //================================================================
            // date -> box no
            //================================================================ 
                input_date_task;
                input_boxno_task;        
        end
    endcase
end 
endtask

task cal_ans_task ; begin 

    gloden_errmsg = No_Err;
    gloden_complete = 0;
    
    dram_data[7:0]   = golden_DRAM[65536+(in_box_no*8)];
	dram_data[15:8]  = golden_DRAM[65536+ 1 +(in_box_no*8)];
	dram_data[23:16] = golden_DRAM[65536+ 2 +(in_box_no*8)];
	dram_data[31:24] = golden_DRAM[65536+ 3 +(in_box_no*8)];
	dram_data[39:32] = golden_DRAM[65536+ 4 +(in_box_no*8)];
	dram_data[47:40] = golden_DRAM[65536+ 5 +(in_box_no*8)];
	dram_data[55:48] = golden_DRAM[65536+ 6 +(in_box_no*8)];
	dram_data[63:56] = golden_DRAM[65536+ 7 +(in_box_no*8)];
    Dr_black_tea = dram_data[63:52];
    Dr_grean_tea = dram_data[51:40];
    Dr_milk = dram_data[31:20];
    Dr_pipeapple = dram_data[19:8];
    Dr_month = dram_data[35:32];
    Dr_day = dram_data[4:0];

    if(in_act === Make_drink) begin
        //meterial need
        case({in_type, in_size}) 
            {Black_Tea, L}: begin
                need_black_tee = 960;
                need_green_tee = 0;
                need_milk = 0;
                need_pipeapple = 0;
            end
            {Black_Tea, M}: begin
                need_black_tee = 720;
                need_green_tee = 0;
                need_milk = 0;
                need_pipeapple = 0;
            end
            {Black_Tea, S}: begin
                need_black_tee = 480;
                need_green_tee = 0;
                need_milk = 0;
                need_pipeapple = 0;
            end
            {Milk_Tea, L}: begin
                need_black_tee = 720;
                need_green_tee = 0;
                need_milk = 240;
                need_pipeapple = 0;
            end
            {Milk_Tea, M}: begin
                need_black_tee = 540;
                need_green_tee = 0;
                need_milk = 180;
                need_pipeapple = 0;
            end
            {Milk_Tea, S}: begin
                need_black_tee = 360;
                need_green_tee = 0;
                need_milk = 120;
                need_pipeapple = 0;
            end
            {Extra_Milk_Tea, L}: begin
                need_black_tee = 480;
                need_green_tee = 0;
                need_milk = 480;
                need_pipeapple = 0;
            end
            {Extra_Milk_Tea, M}: begin
                need_black_tee = 360;
                need_green_tee = 0;
                need_milk = 360;
                need_pipeapple = 0;
            end
            {Extra_Milk_Tea, S}: begin
                need_black_tee = 240;
                need_green_tee = 0;
                need_milk = 240;
                need_pipeapple = 0;
            end
            {Green_Tea, L}: begin
                need_black_tee = 0;
                need_green_tee = 960;
                need_milk = 0;
                need_pipeapple = 0;
            end
            {Green_Tea, M}: begin
                need_black_tee = 0;
                need_green_tee = 720;
                need_milk = 0;
                need_pipeapple = 0;
            end
            {Green_Tea, S}: begin
                need_black_tee = 0;
                need_green_tee = 480;
                need_milk = 0;
                need_pipeapple = 0;
            end
            {Green_Milk_Tea, L}: begin
                need_black_tee = 0;
                need_green_tee = 480;
                need_milk = 480;
                need_pipeapple = 0;
            end
            {Green_Milk_Tea, M}: begin
                need_black_tee = 0;
                need_green_tee = 360;
                need_milk = 360;
                need_pipeapple = 0;
            end
            {Green_Milk_Tea, S}: begin
                need_black_tee = 0;
                need_green_tee = 240;
                need_milk = 240;
                need_pipeapple = 0;
            end
            {Pineapple_Juice, L}: begin
                need_black_tee = 0;
                need_green_tee = 0;
                need_milk = 0;
                need_pipeapple= 960;
            end
            {Pineapple_Juice, M}: begin
                need_black_tee = 0;
                need_green_tee = 0;
                need_milk = 0;
                need_pipeapple = 720;
            end
            {Pineapple_Juice, S}: begin
                need_black_tee = 0;
                need_green_tee = 0;
                need_milk = 0;
                need_pipeapple = 480;
            end
            {Super_Pineapple_Tea, L}: begin
                need_black_tee = 480;
                need_green_tee = 0;
                need_milk = 0;
                need_pipeapple = 480;
            end
            {Super_Pineapple_Tea, M}: begin
                need_black_tee = 360;
                need_green_tee = 0;
                need_milk = 0;
                need_pipeapple = 360;
            end
            {Super_Pineapple_Tea, S}: begin
                need_black_tee = 240;
                need_green_tee = 0;
                need_milk = 0;
                need_pipeapple = 240;
            end
            {Super_Pineapple_Milk_Tea, L}: begin
                need_black_tee = 480;
                need_green_tee = 0;
                need_milk = 240;
                need_pipeapple = 240;
            end
            {Super_Pineapple_Milk_Tea, M}: begin
                need_black_tee = 360;
                need_green_tee = 0;
                need_milk = 180;
                need_pipeapple = 180;
            end
            {Super_Pineapple_Milk_Tea, S}: begin
                need_black_tee = 240;
                need_green_tee = 0;
                need_milk = 120;
                need_pipeapple = 120;
            end
            default: begin
                need_black_tee = 0;
                need_green_tee = 0;
                need_milk = 0;
                need_pipeapple = 0;
            end
        endcase

        //err
        if ((in_month > Dr_month) || (in_month == Dr_month && in_day > Dr_day)) begin
            gloden_errmsg = No_Exp;
        end
        else if ((Dr_black_tea < need_black_tee) || (Dr_grean_tea < need_green_tee) || (Dr_milk < need_milk) || (Dr_pipeapple < need_pipeapple)) begin
            gloden_errmsg = No_Ing;
        end
        else begin
            gloden_errmsg = No_Err;
        end

        //write back
        if(gloden_errmsg == No_Err) begin
            dram_data[63:52] = Dr_black_tea - need_black_tee;
            dram_data[51:40] = Dr_grean_tea - need_green_tee;
            dram_data[31:20] = Dr_milk - need_milk;
            dram_data[19:8] = Dr_pipeapple - need_pipeapple;
            dram_data[39:32] = Dr_month;
            dram_data[7:0] = Dr_day;
        end
        else begin
            dram_data[63:52] = Dr_black_tea;
            dram_data[51:40] = Dr_grean_tea;
            dram_data[31:20] = Dr_milk;
            dram_data[19:8] = Dr_pipeapple;
            dram_data[39:32] = Dr_month;
            dram_data[7:0] = Dr_day;
        end

    end
    else if(in_act === Supply) begin

        //black tea
        if((Dr_black_tea + in_black_tea) > 4095) begin
            dram_data[63:52] = 4095;
        end
        else begin
            dram_data[63:52] = Dr_black_tea + in_black_tea;
        end

        //green tea
        if((Dr_grean_tea + in_grean_tea) > 4095) begin
            dram_data[51:40] = 4095;
        end
        else begin
            dram_data[51:40] = Dr_grean_tea + in_grean_tea;
        end

        //milk
        if((Dr_milk + in_milk) > 4095) begin
            dram_data[31:20] = 4095;
        end
        else begin
            dram_data[31:20] = Dr_milk + in_milk;
        end

        //pipeapple
        if((Dr_pipeapple + in_pipeapple) > 4095) begin
            dram_data[19:8] = 4095;
        end
        else begin
            dram_data[19:8] = Dr_pipeapple + in_pipeapple;
        end

        dram_data[39:32] = in_month;
        dram_data[7:0] = in_day;

        //err
        if(((Dr_black_tea + in_black_tea) > 4095) || ((Dr_grean_tea + in_grean_tea) > 4095) || ((Dr_milk + in_milk) > 4095) || ((Dr_pipeapple + in_pipeapple) > 4095)) begin
            gloden_errmsg = Ing_OF;
        end
        else begin
            gloden_errmsg = No_Err;
        end
        
    end
    else if(in_act === Check_Valid_Date) begin
        //err
        if ((in_month > Dr_month) || (in_month == Dr_month && in_day > Dr_day)) begin
            gloden_errmsg = No_Exp;
        end
        else begin
            gloden_errmsg = No_Err;
        end

    end

    //complete
    if(gloden_errmsg == No_Err) begin
        gloden_complete = 1;
    end
    else begin
        gloden_complete = 0;
    end

    golden_DRAM[65536+(in_box_no*8)]   = dram_data[7:0]   ;
    golden_DRAM[65536+ 1 +(in_box_no*8)] = dram_data[15:8]  ;
    golden_DRAM[65536+ 2 +(in_box_no*8)] = dram_data[23:16] ;
    golden_DRAM[65536+ 3 +(in_box_no*8)] = dram_data[31:24] ;
    golden_DRAM[65536+ 4 +(in_box_no*8)] = dram_data[39:32] ;
    golden_DRAM[65536+ 5 +(in_box_no*8)] = dram_data[47:40] ;
    golden_DRAM[65536+ 6 +(in_box_no*8)] = dram_data[55:48] ;
    golden_DRAM[65536+ 7 +(in_box_no*8)] = dram_data[63:56] ;


end endtask 

task wait_out_valid_task ; begin 
	while (inf.out_valid !== 1) begin 
        @(negedge clk);
	end
end endtask 

task check_ans_task ; begin	
        if (inf.complete !== gloden_complete || inf.err_msg !== gloden_errmsg) begin 
            $display("*************************************************************");
            $display("                     Wrong Answer                            ");
            $display("*************************************************************");
            $finish ;
        end
end endtask 

task YOU_PASS_task ; begin 
    $display("*************************************************************");
	$display("                    Congratulations                          ");
    $display("*************************************************************");
    $finish ;
end endtask 



//================================================================
// sub task
//================================================================
task input_act_task; begin
    @(negedge clk) ;

	inf.sel_action_valid = 1 ;
	inf.D.d_act[0] = in_act ;
	@(negedge clk) ;

	inf.sel_action_valid = 0 ;
	inf.D = 'dx;
end 
endtask

task input_typesize_task; begin
    //type
    type_size_obj.randomize();
    in_cnt = type_size_obj.cnt;

    if(in_cnt == 0 || in_cnt == 1 || in_cnt == 2)    in_type = Black_Tea; 

    if(in_cnt == 3 || in_cnt == 4 || in_cnt == 5)    in_type = Milk_Tea; 

    if(in_cnt == 6 || in_cnt == 7 || in_cnt == 8)    in_type = Extra_Milk_Tea; 

    if(in_cnt == 9 || in_cnt == 10 || in_cnt == 11)  in_type = Green_Tea; 

    if(in_cnt == 12 || in_cnt == 13 || in_cnt == 14) in_type = Green_Milk_Tea; 

    if(in_cnt == 15 || in_cnt == 16 || in_cnt == 17) in_type = Pineapple_Juice; 

    if(in_cnt == 18 || in_cnt == 19 || in_cnt == 20) in_type = Super_Pineapple_Tea; 

    if(in_cnt == 21 || in_cnt == 22 || in_cnt == 23) in_type = Super_Pineapple_Milk_Tea; 
    
    inf.D.d_type[0] = in_type;
    inf.type_valid = 1;
    @(negedge clk) ;
    
    inf.D = 'dx;
    inf.type_valid = 0; 

    //size
    if(in_cnt == 0 || in_cnt == 3 || in_cnt == 6 || in_cnt == 9 || in_cnt == 12 || in_cnt == 15 || in_cnt == 18 || in_cnt == 21)   in_size = L; 

    if(in_cnt == 1 || in_cnt == 4 || in_cnt == 7 || in_cnt == 10 || in_cnt == 13 || in_cnt == 16 || in_cnt == 19 || in_cnt == 22)  in_size = M; 

    if(in_cnt == 2 || in_cnt == 5 || in_cnt == 8 || in_cnt == 11 || in_cnt == 14 || in_cnt == 17 || in_cnt == 20 || in_cnt == 23)  in_size = S; 
    
    inf.D.d_size[0] = in_size;
    inf.size_valid = 1;
    @(negedge clk);
    
    inf.D = 'dx;
    inf.size_valid = 0; 

end 
endtask

task input_date_task; begin
    if(in_act === Make_drink && ipat>=300) begin
        in_month = 12;
        in_day = 30;
    end
    else if(ipat<500) begin
        date_obj.randomize();
        in_month = date_obj.beverage_month;
        in_day = date_obj.beverage_day;
    end
    else if(ipat>=500 && ipat<1800) begin
        in_month = 1;
        in_day = 1;
    end

    inf.D.d_date[0].M = in_month;
    inf.D.d_date[0].D = in_day;
    inf.date_valid = 1;
    @(negedge clk);

    inf.D = 'dx ;
    inf.date_valid = 0 ;

end 
endtask

task input_boxno_task; begin
    boxno_material_obj.randomize() ;
    in_box_no = boxno_material_obj.beverage_box_no;
    inf.D.d_box_no[0] = boxno_material_obj.beverage_box_no;
    inf.box_no_valid = 1;
    @(negedge clk);
    
    inf.D = 'dx;
    inf.box_no_valid = 0;

end 
endtask

task input_meterial_task; begin
    //balck tea
    boxno_material_obj.randomize() ;
    in_black_tea = boxno_material_obj.beverage_material;
    inf.D.d_ing[0] = boxno_material_obj.beverage_material ;
    inf.box_sup_valid = 1 ;
    @(negedge clk) ;
    
    inf.D = 'dx; 
    inf.box_sup_valid = 0;     

    //green tea
    boxno_material_obj.randomize() ;
    in_grean_tea = boxno_material_obj.beverage_material;
    inf.D.d_ing[0] = boxno_material_obj.beverage_material ;
    inf.box_sup_valid = 1 ;
    @(negedge clk) ;
    
    inf.D = 'dx; 
    inf.box_sup_valid = 0;   

    //milk
    boxno_material_obj.randomize() ;
    in_milk = boxno_material_obj.beverage_material;
    inf.D.d_ing[0] = boxno_material_obj.beverage_material ;
    inf.box_sup_valid = 1 ;
    @(negedge clk) ;
    
    inf.D = 'dx;
    inf.box_sup_valid = 0;      

    //pipeapple
    boxno_material_obj.randomize() ;
    in_pipeapple = boxno_material_obj.beverage_material;
    inf.D.d_ing[0] = boxno_material_obj.beverage_material ;
    inf.box_sup_valid = 1 ;
    @(negedge clk) ;
    
    inf.D = 'dx; 
    inf.box_sup_valid = 0;   
end 
endtask


endprogram
