`ifdef RTL
    `define CYCLE_TIME 40.0
`endif
`ifdef GATE
    `define CYCLE_TIME 40.0
`endif

`include "../00_TESTBED/pseudo_DRAM.v"
`include "../00_TESTBED/pseudo_SD.v"

module PATTERN(
    // Input Signals
    clk,
    rst_n,
    in_valid,
    direction,
    addr_dram,
    addr_sd,
    // Output Signals
    out_valid,
    out_data,
    // DRAM Signals
    AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
	AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
    // SD Signals
    MISO,
    MOSI
);

/* Input for design */
output reg        clk, rst_n;
output reg        in_valid;
output reg        direction;
output reg [13:0] addr_dram;
output reg [15:0] addr_sd;

/* Output for pattern */
input        out_valid;
input  [7:0] out_data; 

// DRAM Signals
// write address channel
input [31:0] AW_ADDR;
input AW_VALID;
output AW_READY;
// write data channel
input W_VALID;
input [63:0] W_DATA;
output W_READY;
// write response channel
output B_VALID;
output [1:0] B_RESP;
input B_READY;
// read address channel
input [31:0] AR_ADDR;
input AR_VALID;
output AR_READY;
// read data channel
output [63:0] R_DATA;
output R_VALID;
output [1:0] R_RESP;
input R_READY;

// SD Signals
output MISO;
input MOSI;

//================================================================
// parameters & integer
//================================================================
real CYCLE = `CYCLE_TIME;
parameter DRAM_p = "../00_TESTBED/DRAM_init.dat";
parameter SD_p = "../00_TESTBED/SD_init.dat";
parameter CYCLE_DELAY = 10000;
integer pat_read;
integer PAT_NUM;
integer total_latency, latency;
integer i_pat, i, j;
integer counter;

//================================================================
// wire & registers 
// ================================================================
reg [63:0] golden_DRAM[0:8191];
reg [63:0] golden_SD[0:65535];
reg        pat_direction;
reg [13:0] pat_addr_DRAM;
reg [15:0] pat_addr_SD;
reg isCheckMAIN_2;
reg [7:0] golden_ans_decomp [0:7];
reg [63:0] golden_ans;
reg B_READY_check, B_VALID_check;
reg W_READY_check, W_VALID_check;

//================================================================
// initial
//================================================================
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

initial begin
    pat_read = $fopen("../00_TESTBED/Input.txt", "r"); 
    $readmemh(DRAM_p, golden_DRAM);
    $readmemh(SD_p, golden_SD);

    reset_signal_task;

    i_pat = 0;
    total_latency = 0;

    i = $fscanf(pat_read, "%d", PAT_NUM); 
    for (i_pat = 1; i_pat <= PAT_NUM; i_pat = i_pat + 1) begin
        input_task;
        wait_out_valid_task;
        check_ans_task;
        total_latency = total_latency + latency;
        $display("PASS PATTERN NO.%4d", i_pat);
    end
    $fclose(pat_read);

    $writememh("../00_TESTBED/DRAM_final.dat", u_DRAM.DRAM); //Write down your DRAM Final State
    $writememh("../00_TESTBED/SD_final.dat", u_SD.SD);		 //Write down your SD CARD Final State
    YOU_PASS_task;
end

//================================================================
// Global task
//================================================================
task reset_signal_task; begin
    rst_n      = 'b1;
    in_valid   = 'b0;
	direction  = 'bx;
	addr_dram  = 'bx;
    addr_sd	   = 'bx;
    latency    = 0;
    isCheckMAIN_2 = 0;
    B_READY_check = 0;
    B_VALID_check = 0;

    force clk = 0;
    #CYCLE;       rst_n = 0; 
    #(100)      //The pattern will check the output signal 100ns after the reset signal is pulled low.

    if( (out_valid !== 0) || (out_data !== 0) || 
        (AW_ADDR !== 0) || (AW_VALID !== 0) || (W_VALID !== 0)   || (W_DATA !== 0)   || 
        (B_READY !== 0) || (AR_ADDR !== 0)  ||(AR_VALID !== 0)   || (R_READY !== 0)  || 
        (MOSI !== 1) ) begin

        $display("***********************************************************************");
        $display("*  Error Code: SPEC MAIN-1 FAIL                                       *");
        $display("*  All output signals should be reset after the reset signal is asserted.");
        $display("***********************************************************************");
        $finish;
    end

    #(CYCLE); rst_n = 1;
    #(CYCLE); release clk;
    isCheckMAIN_2 = 1;
end 
endtask 

task input_task; begin
    i = $fscanf(pat_read, "%d %d %d", pat_direction, pat_addr_DRAM, pat_addr_SD); 

    repeat($random() % 3 + 1) @(negedge clk);// Random delay for 2 ~ 4 cycle
    //for input task
    in_valid = 1;
    direction = pat_direction;
    addr_dram = pat_addr_DRAM; 
    addr_sd = pat_addr_SD;

    //for output task -> write here is good to debug
    if(pat_direction) begin //SD->DRAM
        golden_ans = u_SD.SD[pat_addr_SD];    
        golden_DRAM[pat_addr_DRAM] =  golden_ans;
    end
     else begin //DRAM->SD
        golden_ans = u_DRAM.DRAM[pat_addr_DRAM]; 
        golden_SD[pat_addr_SD] =  golden_ans;
    end

    @(negedge clk);
    in_valid = 0;
    direction = 'bx;
    addr_dram = 'bx;
    addr_sd = 'bx;

end 
endtask 

task wait_out_valid_task; begin
    latency = -1;
    B_READY_check = 0;
    B_VALID_check = 0;
    W_READY_check = 0;
    W_VALID_check = 0;
    while(out_valid !== 1) begin
        latency = latency + 1;
        if(latency == CYCLE_DELAY) begin
            $display("***********************************************************************");
            $display("*  Error Code: SPEC MAIN-3 FAIL                                       *");
            $display("*  The execution latency is limited in 10000 cycles.                  *");
            $display("***********************************************************************");
            $finish;
        end

        if(B_READY) begin
            B_READY_check = B_READY;
        end
        if(B_VALID) begin
            B_VALID_check = B_VALID;
        end
        if(W_READY) begin
            W_READY_check = W_READY;
        end
        if(W_VALID) begin
            W_VALID_check = W_VALID;
        end
        @(negedge clk);//one cycle do one time
    end
    //@(negedge clk);//Moving it here will cause the while loop to finish instantly.
end 
endtask 

task check_ans_task; begin

    golden_ans_decomp[7] = golden_ans[7:0];
    golden_ans_decomp[6] = golden_ans[15:8];
    golden_ans_decomp[5] = golden_ans[23:16];
    golden_ans_decomp[4] = golden_ans[31:24];
    golden_ans_decomp[3] = golden_ans[39:32];
    golden_ans_decomp[2] = golden_ans[47:40];
    golden_ans_decomp[1] = golden_ans[55:48];
    golden_ans_decomp[0] = golden_ans[63:56];

    counter = -1;
    while(out_valid === 1) begin

        counter = counter + 1;
        if(counter > 7) begin
            $display("***********************************************************************");
            $display("*  Error Code: SPEC MAIN-4 FAIL                                       *");
            $display("*  The out_valid is no pull low                                       *");
            $display("***********************************************************************");
            $finish;   
        end

        if(pat_direction) begin //(1) SD card -> DRAM   (0) DRAM -> SD card 
            if(!W_READY_check || !W_VALID_check) begin
                $display("***********************************************************************");
                $display("*  Error Code: SPEC MAIN-6 FAIL                                       *");
                $display("*  it doesn't write data into DRAM-DRAM.(6-2)*                         ");
                $display("***********************************************************************");
                $finish;      
            end
            if(!B_READY_check || !B_VALID_check) begin
                $display("***********************************************************************");
                $display("*  Error Code: SPEC MAIN-6 FAIL                                       *");
                $display("*  Write Response Channel (B_RADY and B_VALID) not both pull high yet-DRAM.(6-5)*");
                $display("***********************************************************************");
                $finish;      
            end
        end
        
        for(i=0; i<=8191; i=i+1) begin
            if(golden_DRAM[i] !== u_DRAM.DRAM[i]) begin
                $display("***********************************************************************");
                $display("*  Error Code: SPEC MAIN-6 FAIL                                       *");
                $display("*  The data in the DRAM and SD card should be correct when out_valid is high-DRAM.(6-1, 6-3)*");
                $display("***********************************************************************");
                $finish;                   
            end
        end

        for(i=0; i<=65535; i=i+1) begin
            if(!MISO || golden_SD[i] !== u_SD.SD[i]) begin
                $display("***********************************************************************");
                $display("*  Error Code: SPEC MAIN-6 FAIL                                       *");
                $display("*  The data in the DRAM and SD card should be correct when out_valid is high-SD.(6-4)*");
                $display("***********************************************************************");
                $finish;                   
            end
        end

        if(out_data !==  golden_ans_decomp[counter]) begin
            $display("***********************************************************************");
            $display("*  Error Code: SPEC MAIN-5 FAIL                                       *");
            $display("*  The out_data should be correct when out_valid is high.           *");
            $display("***********************************************************************");
            $finish;              
        end
        @(negedge clk);

    end

    if(counter < 7) begin
            $display("***********************************************************************");
            $display("*  Error Code: SPEC MAIN-4 FAIL                                       *");
            $display("*  The asserted is less than 8 cycles                                 *");
            $display("***********************************************************************");
            $finish;        
    end
    @(negedge clk);
end 
endtask    

always @(*) begin
    if(isCheckMAIN_2) begin
        if((out_valid === 0) && (out_data !== 0)) begin
            $display("***********************************************************************");
            $display("*  Error Code: SPEC MAIN-2 FAIL                                       *");
            $display("*  The out_data should be reset when your out_valid is low.           *");
            $display("***********************************************************************");
            $finish;
        end       
    end
    @(negedge clk);
end

task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*                Your execution cycles = %5d cycles          *", total_latency);
    $display("*                Your clock period = %.1f ns          *", CYCLE);
    $display("*                Total Latency = %.1f ns          *", total_latency*CYCLE);
    $display("*************************************************************************");
    $finish;
end endtask

task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                    Error message from PATTERN.v                       *");
end endtask

pseudo_DRAM u_DRAM (
    .clk(clk),
    .rst_n(rst_n),
    // write address channel
    .AW_ADDR(AW_ADDR),
    .AW_VALID(AW_VALID),
    .AW_READY(AW_READY),
    // write data channel
    .W_VALID(W_VALID),
    .W_DATA(W_DATA),
    .W_READY(W_READY),
    // write response channel
    .B_VALID(B_VALID),
    .B_RESP(B_RESP),
    .B_READY(B_READY),
    // read address channel
    .AR_ADDR(AR_ADDR),
    .AR_VALID(AR_VALID),
    .AR_READY(AR_READY),
    // read data channel
    .R_DATA(R_DATA),
    .R_VALID(R_VALID),
    .R_RESP(R_RESP),
    .R_READY(R_READY)
);

pseudo_SD u_SD (
    .clk(clk),
    .MOSI(MOSI),
    .MISO(MISO)
);

endmodule