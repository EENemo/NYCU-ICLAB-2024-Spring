module bridge(input clk, INF.bridge_inf inf);
import usertype::*;
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
logic AR_VALID_w, R_READY_w, AW_VALID_w, W_VALID_w, B_READY_w;
logic [16:0] AR_ADDR_w, AW_ADDR_w;
logic [63:0] W_DATA_w;
logic [16:0] real_addr;
logic [16:0] address_r, address_w;

logic C_out_valid_w;
logic [63:0] C_data_r_w;

logic [10:0] shift_add;
logic [63:0] data_w, data_r;
//================================================================
// design
//================================================================
//output to bev
always_comb begin
    if((inf.B_VALID && !inf.B_READY) || (inf.R_VALID && !inf.R_READY)) begin
        C_out_valid_w = 1;
    end
    else begin
        C_out_valid_w = 0;
    end
end

//address
assign shift_add = inf.C_addr << 3;
assign real_addr = {1'd1, 5'd0, shift_add};
assign address_w = real_addr;
assign inf.AR_ADDR = address_r;
assign inf.AW_ADDR = address_r;

//data
always_comb begin
    if(!inf.C_r_wb) begin
        data_w = inf.C_data_w;
    end 
    else if(inf.R_VALID) begin
        data_w = inf.R_DATA;
    end
    else begin
        data_w = data_r;
    end
end
assign inf.W_DATA = data_r;
assign inf.C_data_r = data_r;

//AR channel
always_comb begin
    if(inf.AR_READY) begin
        AR_VALID_w = 0;
    end
    else if(inf.C_in_valid && inf.C_r_wb) begin
        AR_VALID_w = 1;
    end 
    else begin
        AR_VALID_w = inf.AR_VALID;
    end
end

//R channel
always_comb begin
    if(inf.R_READY) begin
        R_READY_w = 0;
    end
    else if(inf.R_VALID) begin
        R_READY_w = 1;
    end 
    else begin
        R_READY_w = inf.R_READY;
    end

end

//AW channel
always_comb begin
    if(inf.AW_READY) begin
        AW_VALID_w = 0;
    end
    else if(inf.C_in_valid && !inf.C_r_wb) begin
        AW_VALID_w = 1;
    end 
    else begin
        AW_VALID_w = inf.AW_VALID;
    end
end

//W channel
always_comb begin
    if(inf.W_READY) begin
        W_VALID_w = 0; 
    end
    else if(inf.C_in_valid && !inf.C_r_wb) begin
        W_VALID_w = 1;
    end        
    else begin
        W_VALID_w = inf.W_VALID; 
    end
end

//WB channel
always_comb begin
    if(inf.B_READY) begin
        B_READY_w = 0;
    end
    else if(inf.B_VALID) begin
        B_READY_w = 1;
    end
    else begin
        B_READY_w = 0;
    end
end

always_ff @(posedge clk, negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.AR_VALID <= 0;
        inf.R_READY <= 0;
        inf.AW_VALID <= 0;
        inf.W_VALID <= 0;
        inf.B_READY <= 0;

        inf.C_out_valid <= 0;
        data_r <= 0;
        address_r <= 0;
    end
    else begin
        inf.AR_VALID <= AR_VALID_w;
        inf.R_READY <= R_READY_w;
        inf.AW_VALID <= AW_VALID_w;
        inf.W_VALID <= W_VALID_w;
        inf.B_READY <= B_READY_w;

        inf.C_out_valid <= C_out_valid_w;
        data_r <= data_w;
        address_r <= address_w;
    end
end

endmodule
