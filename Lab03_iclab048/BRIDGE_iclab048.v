//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : Ting-Yu Chang
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : BRIDGE_encrypted.v
//   Module Name : BRIDGE
//   Release version : v1.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module BRIDGE(
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

// Input Signals
input clk, rst_n;
input in_valid;
input direction;
input [12:0] addr_dram;
input [15:0] addr_sd;

// Output Signals
output reg out_valid;
output reg [7:0] out_data;

// DRAM Signals
// write address channel
output reg [31:0] AW_ADDR;
output reg AW_VALID;
input AW_READY;
// write data channel
output reg W_VALID;
output reg [63:0] W_DATA;
input W_READY;
// write response channel
input B_VALID;
input [1:0] B_RESP;
output reg B_READY;
// read address channel
output reg [31:0] AR_ADDR;
output reg AR_VALID;
input AR_READY;
// read data channel
input [63:0] R_DATA;
input R_VALID;
input [1:0] R_RESP;
output reg R_READY;

// SD Signals
input MISO;
output reg MOSI;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
parameter IDLE = 0,         DIREC = 1,      WAIT = 2,      
          R_DRAM_AR = 3,    R_DRAM_R = 4,
          W_DRAM_AW = 5,    W_DRAM_W = 6,   W_DRAM_B = 7,
          R_SD_CRC7 = 8,    R_SD_COM = 9,   R_SD_RES = 10,  R_SD_DATA = 11,    R_SD_CRC16 = 12,
          W_SD_CRC7 = 13,   W_SD_COM = 14,  W_SD_RES = 15,  W_SD_CRC16 = 16,   W_SD_DATA = 17,  W_SD_DATA_RES =18,
          OUT = 19,         WAIT8 = 20    ;

parameter CMD24 = 6'd24,
          CMD17 = 6'd17;

parameter START_TOKEN = 8'hFE;
//==============================================//
//           reg & wire declaration             //
//==============================================//
//output
reg out_valid_w;
reg [7:0] out_data_w;
reg AW_VALID_w, W_VALID_w, B_READY_w, AR_VALID_w, R_READY_w;
reg [31:0] AW_ADDR_w, AR_ADDR_w;
reg [63:0] W_DATA_w;
reg MOSI_w;     
//DFF
reg [4:0] state_cs, state_ns;
reg [4:0] next_state_cs, next_state_ns;
reg direction_r, direction_w;
reg [31:0] addr_dram_r, addr_dram_w;
reg [31:0] addr_sd_r, addr_sd_w;
reg [63:0] data_r, data_w;
reg [6:0] counter_r, counter_w;
reg [3:0] wait_counter_r, wait_counter_w;
//crc
reg [6:0] CRC7_data_r, CRC7_data_w;
reg [15:0] CRC16_data_r ,CRC16_data_w;
reg [15:0] SD_CRC16_data_r ,SD_CRC16_data_w;    //SD transfer back
wire [47:0] r_sd_command_seq, w_sd_command_seq;
wire [87:0] w_sd_data_seq;

//==============================================//
//                  design                      //
//==============================================//
always @(*) begin
    next_state_ns = next_state_cs;

    case(state_cs)
        IDLE: state_ns = (in_valid) ? DIREC : IDLE; //1
        DIREC: state_ns = (direction_r) ? R_SD_CRC7 : R_DRAM_AR; //1  //(1) SD card -> DRAM   (0) DRAM -> SD card 
        WAIT: state_ns = (MISO == 0) ? next_state_cs : WAIT; //2
        WAIT8: state_ns = (wait_counter_r == 0) ? next_state_cs : WAIT8; //20
        R_DRAM_AR: state_ns = (AR_READY) ? R_DRAM_R : R_DRAM_AR; //3
        R_DRAM_R: state_ns = (R_VALID && R_READY && R_RESP == 0) ? W_SD_CRC7 : R_DRAM_R; //4
        W_DRAM_AW: state_ns = (AW_READY) ? W_DRAM_W : W_DRAM_AW; //5
        W_DRAM_W: state_ns = (W_READY) ? W_DRAM_B : W_DRAM_W; //6
        W_DRAM_B: begin //7
            if(B_VALID && B_READY && B_RESP == 0) 
                state_ns = OUT;
            else if(B_VALID) 
                state_ns = W_DRAM_B;
            else 
                state_ns = W_DRAM_B;
        end
        R_SD_CRC7: state_ns = R_SD_COM; //8           
        R_SD_COM: begin//9
            if(counter_r < 48) 
                state_ns = R_SD_COM;
            else begin
                state_ns = WAIT;
                next_state_ns = R_SD_RES;
            end            
        end
        R_SD_RES: begin//10
            if(MISO == 0) begin
                state_ns = R_SD_RES;
            end
            else begin
                state_ns = WAIT;
                next_state_ns = R_SD_DATA;
            end       
        end
        R_SD_DATA: state_ns = (counter_r < 80) ? R_SD_DATA : R_SD_CRC16; //11
        R_SD_CRC16: state_ns = W_DRAM_AW; //12
        W_SD_CRC7: state_ns = W_SD_COM; //13
        W_SD_COM: begin //14
            if(counter_r < 48) 
                state_ns = W_SD_COM;
            else begin
                state_ns = WAIT;
                next_state_ns = W_SD_RES;
            end
        end
        W_SD_RES: state_ns = (MISO == 0) ? W_SD_RES : W_SD_CRC16;//15
        W_SD_CRC16: begin//16
            state_ns = WAIT8; 
            next_state_ns = W_SD_DATA;
        end
        W_SD_DATA: begin//17
            if(counter_r < 88) 
                state_ns = W_SD_DATA;
            else begin
                state_ns = WAIT8;
                next_state_ns = W_SD_DATA_RES;
            end           
        end    
        W_SD_DATA_RES: state_ns = (MISO == 1) ? OUT : W_SD_DATA_RES; //18
        OUT: state_ns = (counter_r == 8) ? IDLE : OUT; //19
        default: state_ns = IDLE;
    endcase
end
//==============================================
//                  input & output                         
//==============================================
//input data
always @(*) begin
    if(state_cs == IDLE && in_valid) begin
        direction_w = direction;
        addr_dram_w = addr_dram;
        addr_sd_w = addr_sd;        
    end
    else begin
        direction_w = direction_r;
        addr_dram_w = addr_dram_r;
        addr_sd_w = addr_sd_r;        
    end
end
//output data
always @(*) begin
    if(state_cs == OUT) begin
        out_valid_w = 1;
        case(counter_r)
            0: out_data_w = data_r[63:56];
            1: out_data_w = data_r[55:48];
            2: out_data_w = data_r[47:40];
            3: out_data_w = data_r[39:32];
            4: out_data_w = data_r[31:24];
            5: out_data_w = data_r[23:16];
            6: out_data_w = data_r[15:8];
            7: out_data_w = data_r[7:0];
            default: begin
                out_valid_w = 0;
                out_data_w = 0;
            end 
        endcase    
    end 
    else begin
        out_valid_w = 0;
        out_data_w = 0;
    end      
end
//==============================================
//                  AXI                         
//==============================================
//AW_channel
always @(*) begin
    if(state_cs == W_DRAM_AW) begin
        if(AW_READY && AW_VALID) begin
            AW_VALID_w = 0;
            AW_ADDR_w = 0;
        end
        else begin
            AW_VALID_w = 1;
            AW_ADDR_w = addr_dram_r;
        end 
    end
    else begin
        AW_VALID_w = 0;
        AW_ADDR_w = 0; 
    end
end
//W_channel
always @(*) begin
    if(state_cs == W_DRAM_W) begin
        if(W_READY && W_VALID) begin
            W_VALID_w = 0;
            W_DATA_w = 0;   
        end
        else begin
            W_VALID_w = 1;
            W_DATA_w = data_r;   
        end        
    end
    else begin
        W_VALID_w = 0;
        W_DATA_w = 0;   
    end
end
//WB channel
always @(*) begin
    if(state_cs == W_DRAM_B) begin
        if(B_VALID && B_READY && B_RESP == 0) 
            B_READY_w = 0;
        else if(B_VALID) 
            B_READY_w = 1;
        else 
            B_READY_w = 0;
    end
    else 
        B_READY_w = 0;
end
//AR_channel
always @(*) begin
    if(state_cs == R_DRAM_AR) begin
        if(AR_READY && AR_VALID) begin
            AR_VALID_w = 0;
            AR_ADDR_w = 0;
        end
        else begin
            AR_VALID_w = 1;
            AR_ADDR_w = addr_dram_r;
        end 
    end
    else begin
        AR_VALID_w = 0;
        AR_ADDR_w = 0; 
    end
end
//R_channel
always @(*) begin
    if(state_cs == R_DRAM_R) begin
        if(R_VALID && R_READY && R_RESP == 0) 
            R_READY_w = 0;
        else 
            R_READY_w = 1;
    end
    else begin
        R_READY_w = 0;
    end
end

//==============================================
//                  SD                         
//==============================================
//CRC7_data_w
always @(*) begin
    if(state_cs == R_SD_CRC7) begin
        CRC7_data_w = CRC7({2'b01, CMD17, addr_sd_r});
    end
    else if(state_cs == W_SD_CRC7) begin
        CRC7_data_w = CRC7({2'b01, CMD24, addr_sd_r});
    end
    else begin
        CRC7_data_w = CRC7_data_r;
    end
end

//CRC16_data_w
always @(*) begin
    if(state_cs == W_SD_CRC16) begin
        CRC16_data_w = CRC16_CCITT(data_r);
    end
    else begin
        CRC16_data_w = CRC16_data_r;
    end
end

//MOSI
assign r_sd_command_seq = {2'b01, CMD17, addr_sd_r, CRC7_data_r, 1'b1};
assign w_sd_command_seq = {2'b01, CMD24, addr_sd_r, CRC7_data_r, 1'b1};
assign w_sd_data_seq = {START_TOKEN, data_r, CRC16_data_r};
always @(*) begin
    if(state_cs == R_SD_COM) begin
        if(counter_r < 48)begin
            MOSI_w = r_sd_command_seq[47-counter_r];
        end
        else 
            MOSI_w =1;
    end
    else if(state_cs == W_SD_COM) begin
        if(counter_r < 48) begin
            MOSI_w = w_sd_command_seq[47-counter_r];
        end
        else 
            MOSI_w =1;
    end
    else if(state_cs == W_SD_DATA) begin
        if(counter_r < 88) begin
            MOSI_w = w_sd_data_seq[87-counter_r];
        end
        else 
            MOSI_w =1;
    end
    else begin
        MOSI_w = 1;
    end
end

//MISO & AXI R_channel data
always @(*) begin
    data_w = data_r;
    if(state_cs == R_SD_DATA) begin
        if(counter_r < 64) 
            data_w[63-counter_r] = MISO;        
        else if(counter_r < 80)
            SD_CRC16_data_w[79-counter_r] = MISO; 
        else begin
            data_w = data_r;
            SD_CRC16_data_w = SD_CRC16_data_r;
        end  
    end
    else if(state_cs == R_DRAM_R) begin
        if(R_VALID && R_READY && R_RESP == 0) 
            data_w = R_DATA;
        else 
            data_w = data_r;
    end
    else begin
        data_w = data_r;
        SD_CRC16_data_w = SD_CRC16_data_r;
    end
end

//counter
always @(*) begin //counter < 48
    if(state_cs == R_SD_COM || state_cs == W_SD_COM) begin
        if(counter_r < 48) begin
            counter_w = counter_r + 1;
        end
        else  begin
            counter_w = counter_r;
        end
    end
    else if(state_cs == R_SD_DATA || state_cs == W_SD_DATA) begin
        if(counter_r < 88) begin
            counter_w = counter_r + 1;
        end
        else  begin
            counter_w = counter_r;
        end        
    end
    else if(state_cs == OUT) begin
        if(counter_r < 8) begin
            counter_w = counter_r + 1;
        end
        else  begin
            counter_w = counter_r;
        end          
    end
    else begin
        counter_w = 0;
    end
end

//wait_counter
always @(*) begin
    if(state_cs == W_SD_RES) begin
        wait_counter_w = 4;
    end
    else if(state_cs == W_SD_DATA) begin
        wait_counter_w = 8;
    end
    else if(state_cs == WAIT8) begin
        wait_counter_w = wait_counter_r - 1;
    end
    else begin
        wait_counter_w = wait_counter_r;
    end
end

//==============================================
//                  DFF                         
//==============================================
//DFF
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        state_cs <= 0;
        next_state_cs <= 0;
        direction_r <= 0;
        addr_dram_r <= 0;
        addr_sd_r <= 0;
        data_r <= 0;
        counter_r <= 0;
        wait_counter_r <= 0;
        CRC7_data_r <= 0;
        CRC16_data_r <= 0;
        SD_CRC16_data_r <= 0;
    end
    else begin
        state_cs <= state_ns;
        next_state_cs <= next_state_ns;
        direction_r <= direction_w;
        addr_dram_r <= addr_dram_w;
        addr_sd_r <= addr_sd_w;
        data_r <= data_w;
        counter_r <= counter_w;
        wait_counter_r <= wait_counter_w;
        CRC7_data_r <= CRC7_data_w;
        CRC16_data_r <= CRC16_data_w;
        SD_CRC16_data_r <= SD_CRC16_data_w;
    end
end

//output DFF
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out_data <= 0;
        AW_ADDR <= 0;
        AW_VALID <= 0;
        W_VALID <= 0;
        W_DATA <= 0;
        B_READY <= 0;
        AR_ADDR <= 0;
        AR_VALID <= 0;
        R_READY <= 0;
        MOSI <= 1;
    end
    else begin
        out_valid <= out_valid_w;
        out_data <= out_data_w;
        AW_ADDR <= AW_ADDR_w;
        AW_VALID <= AW_VALID_w;
        W_VALID <= W_VALID_w;
        W_DATA <= W_DATA_w;
        B_READY <= B_READY_w;
        AR_ADDR <= AR_ADDR_w;
        AR_VALID <= AR_VALID_w;
        R_READY <= R_READY_w;
        MOSI <= MOSI_w;        
    end
end

//==============================================//
//             Example for function             //
//==============================================//
function automatic [6:0] CRC7;  // Return 7-bit result
    input [39:0] data;  // 40-bit data input
    reg [6:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 7'h9;  // x^7 + x^3 + 1

    begin
        crc = 7'd0;
        for (i = 0; i < 40; i = i + 1) begin
            data_in = data[39-i];
            data_out = crc[6];
            crc = crc << 1;  // Shift the CRC
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC7 = crc;
    end
endfunction

function automatic [15:0] CRC16_CCITT;
    input [63:0] data;  // 40-bit data input
    reg [15:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 16'h1021;  // x^16 + x^12 + x^5 + 1

    begin
        crc = 16'd0;
        for (i = 0; i < 64; i = i + 1) begin
            data_in = data[63-i];
            data_out = crc[15];
            crc = crc << 1;  // Shift the CRC
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC16_CCITT = crc;
    end
endfunction
endmodule

