module Handshake_syn #(parameter WIDTH=8) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output  sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
output reg flag_handshake_to_clk1;
input flag_clk1_to_handshake;

output flag_handshake_to_clk2;
input flag_clk2_to_handshake;

// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;

//---------------------------------------------------------------------
//   reg_wire                     V5 lastst    back
//---------------------------------------------------------------------	
reg [WIDTH-1:0] src_data_r, src_data_w;
reg [WIDTH-1:0] dout_w;
reg sreq_w, dack_w;
reg dvalid_r;
wire dvalid_w;
//---------------------------------------------------------------------
//   design                         
//---------------------------------------------------------------------	
//source
assign sidle = (!sreq && !sack);

always @(*) begin
    if(sready && sidle) begin
        src_data_w = din;
    end
    else begin
        src_data_w = src_data_r;
    end
end

always @(*) begin
    if(sready) begin
        sreq_w = 1;
    end
    else if(sack) begin
        sreq_w = 0;
    end
    else begin
        sreq_w = sreq;
    end
end

NDFF_syn U_S2D (.D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n));

always @(posedge sclk, negedge rst_n) begin
    if(!rst_n) begin
        src_data_r <= 0;
        sreq <= 0;
    end
    else begin
        src_data_r <= src_data_w;
        sreq <= sreq_w;
    end
end

//destination
assign dvalid_w = dack;

always @(*) begin
    if(dack) begin
        dvalid = dvalid_w ^ dvalid_r;
    end
    else begin
        dvalid = 0;
    end
end

always @(*) begin
    if(dreq) begin
        dout_w = src_data_r;
    end
    else begin
        dout_w = dout;
    end
end

always @(*) begin
    if(dreq) begin
        dack_w = 1;
    end
    else begin
        dack_w = 0;
    end
end

NDFF_syn U_D2S (.D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n));

always @(posedge dclk, negedge rst_n) begin
    if(!rst_n) begin
        dout <= 0;
        dack <= 0;
        dvalid_r <= 0;
    end
    else begin
        dout <= dout_w;
        dack <= dack_w;
        dvalid_r <= dvalid_w;
    end
end

endmodule