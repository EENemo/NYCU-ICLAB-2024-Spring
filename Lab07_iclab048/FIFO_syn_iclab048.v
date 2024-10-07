module FIFO_syn #(parameter WIDTH=8, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo,

    flag_fifo_to_clk1,
	flag_clk1_to_fifo
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
output  flag_fifo_to_clk2;
input flag_clk2_to_fifo;

output flag_fifo_to_clk1;
input flag_clk1_to_fifo;

wire [WIDTH-1:0] rdata_q;

// Remember: 
//   wptr and rptr should be gray coded
//   Don't modify the signal name
reg [$clog2(WORDS):0] wptr;
reg [$clog2(WORDS):0] rptr;

// rdata
//  Add one more register stage to rdata
reg rinc_shift1_r, rinc_shift2_r;
always @(posedge rclk, negedge rst_n) begin
    if (!rst_n) begin
        rdata <= 0;
    end
    else begin
		if (rinc_shift1_r) begin
			rdata <= rdata_q;
		end
    end
end

//---------------------------------------------------------------------
//   reg_wire               V5 lastst          back
//---------------------------------------------------------------------	
wire w_we;
wire [6:0] waddr, raddr;
wire [6:0] wq2_rptr, rq2_wptr;
reg [6:0] wb_cnt_r;
wire [6:0] wb_cnt_w, wptr_w;
reg [6:0] rb_cnt_r;
wire [6:0] rb_cnt_w, rptr_w;
reg rempty_w;
reg wfull_w;
wire w_efficient, r_efficient;

//---------------------------------------------------------------------
//   design                         
//---------------------------------------------------------------------	
//Write pointer
assign w_efficient = (winc && ~wfull);
assign wb_cnt_w = wb_cnt_r + w_efficient;
assign wptr_w = (wb_cnt_w>>1) ^ wb_cnt_w;

//Write Sram
assign waddr = wb_cnt_r;
assign w_we = ~w_efficient;

//full signal
always @(*) begin
    if(wptr_w == {~wq2_rptr[6], ~wq2_rptr[5], wq2_rptr[4:0]}) begin
        wfull_w = 1;
    end
    else begin
        wfull_w = 0;
    end
end

always @(posedge wclk, negedge rst_n) begin
    if(!rst_n) begin
        wb_cnt_r <= 0;
        wptr <= 0;
        wfull <= 0;
    end
    else begin
        wb_cnt_r <= wb_cnt_w;
        wptr <= wptr_w; 
        wfull <= wfull_w;
    end
end

//Read pointer
assign r_efficient = (rinc & ~rempty);
assign rb_cnt_w = rb_cnt_r + r_efficient;
assign rptr_w = (rb_cnt_w>>1) ^ rb_cnt_w;

//Read Sram
assign raddr = rb_cnt_r;

//empty logic
always @(*) begin
    if(rptr_w == rq2_wptr) begin
        rempty_w = 1;
    end
    else begin
        rempty_w = 0;
    end
end

always @(posedge rclk, negedge rst_n) begin
    if(!rst_n) begin
        rb_cnt_r <= 0;
        rptr <= 0;
        rempty <= 0;
    end
    else begin
        rb_cnt_r <= rb_cnt_w;
        rptr <= rptr_w;
        rempty <= rempty_w;
    end
end

//Write2Read to read2Write synchronizer
NDFF_BUS_syn #(7) U_sync_w2r( .D(wptr), .Q(rq2_wptr), .clk(rclk), .rst_n(rst_n) );
NDFF_BUS_syn #(7) U_sync_r2w( .D(rptr), .Q(wq2_rptr), .clk(wclk), .rst_n(rst_n) );


//for clk1 module read data delay
assign flag_fifo_to_clk1 = rinc_shift1_r;
always @(posedge rclk, negedge rst_n) begin
    if(!rst_n) begin
        rinc_shift1_r <= 0;
        rinc_shift2_r <= 0;
    end
    else begin
        rinc_shift1_r <= rinc;
        rinc_shift2_r <= rinc_shift1_r;
    end
end


DUAL_64X8X1BM1 u_dual_sram (
    .CKA(wclk),
    .CKB(rclk),
    .WEAN(w_we),
    .WEBN(1'b1),
    .CSA(1'b1),
    .CSB(1'b1),
    .OEA(1'b1),
    .OEB(1'b1),
    .A0(waddr[0]),
    .A1(waddr[1]),
    .A2(waddr[2]),
    .A3(waddr[3]),
    .A4(waddr[4]),
    .A5(waddr[5]),
    .B0(raddr[0]),
    .B1(raddr[1]),
    .B2(raddr[2]),
    .B3(raddr[3]),
    .B4(raddr[4]),
    .B5(raddr[5]),
    .DIA0(wdata[0]),
    .DIA1(wdata[1]),
    .DIA2(wdata[2]),
    .DIA3(wdata[3]),
    .DIA4(wdata[4]),
    .DIA5(wdata[5]),
    .DIA6(wdata[6]),
    .DIA7(wdata[7]),
    .DIB0(1'b0),
    .DIB1(1'b0),
    .DIB2(1'b0),
    .DIB3(1'b0),
    .DIB4(1'b0),
    .DIB5(1'b0),
    .DIB6(1'b0),
    .DIB7(1'b0),
    .DOB0(rdata_q[0]),
    .DOB1(rdata_q[1]),
    .DOB2(rdata_q[2]),
    .DOB3(rdata_q[3]),
    .DOB4(rdata_q[4]),
    .DOB5(rdata_q[5]),
    .DOB6(rdata_q[6]),
    .DOB7(rdata_q[7])
);


endmodule
