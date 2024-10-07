//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : Tzu-Yun Huang
//	 Editor		: Ting-Yu Chang
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : pseudo_DRAM.v
//   Module Name : pseudo_DRAM
//   Release version : v3.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module pseudo_DRAM(
	clk, rst_n,
	AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
	AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP
);

input clk, rst_n;
// write address channel
input [31:0] AW_ADDR;
input AW_VALID;
output reg AW_READY;
// write data channel
input W_VALID;
input [63:0] W_DATA;
output reg W_READY;
// write response channel
output reg B_VALID;
output reg [1:0] B_RESP;
input B_READY;

// read address channel
input [31:0] AR_ADDR;
input AR_VALID;
output reg AR_READY;
// read data channel
output reg [63:0] R_DATA;
output reg R_VALID;
output reg [1:0] R_RESP;
input R_READY;

//================================================================
// parameters & integer
//================================================================

parameter DRAM_p_r = "../00_TESTBED/DRAM_init.dat";
parameter OKEY = 2'b00;
integer count;
integer num;

//================================================================
// wire & registers 
// ================================================================
reg [63:0] DRAM[0:8191];
reg start_flag, isWrite, isCount_AW_READY, isCount_AR_READY, isCount_B_VALID;
reg [31:0] AW_ADDR_reg, AR_ADDR_reg;
reg [31:0] ADDR_stable;
reg [63:0] DATA_stable;
//================================================================
// initial
//================================================================
initial begin
	reset_w_r_task;
	$readmemh(DRAM_p_r, DRAM);
end

//write channel
initial begin
	wait(start_flag);
	while (1) begin
		init_w_signal_task;
		AW_channel_task;
		check_addr_range;
		W_channel_task;
		B_channel_task;
	end
end

//read channel
initial begin
	wait(start_flag);
	while (1) begin
		init_r_signal_task;
		AR_channel_task;
		check_addr_range;
		R_channel_task;
	end
end
//================================================================
// write task
//================================================================

task init_w_signal_task; begin
	AW_READY = 0; W_READY = 0;
	B_VALID = 0; B_RESP = 0;
end
endtask

task AW_channel_task; begin
	wait(AW_VALID);
	check_stable50_task;

	@(posedge clk);
	AW_READY = 1;	isCount_AW_READY = 1;
	AW_ADDR_reg = AW_ADDR;	isWrite = 1;
	@(posedge clk);
	AW_READY = 0;
end
endtask

task W_channel_task; begin
	wait(W_VALID || count === 49); //count == 98因為要下面要等一個@(posedge clk);是99cc
	check_stable50_task;

	@(posedge clk);
	W_READY = 1;
	wait(W_VALID);
	DRAM[AW_ADDR_reg] = W_DATA;
	@(posedge clk);
	W_READY = 0;
end
endtask

task B_channel_task; begin

	@(posedge clk);
	B_VALID = 1;	isCount_B_VALID = 1;
	B_RESP = OKEY;
	wait(B_READY);
	@(posedge clk);
	B_VALID = 0;	
end
endtask

//================================================================
// read task
//================================================================
task init_r_signal_task; begin
	AR_READY = 0; R_DATA = 0;
	R_VALID = 0; R_RESP = 0;
end
endtask

task AR_channel_task; begin
	wait(AR_VALID);
	check_stable50_task;

	@(posedge clk);
	AR_READY = 1;	isCount_AR_READY = 1;
	AR_ADDR_reg = AR_ADDR;	isWrite = 0;
	@(posedge clk);
	AR_READY = 0;
end
endtask	

task R_channel_task; begin
	wait(R_READY || count === 49);
	check_stable50_task;

	@(posedge clk);
	R_VALID = 1;
	R_RESP = OKEY;
	R_DATA = DRAM[AR_ADDR_reg];
	wait(R_READY);
	@(posedge clk);
	R_VALID = 0;
	R_DATA = 0;
end
endtask	
//================================================================
// Global task
//================================================================
task reset_w_r_task; begin
	@(negedge rst_n);
	AW_READY = 0; W_READY = 0;
	B_VALID = 0; B_RESP = 0;
	AR_READY = 0; R_DATA = 0;
	R_VALID = 0; R_RESP = 0;
	start_flag = 1;
end 
endtask 

always@(*)begin
    @(negedge clk);
	if((AR_VALID === 0) && (AR_ADDR !== 0))begin
		$display("***********************************************************************");
		$display("*  Error Code: SPEC DRAM-1 FAIL                                       *");
		$display("*  AR_ADDR should be reset when AR_VALID is low                       *");
		$display("***********************************************************************");
		$finish;			
	end

	if((AW_VALID === 0) && (AW_ADDR !== 0))begin
		$display("***********************************************************************");
		$display("*  Error Code: SPEC DRAM-1 FAIL                                       *");
		$display("*  AW_ADDR should be reset when AW_VALID is low                       *");
		$display("***********************************************************************");
		$finish;			
	end

	if((W_VALID === 0) && (W_DATA !== 0))begin
		$display("***********************************************************************");
		$display("*  Error Code: SPEC DRAM-1 FAIL		                                *");
		$display("*  W_DATA should be reset when W_VALID is low                         *");
		$display("***********************************************************************");
		$finish;			
	end
end

task check_addr_range; begin
	if(isWrite) begin
		if(!(0 <= AW_ADDR_reg && AW_ADDR_reg <= 8191)) begin
			$display("***********************************************************************");
			$display("*  Error Code: SPEC DRAM-2 FAIL                                       *");
			$display("*  The DRAM address should be within the legal range (0~8191)-Write.  *");
			$display("***********************************************************************");
			$finish;
		end
	end
	else begin
		if(!(0 <= AR_ADDR_reg && AR_ADDR_reg <= 8191)) begin
			$display("***********************************************************************");
			$display("*  Error Code: SPEC DRAM-2 FAIL                                       *");
			$display("*  The DRAM address should be within the legal range (0~8191)-Read.   *");
			$display("***********************************************************************");
			$finish;
		end			
	end
end 
endtask 

task check_stable50_task; begin
	num = 0;
	if(AW_VALID) begin
		ADDR_stable = AW_ADDR;
		@(negedge clk);	//第一個一定對
		// @(posedge clk);//第一個會被忽略，可能是因為wait(AW_VALID);的變化也是在posedge，所以第一個@(posedge clk);直接執行完畢
		
		num = $urandom_range(49,2);	
		while(num !== 0) begin
			if(!(AW_VALID && (AW_ADDR === ADDR_stable)))begin
				$display("***********************************************************************");
				$display("*  Error Code: SPEC DRAM-3 FAIL                                       *");
				$display("*  AW_VALID and AW_ADDR should remain stable until AW_READY goes high *");
				$display("***********************************************************************");
				$finish;
			end	
			num = num - 1;
			@(negedge clk);
		end		
	end
	
	if(AR_VALID) begin
		ADDR_stable = AR_ADDR;
		@(negedge clk);	

		num = $urandom_range(49,2);	
		while(num !== 0) begin	
			if(!(AR_VALID && (AR_ADDR === ADDR_stable)))begin
				$display("***********************************************************************");
				$display("*  Error Code: SPEC DRAM-3 FAIL                                       *");
				$display("*  AR_VALID and AR_ADDR should remain stable until AR_READY goes high.*");
				$display("***********************************************************************");
				$finish;
			end		
			num = num - 1;
			@(negedge clk);
		end	
	end

	if(W_VALID) begin
		DATA_stable = W_DATA;
		@(negedge clk);	

		num = $urandom_range(49,2);	
		while(num !== 0) begin
			if(!(W_VALID && (W_DATA === DATA_stable)))begin
				$display("***********************************************************************");
				$display("*  Error Code: SPEC DRAM-3 FAIL                                       *");
				$display("*  W_VALID and W_DATA should remain stable until W_READY goes high.   *");
				$display("***********************************************************************");
				$finish;
			end		
			num = num - 1;
			@(negedge clk);
		end
	end

	if(R_READY) begin
		@(negedge clk);	

		num = $urandom_range(49,2);	
		while(num !== 0) begin
			if(!R_READY)begin
				$display("***********************************************************************");
				$display("*  Error Code: SPEC DRAM-3 FAIL                                       *");
				$display("*  R_READY should remain stable until R_VALID goes high.              *");
				$display("***********************************************************************");
				$finish;
			end	
			num = num - 1;
			@(negedge clk);
		end
	end
end 
endtask 

always @(negedge clk) begin
	count = 0;
	if(isCount_AW_READY) begin
		while(!W_VALID)begin
			count = count + 1;
			if(count > 100) begin
				$display("***********************************************************************");
				$display("*  Error Code: SPEC DRAM-4 FAIL                                       *");
				$display("*  W_VALID should be asserted within 100 cycles after AW_READY goes high.*");
				$display("***********************************************************************");
				$finish;				
			end
			@(negedge clk);	
		end
		isCount_AW_READY = 0;
	end

	if(isCount_AR_READY) begin
		while(!R_READY)begin
			count = count + 1;
			if(count > 100) begin
				$display("***********************************************************************");
				$display("*  Error Code: SPEC DRAM-4 FAIL                                       *");
				$display("*  R_READY should be asserted within 100 cycles after AR_READY goes high.*");
				$display("***********************************************************************");
				$finish;				
			end
			@(negedge clk);	
		end
		isCount_AR_READY = 0;
	end

	if(isCount_B_VALID) begin
		while(!B_READY)begin
			count = count + 1;
			if(count > 100) begin
				$display("***********************************************************************");
				$display("*  Error Code: SPEC DRAM-4 FAIL                                       *");
				$display("*  B_READY should be asserted within 100 cycles after B_VALID goes high.*");
				$display("***********************************************************************");
				$finish;				
			end
			@(negedge clk);		
		end
		isCount_B_VALID = 0;
	end
end

always @(*) begin
    @(negedge clk);
	if((AR_READY === 1) || (AR_VALID === 1))begin
		if(R_READY === 1) begin
			$display("***********************************************************************");
			$display("*  Error Code: SPEC DRAM-5 FAIL                                       *");
			$display("*  R_READY should not be pulled high when AR_READY or AR_VALID goes high.*");
			$display("***********************************************************************");
			$finish;			
		end
	end

	if((AW_READY === 1) || (AW_VALID === 1))begin
		if(W_VALID === 1) begin
			$display("***********************************************************************");
			$display("*  Error Code: SPEC DRAM-5 FAIL                                       *");
			$display("*  W_VALID should not be pulled high when AW_READY or AW_VALID goes high.*");
			$display("***********************************************************************");
			$finish;			
		end
	end
end

// ===============================================================
// other
// ===============================================================

task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                 Error message from pseudo_SD.v                        *");
end endtask

endmodule

