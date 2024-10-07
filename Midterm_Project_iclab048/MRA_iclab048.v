//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Spring
//   Midterm Proejct            : MRA  
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MRA.v
//   Module Name : MRA
//	 new V5 (已解決in30_pat21)
//   Area: 2493074
//   period: 15
//   敘述:
//   1. 修復03出現X
//   2. 修復跑出邊界
//   3. 修復ST在隔壁
//   4. 更改V1寫法
//   5. 修復loc pop 0
//   6. input30的pattern21問題(fix)
//   7. 最終版上船載回
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module MRA(
	// CHIP IO
	clk            	,	
	rst_n          	,	
	in_valid       	,	
	frame_id        ,	
	net_id         	,	  
	loc_x          	,	  
    loc_y         	,
	cost	 		,		
	busy         	,

    // AXI4 IO
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
	   rready_m_inf,
	
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
	   bready_m_inf 
);

// ===============================================================
//  					Input / Output 
// ===============================================================
//parameter AXI
parameter ID_WIDTH=4, ADDR_WIDTH=32, DATA_WIDTH=128;

// << CHIP io port with system >>
input 			  	clk,rst_n;
input 			   	in_valid;
input  [4:0] 		frame_id;
input  [3:0]       	net_id;     
input  [5:0]       	loc_x; 
input  [5:0]       	loc_y; 
output wire [13:0] 	cost;
output reg          busy;       
  
// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       Your AXI-4 interface could be designed as a bridge in submodule,
	   therefore I declared output of AXI as wire.  
	   Ex: AXI4_interface AXI4_INF(...);
*/

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output wire [7:0]              arlen_m_inf;

output reg                  arvalid_m_inf;
output wire [ADDR_WIDTH-1:0]  araddr_m_inf;
input  wire                  arready_m_inf;
// ------------------------
// (2)	axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;

input  wire                    rlast_m_inf;
input  wire [1:0]              rresp_m_inf;

output reg                   rready_m_inf;
input  wire                   rvalid_m_inf;
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [7:0]              awlen_m_inf;

output reg                  awvalid_m_inf;
input  wire                  awready_m_inf;
output wire [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)	axi write data channel 
output reg                   wvalid_m_inf;
input  wire                   wready_m_inf;
output reg [DATA_WIDTH-1:0]   wdata_m_inf;
output reg                    wlast_m_inf;
// -------------------------
// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output reg                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------

// ===============================================================
//  					Reg / Wire 
// ===============================================================
integer i;
integer j;
//AXI
parameter IDLE_A = 0, AR_READ = 1, READ = 2, AW_WRITE = 3, PRELOAD = 4, WRITE = 5, RESP = 6;
parameter IDLE = 0,	WAIT_F = 1, FILL = 2, RETRA = 3, WAIT_W = 4, READ_S = 5, WAIT_S = 6, CAL = 7, REFRESH = 8, WRITE_D = 9, OUT = 10;
//AXI
reg [2:0] axi_state_cs, axi_state_ns;
reg [7:0] axi_cnt_r, axi_cnt_w;
reg arvalid_m_inf_w, rready_m_inf_w, awvalid_m_inf_w, wvalid_m_inf_w, wlast_m_inf_w, bready_m_inf_w;
reg axi_read_flag, axi_write_flag;
wire [31:0] read_addr, frame_addr, weight_addr;

wire [127:0] dout_frame, dout_weight;
reg [4:0] frame_id_r, frame_id_w;

wire [6:0] addgen_y, addgen_x, retrace_addr;
reg [127:0] retrace_data;
reg retrace_finish;

reg [127:0] fsr_dout_r, fsr_dout_w, wsr_dout_w, wsr_dout_r;
wire [4:0] retrace_deal;
reg [2:0] preload_cnt_r, preload_cnt_w;
reg wready_m_inf_r;
reg [3:0] state_cs, state_ns;
reg fill_finish_spe;
// ===============================================================
//  					AXI Interface
// ===============================================================
// (1)	axi read address channel 
assign arid_m_inf = 3'd0;
assign arburst_m_inf = 2'b01;
assign arsize_m_inf = 3'b100;
assign arlen_m_inf = 8'd127;
// (1) 	axi write address channel 
assign awid_m_inf = 3'd0;
assign awburst_m_inf = 2'b01;
assign awsize_m_inf = 3'b100;
assign awlen_m_inf = 8'd127;


always @(*) begin
	case (axi_state_cs)
		IDLE_A: begin //0
			if(axi_read_flag) 		axi_state_ns = AR_READ;
			else if(axi_write_flag) axi_state_ns = AW_WRITE;
			else 					axi_state_ns = IDLE_A;
		end
		AR_READ: begin //1
			if(arvalid_m_inf && arready_m_inf) axi_state_ns = READ;
			else 							   axi_state_ns = AR_READ;
		end
		READ: begin //2
			if(rvalid_m_inf && rready_m_inf && rlast_m_inf) axi_state_ns = IDLE_A;
			else 										    axi_state_ns = READ;
		end
		AW_WRITE: begin //3
			if(awvalid_m_inf && awready_m_inf) axi_state_ns = PRELOAD;
			else 							   axi_state_ns = AW_WRITE;
		end
		PRELOAD: begin //4
			if(preload_cnt_r == 3) axi_state_ns = WRITE;
			else 			   axi_state_ns = PRELOAD;
		end
		WRITE: begin //5
			if(wvalid_m_inf && wready_m_inf_r && (axi_cnt_r == 127))   axi_state_ns = RESP; //counter 資訊未填
			else 							   						axi_state_ns = WRITE;
		end
		RESP: begin
			if(bvalid_m_inf && bready_m_inf) axi_state_ns = IDLE_A;
			else 							 axi_state_ns = RESP;
		end
		default: axi_state_ns = IDLE_A;
	endcase
end

assign frame_addr = frame_id_r ? (32'h0001_0000 | (32'h0000_0800 * (frame_id_r))) : 32'h0001_0000 ;
assign weight_addr = frame_id_r ? (32'h0002_0000 | (32'h0000_0800 * (frame_id_r))) : 32'h0002_0000 ;

assign read_addr = axi_cnt_r[7] ? weight_addr : frame_addr;
//
assign araddr_m_inf = read_addr;
assign awaddr_m_inf = frame_addr;


//AR_channel
always @(*) begin
    if(axi_state_cs == AR_READ) begin
        if(arvalid_m_inf && arready_m_inf) begin
            arvalid_m_inf_w = 0;
        end
        else begin
            arvalid_m_inf_w = 1;
        end 
    end
    else begin
        arvalid_m_inf_w = 0;
    end
end

//R_channel
always @(*) begin
    if(axi_state_cs == READ) begin
        if(rvalid_m_inf && rready_m_inf && rlast_m_inf) begin //數到127
			rready_m_inf_w = 0;
		end
        else begin
			rready_m_inf_w = 1;
		end
    end
    else begin
        rready_m_inf_w = 0;
    end
end

//AW_channel
always @(*) begin
    if(axi_state_cs == AW_WRITE) begin
        if(awvalid_m_inf && awready_m_inf) begin
            awvalid_m_inf_w = 0;
        end
        else begin
            awvalid_m_inf_w = 1;
        end 
    end
    else begin
        awvalid_m_inf_w = 0;
    end
end
//W_channel
always @(*) begin
    if(axi_state_cs == WRITE) begin
        if(wvalid_m_inf && wready_m_inf_r) begin
			if(axi_cnt_r == 126) begin
				wlast_m_inf_w = 1;
				wvalid_m_inf_w = 1;
			end
			else if(axi_cnt_r == 127) begin
				wlast_m_inf_w = 0;
				wvalid_m_inf_w = 0;
			end
			else begin
				wlast_m_inf_w = 0;
				wvalid_m_inf_w = 1;
			end
        end
        else begin
			wlast_m_inf_w = 0;
            wvalid_m_inf_w = 1; 
        end        
    end
    else begin
		wlast_m_inf_w = 0;
        wvalid_m_inf_w = 0; 
    end
end

always @(*) begin
	if(axi_state_cs == WRITE && wvalid_m_inf && wready_m_inf_r) begin
		if(axi_cnt_r == 1) begin
			wdata_m_inf = wsr_dout_r;
		end
		else begin
			wdata_m_inf = fsr_dout_r;
		end
	end
	else begin
		wdata_m_inf = fsr_dout_r;
	end
end
//WB channel
always @(*) begin
    if(axi_state_cs == RESP) begin
        if(bvalid_m_inf && bready_m_inf) begin
			bready_m_inf_w = 0;
		end
		else begin
			bready_m_inf_w = 1;
		end
    end
    else 
        bready_m_inf_w = 0;
end

//store counter
always @(*) begin
	if((rvalid_m_inf && rready_m_inf)) begin
		axi_cnt_w = axi_cnt_r + 1;
	end
	else if(axi_state_cs == AW_WRITE || axi_state_cs == RESP)begin
		axi_cnt_w = 0;
	end
	else if(axi_state_cs == WRITE && wvalid_m_inf && wready_m_inf) begin
			axi_cnt_w = axi_cnt_r + 1;
	end
	else begin
		axi_cnt_w = axi_cnt_r;
	end
end

always @(*) begin
	if(axi_state_cs == IDLE_A) begin
		preload_cnt_w = 0;
	end
	else if(axi_state_cs == PRELOAD) begin
		preload_cnt_w = preload_cnt_r + 1;
	end
	else begin
		preload_cnt_w = 0;
	end
end


always @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		axi_state_cs <= 0; 
		axi_cnt_r <= 0;
		arvalid_m_inf <= 0;
		rready_m_inf <= 0;
		awvalid_m_inf <= 0;
		wvalid_m_inf <= 0;
		wready_m_inf_r <= 0;
		wlast_m_inf <= 0;
		bready_m_inf <= 0;
		preload_cnt_r <= 0;
	end
	else begin
		axi_state_cs <= axi_state_ns; 
		axi_cnt_r <= axi_cnt_w;
		arvalid_m_inf <= arvalid_m_inf_w;
		rready_m_inf <= rready_m_inf_w;
		awvalid_m_inf <= awvalid_m_inf_w;
		wvalid_m_inf <= wvalid_m_inf_w;
		wready_m_inf_r <= wready_m_inf;
		wlast_m_inf <= wlast_m_inf_w;
		bready_m_inf <= bready_m_inf_w;
		preload_cnt_r <= preload_cnt_w;
	end
end

// ===============================================================
//  					FSM
// ===============================================================
reg [3:0] net_id_r [0:14];
reg [3:0] net_id_w [0:14];
reg [5:0] loc_x_r [0:29];
reg [5:0] loc_x_w [0:29];
reg [5:0] loc_y_r [0:29];
reg [5:0] loc_y_w [0:29];
reg [4:0] in_cnt_r, in_cnt_w;
wire [3:0] net_pr;
reg fill_finish;
reg weight_read_finish_r, weight_read_finish_w;

always @(*) begin
	state_ns = IDLE;
	case(state_cs) 
		IDLE: begin//0
			if(in_valid) state_ns = WAIT_F;
			else         state_ns = IDLE;
		end
		WAIT_F: begin//1
			if(&axi_cnt_r[6:0]) state_ns = FILL;
			else                state_ns = WAIT_F;
		end	
		FILL: begin//2
			if(fill_finish) state_ns = RETRA;
			else if(fill_finish_spe)       state_ns = REFRESH;
			else            state_ns = FILL;
		end
		RETRA: begin//3
			if(weight_read_finish_r) state_ns = READ_S;
			else 					 state_ns = WAIT_W;
		end
		WAIT_W: begin//4
			if(weight_read_finish_r) state_ns = READ_S;
			else 					 state_ns = WAIT_W;
		end
		READ_S: begin //5
			state_ns = WAIT_S;
		end
		WAIT_S: begin //6
			state_ns = CAL;
		end
		CAL: begin //7
			if(retrace_finish) state_ns = REFRESH;//new net_id
			else               state_ns = RETRA; 
		end
		REFRESH: begin //8
			if(in_cnt_r == 0)  state_ns = WRITE_D;
			else               state_ns = FILL; //new net_id
		end
		WRITE_D: begin //9
			if(bvalid_m_inf && bready_m_inf) state_ns = IDLE;
			else 							 state_ns = WRITE_D;
		end
		default: state_ns = IDLE;
	endcase
end

always @(*) begin
	if(in_valid) begin
		axi_read_flag = 1;
	end
	else if(state_cs != WRITE_D && axi_cnt_r[7]) begin
		axi_read_flag = 1;
	end
	else begin
		axi_read_flag = 0;
	end
end

always @(*) begin
	if(state_cs == WRITE_D) begin
		axi_write_flag = 1;
	end
	else begin
		axi_write_flag = 0;
	end
end

//input
always @(*) begin
	if(in_valid) begin
		in_cnt_w = in_cnt_r + 1;
	end
	else if((state_cs == CAL && retrace_finish) || (state_cs == REFRESH && fill_finish_spe)) begin //
		in_cnt_w = in_cnt_r - 2;
	end
	else begin
		in_cnt_w = in_cnt_r; 
	end
end

assign net_pr = in_cnt_r >> 1;
always @(*) begin
	if(in_valid) begin
		frame_id_w = frame_id;
	end
	else begin
		frame_id_w = frame_id_r;
	end
end

always @(*) begin
	for(i=0; i<15; i=i+1) begin
		if(net_pr == i && in_valid) begin
			net_id_w[i] = net_id;
		end
		else if(state_cs == REFRESH) begin
			if(i<14) begin
				net_id_w[i] = net_id_r[i+1];
			end
			net_id_w[14] = 0;
		end
		else begin
			net_id_w[i] = net_id_r[i];
		end
	end
end

always @(*) begin
	for(i=0; i<30; i=i+1) begin
		if(in_cnt_r == i && in_valid) begin
			loc_x_w[i] = loc_x;
		end
		else if(state_cs == REFRESH) begin
			if(i< 28) begin
				loc_x_w[i] = loc_x_r[i+2];
			end
			loc_x_w[28] = 0;
			loc_x_w[29] = 0;
		end
		else begin
			loc_x_w[i] = loc_x_r[i];
		end
	end
end

always @(*) begin
	for(i=0; i<30; i=i+1) begin
		if(in_cnt_r == i && in_valid) begin
			loc_y_w[i] = loc_y;
		end
		else if(state_cs == REFRESH) begin
			if(i< 28) begin
				loc_y_w[i] = loc_y_r[i+2];
			end
			loc_y_w[28] = 0;
			loc_y_w[29] = 0;
		end
		else begin
			loc_y_w[i] = loc_y_r[i];
		end
	end
end

//weight_read_finish_r
always @(*) begin
	if(state_cs == IDLE) begin
		weight_read_finish_w = 0;
	end
	else if(&axi_cnt_r) begin
		weight_read_finish_w = 1;
	end
	else begin
		weight_read_finish_w = weight_read_finish_r;
	end
end

always @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		state_cs <= 0;
		frame_id_r <= 0;
		for(i=0; i<15; i=i+1) net_id_r[i] <= 0;
		for(i=0; i<30; i=i+1) loc_x_r[i] <= 0;
		for(i=0; i<30; i=i+1) loc_y_r[i] <= 0;
		in_cnt_r <= 0;
		weight_read_finish_r <= 0;
	end
	else begin
		state_cs <= state_ns;
		frame_id_r <= frame_id_w;
		for(i=0; i<15; i=i+1) net_id_r[i] <= net_id_w[i];
		for(i=0; i<30; i=i+1) loc_x_r[i] <= loc_x_w[i];
		for(i=0; i<30; i=i+1) loc_y_r[i] <= loc_y_w[i];
		in_cnt_r <= in_cnt_w;
		weight_read_finish_r <= weight_read_finish_w;
	end
end
// ===============================================================
//  					SRAM
// ===============================================================
reg we_frame, we_weight;
reg [6:0] addr_frame, addr_weight;
reg [127:0] di_frame, di_weight;

always @(*) begin
	if(axi_state_cs == READ && axi_cnt_r[7] == 0) begin
		we_frame = 0;
	end
	else if(state_cs == CAL) begin
		we_frame = 0;
	end
	else begin //state_cs == READ_S
		we_frame = 1;
	end
end

always @(*) begin
	if(axi_state_cs == READ && axi_cnt_r[7] == 1) begin
		we_weight = 0;
	end
	else begin
		we_weight = 1;
	end
end


always @(*) begin
	if(axi_state_cs == READ) begin
		addr_frame = axi_cnt_r;
	end
	else if(state_cs == READ_S || state_cs == CAL) begin
		addr_frame = retrace_addr;
	end
	else if(axi_state_cs == PRELOAD) begin
		addr_frame = preload_cnt_r;
	end
	else if(axi_state_cs == WRITE) begin
		addr_frame = axi_cnt_r + 2;
	end
	else begin
		addr_frame = 0;
	end
end

always @(*) begin
	if(axi_state_cs == READ) begin
		addr_weight = axi_cnt_r;
	end
	else if(state_cs == READ_S) begin
		addr_weight = retrace_addr;
	end
	else begin
		addr_weight = 0;
	end
end

always @(*) begin
	if(axi_state_cs == READ) begin
		di_frame = rdata_m_inf;
	end
	else if(state_cs == CAL) begin
		di_frame = retrace_data;
	end
	else begin
		di_frame = 0;
	end
end

always @(*) begin
	if(axi_state_cs == READ) begin
		di_weight = rdata_m_inf;
	end
	else begin
		di_weight = 0;
	end
end

U_S_ram U_FRAME(
    .clk(clk), .we(we_frame), .address(addr_frame), .di(di_frame), .dout(dout_frame)
);
U_S_ram U_WEIGHT(
    .clk(clk), .we(we_weight), .address(addr_weight), .di(di_weight), .dout(dout_weight)
);
// ===============================================================
//  					Path Map
// ===============================================================
reg [1:0] Path_map_r [0:63] [0:63];
reg [1:0] Path_map_w [0:63] [0:63];
wire [5:0] path_x_pr, path_y_pr_w;
reg [5:0] path_y_pr_r;
reg [1:0] fill_cnt_r, fill_cnt_w;
reg [1:0] fill_value; 
reg [5:0] retrace_x_r, retrace_x_w;
reg [5:0] retrace_y_r, retrace_y_w;

//Path
assign path_x_pr = axi_cnt_r[0] ? 32 : 0;
assign path_y_pr_w = axi_cnt_r[0] ? path_y_pr_r+1 : path_y_pr_r;

always @(*) begin
	for(i=0; i<64; i=i+1) begin
		for(j=0; j<64; j=j+1) Path_map_w[i][j] = Path_map_r[i][j];				
	end

	case(state_cs) 
	IDLE: begin
		for(i=0; i<64; i=i+1) begin
			for(j=0; j<64; j=j+1) begin
				Path_map_w[i][j] = 0;
			end
		end
	end
	WAIT_F:begin
		for(i=0; i<64; i=i+1) begin
			for(j=0; j<33; j=j+1) begin
				if(path_x_pr == j && path_y_pr_r == i) begin
					if(rdata_m_inf[3:0] != 0) begin
						Path_map_w[i][j] = 1;
					end
					if(rdata_m_inf[7:4] != 0) begin
						Path_map_w[i][j+1] = 1;
					end
					if(rdata_m_inf[11:8] != 0) begin
						Path_map_w[i][j+2] = 1;
					end
					if(rdata_m_inf[15:12] != 0) begin
						Path_map_w[i][j+3] = 1;
					end
					if(rdata_m_inf[19:16] != 0) begin
						Path_map_w[i][j+4] = 1;
					end
					if(rdata_m_inf[23:20] != 0) begin
						Path_map_w[i][j+5] = 1;
					end
					if(rdata_m_inf[27:24] != 0) begin
						Path_map_w[i][j+6] = 1;
					end
					if(rdata_m_inf[31:28] != 0) begin
						Path_map_w[i][j+7] = 1;
					end
					if(rdata_m_inf[35:32] != 0) begin
						Path_map_w[i][j+8] = 1;
					end
					if(rdata_m_inf[39:36] != 0) begin
						Path_map_w[i][j+9] = 1;
					end
					if(rdata_m_inf[43:40] != 0) begin
						Path_map_w[i][j+10] = 1;
					end
					if(rdata_m_inf[47:44] != 0) begin
						Path_map_w[i][j+11] = 1;
					end
					if(rdata_m_inf[51:48] != 0) begin
						Path_map_w[i][j+12] = 1;
					end
					if(rdata_m_inf[55:52] != 0) begin
						Path_map_w[i][j+13] = 1;
					end
					if(rdata_m_inf[59:56] != 0) begin
						Path_map_w[i][j+14] = 1;
					end
					if(rdata_m_inf[63:60]!= 0) begin
						Path_map_w[i][j+15] = 1;
					end
					if(rdata_m_inf[67:64] != 0) begin
						Path_map_w[i][j+16] = 1;
					end
					if(rdata_m_inf[71:68] != 0) begin
						Path_map_w[i][j+17] = 1;
					end
					if(rdata_m_inf[75:72] != 0) begin
						Path_map_w[i][j+18] = 1;
					end
					if(rdata_m_inf[79:76] != 0) begin
						Path_map_w[i][j+19] = 1;
					end
					if(rdata_m_inf[83:80] != 0) begin
						Path_map_w[i][j+20] = 1;
					end
					if(rdata_m_inf[87:84] != 0) begin
						Path_map_w[i][j+21] = 1;
					end
					if(rdata_m_inf[91:88] != 0) begin
						Path_map_w[i][j+22] = 1;
					end
					if(rdata_m_inf[95:92] != 0) begin
						Path_map_w[i][j+23] = 1;
					end
					if(rdata_m_inf[99:96] != 0) begin
						Path_map_w[i][j+24] = 1;
					end
					if(rdata_m_inf[103:100] != 0) begin
						Path_map_w[i][j+25] = 1;
					end
					if(rdata_m_inf[107:104] != 0) begin
						Path_map_w[i][j+26] = 1;
					end
					if(rdata_m_inf[111:108] != 0) begin
						Path_map_w[i][j+27] = 1;
					end
					if(rdata_m_inf[115:112] != 0) begin
						Path_map_w[i][j+28] = 1;
					end
					if( rdata_m_inf[119:116] != 0) begin
						Path_map_w[i][j+29] = 1;
					end
					if(rdata_m_inf[123:120] != 0) begin
						Path_map_w[i][j+30] = 1;
					end
					if( rdata_m_inf[127:124] != 0) begin
						Path_map_w[i][j+31] = 1;
					end
				end
			end 				
		end
	end
	FILL: begin
		//fill做法: 
		//1. 若自己是默認直
		//2. 若是S的上下左右，先擴一個2
		//3. 若自己的上下左右有2或3，表示傳到自己

		//一般
		for(i=1; i<63; i=i+1) begin //y 
			for(j=1; j<63; j=j+1) begin //x

					if(Path_map_r[i][j] == 0) begin
						if(((loc_x_r[0]+1) == j && loc_y_r[0] == i) || ((loc_x_r[0]-1) == j && loc_y_r[0] == i) || (loc_x_r[0] == j && (loc_y_r[0]+1) == i) || (loc_x_r[0] == j && (loc_y_r[0]-1) == i)) begin
							Path_map_w[i][j] = fill_value;
						end
						if(Path_map_r[i][j+1][1] == 1 || Path_map_r[i][j-1][1] == 1 || Path_map_r[i+1][j][1] == 1 || Path_map_r[i-1][j][1] == 1) begin
							Path_map_w[i][j] = fill_value;
						end
					end
			end
		end

		//上
		for(i=0; i<1; i=i+1) begin //y
			for(j=1; j<63; j=j+1) begin //x

				if(Path_map_r[i][j] == 0) begin
					if(Path_map_r[i][j+1][1] == 1 || Path_map_r[i][j-1][1] == 1 || Path_map_r[i+1][j][1] == 1) begin
						Path_map_w[i][j] = fill_value;
					end
				end 

			end
		end

		//下
		for(i=63; i<64; i=i+1) begin //y
			for(j=1; j<63; j=j+1) begin //x

				if(Path_map_r[i][j] == 0) begin
					if(Path_map_r[i][j+1][1] == 1 || Path_map_r[i][j-1][1] == 1 || Path_map_r[i-1][j][1] == 1) begin
						Path_map_w[i][j] = fill_value;
					end
				end 

			end
		end

		//左
		for(i=1; i<63; i=i+1) begin //y
			for(j=0; j<1; j=j+1) begin //x

				if(Path_map_r[i][j] == 0) begin
					if(Path_map_r[i-1][j][1] == 1 || Path_map_r[i+1][j][1] == 1 || Path_map_r[i][j+1][1] == 1) begin
						Path_map_w[i][j] = fill_value;
					end
				end 

			end
		end

		//右
		for(i=1; i<63; i=i+1) begin //y
			for(j=63; j<64; j=j+1) begin //x

				if(Path_map_r[i][j] == 0) begin
					if(Path_map_r[i-1][j][1] == 1 || Path_map_r[i+1][j][1] == 1 || Path_map_r[i][j-1][1] == 1) begin
						Path_map_w[i][j] = fill_value;
					end
				end 

			end
		end
		
		if(Path_map_r[0][0] == 0) begin
			if(Path_map_r[0][1][1] == 1 || Path_map_r[1][0][1] == 1) begin
				Path_map_w[0][0] = fill_value;
			end
		end 
		if(Path_map_r[0][63] == 0) begin
			if(Path_map_r[0][62][1] == 1 || Path_map_r[1][63][1] == 1) begin
				Path_map_w[0][63] = fill_value;
			end
		end 
		if(Path_map_r[63][0] == 0) begin
			if(Path_map_r[63][1][1] == 1 || Path_map_r[62][0][1] == 1) begin
				Path_map_w[63][0] = fill_value;
			end
		end 
		if(Path_map_r[63][63] == 0) begin
			if(Path_map_r[63][62][1] == 1 || Path_map_r[62][63][1] == 1) begin
				Path_map_w[63][63] = fill_value;
			end
		end 

	end

	CAL: begin
		Path_map_w[retrace_y_r][retrace_x_r] = 1;
	end
	REFRESH: begin
		for(i=0; i<64; i=i+1) begin //y
			for(j=0; j<64; j=j+1) begin //x
				if(Path_map_r[i][j][1] == 1) begin
					Path_map_w[i][j] = 0;
				end
			end
		end
	end
	endcase
end

//filling
//讓retrace有正確初始直
always @(*) begin
	if(state_cs == FILL) begin
		if(!fill_finish) begin
			fill_cnt_w = fill_cnt_r + 1;
		end
		else begin
			fill_cnt_w = fill_cnt_r - 1; 
		end
	end
	else if(state_cs == RETRA) begin
		fill_cnt_w = fill_cnt_r - 1;
	end
	else if(state_cs == IDLE || state_cs == REFRESH) begin
		fill_cnt_w = 0;
	end
	else begin
		fill_cnt_w = fill_cnt_r;
	end
end

always @(*) begin
	case(fill_cnt_r) 
		0: fill_value = 2;
		1: fill_value = 2;
		2: fill_value = 3;
		3: fill_value = 3;
	endcase
end

//到T的上|下|左|右有一個是2or3結束fill
always @(*) begin
	if(Path_map_r[loc_y_r[1]][loc_x_r[1]+1][1] == 1 || Path_map_r[loc_y_r[1]][loc_x_r[1]-1][1] == 1 || Path_map_r[loc_y_r[1]+1][loc_x_r[1]][1] == 1 || Path_map_r[loc_y_r[1]-1][loc_x_r[1]][1] == 1) begin
		fill_finish = 1;
	end
	else begin
		fill_finish = 0;
	end
end

//修復ST對接
always @(*) begin 
	if(state_cs == FILL || state_cs == REFRESH) begin
		if(((loc_y_r[1]+1) == loc_y_r[0] && loc_x_r[1] == loc_x_r[0]) || ((loc_y_r[1]-1) == loc_y_r[0] && loc_x_r[1] == loc_x_r[0]) || (loc_y_r[1] == loc_y_r[0] && (loc_x_r[1]+1) == loc_x_r[0]) || (loc_y_r[1] == loc_y_r[0] && (loc_x_r[1]-1) == loc_x_r[0])) begin
			fill_finish_spe = 1;
		end
		else begin
			fill_finish_spe = 0;
		end
	end
	else begin
		fill_finish_spe = 0;
	end

end

//retrace
//算出pr要走哪
always @(*) begin
	retrace_x_w = retrace_x_r;
    retrace_y_w = retrace_y_r;
	if(state_cs == RETRA) begin

		//一般
		if(retrace_x_r > 0 && retrace_x_r < 63 && retrace_y_r > 0 && retrace_y_r < 63) begin
			if(Path_map_r[retrace_y_r+1][retrace_x_r] == fill_value) begin
				retrace_x_w = retrace_x_r;
				retrace_y_w = retrace_y_r + 1;
			end
			else if(Path_map_r[retrace_y_r-1][retrace_x_r] == fill_value) begin
				retrace_x_w = retrace_x_r;
				retrace_y_w = retrace_y_r - 1;
			end
			else if(Path_map_r[retrace_y_r][retrace_x_r+1] == fill_value) begin
				retrace_x_w = retrace_x_r+1;
				retrace_y_w = retrace_y_r;
			end
			else begin
				retrace_x_w = retrace_x_r-1;
				retrace_y_w = retrace_y_r;
			end
		end

		//上
		if(retrace_y_r == 0 && retrace_x_r > 0 && retrace_x_r < 63) begin
			if(Path_map_r[retrace_y_r+1][retrace_x_r] == fill_value) begin
				retrace_x_w = retrace_x_r;
				retrace_y_w = retrace_y_r + 1;
			end
			else if(Path_map_r[retrace_y_r][retrace_x_r+1] == fill_value) begin
				retrace_x_w = retrace_x_r+1;
				retrace_y_w = retrace_y_r;
			end
			else begin
				retrace_x_w = retrace_x_r-1;
				retrace_y_w = retrace_y_r;
			end
		end

		//下
		if(retrace_y_r == 63 && retrace_x_r > 0 && retrace_x_r < 63) begin
			if(Path_map_r[retrace_y_r-1][retrace_x_r] == fill_value) begin
				retrace_x_w = retrace_x_r;
				retrace_y_w = retrace_y_r - 1;
			end
			else if(Path_map_r[retrace_y_r][retrace_x_r+1] == fill_value) begin
				retrace_x_w = retrace_x_r+1;
				retrace_y_w = retrace_y_r;
			end
			else begin
				retrace_x_w = retrace_x_r-1;
				retrace_y_w = retrace_y_r;
			end
		end

		//左
		if(retrace_x_r == 0 && retrace_y_r > 0 && retrace_y_r < 63) begin
			if(Path_map_r[retrace_y_r+1][retrace_x_r] == fill_value) begin
				retrace_x_w = retrace_x_r;
				retrace_y_w = retrace_y_r + 1;
			end
			else if(Path_map_r[retrace_y_r-1][retrace_x_r] == fill_value) begin
				retrace_x_w = retrace_x_r;
				retrace_y_w = retrace_y_r - 1;
			end
			else begin
				retrace_x_w = retrace_x_r+1;
				retrace_y_w = retrace_y_r;
			end
		end

		//右
		if(retrace_x_r == 63 && retrace_y_r > 0 && retrace_y_r < 63) begin
			if(Path_map_r[retrace_y_r+1][retrace_x_r] == fill_value) begin
				retrace_x_w = retrace_x_r;
				retrace_y_w = retrace_y_r + 1;
			end
			else if(Path_map_r[retrace_y_r-1][retrace_x_r] == fill_value) begin
				retrace_x_w = retrace_x_r;
				retrace_y_w = retrace_y_r - 1;
			end
			else begin
				retrace_x_w = retrace_x_r-1;
				retrace_y_w = retrace_y_r;
			end
		end

		
		if(retrace_x_r == 0 && retrace_y_r == 0) begin
				if(Path_map_r[retrace_y_r+1][retrace_x_r] == fill_value) begin
					retrace_x_w = retrace_x_r;
					retrace_y_w = retrace_y_r + 1;
				end
				else begin
					retrace_x_w = retrace_x_r+1;
					retrace_y_w = retrace_y_r;
				end
		end 
		if(retrace_x_r == 63 && retrace_y_r == 0) begin
			if(Path_map_r[retrace_y_r+1][retrace_x_r] == fill_value) begin
				retrace_x_w = retrace_x_r;
				retrace_y_w = retrace_y_r + 1;
			end
			else begin
				retrace_x_w = retrace_x_r-1;
				retrace_y_w = retrace_y_r;
			end
		end 
		if(retrace_x_r == 0 && retrace_y_r == 63) begin
			if(Path_map_r[retrace_y_r-1][retrace_x_r] == fill_value) begin
				retrace_x_w = retrace_x_r;
				retrace_y_w = retrace_y_r - 1;
			end
			else begin
				retrace_x_w = retrace_x_r+1;
				retrace_y_w = retrace_y_r;
			end
		end 
		if(retrace_x_r == 63 && retrace_y_r == 63) begin
			if(Path_map_r[retrace_y_r-1][retrace_x_r] == fill_value) begin
				retrace_x_w = retrace_x_r;
				retrace_y_w = retrace_y_r - 1;
			end
			else begin
				retrace_x_w = retrace_x_r-1;
				retrace_y_w = retrace_y_r;
			end
		end 

	end
	else if(state_cs == FILL) begin
		retrace_x_w = loc_x_r[1];
		retrace_y_w = loc_y_r[1];
	end
	else begin
		retrace_x_w = retrace_x_r;
		retrace_y_w = retrace_y_r;
	end
end


always @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		for(i=0; i<64; i=i+1) begin
			for(j=0; j<64; j=j+1) Path_map_r[i][j] <= 0;				
		end
		path_y_pr_r <= 0;
		fill_cnt_r <= 0;
		retrace_x_r <= 0;
		retrace_y_r <= 0;
	end
	else begin
		for(i=0; i<64; i=i+1) begin
			for(j=0; j<64; j=j+1) Path_map_r[i][j] <= Path_map_w[i][j];				
		end
		path_y_pr_r <= path_y_pr_w;
		fill_cnt_r <= fill_cnt_w;
		retrace_x_r <= retrace_x_w;
		retrace_y_r <= retrace_y_w;
	end
end

// ===============================================================
//  					Access F & W Sram
// ===============================================================
//address generate
//基於(x,y)計算地址
assign addgen_y = retrace_y_r << 1;
assign addgen_x = (retrace_x_r < 32) ? 0 : 1;
assign retrace_addr = addgen_x + addgen_y;

//retrace path deal
//將reatrace結果連接在從sram讀出的data，再寫回
assign retrace_deal = (retrace_x_r < 32) ? retrace_x_r : retrace_x_r - 32;

always @(*) begin
	case(retrace_deal)
		0: retrace_data = {fsr_dout_r[127:4], net_id_r[0]};
		1: retrace_data = {fsr_dout_r[127:8], net_id_r[0], fsr_dout_r[3:0]};
		2: retrace_data = {fsr_dout_r[127:12], net_id_r[0], fsr_dout_r[7:0]};
		3: retrace_data = {fsr_dout_r[127:16], net_id_r[0], fsr_dout_r[11:0]};
		4: retrace_data = {fsr_dout_r[127:20], net_id_r[0], fsr_dout_r[15:0]};
		5: retrace_data = {fsr_dout_r[127:24], net_id_r[0], fsr_dout_r[19:0]};
		6: retrace_data = {fsr_dout_r[127:28], net_id_r[0], fsr_dout_r[23:0]};
		7: retrace_data = {fsr_dout_r[127:32], net_id_r[0], fsr_dout_r[27:0]};
		8: retrace_data = {fsr_dout_r[127:36], net_id_r[0], fsr_dout_r[31:0]};
		9: retrace_data = {fsr_dout_r[127:40], net_id_r[0], fsr_dout_r[35:0]};
		10: retrace_data = {fsr_dout_r[127:44], net_id_r[0], fsr_dout_r[39:0]};
		11: retrace_data = {fsr_dout_r[127:48], net_id_r[0], fsr_dout_r[43:0]};
		12: retrace_data = {fsr_dout_r[127:52], net_id_r[0], fsr_dout_r[47:0]};
		13: retrace_data = {fsr_dout_r[127:56], net_id_r[0], fsr_dout_r[51:0]};
		14: retrace_data = {fsr_dout_r[127:60], net_id_r[0], fsr_dout_r[55:0]};
		15: retrace_data = {fsr_dout_r[127:64], net_id_r[0], fsr_dout_r[59:0]};
		16: retrace_data = {fsr_dout_r[127:68], net_id_r[0], fsr_dout_r[63:0]};
		17: retrace_data = {fsr_dout_r[127:72], net_id_r[0], fsr_dout_r[67:0]};
		18: retrace_data = {fsr_dout_r[127:76], net_id_r[0], fsr_dout_r[71:0]};
		19: retrace_data = {fsr_dout_r[127:80], net_id_r[0], fsr_dout_r[75:0]};
		20: retrace_data = {fsr_dout_r[127:84], net_id_r[0], fsr_dout_r[79:0]};
		21: retrace_data = {fsr_dout_r[127:88], net_id_r[0], fsr_dout_r[83:0]};
		22: retrace_data = {fsr_dout_r[127:92], net_id_r[0], fsr_dout_r[87:0]};
		23: retrace_data = {fsr_dout_r[127:96], net_id_r[0], fsr_dout_r[91:0]};
		24: retrace_data = {fsr_dout_r[127:100], net_id_r[0], fsr_dout_r[95:0]};
		25: retrace_data = {fsr_dout_r[127:104], net_id_r[0], fsr_dout_r[99:0]};
		26: retrace_data = {fsr_dout_r[127:108], net_id_r[0], fsr_dout_r[103:0]};
		27: retrace_data = {fsr_dout_r[127:112], net_id_r[0], fsr_dout_r[107:0]};
		28: retrace_data = {fsr_dout_r[127:116], net_id_r[0], fsr_dout_r[111:0]};
		29: retrace_data = {fsr_dout_r[127:120], net_id_r[0], fsr_dout_r[115:0]};
		30: retrace_data = {fsr_dout_r[127:124], net_id_r[0], fsr_dout_r[119:0]};
		31: retrace_data = {net_id_r[0], fsr_dout_r[123:0]};
	endcase
end

//weight sram DFF
always @(*) begin
	if(state_cs == WAIT_S) begin
		wsr_dout_w = dout_weight;
	end
	else if(axi_state_cs == PRELOAD) begin
		if(preload_cnt_r == 2) begin
			wsr_dout_w = dout_frame;
		end
		else begin
			wsr_dout_w = wsr_dout_r;
		end
	end
	else begin
		wsr_dout_w = wsr_dout_r;
	end
end

//frame sram DFF   dout_frame
always @(*) begin
	if(state_cs == WAIT_S) begin
		fsr_dout_w = dout_frame;
	end
	else if(axi_state_cs == PRELOAD) begin
		if(preload_cnt_r == 1) begin
			fsr_dout_w = dout_frame;
		end
		else begin
			fsr_dout_w = fsr_dout_r;
		end
	end
	else if(axi_state_cs == WRITE) begin
		if(wvalid_m_inf && wready_m_inf) begin
			fsr_dout_w = dout_frame;
		end
		else begin
			fsr_dout_w = fsr_dout_r;
		end
	end
	else begin
		fsr_dout_w = fsr_dout_r;
	end
end

always @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		fsr_dout_r <= 0;
		wsr_dout_r <= 0;
	end
	else begin
		fsr_dout_r <= fsr_dout_w;
		wsr_dout_r <= wsr_dout_w;
	end
end

// ===============================================================
//  					1. Write F Sram //邏輯在上面
//                      2. Cal cost
//                      3. Update Path Map //邏輯在上面
// ===============================================================
reg [13:0] cost_tmp_r, cost_tmp_w;
reg [13:0] weight_cost;

//RETRA finish
//計算何時retrace完，不用跳回RETRA
always @(*) begin
	if( ((retrace_y_r+1) == loc_y_r[0] && (retrace_x_r) ==  loc_x_r[0]) || ((retrace_y_r-1) == loc_y_r[0] && (retrace_x_r) ==  loc_x_r[0]) || ((retrace_y_r) == loc_y_r[0] && (retrace_x_r+1) ==  loc_x_r[0]) || ((retrace_y_r) == loc_y_r[0] && (retrace_x_r-1) ==  loc_x_r[0]) ) begin
		retrace_finish = 1;
	end
	else begin
		retrace_finish = 0;
	end
end

//Cal cost 
always @(*) begin
	case(retrace_deal)
		0: weight_cost = wsr_dout_r[3:0];
		1: weight_cost = wsr_dout_r[7:4];
		2: weight_cost = wsr_dout_r[11:8];
		3: weight_cost = wsr_dout_r[15:12];
		4: weight_cost = wsr_dout_r[19:16];
		5: weight_cost = wsr_dout_r[23:20];
		6: weight_cost = wsr_dout_r[27:24];
		7: weight_cost = wsr_dout_r[31:28];
		8: weight_cost = wsr_dout_r[35:32];
		9: weight_cost = wsr_dout_r[39:36];
		10: weight_cost = wsr_dout_r[43:40];
		11: weight_cost = wsr_dout_r[47:44];
		12: weight_cost = wsr_dout_r[51:48];
		13: weight_cost = wsr_dout_r[55:52];
		14: weight_cost = wsr_dout_r[59:56];
		15: weight_cost = wsr_dout_r[63:60];
		16: weight_cost = wsr_dout_r[67:64];
		17: weight_cost = wsr_dout_r[71:68];
		18: weight_cost = wsr_dout_r[75:72];
		19: weight_cost = wsr_dout_r[79:76];
		20: weight_cost = wsr_dout_r[83:80];
		21: weight_cost = wsr_dout_r[87:84];
		22: weight_cost = wsr_dout_r[91:88];
		23: weight_cost = wsr_dout_r[95:92];
		24: weight_cost = wsr_dout_r[99:96];
		25: weight_cost = wsr_dout_r[103:100];
		26: weight_cost = wsr_dout_r[107:104];
		27: weight_cost = wsr_dout_r[111:108];
		28: weight_cost = wsr_dout_r[115:112];
		29: weight_cost = wsr_dout_r[119:116];
		30: weight_cost = wsr_dout_r[123:120];
		31: weight_cost = wsr_dout_r[127:124];
	endcase
end

always @(*) begin
	if(state_cs == WAIT_F) begin
		cost_tmp_w = 0;
	end
	else if(state_cs == CAL) begin
		cost_tmp_w = cost_tmp_r + weight_cost;
	end
	else begin
		cost_tmp_w = cost_tmp_r;
	end
end

always @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		cost_tmp_r <= 0;
	end
	else begin
		cost_tmp_r <= cost_tmp_w;
	end
end
assign cost = cost_tmp_r;

// ===============================================================
//  					Write back Dram
// ===============================================================


// ===============================================================
//  					OUT
// ===============================================================
reg busy_w;

always @(*) begin
	if(state_cs != IDLE && !in_valid) begin
		busy_w = 1;
	end
	else begin
		busy_w = 0;
	end
end

always @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		busy <= 0;   
	end
	else begin
		busy <= busy_w; 
	end
end
endmodule

module U_S_ram (
    input clk,
    input we,
    input [6:0] address,
    input [127:0] di,
    output [127:0] dout
);

frame_128X128 U_DATA(.A0(address[0]), .A1(address[1]), .A2(address[2]), .A3(address[3]), .A4(address[4]), .A5(address[5]), .A6(address[6]), 

                     .DO0(dout[0]), .DO1(dout[1]), .DO2(dout[2]), .DO3(dout[3]), .DO4(dout[4]), .DO5(dout[5]), .DO6(dout[6]), .DO7(dout[7]),
					 .DO8(dout[8]), .DO9(dout[9]), .DO10(dout[10]), .DO11(dout[11]), .DO12(dout[12]), .DO13(dout[13]), .DO14(dout[14]), .DO15(dout[15]),
					 .DO16(dout[16]), .DO17(dout[17]), .DO18(dout[18]), .DO19(dout[19]), .DO20(dout[20]), .DO21(dout[21]), .DO22(dout[22]), .DO23(dout[23]),
					 .DO24(dout[24]), .DO25(dout[25]), .DO26(dout[26]), .DO27(dout[27]), .DO28(dout[28]), .DO29(dout[29]), .DO30(dout[30]), .DO31(dout[31]),
					 .DO32(dout[32]), .DO33(dout[33]), .DO34(dout[34]), .DO35(dout[35]), .DO36(dout[36]), .DO37(dout[37]), .DO38(dout[38]), .DO39(dout[39]),
					 .DO40(dout[40]), .DO41(dout[41]), .DO42(dout[42]), .DO43(dout[43]), .DO44(dout[44]), .DO45(dout[45]), .DO46(dout[46]), .DO47(dout[47]),
					 .DO48(dout[48]), .DO49(dout[49]), .DO50(dout[50]), .DO51(dout[51]), .DO52(dout[52]), .DO53(dout[53]), .DO54(dout[54]), .DO55(dout[55]),
					 .DO56(dout[56]), .DO57(dout[57]), .DO58(dout[58]), .DO59(dout[59]), .DO60(dout[60]), .DO61(dout[61]), .DO62(dout[62]), .DO63(dout[63]),
					 .DO64(dout[64]), .DO65(dout[65]), .DO66(dout[66]), .DO67(dout[67]), .DO68(dout[68]), .DO69(dout[69]), .DO70(dout[70]), .DO71(dout[71]),
					 .DO72(dout[72]), .DO73(dout[73]), .DO74(dout[74]), .DO75(dout[75]), .DO76(dout[76]), .DO77(dout[77]), .DO78(dout[78]), .DO79(dout[79]),
					 .DO80(dout[80]), .DO81(dout[81]), .DO82(dout[82]), .DO83(dout[83]), .DO84(dout[84]), .DO85(dout[85]), .DO86(dout[86]), .DO87(dout[87]),
					 .DO88(dout[88]), .DO89(dout[89]), .DO90(dout[90]), .DO91(dout[91]), .DO92(dout[92]), .DO93(dout[93]), .DO94(dout[94]), .DO95(dout[95]),
					 .DO96(dout[96]), .DO97(dout[97]), .DO98(dout[98]), .DO99(dout[99]), .DO100(dout[100]), .DO101(dout[101]), .DO102(dout[102]), .DO103(dout[103]),
					 .DO104(dout[104]), .DO105(dout[105]), .DO106(dout[106]), .DO107(dout[107]), .DO108(dout[108]), .DO109(dout[109]), .DO110(dout[110]), .DO111(dout[111]),
					 .DO112(dout[112]), .DO113(dout[113]), .DO114(dout[114]), .DO115(dout[115]), .DO116(dout[116]), .DO117(dout[117]), .DO118(dout[118]), .DO119(dout[119]),
					 .DO120(dout[120]), .DO121(dout[121]), .DO122(dout[122]), .DO123(dout[123]), .DO124(dout[124]), .DO125(dout[125]), .DO126(dout[126]), .DO127(dout[127]),

                     .DI0(di[0]), .DI1(di[1]), .DI2(di[2]), .DI3(di[3]), .DI4(di[4]), .DI5(di[5]), .DI6(di[6]), .DI7(di[7]),
					 .DI8(di[8]), .DI9(di[9]), .DI10(di[10]), .DI11(di[11]), .DI12(di[12]), .DI13(di[13]), .DI14(di[14]), .DI15(di[15]),
					 .DI16(di[16]), .DI17(di[17]), .DI18(di[18]), .DI19(di[19]), .DI20(di[20]), .DI21(di[21]), .DI22(di[22]), .DI23(di[23]),
					 .DI24(di[24]), .DI25(di[25]), .DI26(di[26]), .DI27(di[27]), .DI28(di[28]), .DI29(di[29]), .DI30(di[30]), .DI31(di[31]),
					 .DI32(di[32]), .DI33(di[33]), .DI34(di[34]), .DI35(di[35]), .DI36(di[36]), .DI37(di[37]), .DI38(di[38]), .DI39(di[39]),
					 .DI40(di[40]), .DI41(di[41]), .DI42(di[42]), .DI43(di[43]), .DI44(di[44]), .DI45(di[45]), .DI46(di[46]), .DI47(di[47]),
					 .DI48(di[48]), .DI49(di[49]), .DI50(di[50]), .DI51(di[51]), .DI52(di[52]), .DI53(di[53]), .DI54(di[54]), .DI55(di[55]),
					 .DI56(di[56]), .DI57(di[57]), .DI58(di[58]), .DI59(di[59]), .DI60(di[60]), .DI61(di[61]), .DI62(di[62]), .DI63(di[63]),
					 .DI64(di[64]), .DI65(di[65]), .DI66(di[66]), .DI67(di[67]), .DI68(di[68]), .DI69(di[69]), .DI70(di[70]), .DI71(di[71]),
					 .DI72(di[72]), .DI73(di[73]), .DI74(di[74]), .DI75(di[75]), .DI76(di[76]), .DI77(di[77]), .DI78(di[78]), .DI79(di[79]),
					 .DI80(di[80]), .DI81(di[81]), .DI82(di[82]), .DI83(di[83]), .DI84(di[84]), .DI85(di[85]), .DI86(di[86]), .DI87(di[87]),
					 .DI88(di[88]), .DI89(di[89]), .DI90(di[90]), .DI91(di[91]), .DI92(di[92]), .DI93(di[93]), .DI94(di[94]), .DI95(di[95]),
					 .DI96(di[96]), .DI97(di[97]), .DI98(di[98]), .DI99(di[99]), .DI100(di[100]), .DI101(di[101]), .DI102(di[102]), .DI103(di[103]),
					 .DI104(di[104]), .DI105(di[105]), .DI106(di[106]), .DI107(di[107]), .DI108(di[108]), .DI109(di[109]), .DI110(di[110]), .DI111(di[111]),
					 .DI112(di[112]), .DI113(di[113]), .DI114(di[114]), .DI115(di[115]), .DI116(di[116]), .DI117(di[117]), .DI118(di[118]), .DI119(di[119]),
					 .DI120(di[120]), .DI121(di[121]), .DI122(di[122]), .DI123(di[123]), .DI124(di[124]), .DI125(di[125]), .DI126(di[126]), .DI127(di[127]),

                     .CK(clk), .WEB(we), .OE(1'b1), .CS(1'b1));
endmodule

