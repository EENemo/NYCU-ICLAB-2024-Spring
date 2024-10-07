//fix waring ALL
module CAD(
    // input signals
    clk,
    rst_n,
    in_valid, 
    in_valid2,
    mode,
    matrix_size,
    matrix,
    matrix_idx,
    // output signals
    out_valid,
    out_value
    );

input [1:0] matrix_size;
input clk;
input [7:0] matrix;
input rst_n;
input [3:0] matrix_idx;
input in_valid2;

input mode;
input in_valid;
output reg out_valid;
output reg out_value;
//=======================================================
//                   Reg/Wire
//=======================================================
parameter IDLE = 4'd0, 
          LOAD_D = 4'd1, 
          LOAD_W = 4'd2, 
          IDX = 4'd3, 
          READ_IMG = 4'd4, 
          CONV = 4'd5,
          DCONV = 4'd6,
          OUT = 4'd7,
          SKIP = 4'd8,
          SEND = 4'd9;
          
integer i;
reg [3:0] state_cs, state_ns;
reg [1:0] m_size_r, m_size_w;
reg in_valid2_r;
reg in_valid2_w;
reg [3:0] m_idx_r [0:1];
reg [3:0] m_idx_w [0:1];
reg m_mode_r, m_mode_w;
reg [13:0] w_counter_r, w_counter_w;
reg w_counter_rst;

reg [13:0] d_addr_offset;
reg [8:0] w_addr_offset;
reg [13:0] rd_counter_r, rd_counter_w;
reg [10:0] rw_counter_r, rw_counter_w;
reg [13:0] d_addr_tmp;
reg [13:0] d_addr;
reg [8:0] w_addr_tmp;
reg [8:0] w_addr;
reg d_we, w_we;
reg read_img_finish_flag;
reg [9:0] img_counter_r, img_counter_w;
reg [10:0] adtr_addr_cnt_r, adtr_addr_cnt_w;
reg [10:0] out_addr_cnt_r, out_addr_cnt_w;
reg [4:0] send_cnt_r, send_cnt_w;
reg [4:0] out_send_cnt_r, out_send_cnt_w;
reg out_we;
reg [10:0] o_addr_tmp;
reg [10:0] o_addr;
reg out_addr_cnt_en;
reg [19:0] out_ram_r;
reg [19:0] out_ram_w;
wire [19:0] out_ram;
reg out_valid_w, out_value_w;
reg send_flag_w, send_flag_r;
//=======================================================
//                     FSM
//=======================================================
always @(*) begin
    w_counter_rst = 0;
    case(state_cs)
        IDLE: begin
            if(in_valid) 
                state_ns = LOAD_D;
            else if(in_valid2) 
                state_ns = IDX;
            else
                state_ns = IDLE;
        end
        LOAD_D: begin
            if( (m_size_r == 2 && (&w_counter_r)) || (m_size_r == 1 && (&w_counter_r[11:0]) ) || (m_size_r == 0 && (&w_counter_r[9:0])) ) begin
                w_counter_rst = 1;
                state_ns = LOAD_W;
            end
            else begin
                state_ns = LOAD_D;
            end
        end
        LOAD_W: begin
            if(w_counter_r == 399) begin
                w_counter_rst = 1;
                state_ns = IDX;
            end
            else begin
                state_ns = LOAD_W;
            end
        end
        IDX: begin
            if(!in_valid2 && in_valid2_r) begin
                state_ns = READ_IMG;
            end
            else
                state_ns = IDX;
        end
        READ_IMG: begin
            if(read_img_finish_flag && m_mode_r == 0) begin
                state_ns = CONV;
            end
            else if(read_img_finish_flag && m_mode_r == 1) begin
                state_ns = DCONV;
            end
            else begin
                state_ns = READ_IMG;
            end
        end
        CONV: begin
            if(m_size_r == 0 && adtr_addr_cnt_r == 4) begin
                state_ns = OUT;
            end
            else if(m_size_r == 1 && adtr_addr_cnt_r == 36) begin
                state_ns = OUT;
            end
            else if(m_size_r == 2 && adtr_addr_cnt_r == 196) begin
                state_ns = OUT;
            end
            else begin
                state_ns = CONV;
            end
        end
        DCONV: begin
            if(m_size_r == 0 && adtr_addr_cnt_r == 144) begin
                state_ns = OUT;
            end
            else if(m_size_r == 1 && adtr_addr_cnt_r == 400) begin
                state_ns = OUT;
            end
            else if(m_size_r == 2 && adtr_addr_cnt_r == 1296) begin
                state_ns = OUT;
            end
            else begin
                state_ns = DCONV;
            end
        end
        OUT: begin
            state_ns = SKIP;
        end
        SKIP: begin
            state_ns = SEND;
        end
        SEND: begin
            if(m_mode_r) begin//DE
                if( m_size_r == 0 && out_addr_cnt_r == 144 && send_cnt_r == 19) begin
                    state_ns = IDLE;
                end
                else if(m_size_r == 1 && out_addr_cnt_r == 400 && send_cnt_r == 19) begin
                    state_ns = IDLE;
                end
                else if(m_size_r == 2 && out_addr_cnt_r == 1296 && send_cnt_r == 19) begin
                    state_ns = IDLE;
                end
                else begin
                    state_ns = SEND;
                end
            end
            else begin
                if(m_size_r == 0 && out_addr_cnt_r == 4 && send_cnt_r == 0) begin
                    state_ns = IDLE;
                end
                else if(m_size_r == 1 && out_addr_cnt_r == 36 && send_cnt_r == 0) begin
                    state_ns = IDLE;
                end
                else if(m_size_r == 2 && out_addr_cnt_r == 196 && send_cnt_r == 0) begin
                    state_ns = IDLE;
                end
                else begin
                    state_ns = SEND;
                end
            end
        end
        default: state_ns = IDLE;
    endcase
end

//matrix_size
always @(*) begin
    if(state_cs ==  IDLE && w_counter_r == 0 && in_valid) begin
        m_size_w = matrix_size;
    end
    else begin
        m_size_w = m_size_r;
    end
end

//matrix_idx && mode
always @(*) begin
    if(in_valid2) begin
        m_idx_w[0] = matrix_idx;
        m_idx_w[1] = m_idx_r[0];
    end
    else begin
        for(i=0; i<2; i=i+1) m_idx_w[i] = m_idx_r[i];
    end
end

always @(*) begin
    if(in_valid2 && !in_valid2_r) begin
        m_mode_w = mode;
    end
    else begin
        m_mode_w = m_mode_r;
    end
end

//DFF
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        state_cs <= 0;
        m_size_r <= 0;
        in_valid2_r <= 0;
        for(i=0; i<2; i=i+1) m_idx_r[i] <= 0;
        m_mode_r <= 0;

    end
    else begin
        state_cs <= state_ns;
        m_size_r <= m_size_w;
        in_valid2_r <= in_valid2;
        for(i=0; i<2; i=i+1) m_idx_r[i] <= m_idx_w[i];
        m_mode_r <= m_mode_w;
    end
end
//=======================================================
//                   Read & Write SRAM 
//=======================================================
//deal with address offset
always @(*) begin
    case(m_size_r)
        0: d_addr_offset = m_idx_r[1] * 64;//8*8
        1: d_addr_offset = m_idx_r[1] * 256;//16*16
        2: d_addr_offset = m_idx_r[1] * 1024;//32*32
        default: d_addr_offset = m_idx_r[1] * 64;
    endcase
end
always @(*) begin
    w_addr_offset = m_idx_r[0] * 25;
end

//write counter
always @(*) begin
    if(w_counter_rst) begin
        w_counter_w = 0;
    end
    else if(in_valid) begin
        w_counter_w = w_counter_r + 1;
    end
    else begin
        w_counter_w = w_counter_r;
    end
end

//read counter_data & read counter_kernel
always @(*) begin
    if(state_cs == IDX) begin
        rd_counter_w = d_addr_offset;
    end
    else if(state_cs == READ_IMG) begin
        rd_counter_w = rd_counter_r + 1;
    end
    else begin
        rd_counter_w = 0;
    end
end
always @(*) begin
    if(state_cs == IDX) begin
        rw_counter_w = w_addr_offset;
    end
    else if(state_cs == READ_IMG && img_counter_r < 25) begin
        rw_counter_w = rw_counter_r + 1;
    end
    else begin
        rw_counter_w = 0;
    end
end
//Address mux & WE
always @(*) begin
    if(in_valid && state_cs != LOAD_W) begin
        d_addr_tmp = w_counter_r;
        d_we = 0;
    end
    else begin
        d_addr_tmp = rd_counter_r;
        d_we = 1;
    end
end
always @(*) begin
    if(d_addr_tmp > 16383) begin
        d_addr = 0;
    end
    else begin
        d_addr = d_addr_tmp;
    end
end
always @(*) begin
    if(in_valid && state_cs == LOAD_W) begin
        w_addr_tmp = w_counter_r[8:0];
        w_we = 0;
    end
    else begin
        w_addr_tmp = rw_counter_r;
        w_we = 1;
    end
end
always @(*) begin
    if(w_addr_tmp > 399) begin
        w_addr = 0;
    end
    else begin
        w_addr = w_addr_tmp;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        w_counter_r <= 0;
        rd_counter_r <= 0;
        rw_counter_r <= 0;
    end
    else begin
        w_counter_r <= w_counter_w;
        rd_counter_r <= rd_counter_w;
        rw_counter_r <= rw_counter_w;
    end
end
//=======================================================
//                    Read signal
//=======================================================
reg signed [7:0] IMG_r [0:1023];
reg signed [7:0] IMG_w [0:1023];
reg signed [7:0] WEIGHT_r [0:24];
reg signed [7:0] WEIGHT_w [0:24];
reg signed [7:0] pad_img [0:1599];
wire [7:0] d_dout, w_dout;

reg [10:0] conv_cnt_start_r, conv_cnt_start_w;
reg [10:0]conv_cnt_nxt;
reg [3:0] conv_cnt_10t_r, conv_cnt_10t_w;
reg [10:0] conv_cnt_offset_r, conv_cnt_offset_w;
reg [4:0] conv_cnt_bt_r, conv_cnt_bt_w;
reg conv_mode_r, conv_mode_w;
reg [10:0] dconv_cnt_start_r, dconv_cnt_start_w;
reg [2:0] dconv_cnt_5t_r, dconv_cnt_5t_w;
reg [10:0] dconv_cnt_offset_r, dconv_cnt_offset_w;
reg [5:0] dconv_cnt_bt_r, dconv_cnt_bt_w;

reg signed [7:0] img_sel_r [0:4];
reg signed [7:0] img_sel_w [0:4];
reg signed [7:0] weight_sel_r [0:4];
reg signed [7:0] weight_sel_w [0:4];
reg [4:0] weight_cnt_r, weight_cnt_w;
reg read_img_wait1t_flag_r, read_img_wait1t_flag_w;
reg weight_cntwait1t_flag_r, weight_cntwait1t_flag_w;
reg weight_cntwait2t_flag_r, weight_cntwait2t_flag_w;
//IMG array counter
always @(*) begin
    if(state_cs == READ_IMG) begin
        read_img_wait1t_flag_w = 1;
    end
    else begin
        read_img_wait1t_flag_w = 0;
    end
end
always @(*) begin
    if(state_cs == READ_IMG && read_img_wait1t_flag_r) begin
        img_counter_w = img_counter_r + 1;
    end
    else begin
        img_counter_w = 0;
    end
end
always @(*) begin
    if(m_size_r == 0 && img_counter_r == 63) begin
        read_img_finish_flag = 1;
    end
    else if(m_size_r == 1 && img_counter_r == 255) begin
        read_img_finish_flag = 1;
    end
    else if(m_size_r == 2 && img_counter_r == 1023) begin
        read_img_finish_flag = 1;
    end
    else begin
        read_img_finish_flag = 0;
    end
end
//IMG & Weight array
always @(*) begin
    for(i=0; i<1024; i=i+1) IMG_w[i] = IMG_r[i];
    for(i=0; i<1024; i=i+1) begin
        if(img_counter_r == i && state_cs == READ_IMG) begin
            IMG_w[i] = d_dout;
        end
    end
    for(i=0; i<1024; i=i+1) begin
        if(state_cs == IDLE) begin
            IMG_w[i] = 0;
        end
    end
end
always @(*) begin
    for(i=0; i<25; i=i+1) begin
        if(img_counter_r == i && state_cs == READ_IMG) begin
            WEIGHT_w[i] = w_dout;
        end
        else begin
            WEIGHT_w[i] = WEIGHT_r[i];
        end
    end
end
//Padding
//Padding 層
always @(*) begin
    for(i=0; i<1600; i=i+1) pad_img[i] = 0;
    if(m_size_r == 2) begin
        for(i=0; i<32; i=i+1) begin
            pad_img[i+164] = IMG_r[i];
            pad_img[i+204] = IMG_r[i+32];
            pad_img[i+244] = IMG_r[i+64];
            pad_img[i+284] = IMG_r[i+96];
            pad_img[i+324] = IMG_r[i+128];
            pad_img[i+364] = IMG_r[i+160];
            pad_img[i+404] = IMG_r[i+192];
            pad_img[i+444] = IMG_r[i+224];
            pad_img[i+484] = IMG_r[i+256];
            pad_img[i+524] = IMG_r[i+288];
            pad_img[i+564] = IMG_r[i+320];
            pad_img[i+604] = IMG_r[i+352];
            pad_img[i+644] = IMG_r[i+384];
            pad_img[i+684] = IMG_r[i+416];
            pad_img[i+724] = IMG_r[i+448];
            pad_img[i+764] = IMG_r[i+480];
            pad_img[i+804] = IMG_r[i+512];
            pad_img[i+844] = IMG_r[i+544];
            pad_img[i+884] = IMG_r[i+576];
            pad_img[i+924] = IMG_r[i+608];
            pad_img[i+964] = IMG_r[i+640];
            pad_img[i+1004] = IMG_r[i+672];
            pad_img[i+1044] = IMG_r[i+704];
            pad_img[i+1084] = IMG_r[i+736];
            pad_img[i+1124] = IMG_r[i+768];
            pad_img[i+1164] = IMG_r[i+800];
            pad_img[i+1204] = IMG_r[i+832];
            pad_img[i+1244] = IMG_r[i+864];
            pad_img[i+1284] = IMG_r[i+896];
            pad_img[i+1324] = IMG_r[i+928];
            pad_img[i+1364] = IMG_r[i+960];
            pad_img[i+1404] = IMG_r[i+992];
        end
    end
    if(m_size_r == 1) begin
        for(i=0; i<16; i=i+1) begin
            pad_img[i+164] = IMG_r[i];
            pad_img[i+204] = IMG_r[i+16];
            pad_img[i+244] = IMG_r[i+32];
            pad_img[i+284] = IMG_r[i+48];
            pad_img[i+324] = IMG_r[i+64];
            pad_img[i+364] = IMG_r[i+80];
            pad_img[i+404] = IMG_r[i+96];
            pad_img[i+444] = IMG_r[i+112];
            pad_img[i+484] = IMG_r[i+128];
            pad_img[i+524] = IMG_r[i+144];
            pad_img[i+564] = IMG_r[i+160];
            pad_img[i+604] = IMG_r[i+176];
            pad_img[i+644] = IMG_r[i+192];
            pad_img[i+684] = IMG_r[i+208];
            pad_img[i+724] = IMG_r[i+224];
            pad_img[i+764] = IMG_r[i+240];
        end
    end
    if(m_size_r == 0) begin
        for(i=0; i<8; i=i+1) begin
            pad_img[i+164] = IMG_r[i];
            pad_img[i+204] = IMG_r[i+8];
            pad_img[i+244] = IMG_r[i+16];
            pad_img[i+284] = IMG_r[i+24];
            pad_img[i+324] = IMG_r[i+32];
            pad_img[i+364] = IMG_r[i+40];
            pad_img[i+404] = IMG_r[i+48];
            pad_img[i+444] = IMG_r[i+56];
        end
    end
end
//DCONV counter 區
always @(*) begin 
    if(state_cs == DCONV) begin
        if(m_size_r == 0 && dconv_cnt_bt_r == 11 && dconv_cnt_5t_r == 4) begin
            dconv_cnt_start_w = dconv_cnt_start_r + 29;
        end
        else if(m_size_r == 1 && dconv_cnt_bt_r == 19 && dconv_cnt_5t_r == 4) begin
            dconv_cnt_start_w = dconv_cnt_start_r + 21;
        end
        else if(m_size_r == 2 && dconv_cnt_bt_r == 35 && dconv_cnt_5t_r == 4) begin
            dconv_cnt_start_w = dconv_cnt_start_r + 5;
        end
        else if(dconv_cnt_5t_r == 4) begin
            dconv_cnt_start_w = dconv_cnt_start_r + 1;
        end
        else begin
            dconv_cnt_start_w = dconv_cnt_start_r;
        end
    end
    else begin
        dconv_cnt_start_w = 0;
    end
end
always @(*) begin
    if(state_cs == DCONV) begin
        if(dconv_cnt_5t_r == 4) begin
            dconv_cnt_5t_w = 0;
        end
        else begin
            dconv_cnt_5t_w = dconv_cnt_5t_r + 1;
        end
    end
    else begin
        dconv_cnt_5t_w = 0;
    end
end
always @(*) begin
    if(state_cs == DCONV) begin
        case(dconv_cnt_5t_r)
            0: dconv_cnt_offset_w = dconv_cnt_start_r;
            1: dconv_cnt_offset_w = dconv_cnt_offset_r + 40;
            2: dconv_cnt_offset_w = dconv_cnt_offset_r + 40;
            3: dconv_cnt_offset_w = dconv_cnt_offset_r + 40;
            4: dconv_cnt_offset_w = dconv_cnt_offset_r + 40;
            default: dconv_cnt_offset_w = dconv_cnt_start_r;
        endcase
    end
    else begin
        dconv_cnt_offset_w = dconv_cnt_start_r;
    end
end
always @(*) begin
    if(state_cs == IDLE) begin
        dconv_cnt_bt_w = 0;
    end
    else if(state_cs == DCONV && dconv_cnt_5t_r == 4) begin
        if(m_size_r == 0 && dconv_cnt_bt_r == 11) begin
            dconv_cnt_bt_w = 0;
        end
        else if(m_size_r == 1 && dconv_cnt_bt_r == 19) begin
            dconv_cnt_bt_w = 0;
        end
        else if(m_size_r == 2 && dconv_cnt_bt_r == 35) begin
            dconv_cnt_bt_w = 0;
        end
        else begin
            dconv_cnt_bt_w = dconv_cnt_bt_r + 1;  
        end
    end
    else begin
        dconv_cnt_bt_w = dconv_cnt_bt_r;
    end
end
//CONV counter 區
always @(*) begin 
    if(state_cs == CONV) begin
        if(m_size_r == 0 && conv_cnt_bt_r == 3 && conv_cnt_10t_r == 9) begin
            conv_cnt_start_w = conv_cnt_start_r + 77;
        end
        else if(m_size_r == 1 && conv_cnt_bt_r == 11 && conv_cnt_10t_r == 9) begin
            conv_cnt_start_w = conv_cnt_start_r + 69;
        end
        else if(m_size_r == 2 && conv_cnt_bt_r == 27 && conv_cnt_10t_r == 9) begin
            conv_cnt_start_w = conv_cnt_start_r + 53;
        end
        else if(conv_cnt_10t_r == 9) begin
            conv_cnt_start_w = conv_cnt_start_r + 1;
        end
        else begin
            conv_cnt_start_w = conv_cnt_start_r;
        end
    end
    else begin
        conv_cnt_start_w = 164;
    end
end
always @(*) begin
    conv_cnt_nxt = conv_cnt_start_r + 40;
end
always @(*) begin
    if(state_cs == CONV) begin
        if(conv_cnt_10t_r == 9) begin
            conv_cnt_10t_w = 0;
        end
        else begin
            conv_cnt_10t_w = conv_cnt_10t_r + 1;
        end
    end
    else begin
        conv_cnt_10t_w = 0;
    end
end
always @(*) begin
    if(state_cs == CONV) begin
        if(conv_cnt_10t_r == 4 || conv_cnt_10t_r == 8) begin
            conv_mode_w = ~conv_mode_r;
        end
        else begin
            conv_mode_w = conv_mode_r;
        end
    end
    else begin
        conv_mode_w = 0;
    end
end
always @(*) begin
    if(state_cs == CONV) begin
        case(conv_cnt_10t_r)
            0, 5: begin
                if(conv_mode_r) begin //1
                    conv_cnt_offset_w = conv_cnt_nxt;
                end
                else begin
                    conv_cnt_offset_w = conv_cnt_start_r;
                end
            end
            1, 6: conv_cnt_offset_w = conv_cnt_offset_r + 40;
            2, 7: conv_cnt_offset_w = conv_cnt_offset_r + 40;
            3, 8: conv_cnt_offset_w = conv_cnt_offset_r + 40;
            4, 9: conv_cnt_offset_w = conv_cnt_offset_r + 40;
            default: conv_cnt_offset_w = conv_cnt_start_r;
        endcase
    end
    else begin
        conv_cnt_offset_w = conv_cnt_start_r;
    end
end
always @(*) begin
    if(state_cs == IDLE) begin
        conv_cnt_bt_w = 0;
    end
    else if(state_cs == CONV && conv_cnt_10t_r == 9) begin
        if(m_size_r == 0 && conv_cnt_bt_r == 3) begin
            conv_cnt_bt_w = 0;
        end
        else if(m_size_r == 1 && conv_cnt_bt_r == 11) begin
            conv_cnt_bt_w = 0;
        end
        else if(m_size_r == 2 && conv_cnt_bt_r == 27) begin
            conv_cnt_bt_w = 0;
        end
        else begin
            conv_cnt_bt_w = conv_cnt_bt_r + 1;  
        end
    end
    else begin
        conv_cnt_bt_w = conv_cnt_bt_r;
    end
end
//MUX to DFF
always @(*) begin
    for(i=0; i<5; i=i+1) img_sel_w[i] = img_sel_r[i];
    if(m_mode_r) begin
        for(i=0; i<1596; i=i+1) begin
            if(dconv_cnt_offset_r == i) begin
                img_sel_w[0] = pad_img[i];
                img_sel_w[1] = pad_img[i+1];
                img_sel_w[2] = pad_img[i+2];
                img_sel_w[3] = pad_img[i+3];
                img_sel_w[4] = pad_img[i+4];
            end
        end
        if(dconv_cnt_offset_r > 1595) begin
            img_sel_w[0] = pad_img[0];
            img_sel_w[1] = pad_img[0];
            img_sel_w[2] = pad_img[0];
            img_sel_w[3] = pad_img[0];
            img_sel_w[4] = pad_img[0];
        end
    end
    else begin
        for(i=0; i<1596; i=i+1) begin
            if(conv_cnt_offset_r == i) begin
                img_sel_w[0] = pad_img[i];
                img_sel_w[1] = pad_img[i+1];
                img_sel_w[2] = pad_img[i+2];
                img_sel_w[3] = pad_img[i+3];
                img_sel_w[4] = pad_img[i+4];
            end
        end
        if(dconv_cnt_offset_r > 1595) begin
            img_sel_w[0] = pad_img[0];
            img_sel_w[1] = pad_img[0];
            img_sel_w[2] = pad_img[0];
            img_sel_w[3] = pad_img[0];
            img_sel_w[4] = pad_img[0];
        end
    end
end
//Weight counter & MUX
always @(*) begin
    if(state_cs == CONV || state_ns == DCONV) begin
        weight_cntwait1t_flag_w = 1;
    end
    else begin
        weight_cntwait1t_flag_w = 0;
    end
end
always @(*) begin
    if(state_ns == DCONV && weight_cntwait1t_flag_r) begin
        weight_cntwait2t_flag_w = 1;
    end
    else begin
        weight_cntwait2t_flag_w = 0;
    end
end
always @(*) begin
    if((state_cs == CONV && weight_cntwait1t_flag_r) || (state_ns == DCONV &&weight_cntwait2t_flag_r)) begin
        if(weight_cnt_r == 20) begin
            weight_cnt_w = 0;
        end
        else begin
            weight_cnt_w = weight_cnt_r + 5;
        end
    end
    else begin
        weight_cnt_w = 0;
    end
end

always @(*) begin
    for(i=0; i<5; i=i+1) weight_sel_w[i] = weight_sel_r[i];
    if(state_cs == CONV) begin
        for(i=0; i<21; i=i+1) begin
            if(weight_cnt_r == i) begin
                weight_sel_w[0] = WEIGHT_r[i];
                weight_sel_w[1] = WEIGHT_r[i+1];
                weight_sel_w[2] = WEIGHT_r[i+2];
                weight_sel_w[3] = WEIGHT_r[i+3];
                weight_sel_w[4] = WEIGHT_r[i+4];
            end
        end
        if(weight_cnt_r > 20) begin
            weight_sel_w[0] = WEIGHT_r[0];
            weight_sel_w[1] = WEIGHT_r[0];
            weight_sel_w[2] = WEIGHT_r[0];
            weight_sel_w[3] = WEIGHT_r[0];
            weight_sel_w[4] = WEIGHT_r[0];
        end
    end
    if(state_cs == DCONV) begin
        if(weight_cnt_r == 0) begin
            weight_sel_w[0] = WEIGHT_r[24];
            weight_sel_w[1] = WEIGHT_r[23];
            weight_sel_w[2] = WEIGHT_r[22];
            weight_sel_w[3] = WEIGHT_r[21];
            weight_sel_w[4] = WEIGHT_r[20];
        end
        if(weight_cnt_r == 5) begin
            weight_sel_w[0] = WEIGHT_r[19];
            weight_sel_w[1] = WEIGHT_r[18];
            weight_sel_w[2] = WEIGHT_r[17];
            weight_sel_w[3] = WEIGHT_r[16];
            weight_sel_w[4] = WEIGHT_r[15];
        end
        if(weight_cnt_r == 10) begin
            weight_sel_w[0] = WEIGHT_r[14];
            weight_sel_w[1] = WEIGHT_r[13];
            weight_sel_w[2] = WEIGHT_r[12];
            weight_sel_w[3] = WEIGHT_r[11];
            weight_sel_w[4] = WEIGHT_r[10];
        end
        if(weight_cnt_r == 15) begin
            weight_sel_w[0] = WEIGHT_r[9];
            weight_sel_w[1] = WEIGHT_r[8];
            weight_sel_w[2] = WEIGHT_r[7];
            weight_sel_w[3] = WEIGHT_r[6];
            weight_sel_w[4] = WEIGHT_r[5];
        end
        if(weight_cnt_r == 20) begin
            weight_sel_w[0] = WEIGHT_r[4];
            weight_sel_w[1] = WEIGHT_r[3];
            weight_sel_w[2] = WEIGHT_r[2];
            weight_sel_w[3] = WEIGHT_r[1];
            weight_sel_w[4] = WEIGHT_r[0];
        end
    end
end

//DFF
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        conv_cnt_start_r <= 0;
        conv_cnt_10t_r <= 0;
        conv_cnt_offset_r <= 0;
        conv_cnt_bt_r <= 0;
        conv_mode_r <= 0;
    end
    else begin
        conv_cnt_start_r <= conv_cnt_start_w;
        conv_cnt_10t_r <= conv_cnt_10t_w;
        conv_cnt_offset_r <= conv_cnt_offset_w;
        conv_cnt_bt_r <= conv_cnt_bt_w;
        conv_mode_r <= conv_mode_w;
    end
end
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        dconv_cnt_start_r <= 0;
        dconv_cnt_5t_r <= 0;
        dconv_cnt_offset_r <= 0;
        dconv_cnt_bt_r <= 0;
    end
    else begin
        dconv_cnt_start_r <= dconv_cnt_start_w;
        dconv_cnt_5t_r <= dconv_cnt_5t_w;
        dconv_cnt_offset_r <= dconv_cnt_offset_w;
        dconv_cnt_bt_r <= dconv_cnt_bt_w;
    end
end
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<1024; i=i+1) IMG_r[i] <= 0;
        for(i=0; i<25; i=i+1) WEIGHT_r[i] <= 0;
        img_counter_r <= 0;
        read_img_wait1t_flag_r <= 0;
        for(i=0; i<5; i=i+1) img_sel_r[i] <= 0;
        for(i=0; i<5; i=i+1) weight_sel_r[i] <= 0;
        weight_cnt_r <= 0;
        weight_cntwait1t_flag_r <= 0;
        weight_cntwait2t_flag_r <= 0;
    end
    else begin
        for(i=0; i<1024; i=i+1) IMG_r[i] <= IMG_w[i];
        for(i=0; i<25; i=i+1) WEIGHT_r[i] <= WEIGHT_w[i];
        img_counter_r <= img_counter_w;
        read_img_wait1t_flag_r <= read_img_wait1t_flag_w;
        for(i=0; i<5; i=i+1) img_sel_r[i] <= img_sel_w[i];
        for(i=0; i<5; i=i+1) weight_sel_r[i] <= weight_sel_w[i];
        weight_cnt_r <= weight_cnt_w;
        weight_cntwait1t_flag_r <= weight_cntwait1t_flag_w;
        weight_cntwait2t_flag_r <= weight_cntwait2t_flag_w;
    end
end
//=======================================================
//                    Operation
//=======================================================
reg signed [15:0] multi_r [0:4];
reg signed [15:0] multi_w [0:4];
reg signed [19:0] add [0:2];
reg signed [19:0] adder_tree_r [0:3];
reg signed [19:0] adder_tree_w [0:3];
reg adtr_flag_r, adtr_flag_w;
reg [4:0] adtr_cnt_r, adtr_cnt_w;
reg [1:0] adtr_pr_r, adtr_pr_w;
reg signed [19:0] adtr_acc;
reg signed [19:0] pool_tmp0, pool_tmp1, pool_out;
reg signed [19:0] di_o;
reg adtr_we;

//adtr_flag_r
always @(*) begin
    if(state_cs == CONV && adtr_cnt_r == 22 && adtr_flag_r == 0) begin
        adtr_flag_w = 1;
    end
    else if(state_cs == DCONV && adtr_cnt_r == 7 && adtr_flag_r == 0) begin
        adtr_flag_w = 1;
    end
    else if(state_cs == IDLE) begin
        adtr_flag_w = 0;
    end
    else begin
        adtr_flag_w = adtr_flag_r;
    end

end
//adtr_cnt_r
always @(*) begin
    if(state_cs == CONV) begin
        if(adtr_flag_r == 0 && adtr_cnt_r == 22) begin
            adtr_cnt_w = 0;
        end
        else if(adtr_flag_r == 1 && adtr_cnt_r == 19) begin
            adtr_cnt_w = 0;
        end
        else begin
            adtr_cnt_w = adtr_cnt_r + 1;
        end
    end
    else if(state_cs == DCONV) begin
        if(adtr_flag_r == 0 && adtr_cnt_r == 7) begin
            adtr_cnt_w = 0;
        end
        else if(adtr_flag_r == 1 && adtr_cnt_r == 4) begin
            adtr_cnt_w = 0;
        end
        else begin
            adtr_cnt_w = adtr_cnt_r + 1;
        end
    end
    else begin
        adtr_cnt_w = 0;
    end
end
//adder tr output reg sel
always @(*) begin
    if(state_cs == CONV) begin
        if(adtr_flag_r == 0 && (adtr_cnt_r == 7 || adtr_cnt_r == 12 || adtr_cnt_r == 17 || adtr_cnt_r == 22)) begin
            adtr_pr_w = adtr_pr_r + 1;
        end
        else if(adtr_flag_r == 1 && (adtr_cnt_r == 4 || adtr_cnt_r == 9 || adtr_cnt_r == 14 || adtr_cnt_r == 19)) begin
            adtr_pr_w = adtr_pr_r + 1;
        end
        else begin
            adtr_pr_w = adtr_pr_r;
        end
    end
    else begin
        adtr_pr_w = 0;
    end

end

//累加MUX
always @(*) begin
    if(state_cs == CONV) begin
        if(adtr_flag_r == 0 && (adtr_cnt_r == 3 || adtr_cnt_r == 8 || adtr_cnt_r == 13  || adtr_cnt_r == 18)) begin
            adtr_acc = 0;
        end
        else if(adtr_flag_r == 1 && (adtr_cnt_r == 0 || adtr_cnt_r == 5 || adtr_cnt_r == 10 || adtr_cnt_r == 15)) begin
            adtr_acc = 0;
        end
        else begin
            adtr_acc = adder_tree_r[adtr_pr_r];
        end
    end
    else if(state_cs == DCONV) begin
        if(adtr_flag_r == 0 && adtr_cnt_r == 3) begin
            adtr_acc = 0;
        end
        else if(adtr_flag_r == 1 && adtr_cnt_r == 0) begin
            adtr_acc = 0;
        end
        else begin
            adtr_acc = adder_tree_r[0];
        end
    end
    else begin
        adtr_acc = 0;
    end
end
//Adder tree
always @(*) begin
    multi_w[0] = img_sel_r[0] * weight_sel_r[0];
    multi_w[1] = img_sel_r[1] * weight_sel_r[1];
    multi_w[2] = img_sel_r[2] * weight_sel_r[2];
    multi_w[3] = img_sel_r[3] * weight_sel_r[3];
    multi_w[4] = img_sel_r[4] * weight_sel_r[4];
end
always @(*) begin
    add[0] = multi_r[0] + adtr_acc;
    add[1] = multi_r[1] + multi_r[2];
    add[2] = multi_r[3] + multi_r[4];
end
always @(*) begin
    for(i=0; i<4; i=i+1) adder_tree_w[i] = adder_tree_r[i];
    case(adtr_pr_r)
    0:adder_tree_w[adtr_pr_r] = add[0] + add[1] + add[2];
    1:adder_tree_w[adtr_pr_r] = add[0] + add[1] + add[2];
    2:adder_tree_w[adtr_pr_r] = add[0] + add[1] + add[2];
    3:adder_tree_w[adtr_pr_r] = add[0] + add[1] + add[2];
    endcase
    // adder_tree_w[adtr_pr_r] = add[0] + add[1] + add[2];
end
//comparator
always @(*) begin
    if(adder_tree_r[0] > adder_tree_r[1]) begin
        pool_tmp0 = adder_tree_r[0];
    end
    else begin
        pool_tmp0 = adder_tree_r[1];
    end
end
always @(*) begin
    if(adder_tree_r[2] > adder_tree_r[3]) begin
        pool_tmp1 = adder_tree_r[2];
    end
    else begin
        pool_tmp1 = adder_tree_r[3];
    end
end
always @(*) begin
    if(pool_tmp0 > pool_tmp1) begin
        pool_out = pool_tmp0;
    end
    else begin
        pool_out = pool_tmp1;
    end
end

//store output sram data
always @(*) begin
    if(state_cs == CONV) begin
        di_o = pool_out;
    end
    else begin
        di_o = adder_tree_r[0];
    end
end

//O_SRAM_address//O_SRAM_WE
always @(*) begin
    if(state_cs == CONV) begin
        if(adtr_flag_r == 1 && adtr_cnt_r == 0) begin
            adtr_we = 0;
            adtr_addr_cnt_w = adtr_addr_cnt_r + 1; 
        end
        else begin
            adtr_we = 1;
            adtr_addr_cnt_w = adtr_addr_cnt_r;
        end
    end
    else if(state_cs == DCONV) begin
        if(adtr_flag_r == 1 && adtr_cnt_r == 0) begin
            adtr_we = 0;
            adtr_addr_cnt_w = adtr_addr_cnt_r + 1; 
        end
        else begin
            adtr_we = 1;
            adtr_addr_cnt_w = adtr_addr_cnt_r;
        end
    end
    else begin
        adtr_we = 0;
        adtr_addr_cnt_w = 0;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<5; i=i+1) multi_r[i] <= 0;
        for(i=0; i<4; i=i+1) adder_tree_r[i] <= 0;
        adtr_cnt_r <= 0;
        adtr_flag_r <= 0;
        adtr_pr_r <= 0;
        adtr_addr_cnt_r <= 0;
    end
    else begin
        for(i=0; i<5; i=i+1) multi_r[i] <= multi_w[i];
        for(i=0; i<4; i=i+1) adder_tree_r[i] <= adder_tree_w[i];
        adtr_cnt_r <= adtr_cnt_w;
        adtr_flag_r <= adtr_flag_w;
        adtr_pr_r <= adtr_pr_w;
        adtr_addr_cnt_r <= adtr_addr_cnt_w;
    end
end
//=======================================================
//                    OUT
//=======================================================
always @(*) begin
    if(state_cs == SEND) begin
        send_flag_w = 1;
    end
    else begin
        send_flag_w = 0;
    end
end

//outpur sram 訊號
always @(*) begin
    if(state_cs == OUT || state_cs == SKIP || state_cs == SEND) begin
        out_we = 1;
        o_addr_tmp = out_addr_cnt_r;
    end
    else if(state_cs == CONV || state_cs == DCONV) begin
        out_we = adtr_we;
        o_addr_tmp = adtr_addr_cnt_r;
    end
    else begin
        out_we = 1;
        o_addr_tmp = out_addr_cnt_r;
    end
end
always @(*) begin
    if(o_addr_tmp > 1295) begin
        o_addr = 0;
    end
    else begin
        o_addr = o_addr_tmp;
    end
end
//out_addr_cnt_r
always @(*) begin
    if(state_cs == IDLE) begin
        out_addr_cnt_w = 0;
    end
    else if(out_addr_cnt_en) begin
        out_addr_cnt_w = out_addr_cnt_r + 1;
    end
    else begin
        out_addr_cnt_w = out_addr_cnt_r;
    end
end

always @(*) begin
    if(state_cs == SEND) begin
        if(m_mode_r  == 0) begin //C
            if( ((m_size_r == 0 && out_addr_cnt_r > 3) || (m_size_r == 1 && out_addr_cnt_r > 35) || (m_size_r == 0 && out_addr_cnt_r > 195) )&& send_cnt_r == 19) begin
                out_ram_w = 0;
            end
            else if(send_flag_r == 0) begin
                out_ram_w = out_ram;
            end
            else if(send_flag_r == 1 && send_cnt_r == 19) begin
                out_ram_w = out_ram;
            end
            else begin
                out_ram_w = out_ram_r;
            end
        end
        else begin
            if( ((m_size_r == 0 && out_addr_cnt_r > 143) || (m_size_r == 1 && out_addr_cnt_r > 399) || (m_size_r == 2 && out_addr_cnt_r > 1295) ) && send_cnt_r == 19) begin
                out_ram_w = 0;
            end
            else if(send_flag_r == 0) begin
                out_ram_w = out_ram;
            end
            else if(send_flag_r == 1 && send_cnt_r == 19) begin
                out_ram_w = out_ram;
            end
            else begin
                out_ram_w = out_ram_r;
            end
        end
    end
    else begin
        out_ram_w = 0;
    end
end
always @(*) begin
    if(state_cs == SEND && send_cnt_r == 16) begin
        out_addr_cnt_en = 1;
    end
    else begin
        out_addr_cnt_en = 0;
    end
end

always @(*) begin
    if(state_cs == SEND && send_flag_r) begin
        if(send_cnt_r == 19) begin
            send_cnt_w = 0;
        end
        else begin
            send_cnt_w = send_cnt_r + 1;
        end
    end
    else begin
        send_cnt_w = 0;
    end
end
always @(*) begin
    if(state_cs == SEND && send_flag_r) begin
        if(m_mode_r == 0) begin //
            if(((m_size_r == 0 && out_addr_cnt_r == 4) || (m_size_r == 1 && out_addr_cnt_r == 36) || (m_size_r == 2 && out_addr_cnt_r == 196) ) && send_cnt_r == 0) begin
                out_valid_w = 0;
                out_value_w = 0;
            end
            else begin
                out_valid_w = 1;
                out_value_w = out_ram_r[send_cnt_r];
            end
        end
        else begin
            if(((m_size_r == 0 && out_addr_cnt_r == 144) || (m_size_r == 1 && out_addr_cnt_r == 400) || (m_size_r == 2 && out_addr_cnt_r == 1296) ) && send_cnt_r == 0) begin
                out_valid_w = 0;
                out_value_w = 0;
            end
            else begin
                out_valid_w = 1;
                out_value_w = out_ram_r[send_cnt_r];
            end
        end
    end
    else begin
        out_valid_w = 0;
        out_value_w = 0;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        out_addr_cnt_r <= 0;
        out_send_cnt_r <= 0;
        send_flag_r <= 0;
    end
    else begin
        out_addr_cnt_r <= out_addr_cnt_w;
        out_send_cnt_r <= out_send_cnt_w;
        send_flag_r <= send_flag_w;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        send_cnt_r <= 0;
        out_valid <= 0;
        out_value <= 0;
        out_ram_r <= 0;
    end
    else begin
        send_cnt_r <= send_cnt_w;
        out_valid <= out_valid_w;
        out_value <= out_value_w;
        out_ram_r <= out_ram_w;
    end
end
//=======================================================
//                    SRAM
//=======================================================   
S_ram_D U_D(
    .clk(clk), .we(d_we), .address(d_addr), .di(matrix), .dout(d_dout)
);
S_ram_W U_W(
    .clk(clk), .we(w_we), .address(w_addr), .di(matrix), .dout(w_dout)
);
S_ram_O U_O(
    .clk(clk), .we(out_we), .address(o_addr), .di(di_o), .dout(out_ram)
);

endmodule

module S_ram_D (
    input clk,
    input we,
    input [13:0] address,
    input [7:0] di,
    output [7:0] dout
);

SUMA_16384_M8 U_DATA(.A0(address[0]), .A1(address[1]), .A2(address[2]), .A3(address[3]), .A4(address[4]), 
                     .A5(address[5]), .A6(address[6]), .A7(address[7]), .A8(address[8]), .A9(address[9]), .A10(address[10]), 
                     .A11(address[11]), .A12(address[12]), .A13(address[13]),

                     .DO0(dout[0]), .DO1(dout[1]), .DO2(dout[2]), .DO3(dout[3]), .DO4(dout[4]), .DO5(dout[5]), .DO6(dout[6]), .DO7(dout[7]),

                     .DI0(di[0]), .DI1(di[1]), .DI2(di[2]), .DI3(di[3]), .DI4(di[4]), .DI5(di[5]), .DI6(di[6]), .DI7(di[7]),

                     .CK(clk), .WEB(we), .OE(1'b1), .CS(1'b1));
endmodule

module S_ram_W (
    input clk,
    input we,
    input [8:0] address,
    input [7:0] di,
    output [7:0] dout
);

SUMA_400_M1 U_WEIGHT(.A0(address[0]), .A1(address[1]), .A2(address[2]), .A3(address[3]), .A4(address[4]), 
                        .A5(address[5]), .A6(address[6]), .A7(address[7]), .A8(address[8]),

                        .DO0(dout[0]), .DO1(dout[1]), .DO2(dout[2]), .DO3(dout[3]), .DO4(dout[4]), .DO5(dout[5]), .DO6(dout[6]), .DO7(dout[7]),

                        .DI0(di[0]), .DI1(di[1]), .DI2(di[2]), .DI3(di[3]), .DI4(di[4]), .DI5(di[5]), .DI6(di[6]), .DI7(di[7]),

                        .CK(clk), .WEB(we), .OE(1'b1), .CS(1'b1));
endmodule

module S_ram_O (
    input clk,
    input we,
    input [10:0] address,
    input [19:0] di,
    output [19:0] dout
);

SUMA_1296 U_OUT(.A0(address[0]), .A1(address[1]), .A2(address[2]), .A3(address[3]), .A4(address[4]), 
                .A5(address[5]), .A6(address[6]), .A7(address[7]), .A8(address[8]), .A9(address[9]), .A10(address[10]),

                .DO0(dout[0]), .DO1(dout[1]), .DO2(dout[2]), .DO3(dout[3]), .DO4(dout[4]), .DO5(dout[5]), .DO6(dout[6]), .DO7(dout[7]),
                .DO8(dout[8]), .DO9(dout[9]), .DO10(dout[10]), .DO11(dout[11]), .DO12(dout[12]), .DO13(dout[13]), .DO14(dout[14]), .DO15(dout[15]),
                .DO16(dout[16]), .DO17(dout[17]), .DO18(dout[18]), .DO19(dout[19]),

                .DI0(di[0]), .DI1(di[1]), .DI2(di[2]), .DI3(di[3]), .DI4(di[4]), .DI5(di[5]), .DI6(di[6]), .DI7(di[7]),
                .DI8(di[8]), .DI9(di[9]), .DI10(di[10]), .DI11(di[11]), .DI12(di[12]), .DI13(di[13]), .DI14(di[14]), .DI15(di[15]),
                .DI16(di[16]), .DI17(di[17]), .DI18(di[18]), .DI19(di[19]),

                .CK(clk), .WEB(we), .OE(1'b1), .CS(1'b1));
endmodule
