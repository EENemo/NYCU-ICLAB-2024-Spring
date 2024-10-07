//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2021-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
//============================================================================
//  version: V9 final
//  area:    553189
//  cc  :    163274
//  period:  3.9
//  DO
//  1. periduction        (ok)
//  2. move inst control  (ok)
//  2. fix timing         ()
//============================================================================
module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/

// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  reg [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  reg [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  reg [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  reg [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  reg [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;   //arid_m_inf[7:4]:                         instuction     //arid_m_inf[3:0]:     data
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;   //araddr_m_inf[2*ADDR_WIDTH-1:ADDR_WIDTH]: instuction     //araddr_m_inf[ADDR_WIDTH-1:0]: data
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;   //arlen_m_inf[13:7]:                       instuction     //arlen_m_inf[6:0]:             data
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;   //arsize_m_inf[5:3]:                       instuction     //arsize_m_inf[2:0]:            data
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;   //arburst_m_inf[3:2]:                      instuction     //arburst_m_inf[1:0]:           data
output  reg  [DRAM_NUMBER-1:0]               arvalid_m_inf;   //arvalid_m_inf[1]:                        instuction     //arvalid_m_inf[0]:             data 
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;   //arready_m_inf[1]:                        instuction     //arready_m_inf[0]:             data
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;  //rid_m_inf[2*ID_WIDTH-1:ID_WIDTH]:        instuction      //rid_m_inf[ID_WIDTH-1:0]:     data
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;  //rdata_m_inf[2*DATA_WIDTH-1:DATA_WIDTH]:  instuction      //rdata_m_inf[DATA_WIDTH-1:0]: data
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;  //rresp_m_inf[3:2]:                        instuction      //rresp_m_inf[1:0]:            data
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;  //rlast_m_inf[1]:                          instuction      //rlast_m_inf[0]:              data
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;  //rvalid_m_inf[1]:                         instuction      //rvalid_m_inf[0]:             data
output  reg [DRAM_NUMBER-1:0]                 rready_m_inf;  //rready_m_inf[1]:                         instuction      //rready_m_inf[0]:             data
// -----------------------------

//
//
// 
/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;
//###########################################
//              parameter 
//###########################################
integer i;
//instruction-Sram
parameter IS_IDLE = 0,                   
          IS_BUSY = 1,
          IS_INITIAL = 3;                      

//instruction-Sram
parameter DS_IDLE = 0,      
          DS_READ_BUSY = 1,  
          DS_WRITE_BUSY = 2,
          DS_INITIAL = 3;                    

//Main-Design
parameter INST_FETCH = 0,                  
          INST_DECODE = 1,           
          EXECUTE = 2,                
          MEM = 3,                                      
          MEM_READ_ONLY = 4,          
          MEM_WRITE_READ = 5,
          WRITE_REG_FILE = 6,
          WRITE_BACK = 7;


parameter ADDSUB = 3'b000,
          SLTMULT = 3'b001,
          LOAD = 3'b010,
          STORE = 3'b011,
          BRANCH = 3'b100,
          DET = 3'b111;
//###########################################
//               reg & wire
//###########################################
//instruction-Sram FSM
reg [1:0] inst_state_cs, inst_state_ns;
wire inst_cache_valid;
reg inst_read_start;
reg [6:0] inst_read_addr_cnt_r, inst_read_addr_cnt_w;


//Data-Sram FSM
reg [2:0] data_state_cs, data_state_ns;
// wire data_cache_valid;
reg data_cache_valid_flg_r, data_cache_valid_flg_w;
reg data_write_finish_flg_r, data_write_finish_flg_w;
reg data_read_start;
reg data_write_start;
reg [6:0] data_readwrite_addr_cnt_r, data_readwrite_addr_cnt_w;

//AXI
reg inst_arvalid_w, inst_rready_w, inst_rvalid_r;
reg data_arvalid_w, data_rready_w, data_rvalid_r;
reg data_awvalid_w, data_wvalid_w, data_bready_w, data_wlast_w;
reg [15:0] data_wdata_w;


//instruction cache
wire [6:0] inst_cache_addr;
wire [15:0] inst_cache_dout;
reg [15:0]  inst_cache_din_r;
wire inst_cache_we;

//data cache
reg [15:0] data_cache_din_r;
reg data_cache_we_r;

reg data_cache_we;
reg [6:0] data_cache_addr;
reg [15:0] data_cache_din;
wire [15:0] data_cache_dout;

//data cache
reg data_cache_we_from_main;
wire [15:0] data_cache_di_from_main;
reg [6:0] data_cache_addr_from_main;
reg data_cache_dirty_r, data_cache_dirty_w;

//Mian FSM
reg [2:0] main_state_cs, main_state_ns;
reg [3:0] inst_10_cnt_r, inst_10_cnt_w;

//instruction sram signal
reg signed [12:0] inst_cache_next_addr_r, inst_cache_next_addr_w;
reg [3:0] inst_save_frame_r, inst_save_frame_w;
wire inst_hit;

//data sram signal
reg [12:0] data_cache_next_addr_r, data_cache_next_addr_w;
reg [3:0] data_save_frame_r, data_save_frame_w;
wire data_hit;

//INST_DECODE
reg signed [15:0] inst_cache_out_r, inst_cache_out_w;
wire  [2:0] opcode;
wire  [3:0] rs, rt, rd;
wire  func;
wire signed [4:0] immediate;
wire  [3:0] coeff_a;
wire  [8:0] coeff_b;
reg signed [15:0] rs_decode_r, rs_decode_w; 
reg signed [15:0] rt_decode_r, rt_decode_w; 

//EXECUTE
wire signed [15:0] 	add_exe;
wire signed [15:0] 	sub_exe;
wire signed [31:0] 	multi_exe;
wire 				slt_exe;
wire 				equal_exe;
wire signed [12:0] 	load_store_addr_exe;
reg [4:0] exe_cnt_r, exe_cnt_w;

//###########################################
//               assign
//###########################################
//instruction
assign arid_m_inf[7:4] = 4'd0;
assign arlen_m_inf[13:7] = 7'd127;
assign arsize_m_inf[5:3] = 3'b001;
assign arburst_m_inf[3:2] = 2'b01;
assign rid_m_inf[7:4] = 4'd0;

//data
assign arid_m_inf[4:0] = 4'd0;
assign arlen_m_inf[6:0] = 7'd127;
assign arsize_m_inf[2:0] = 3'b001;
assign arburst_m_inf[1:0] = 2'b01;
assign rid_m_inf[4:0] = 4'd0;

assign awid_m_inf = 4'd0;
assign awlen_m_inf = 7'd127;         
assign awsize_m_inf = 3'b001;        
assign awburst_m_inf = 2'b01;

//###########################################
//           instruction-Sram
//###########################################
//===========================================
//          instruction-Sram FSM
//===========================================
always @(*) begin
    case(inst_state_cs)
      IS_IDLE: begin
          if(inst_read_start)       inst_state_ns = IS_BUSY;
          else                      inst_state_ns = IS_IDLE;
      end
      IS_BUSY: begin
          if(&inst_read_addr_cnt_r)        inst_state_ns = IS_IDLE;
          else                              inst_state_ns = IS_BUSY;
      end
      IS_INITIAL: begin
            inst_state_ns = IS_BUSY;
      end
      default: inst_state_ns = IS_IDLE;
    endcase
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        inst_state_cs <= 3;
    end
    else begin
        inst_state_cs <= inst_state_ns;
    end
end

//===========================================
//         instruction AXI READ
//===========================================
assign araddr_m_inf[2*ADDR_WIDTH-1:ADDR_WIDTH] = {4'd1, inst_cache_next_addr_r[11:8], 8'd0};

always @(*) begin
    if(arready_m_inf[1]) begin
        inst_arvalid_w = 0;
    end
    else if((inst_state_cs == IS_IDLE && inst_read_start) || (inst_state_cs == IS_INITIAL)) begin
        inst_arvalid_w = 1;
    end
    else begin
        inst_arvalid_w = arvalid_m_inf[1];
    end
end

always @(*) begin
    if(rlast_m_inf[1]) begin
        inst_rready_w = 0;
    end
    else if((inst_state_cs == IS_IDLE && inst_read_start) || (inst_state_cs == IS_INITIAL)) begin 
        inst_rready_w = 1;
    end
    else begin
        inst_rready_w = rready_m_inf[1];
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<2; i=i+1) arvalid_m_inf[i] <= 0;
        for(i=0; i<2; i=i+1) rready_m_inf[i] <= 0;
        awvalid_m_inf <= 0;
        wvalid_m_inf <= 0;
        wlast_m_inf <= 0;
        bready_m_inf <= 0;

        inst_rvalid_r <= 0; 
        data_rvalid_r <= 0;
        inst_cache_din_r <= 0;
        data_cache_din_r <= 0;
        wdata_m_inf <= 0;
    end
    else begin
        arvalid_m_inf[1] <= inst_arvalid_w;
        arvalid_m_inf[0] <= data_arvalid_w;
        rready_m_inf[1] <= inst_rready_w;
        rready_m_inf[0] <= data_rready_w;
        awvalid_m_inf <= data_awvalid_w;
        wvalid_m_inf <= data_wvalid_w;
        wlast_m_inf <= data_wlast_w;
        bready_m_inf <= data_bready_w;

        inst_rvalid_r <= rvalid_m_inf[1];
        data_rvalid_r <= rvalid_m_inf[0];
        inst_cache_din_r <= rdata_m_inf[2*DATA_WIDTH-1:DATA_WIDTH];
        data_cache_din_r <= rdata_m_inf[DATA_WIDTH-1:0];
        wdata_m_inf <= data_wdata_w;
    end
end

//read counter for inst_chache address
always @(*) begin
    if(inst_rvalid_r) begin 
        inst_read_addr_cnt_w = inst_read_addr_cnt_r + 1;
    end
    else begin
        inst_read_addr_cnt_w = inst_read_addr_cnt_r;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        inst_read_addr_cnt_r <= 0;
    end
    else begin
        inst_read_addr_cnt_r <= inst_read_addr_cnt_w;
    end
end

//instruction_cache_valid;
assign inst_cache_valid = (inst_state_cs == IS_IDLE);

//===========================================
//         instruction cache
//===========================================
assign inst_cache_addr = (inst_state_cs == IS_BUSY) ? inst_read_addr_cnt_r : inst_cache_next_addr_r[7:1];
assign inst_cache_we = ~inst_rvalid_r;      //0: write     1: read


m_Cache Inst_cache ( .clk(clk), .we(inst_cache_we), .address(inst_cache_addr), .di(inst_cache_din_r), .dout(inst_cache_dout) );   

//###########################################
//               Data-Sram
//###########################################
//===========================================
//         data cache FSM
//===========================================
reg data_write_back_cnt_r, data_write_back_cnt_w;
always @(*) begin
    case(data_state_cs)
        DS_IDLE: begin
            if(data_write_start)         data_state_ns = DS_WRITE_BUSY;
            else if(data_read_start)                 data_state_ns = DS_READ_BUSY;
            else                              data_state_ns = IS_IDLE;
        end
        DS_READ_BUSY: begin
            if(&data_readwrite_addr_cnt_r)          data_state_ns = DS_IDLE;
            else                                    data_state_ns = DS_READ_BUSY;
        end
        DS_WRITE_BUSY: begin
            if(wlast_m_inf) begin      
                if(data_read_start)
                    data_state_ns = DS_READ_BUSY;
                else
                    data_state_ns = DS_IDLE;
            end         
            else                                    
                data_state_ns = DS_WRITE_BUSY;
        end
        DS_INITIAL: begin
            data_state_ns = DS_READ_BUSY;
        end
        default: data_state_ns = DS_IDLE;
    endcase
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        data_state_cs <= 3;
    end
    else begin
        data_state_cs <= data_state_ns;
    end
end

//===========================================
//         data AXI 
//===========================================
//READ
assign araddr_m_inf[ADDR_WIDTH-1:0] = {4'd1, data_cache_next_addr_r[11:8], 8'd0};

always @(*) begin
    if(arready_m_inf[0]) begin
        data_arvalid_w = 0;
    end
    else if(data_state_cs != DS_READ_BUSY  && data_state_ns == DS_READ_BUSY) begin
        data_arvalid_w = 1;
    end
    else begin
        data_arvalid_w = arvalid_m_inf[0];
    end
end

always @(*) begin
    if(rlast_m_inf[0]) begin
        data_rready_w = 0;
    end
    else if(data_state_cs != DS_READ_BUSY  && data_state_ns == DS_READ_BUSY) begin 
        data_rready_w = 1;
    end
    else begin
        data_rready_w = rready_m_inf[0];
    end
end

//WRITE
assign awaddr_m_inf = {4'd1, data_save_frame_r, 8'd0};
always @(*) begin
    if((data_write_back_cnt_r) || (wready_m_inf))   
        data_wdata_w = data_cache_dout;
    else
        data_wdata_w = wdata_m_inf;
end

always @(*) begin
    if(awready_m_inf) begin
        data_awvalid_w = 0;
    end
    else if(data_state_cs == DS_IDLE && data_write_start) begin
        data_awvalid_w = 1;
    end
    else begin
        data_awvalid_w = awvalid_m_inf;
    end
end

always @(*) begin
    if(wlast_m_inf) begin   
        data_wvalid_w = 0;
    end
    else if(awready_m_inf) begin
        data_wvalid_w = 1;
    end
    else begin
        data_wvalid_w = wvalid_m_inf;
    end
end

always @(*) begin
    if(data_state_cs == DS_WRITE_BUSY && (&data_readwrite_addr_cnt_r)) begin
        data_wlast_w = 1;
    end
    else begin
        data_wlast_w = 0;
    end
end

always @(*) begin
    if(bvalid_m_inf) begin
        data_bready_w = 0;
    end
    else if(wlast_m_inf) begin 
        data_bready_w = 1;
    end
    else begin
        data_bready_w = bready_m_inf;
    end
end

//Other signal
always @(*) begin
    if(data_state_cs == DS_IDLE && data_read_start) begin
        data_cache_valid_flg_w = 0;
    end
    else if(data_state_cs == DS_READ_BUSY && (&data_readwrite_addr_cnt_r)) begin
        data_cache_valid_flg_w = 1;
    end
    else begin
        data_cache_valid_flg_w = data_cache_valid_flg_r;
    end
end

always @(*) begin
    if(data_state_cs == DS_IDLE && data_write_start) begin
        data_write_finish_flg_w = 0;
    end
    else if(wlast_m_inf) begin      
        data_write_finish_flg_w = 1;
    end
    else begin
        data_write_finish_flg_w = data_write_finish_flg_r;
    end
end

always @(*) begin
    if(data_state_cs == DS_READ_BUSY && data_rvalid_r) begin
        data_readwrite_addr_cnt_w = data_readwrite_addr_cnt_r + 1;
    end
    else if(data_state_cs == DS_WRITE_BUSY) begin
        if(data_readwrite_addr_cnt_r == 0 || (wready_m_inf))    
            data_readwrite_addr_cnt_w = data_readwrite_addr_cnt_r + 1;
        else 
            data_readwrite_addr_cnt_w = data_readwrite_addr_cnt_r;
    end
    else begin
        data_readwrite_addr_cnt_w = 0;
    end
end

always @(*) begin
    if(data_state_cs == DS_IDLE && data_write_start)
        data_write_back_cnt_w = 1;
    else 
        data_write_back_cnt_w = 0;
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        data_cache_valid_flg_r <= 0;
        data_write_finish_flg_r <= 0;
        data_readwrite_addr_cnt_r <= 0;
        data_write_back_cnt_r <= 0;
    end
    else begin
        data_cache_valid_flg_r <= data_cache_valid_flg_w;
        data_write_finish_flg_r <= data_write_finish_flg_w;
        data_readwrite_addr_cnt_r <= data_readwrite_addr_cnt_w;
        data_write_back_cnt_r <= data_write_back_cnt_w;
    end
end

//===========================================
//         data cache
//===========================================
assign data_cache_di_from_main = rt_decode_r;

always @(*) begin
    if(main_state_cs == MEM_READ_ONLY || main_state_cs == MEM_WRITE_READ)    
        data_cache_addr_from_main = data_cache_next_addr_r[7:1];
    else
        data_cache_addr_from_main = load_store_addr_exe[7:1];
end

always @(*) begin
    if((main_state_cs == MEM && opcode[0] && data_hit) || (main_state_cs == MEM_WRITE_READ && opcode[0] && data_cache_valid_flg_r))
        data_cache_we_from_main = 0;
    else
        data_cache_we_from_main = 1;
end

always @(*) begin
    if(wready_m_inf) begin  
        data_cache_addr = data_readwrite_addr_cnt_w;
    end
    else if(data_state_cs != DS_IDLE || (data_state_cs == DS_IDLE && data_write_start)) begin    
        data_cache_addr = data_readwrite_addr_cnt_r;
    end
    else begin
        data_cache_addr = data_cache_addr_from_main;
    end
end

always @(*) begin
    case(data_state_cs)
        DS_READ_BUSY:  data_cache_we = ~data_rvalid_r;              //0: write     1: read
        DS_WRITE_BUSY: data_cache_we = 1;
        default: data_cache_we = data_cache_we_from_main;
    endcase
end

always @(*) begin
    if(data_state_cs == DS_READ_BUSY) begin
        data_cache_din = data_cache_din_r;
    end
    else begin
        data_cache_din = data_cache_di_from_main;
    end
end

m_Cache Data_cache ( .clk(clk), .we(data_cache_we), .address(data_cache_addr), .di(data_cache_din), .dout(data_cache_dout) );

//###########################################
//               Main-Design
//###########################################
reg inst_prediction_r, inst_prediction_w;
//FSM
always @(*) begin
    case(main_state_cs)
        INST_FETCH: begin
            if(inst_prediction_r) 
                main_state_ns = INST_DECODE;
            else if(!inst_cache_valid && (inst_cache_next_addr_r[7:1] == inst_read_addr_cnt_r[6:0] && inst_rvalid_r)) 
                main_state_ns = INST_DECODE;
            else if(inst_cache_valid && inst_hit && exe_cnt_r[0])
                main_state_ns = INST_DECODE;
            else
                main_state_ns = INST_FETCH;
        end
        INST_DECODE: begin
            main_state_ns = EXECUTE;
        end
        EXECUTE: begin
            case(opcode)
                3'b001: begin   //MULT
                    if((func && exe_cnt_r[0]) || ~func)      main_state_ns = WRITE_REG_FILE;
                    else                                     main_state_ns = EXECUTE;
                end 
                3'b010, 3'b011: begin   //LOAD, STORE
                    main_state_ns = MEM;
                end
                3'b111: begin   //DET
                    if(exe_cnt_r == 19)      main_state_ns = WRITE_REG_FILE;
                    else                     main_state_ns = EXECUTE;
                end
                default: main_state_ns = WRITE_REG_FILE;
            endcase
        end
        MEM: begin
                case({data_cache_valid_flg_r, data_hit})
                    2'b11: begin
                        main_state_ns = WRITE_REG_FILE;
                    end
                    2'b10: begin
                        if(data_cache_dirty_r)
                            main_state_ns = MEM_WRITE_READ;
                        else
                            main_state_ns = MEM_READ_ONLY;
                    end 
                    default: main_state_ns = MEM;
                endcase
        end
        MEM_READ_ONLY: begin
            if(data_cache_valid_flg_r) 
                main_state_ns = WRITE_REG_FILE;
            else
                main_state_ns = MEM_READ_ONLY;
        end
        MEM_WRITE_READ: begin
            if(data_cache_valid_flg_r) 
                main_state_ns = WRITE_REG_FILE;
            else
                main_state_ns = MEM_WRITE_READ;
        end
        WRITE_REG_FILE: begin
            if(inst_10_cnt_r == 9 && data_cache_dirty_r)
                main_state_ns = WRITE_BACK;
            else
                main_state_ns = INST_FETCH;
        end
        WRITE_BACK: begin
            if(data_write_finish_flg_r)
                main_state_ns = INST_FETCH;
            else
                main_state_ns = WRITE_BACK;
        end
      default: main_state_ns = INST_FETCH;
    endcase
end

always @(*) begin
    if(main_state_cs == WRITE_REG_FILE) begin
        if(inst_10_cnt_r == 9)
            inst_10_cnt_w = 0;
        else
            inst_10_cnt_w = inst_10_cnt_r + 1;
    end
    else begin
        inst_10_cnt_w = inst_10_cnt_r;
    end
end

always @(*) begin
    if((main_state_cs == EXECUTE || main_state_cs == MEM_WRITE_READ || main_state_cs == MEM_READ_ONLY) && opcode == STORE) begin
        data_cache_dirty_w = 1;
    end
    else if(awvalid_m_inf) begin
        data_cache_dirty_w = 0;
    end
    else begin
        data_cache_dirty_w = data_cache_dirty_r;
    end
end

always @(*) begin
    if(main_state_cs == WRITE_REG_FILE && inst_cache_valid && inst_hit) begin
        if(opcode == BRANCH && equal_exe) 
            inst_prediction_w = 0;
        else 
            inst_prediction_w = 1;
    end
    else if(main_state_cs == INST_FETCH) begin
        inst_prediction_w = 0;
    end
    else begin
        inst_prediction_w = inst_prediction_r;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        main_state_cs <= 0;
        inst_10_cnt_r <= 0;
        data_cache_dirty_r <= 0;
        inst_prediction_r <= 0;
    end
    else begin
        main_state_cs <= main_state_ns;
        inst_10_cnt_r <= inst_10_cnt_w;
        data_cache_dirty_r <= data_cache_dirty_w;
        inst_prediction_r <= inst_prediction_w;
    end
end

//===========================================
//         cache read write start 
//===========================================
always @(*) begin
    if(main_state_cs == INST_FETCH && ~inst_hit) begin
        inst_read_start = 1;
    end
    else begin
        inst_read_start = 0;
    end
end

always @(*) begin
    if((main_state_cs == MEM && main_state_ns == MEM_READ_ONLY) || (main_state_cs == MEM && main_state_ns == MEM_WRITE_READ) || (main_state_cs == MEM_WRITE_READ && ~data_write_finish_flg_r)) begin 
        data_read_start = 1;                                                                                
    end
    else begin
        data_read_start = 0;
    end
end

always @(*) begin
    if((main_state_cs == MEM && main_state_ns == MEM_WRITE_READ) || (main_state_cs == WRITE_REG_FILE && main_state_ns == WRITE_BACK)) begin
        data_write_start = 1;                                                                                                        
    end
    else begin
        data_write_start = 0;
    end
end

//===========================================
//         cache read write signal 
//===========================================
//instruction cache signal
assign inst_hit = (inst_save_frame_r == inst_cache_next_addr_r[11:8]);

always @(*) begin
    if(main_state_cs == INST_DECODE) begin
        inst_cache_next_addr_w = inst_cache_next_addr_r + 2;
    end
    else if(main_state_cs == WRITE_REG_FILE) begin
        if(opcode == BRANCH && equal_exe) begin
            inst_cache_next_addr_w = inst_cache_next_addr_r + (immediate << 1);
        end
        else begin
            inst_cache_next_addr_w = inst_cache_next_addr_r;
        end
    end
    else begin
        inst_cache_next_addr_w = inst_cache_next_addr_r;
    end
end

always @(*) begin
    if(main_state_cs == INST_FETCH && ~inst_hit && inst_cache_valid) begin
        inst_save_frame_w = inst_cache_next_addr_r[11:8];
    end
    else begin
        inst_save_frame_w = inst_save_frame_r;
    end
end

//data cache signal
assign data_hit = (data_save_frame_r == load_store_addr_exe[11:8]);

always @(*) begin
    if(main_state_cs == MEM) begin
        data_cache_next_addr_w = load_store_addr_exe;
    end
    else begin
        data_cache_next_addr_w = data_cache_next_addr_r;
    end
end

always @(*) begin
    if(arvalid_m_inf[0]) begin
        data_save_frame_w = load_store_addr_exe[11:8];
    end
    else begin
        data_save_frame_w = data_save_frame_r;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        inst_cache_next_addr_r <= 16'h0000;
        data_cache_next_addr_r <= 16'h0000;
        inst_save_frame_r <= 0;
        data_save_frame_r <= 0;
    end
    else begin
        inst_cache_next_addr_r <= inst_cache_next_addr_w;
        data_cache_next_addr_r <= data_cache_next_addr_w;
        inst_save_frame_r <= inst_save_frame_w;
        data_save_frame_r <= data_save_frame_w;
    end
end

//===========================================
//         instruction decode 
//===========================================
always @(*) begin
    if(main_state_cs == INST_DECODE) begin
        inst_cache_out_w = inst_cache_dout;
    end
    else if(main_state_cs == INST_FETCH && (inst_cache_next_addr_r[7:1] == inst_read_addr_cnt_r[6:0] && inst_rvalid_r)) begin
        inst_cache_out_w = inst_cache_din_r;
    end
    else begin
        inst_cache_out_w = inst_cache_out_r;
    end
end

assign opcode = inst_cache_out_r[15:13];
assign rs = inst_cache_out_r[12:9];
assign rt = inst_cache_out_r[8:5];
assign rd = inst_cache_out_r[4:1];
assign func = inst_cache_out_r[0];
assign immediate = inst_cache_out_r[4:0];
assign coeff_a = inst_cache_out_r[12:9];
assign coeff_b = inst_cache_out_r[8:0];

always @(*) begin
    case(rs)
        0:  rs_decode_w = core_r0;
        1:  rs_decode_w = core_r1;
        2:  rs_decode_w = core_r2;
        3:  rs_decode_w = core_r3;
        4:  rs_decode_w = core_r4;
        5:  rs_decode_w = core_r5;
        6:  rs_decode_w = core_r6;
        7:  rs_decode_w = core_r7;
        8:  rs_decode_w = core_r8;
        9:  rs_decode_w = core_r9;
        10: rs_decode_w = core_r10;
        11: rs_decode_w = core_r11;
        12: rs_decode_w = core_r12;
        13: rs_decode_w = core_r13;
        14: rs_decode_w = core_r14;
        15: rs_decode_w = core_r15;
    endcase
end

always @(*) begin
    case(rt)
        0:  rt_decode_w = core_r0;
        1:  rt_decode_w = core_r1;
        2:  rt_decode_w = core_r2;
        3:  rt_decode_w = core_r3;
        4:  rt_decode_w = core_r4;
        5:  rt_decode_w = core_r5;
        6:  rt_decode_w = core_r6;
        7:  rt_decode_w = core_r7;
        8:  rt_decode_w = core_r8;
        9:  rt_decode_w = core_r9;
        10: rt_decode_w = core_r10;
        11: rt_decode_w = core_r11;
        12: rt_decode_w = core_r12;
        13: rt_decode_w = core_r13;
        14: rt_decode_w = core_r14;
        15: rt_decode_w = core_r15;
    endcase
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        inst_cache_out_r <= 0;
        rs_decode_r <= 0;
        rt_decode_r <= 0;
    end
    else begin
        inst_cache_out_r <= inst_cache_out_w;
        rs_decode_r <= rs_decode_w;
        rt_decode_r <= rt_decode_w;
    end
end

//===========================================
//         Execution-other 
//===========================================
reg [15:0] rd_data_next;

assign add_exe = rs_decode_r + rt_decode_r;
assign sub_exe = rs_decode_r - rt_decode_r;
assign slt_exe = (rs_decode_r < rt_decode_r);
assign equal_exe = (rs_decode_r == rt_decode_r);
assign load_store_addr_exe = ((rs_decode_r + immediate) << 1);

DW02_mult_2_stage #(16, 16) U_multi 
(   .A(rs_decode_r),    
    .B(rt_decode_r),
    .TC(1'd1),          
    .CLK(clk),          
    .PRODUCT(multi_exe) );


always @(*) begin
    case({opcode[0], func})
        2'b00: rd_data_next = add_exe;
        2'b01: rd_data_next = sub_exe;
        2'b10: rd_data_next = slt_exe;
        2'b11: rd_data_next = multi_exe;
    endcase
end

//Gobal cnt
wire [4:0] exe_cnt_tmp;
assign exe_cnt_tmp = exe_cnt_r + 1;
always @(*) begin
    case(main_state_cs)
        INST_FETCH: begin
            if(inst_cache_valid && inst_hit)
                exe_cnt_w = exe_cnt_tmp;
            else
                exe_cnt_w = 0;
        end
        EXECUTE: begin
            if((opcode == SLTMULT && func) || opcode == DET)
                exe_cnt_w = exe_cnt_tmp;
            else
                exe_cnt_w = 0;
        end
        default: exe_cnt_w = 0;
    endcase
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        exe_cnt_r <= 0;
    end
    else begin
        exe_cnt_r <= exe_cnt_w;
    end
end

//===========================================
//         Execution-DET 
//===========================================
reg [1:0] det_shift_cnt_r, det_shift_cnt_w;
reg [1:0] det_mode_cnt_r, det_mode_cnt_w;
reg det_addsub_cnt_r, det_addsub_cnt_w;

reg signed [15:0] det_firstgroup_in_1, det_firstgroup_in_2, det_firstgroup_in_3;
reg signed [15:0] det_sendgroup_in_1, det_sendgroup_in_2, det_sendgroup_in_3;

wire signed [31:0] det_firstgroup_32out_0_w, det_firstgroup_32out_1_w, det_sendgroup_32out_0_w, det_sendgroup_32out_1_w;
reg signed [31:0] det_firstgroup_32out_0_r, det_firstgroup_32out_1_r, det_sendgroup_32out_0_r, det_sendgroup_32out_1_r;
wire signed [63:0] det_firstgroup_64out_w, det_sendgroup_64out_w;
reg signed [63:0] det_firstgroup_64out_r, det_sendgroup_64out_r;

reg signed [67:0] det_firstgroup_acc_r, det_firstgroup_acc_w;
reg signed [67:0] det_sendgroup_acc_r, det_sendgroup_acc_w;
reg signed [67:0] det_firstgroup_acc, det_sendgroup_acc;

reg signed [68:0] det_firstsend_add_r, det_firstsend_add_w;
reg signed [68:0] det_coeff_add_r, det_coeff_add_w;
reg signed [15:0] det_exe;

//first group

always @(*) begin
    case(det_mode_cnt_r)
        0: det_firstgroup_in_1 = core_r5;
        1: det_firstgroup_in_1 = core_r6;
        2: det_firstgroup_in_1 = core_r7;
        default: det_firstgroup_in_1 = core_r5;
    endcase
end

always @(*) begin
    case(det_mode_cnt_r)
        0: det_firstgroup_in_2 = core_r10;
        1: det_firstgroup_in_2 = core_r11;
        2: det_firstgroup_in_2 = core_r9;
        default: det_firstgroup_in_2 = core_r10;
    endcase
end

always @(*) begin
    case(det_mode_cnt_r)
        0: det_firstgroup_in_3 = core_r15;
        1: det_firstgroup_in_3 = core_r13;
        2: det_firstgroup_in_3 = core_r14;
        default: det_firstgroup_in_3 = core_r15;
    endcase
end

DW02_mult_2_stage #(16, 16) U_DET16B_1 
(   .A(core_r0),    
    .B(det_firstgroup_in_1),
    .TC(1'b1),
    .CLK(clk),
    .PRODUCT(det_firstgroup_32out_0_w) );

DW02_mult_2_stage #(16, 16) U_DET16B_2
(   .A(det_firstgroup_in_2),
    .B(det_firstgroup_in_3),
    .TC(1'b1),
    .CLK(clk),
    .PRODUCT(det_firstgroup_32out_1_w) );

DW02_mult_4_stage #(32, 32) U_DET32B_1
(   .A(det_firstgroup_32out_0_r),
    .B(det_firstgroup_32out_1_r),
    .TC(1'b1),
    .CLK(clk),
    .PRODUCT(det_firstgroup_64out_w) );

DW01_addsub #(68) U_DETADDSUB_1 
(   .A(det_firstgroup_acc_r), 
    .B({{4{det_firstgroup_64out_r[63]}}, det_firstgroup_64out_r}), 
    .CI(1'b0), 
    .ADD_SUB(det_addsub_cnt_r),                 //0: add 1:sub
    .SUM(det_firstgroup_acc), 
    .CO() );

always @(*) begin
    if(opcode == DET && main_state_cs == EXECUTE && exe_cnt_r > 5) begin
        det_firstgroup_acc_w = det_firstgroup_acc;
    end
    else begin
        det_firstgroup_acc_w = 0;
    end
end

//second group
always @(*) begin
    case(det_mode_cnt_r)
        0: det_sendgroup_in_1 = core_r4;
        1: det_sendgroup_in_1 = core_r7;
        2: det_sendgroup_in_1 = core_r6;
        default: det_sendgroup_in_1 = core_r4;
    endcase
end

always @(*) begin
    case(det_mode_cnt_r)
        0: det_sendgroup_in_2 = core_r11;
        1: det_sendgroup_in_2 = core_r10;
        2: det_sendgroup_in_2 = core_r8;
        default: det_sendgroup_in_2 = core_r11;
    endcase
end

always @(*) begin
    case(det_mode_cnt_r)
        0: det_sendgroup_in_3 = core_r14;
        1: det_sendgroup_in_3 = core_r12;
        2: det_sendgroup_in_3 = core_r15;
        default: det_sendgroup_in_3 = core_r14;
    endcase
end

DW02_mult_2_stage #(16, 16) U_DET16B_3 
(   .A(core_r1),                        
    .B(det_sendgroup_in_1),
    .TC(1'b1),
    .CLK(clk),
    .PRODUCT(det_sendgroup_32out_0_w) );

DW02_mult_2_stage #(16, 16) U_DET16B_4
(   .A(det_sendgroup_in_2),
    .B(det_sendgroup_in_3),
    .TC(1'b1),
    .CLK(clk),
    .PRODUCT(det_sendgroup_32out_1_w) );

DW02_mult_4_stage #(32, 32) U_DET32B_2
(   .A(det_sendgroup_32out_0_r),
    .B(det_sendgroup_32out_1_r),
    .TC(1'b1),
    .CLK(clk),
    .PRODUCT(det_sendgroup_64out_w) );

DW01_addsub #(68) U_DETADDSUB_2 
(   .A(det_sendgroup_acc_r), 
    .B({{4{det_sendgroup_64out_r[63]}}, det_sendgroup_64out_r} ),
    .CI(1'b0), 
    .ADD_SUB(det_addsub_cnt_r),                 //0: add 1:sub
    .SUM(det_sendgroup_acc), 
    .CO() );    

always @(*) begin
    if(opcode == DET && main_state_cs == EXECUTE && exe_cnt_r > 5) begin
        det_sendgroup_acc_w = det_sendgroup_acc;
    end
    else begin
        det_sendgroup_acc_w = 0;
    end
end    

//filter
wire [4:0] coeff_a_tmp; 
assign coeff_a_tmp = (coeff_a << 1);
always @(*) begin
    det_firstsend_add_w = det_firstgroup_acc_r + det_sendgroup_acc_r;
end

always @(*) begin
    if(opcode == DET && main_state_cs == EXECUTE && exe_cnt_r == 19)
        det_coeff_add_w = ((det_firstsend_add_r) >>> (coeff_a_tmp)) + $signed({1'b0, coeff_b});
    else if(main_state_cs == INST_FETCH) 
        det_coeff_add_w = 0;
    else 
        det_coeff_add_w = det_coeff_add_r;
end

always @(*) begin
    if(det_coeff_add_r > 32767) begin
        det_exe = 32767;
    end
    else if(det_coeff_add_r < -32768) begin
        det_exe = -32768;
    end
    else begin
        det_exe = det_coeff_add_r[15:0];
    end
end


//DET counter
always @(*) begin
    if(opcode == DET && main_state_cs == EXECUTE) begin
        det_shift_cnt_w = det_shift_cnt_r + 1;
    end
    else begin
        det_shift_cnt_w = 0;
    end
end

always @(*) begin
    if(opcode == DET && main_state_cs == EXECUTE) begin
        if(det_shift_cnt_r == 3)
            det_mode_cnt_w = det_mode_cnt_r + 1;
        else
            det_mode_cnt_w = det_mode_cnt_r;
    end
    else begin
        det_mode_cnt_w = 0;
    end
end

always @(*) begin
    if(opcode == DET && main_state_cs == EXECUTE && exe_cnt_r > 5) begin
        det_addsub_cnt_w = det_addsub_cnt_r + 1;    //0: add 1:sub
    end
    else begin
        det_addsub_cnt_w = 0;
    end
end

//reg
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        det_firstsend_add_r <= 0;
        det_coeff_add_r <= 0;
    end
    else begin
        det_firstsend_add_r <= det_firstsend_add_w;
        det_coeff_add_r <= det_coeff_add_w;
    end
end
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        det_shift_cnt_r <= 0;
        det_mode_cnt_r <= 0;
        det_addsub_cnt_r <= 0;

        det_firstgroup_32out_0_r <= 0;
        det_firstgroup_32out_1_r <= 0;
        det_sendgroup_32out_0_r <= 0;
        det_sendgroup_32out_1_r <= 0;
        det_firstgroup_64out_r <= 0;
        det_sendgroup_64out_r <= 0;
        det_firstgroup_acc_r <= 0;
        det_sendgroup_acc_r <= 0;
    end
    else begin
        det_shift_cnt_r <= det_shift_cnt_w;
        det_mode_cnt_r <= det_mode_cnt_w;
        det_addsub_cnt_r <= det_addsub_cnt_w;

        det_firstgroup_32out_0_r <= det_firstgroup_32out_0_w;
        det_firstgroup_32out_1_r <= det_firstgroup_32out_1_w;
        det_sendgroup_32out_0_r <= det_sendgroup_32out_0_w;
        det_sendgroup_32out_1_r <= det_sendgroup_32out_1_w;
        det_firstgroup_64out_r <= det_firstgroup_64out_w;
        det_sendgroup_64out_r <= det_sendgroup_64out_w;
        det_firstgroup_acc_r <= det_firstgroup_acc_w;
        det_sendgroup_acc_r <= det_sendgroup_acc_w;
    end
end  

//===========================================
//         REG file 
//===========================================
reg [15:0] core_r0_w, core_r1_w, core_r2_w, core_r3_w;
reg [15:0] core_r4_w, core_r5_w, core_r6_w, core_r7_w;
reg [15:0] core_r8_w, core_r9_w, core_r10_w, core_r11_w;
reg [15:0] core_r12_w, core_r13_w, core_r14_w, core_r15_w;

always @(*) begin
    if(main_state_cs == WRITE_REG_FILE && (opcode[1:0] == 2'b10) && rt == 0) 
        core_r0_w = data_cache_dout;
    else if(main_state_cs == WRITE_REG_FILE && (opcode[2:1] == 0) && rd == 0) 
        core_r0_w = rd_data_next;
    else if(main_state_cs == WRITE_REG_FILE && opcode == DET)
        core_r0_w = det_exe;
    else if(main_state_cs == EXECUTE && opcode == DET && exe_cnt_r < 12)
        core_r0_w = core_r1;
    else
        core_r0_w = core_r0;
end

always @(*) begin
    if(main_state_cs == WRITE_REG_FILE && (opcode[1:0] == 2'b10) && rt == 1)
        core_r1_w = data_cache_dout;
    else if(main_state_cs == WRITE_REG_FILE && (opcode[2:1] == 0) && rd == 1)
        core_r1_w = rd_data_next;
    else if(main_state_cs == EXECUTE && opcode == DET && exe_cnt_r < 12)
        core_r1_w = core_r2;
    else
        core_r1_w = core_r1;
end

always @(*) begin
    if(main_state_cs == WRITE_REG_FILE && (opcode[1:0] == 2'b10) && rt == 2)
        core_r2_w = data_cache_dout;
    else if(main_state_cs == WRITE_REG_FILE && (opcode[2:1] == 0) && rd == 2)
        core_r2_w = rd_data_next;
    else if(main_state_cs == EXECUTE && opcode == DET && exe_cnt_r < 12)
        core_r2_w = core_r3;
    else
        core_r2_w = core_r2;
end

always @(*) begin
    if(main_state_cs == WRITE_REG_FILE && (opcode[1:0] == 2'b10) && rt == 3)
        core_r3_w = data_cache_dout;
    else if(main_state_cs == WRITE_REG_FILE && (opcode[2:1] == 0) && rd == 3)
        core_r3_w = rd_data_next;
    else if(main_state_cs == EXECUTE && opcode == DET && exe_cnt_r < 12)
        core_r3_w = core_r0;
    else
        core_r3_w = core_r3;
end

always @(*) begin
    if(main_state_cs == WRITE_REG_FILE && (opcode[1:0] == 2'b10) && rt == 4)
        core_r4_w = data_cache_dout;
    else if(main_state_cs == WRITE_REG_FILE && (opcode[2:1] == 0) && rd == 4)
        core_r4_w = rd_data_next;
    else if(main_state_cs == EXECUTE && opcode == DET && exe_cnt_r < 12)
        core_r4_w = core_r5;
    else
        core_r4_w = core_r4;
end

always @(*) begin
    if(main_state_cs == WRITE_REG_FILE && (opcode[1:0] == 2'b10) && rt == 5)
        core_r5_w = data_cache_dout;
    else if(main_state_cs == WRITE_REG_FILE && (opcode[2:1] == 0) && rd == 5)
        core_r5_w = rd_data_next;
    else if(main_state_cs == EXECUTE && opcode == DET && exe_cnt_r < 12)
        core_r5_w = core_r6;
    else
        core_r5_w = core_r5;
end

always @(*) begin
    if(main_state_cs == WRITE_REG_FILE && (opcode[1:0] == 2'b10) && rt == 6)
        core_r6_w = data_cache_dout;
    else if(main_state_cs == WRITE_REG_FILE && (opcode[2:1] == 0) && rd == 6)
        core_r6_w = rd_data_next;
    else if(main_state_cs == EXECUTE && opcode == DET && exe_cnt_r < 12)
        core_r6_w = core_r7;
    else
        core_r6_w = core_r6;
end

always @(*) begin
    if(main_state_cs == WRITE_REG_FILE && (opcode[1:0] == 2'b10) && rt == 7)
        core_r7_w = data_cache_dout;
    else if(main_state_cs == WRITE_REG_FILE && (opcode[2:1] == 0) && rd == 7)
        core_r7_w = rd_data_next;
    else if(main_state_cs == EXECUTE && opcode == DET && exe_cnt_r < 12)
        core_r7_w = core_r4;
    else
        core_r7_w = core_r7;
end

always @(*) begin
    if(main_state_cs == WRITE_REG_FILE && (opcode[1:0] == 2'b10) && rt == 8)
        core_r8_w = data_cache_dout;
    else if(main_state_cs == WRITE_REG_FILE && (opcode[2:1] == 0) && rd == 8)
        core_r8_w = rd_data_next;
    else if(main_state_cs == EXECUTE && opcode == DET && exe_cnt_r < 12)
        core_r8_w = core_r9;
    else
        core_r8_w = core_r8;
end

always @(*) begin
    if(main_state_cs == WRITE_REG_FILE && (opcode[1:0] == 2'b10) && rt == 9)
        core_r9_w = data_cache_dout;
    else if(main_state_cs == WRITE_REG_FILE && (opcode[2:1] == 0) && rd == 9)
        core_r9_w = rd_data_next;
    else if(main_state_cs == EXECUTE && opcode == DET && exe_cnt_r < 12)
        core_r9_w = core_r10;
    else
        core_r9_w = core_r9;
end

always @(*) begin
    if(main_state_cs == WRITE_REG_FILE && (opcode[1:0] == 2'b10) && rt == 10)
        core_r10_w = data_cache_dout;
    else if(main_state_cs == WRITE_REG_FILE && (opcode[2:1] == 0) && rd == 10)
        core_r10_w = rd_data_next;
    else if(main_state_cs == EXECUTE && opcode == DET && exe_cnt_r < 12)
        core_r10_w = core_r11;
    else
        core_r10_w = core_r10;
end

always @(*) begin
    if(main_state_cs == WRITE_REG_FILE && (opcode[1:0] == 2'b10) && rt == 11)
        core_r11_w = data_cache_dout;
    else if(main_state_cs == WRITE_REG_FILE && (opcode[2:1] == 0) && rd == 11)
        core_r11_w = rd_data_next;
    else if(main_state_cs == EXECUTE && opcode == DET && exe_cnt_r < 12)
        core_r11_w = core_r8;
    else
        core_r11_w = core_r11;
end

always @(*) begin
    if(main_state_cs == WRITE_REG_FILE && (opcode[1:0] == 2'b10) && rt == 12)
        core_r12_w = data_cache_dout;
    else if(main_state_cs == WRITE_REG_FILE && (opcode[2:1] == 0) && rd == 12)
        core_r12_w = rd_data_next;
    else if(main_state_cs == EXECUTE && opcode == DET && exe_cnt_r < 12)
        core_r12_w = core_r13;
    else
        core_r12_w = core_r12;
end

always @(*) begin
    if(main_state_cs == WRITE_REG_FILE && (opcode[1:0] == 2'b10) && rt == 13)
        core_r13_w = data_cache_dout;
    else if(main_state_cs == WRITE_REG_FILE && (opcode[2:1] == 0) && rd == 13)
        core_r13_w = rd_data_next;
    else if(main_state_cs == EXECUTE && opcode == DET && exe_cnt_r < 12)
        core_r13_w = core_r14;
    else
        core_r13_w = core_r13;
end

always @(*) begin
    if(main_state_cs == WRITE_REG_FILE && (opcode[1:0] == 2'b10) && rt == 14)
        core_r14_w = data_cache_dout;
    else if(main_state_cs == WRITE_REG_FILE && (opcode[2:1] == 0) && rd == 14)
        core_r14_w = rd_data_next;
    else if(main_state_cs == EXECUTE && opcode == DET && exe_cnt_r < 12)
        core_r14_w = core_r15;
    else
        core_r14_w = core_r14;
end

always @(*) begin
    if(main_state_cs == WRITE_REG_FILE && (opcode[1:0] == 2'b10) && rt == 15)
        core_r15_w = data_cache_dout;
    else if(main_state_cs == WRITE_REG_FILE && (opcode[2:1] == 0) && rd == 15)
        core_r15_w = rd_data_next;
    else if(main_state_cs == EXECUTE && opcode == DET && exe_cnt_r < 12)
        core_r15_w = core_r12;
    else
        core_r15_w = core_r15;
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        core_r0 <= 0;
        core_r1 <= 0;
        core_r2 <= 0;
        core_r3 <= 0;
        core_r4 <= 0;
        core_r5 <= 0;
        core_r6 <= 0;
        core_r7 <= 0;
        core_r8 <= 0;
        core_r9 <= 0;
        core_r10 <= 0;
        core_r11 <= 0;
        core_r12 <= 0;
        core_r13 <= 0;
        core_r14 <= 0;
        core_r15 <= 0;
    end
    else begin
        core_r0 <= core_r0_w;
        core_r1 <= core_r1_w;
        core_r2 <= core_r2_w;
        core_r3 <= core_r3_w;
        core_r4 <= core_r4_w;
        core_r5 <= core_r5_w;
        core_r6 <= core_r6_w;
        core_r7 <= core_r7_w;
        core_r8 <= core_r8_w;
        core_r9 <= core_r9_w;
        core_r10 <= core_r10_w;
        core_r11 <= core_r11_w;
        core_r12 <= core_r12_w;
        core_r13 <= core_r13_w;
        core_r14 <= core_r14_w;
        core_r15 <= core_r15_w;
    end
end

//output
reg IO_stall_w;

always @(*) begin
    if(main_state_cs != INST_FETCH && main_state_ns == INST_FETCH) begin
        IO_stall_w = 0;
    end
    else begin
        IO_stall_w = 1;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        IO_stall <= 1;
    end
    else begin
        IO_stall <= IO_stall_w;
    end
end

endmodule

module m_Cache (
    input clk,
    input we,
    input [6:0] address,
    input [15:0] di,
    output [15:0] dout
);

SUMA180_128W16B U_ram(  .A0(address[0]), .A1(address[1]), .A2(address[2]), .A3(address[3]), .A4(address[4]), 
                        .A5(address[5]), .A6(address[6]), 

                        .DO0(dout[0]), .DO1(dout[1]), .DO2(dout[2]), .DO3(dout[3]), .DO4(dout[4]), .DO5(dout[5]), .DO6(dout[6]), .DO7(dout[7]),
                        .DO8(dout[8]), .DO9(dout[9]), .DO10(dout[10]), .DO11(dout[11]), .DO12(dout[12]), .DO13(dout[13]), .DO14(dout[14]), .DO15(dout[15]),

                        .DI0(di[0]), .DI1(di[1]), .DI2(di[2]), .DI3(di[3]), .DI4(di[4]), .DI5(di[5]), .DI6(di[6]), .DI7(di[7]),
                        .DI8(di[8]), .DI9(di[9]), .DI10(di[10]), .DI11(di[11]), .DI12(di[12]), .DI13(di[13]), .DI14(di[14]), .DI15(di[15]),

                        .CK(clk), .WEB(we), .OE(1'b1), .CS(1'b1));
endmodule















