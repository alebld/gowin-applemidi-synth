// Include the RMII module
`include "rmii.sv"

// Top-level module definition
module top (
    input clk,            // System clock input
    input rst,            // Reset input
    
    rmii netrmii,         // RMII interface
    output phyrst,        // PHY reset signal
    output HP_BCK, HP_WS, HP_DIN, PA_EN,
    output [5:0] led      // Output LEDs
);

wire [6:0] note1, note2, note3, note4;
wire [15:0] snd1, snd2, snd3, snd4;
wire [15:0] dac_data;

wire clk_6m_w;
wire clk_1p5m_w;

assign PA_EN = 1'b1;
// Declare clock signals
logic clk1m;
logic clk6m;

// Instantiate a PLL module for clock generation
PLL_6M PLL6m (
    .clkout(clk6m),
    .clkoutd(clk1m),
    .clkin(clk)
);

Gowin_CLKDIV clk_div4(
    .clkout(clk_1p5m_w), //output clkout
    .hclkin(clk6m), //input hclkin
    .resetn(rst) //input resetn
);

logic [7:0] note_pitch;

sine_nco osc1 (
    .clk(clk_1p5m_w),
    .rst_n(~rst),
    .note_i(note_pitch),
    .value_o(snd1)
);

sine_nco osc2 (
    .clk(clk_1p5m_w),
    .rst_n(~rst),
    .note_i(8'b0),
    .value_o(snd2)
);

sine_nco osc3 (
    .clk(clk_1p5m_w),
    .rst_n(~rst),
    .note_i(8'b0),
    .value_o(snd3)
);

sine_nco osc4 (
    .clk(clk_1p5m_w),
    .rst_n(~rst),
    .note_i(8'b0),
    .value_o(snd4)
);

mixer4 (
    .snd1_i(snd1),
    .snd2_i(snd2),
    .snd3_i(snd3),
    .snd4_i(snd4),
    .data_o(dac_data)
);

DAC_controller (
    .clk(clk_1p5m_w),
    .rst_n(~rst),
    .data_i(dac_data),
    .BCK_o(HP_BCK),
    .DIN_o(HP_DIN), 
    .WS_o(HP_WS)
);

// Declare signal for LEDs
logic [5:0] rled;

// Declare signal for clock division
logic [23:0] ckdiv;

assign led = rled;

// Sequential logic for LED rotation
always_ff @(posedge clk or negedge rst) begin
    if (rst == 1'b0) begin
        rled <= 5'b00001;  // Initialize LED pattern
        ckdiv <= 24'd0;    // Initialize clock divider
    end else begin
        ckdiv <= ckdiv + 24'd1;  // Increment clock divider
        if (ckdiv == 24'd0)
            rled <= {rled[4:0], rled[5]};  // Rotate LEDs
    end
end



// Declare additional signals
logic clk50m;
logic ready;

logic rx_head_av;
logic [31:0] rx_head;
logic rx_data_av;
logic [7:0] rx_data;
logic rx_head_rdy;
logic rx_data_rdy;

logic [31:0] tx_ip;
logic [15:0] tx_dst_port;
logic tx_req;
logic [7:0] tx_data;
logic tx_data_av;
logic tx_req_rdy;
logic tx_data_rdy;

// Instantiate a UDP module
udp #(
    .ip_adr({8'd192, 8'd168, 8'd15, 8'd14}),
    .mac_adr({8'h06, 8'h00, 8'hAA, 8'hBB, 8'h0C, 8'hDD}),
    .arp_refresh_interval(50000000 * 15),  // ARP refresh interval (15 seconds)
    .arp_max_life_time(50000000 * 30)      // ARP maximum life time (30 seconds)
) udp_inst (
    .clk1m(clk1m),
    .rst(rst),
    .clk50m(clk50m),
    .ready(ready),
    .netrmii(netrmii),
    .phyrst(phyrst),
    .rx_head_rdy_i(rx_head_rdy),
    .rx_head_av_o(rx_head_av),
    .rx_head_o(rx_head),
    .rx_data_rdy_i(rx_data_rdy),
    .rx_data_av_o(rx_data_av),
    .rx_data_o(rx_data),
    .tx_ip_i(tx_ip),
    .tx_src_port_i(16'd11451),
    .tx_dst_port_i(tx_dst_port),
    .tx_req_i(tx_req),
    .tx_data_i(tx_data),
    .tx_data_av_i(tx_data_av),
    .tx_req_rdy_o(tx_req_rdy),
    .tx_data_rdy_o(tx_data_rdy)
);

// Assign received data to be transmitted
/*always_comb begin
    tx_data <= rx_data;
    tx_data_av <= rx_data_av;
end*/

// State machine for UDP packet handling
byte tx_state;
byte rtp_state;
logic midi_in;
logic rtp_midi_in;
logic [63:0] tmstmp;

//4 packs of rx head each frame
//0: src_ip
//1: dst_ip
//2: src_port+dst_port
//3: idf+udp_len

always_ff @(posedge clk50m or negedge ready) begin
    if (ready == 0) begin
        tx_state <= 0;
        rtp_state <= 0;
        tx_data_av <= 1'b0;
        rx_head_rdy <= 1'b0;
        rtp_midi_in <= 1'b0;
        midi_in <= 1;
    end else begin
        tx_req <= 1'b0;
        rx_head_rdy <= 1'b0;
        tx_data_av <= 1'b0;

        case (tx_state)
            0: begin
                if (rx_head_av) begin
                    tx_state <= 1;
                    rx_head_rdy <= 1'b1;
                end
            end
            1: begin  // Send the data back to where it came from
                rx_head_rdy <= 1'b1;
                tx_ip <= rx_head;
                tx_state <= 2;
            end
            2: begin
                rx_head_rdy <= 1'b1;
                tx_state <= 3;
            end
            3: begin  // Send the data to the port it came from + 1
                rx_head_rdy <= 1'b1;
                tx_dst_port <= rx_head[31:16]; //+ 16'd1;
                tx_state <= 4;
            end
            4: begin
                tx_state <= 5;
            end
            5: begin  // Wait until data is all received and req is ready
                if (tx_req_rdy && rx_data_av == 1'b0) begin
                    tx_req <= 1'b1;
                    tx_state <= 0;
                    rtp_state <= 0;
                    tx_data_av <= 1'b0;
                    rtp_midi_in <= 1'b0;
                end
            end
        endcase
        //if (rx_data_av) begin
        case (rtp_state)
            0: begin
                if (rx_data_av) begin
                    rx_data_rdy <= 1'b1;
                    case (rx_data)
                        8'hFF: begin
                            tx_data <= 8'hFF;
                            tx_data_av <= 1'b1;
                            rtp_state <= 2;
                            rtp_midi_in <= 1'b1;
                        end
                        8'b10_0_0_0000: begin
                            rtp_state <= 70;
                        end
                    endcase
                end
            end
            1: begin

                    //default: rtp_state <= 100;
                    
            end
            2: begin
                case (rx_data)
                    8'hFF: begin
                        tx_data <= 8'hFF;
                        tx_data_av <= 1'b1;
                        rtp_state <= 3;
                    end
                    //default: rtp_state <= 100;
                endcase
            end
            3: begin
                case (rx_data)
                    //IN
                    8'h49: begin
                        tx_data <= 8'h4f;
                        tx_data_av <= 1'b1;
                        rtp_state <= 4;
                    end
                    //CK
                    8'h43: begin//then 'h4B
                        tx_data <= 8'h43;
                        tx_data_av <= 1'b1;
                        rtp_state <= 30;
                    end
                    //default: rtp_state <= 100;
                endcase
            end


            4: begin
                if (rx_data == 8'h4E) begin
                    tx_data <= 8'h4B;
                    tx_data_av <= 1'b1;
                    rtp_state <= 5;
                end else begin rtp_state <= 100; end
            end
            //Protocol
            5: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 6;
            end
            6: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 7;
            end
            7: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 8;
            end
            8: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 9;
            end
            //Init token
            9: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 10;
            end
            10: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 11;
            end
            11: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 12;
            end
            12: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 13;
            end
            //SSRC
            13: begin
                tx_data <= 8'hAA;
                tx_data_av <= 1'b1;
                rtp_state <= 14;
            end
            14: begin
                tx_data <= 8'hBB;
                tx_data_av <= 1'b1;
                rtp_state <= 15;
            end
            15: begin
                tx_data <= 8'hCC;
                tx_data_av <= 1'b1;
                rtp_state <= 16;
            end
            16: begin
                tx_data <= 8'hDD;
                tx_data_av <= 1'b1;
                rtp_state <= 17;
            end
            //Name
            17: begin
                tx_data <= 8'h47;
                tx_data_av <= 1'b1;
                rtp_state <= 18;
            end
            18: begin
                tx_data <= 8'h57;
                tx_data_av <= 1'b1;
                rtp_state <= 19;
            end
            19: begin
                tx_data <= 8'h49;
                tx_data_av <= 1'b1;
                rtp_state <= 20;
            end
            20: begin
                tx_data <= 8'h4E;
                tx_data_av <= 1'b1;
                rtp_state <= 100;
            end
            
            
            30: begin
                if (rx_data == 8'h4B) begin
                    tx_data <= 8'h4B;
                    tx_data_av <= 1'b1;
                    rtp_state <= 31;
                end else begin rtp_state <= 100; end
            end
            //SSRC
            31: begin
                tx_data <= 8'hAA;
                tx_data_av <= 1'b1;
                rtp_state <= 32;
            end
            32: begin
                tx_data <= 8'hBB;
                tx_data_av <= 1'b1;
                rtp_state <= 33;
            end
            33: begin
                tx_data <= 8'hCC;
                tx_data_av <= 1'b1;
                rtp_state <= 34;
            end
            34: begin
                tx_data <= 8'hDD;
                tx_data_av <= 1'b1;
                rtp_state <= 35;
            end
            //Count
            35: begin
                if (rx_data == 8'h00) begin
                    tx_data <= rx_data + 1;
                    tx_data_av <= 1'b1;
                    rtp_state <= 60;
                end else begin
                    rtp_state <= 100;
                end
            end
            //Unused
            60: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 61;
            end
            61: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 62;
            end
            62: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 36;
            end
            /*39: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 40;
            end*/
            //timestamp1
            36: begin
                tx_data <= rx_data;
                tmstmp[63:56] <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 37;
            end
            37: begin
                tx_data <= rx_data;
                tmstmp[55:48] <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 38;
            end
            38: begin
                tx_data <= rx_data;
                tmstmp[47:40] <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 39;
            end
            39: begin
                tx_data <= rx_data;
                tmstmp[39:32] <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 40;
            end
            40: begin
                tx_data <= rx_data;
                tmstmp[31:24] <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 41;
            end
            41: begin
                tx_data <= rx_data;
                tmstmp[23:16] <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 42;
            end
            42: begin
                tx_data <= rx_data;
                tmstmp[15:8] <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 43;
            end
            43: begin
                tx_data <= rx_data;
                tmstmp[7:0] <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 44;
            end
            //timestamp2
            44: begin
                tx_data <= tmstmp[63:56];
                tx_data_av <= 1'b1;
                rtp_state <= 45;
            end
            45: begin
                tx_data <= tmstmp[55:48];
                tx_data_av <= 1'b1;
                rtp_state <= 46;
            end
            46: begin
                tx_data <= tmstmp[47:40];
                tx_data_av <= 1'b1;
                rtp_state <= 47;
            end
            47: begin
                tx_data <= tmstmp[39:32];
                tx_data_av <= 1'b1;
                rtp_state <= 48;
            end
            48: begin
                tx_data <= tmstmp[31:24];
                tx_data_av <= 1'b1;
                rtp_state <= 49;
            end
            49: begin
                tx_data <= tmstmp[23:16];
                tx_data_av <= 1'b1;
                rtp_state <= 50;
            end
            50: begin
                tx_data <= tmstmp[15:8];
                tx_data_av <= 1'b1;
                rtp_state <= 51;
            end
            51: begin
                tx_data <= tmstmp[7:0]+8'h0A;
                tx_data_av <= 1'b1;
                rtp_state <= 52;
            end
            //timestamp3
            52: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 53;
            end    
            53: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 54;
            end        
            54: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 55;
            end        
            55: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 56;
            end        
            56: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 57;
            end        
            57: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 58;
            end        
            58: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 59;
            end        
            59: begin
                tx_data <= rx_data;
                tx_data_av <= 1'b1;
                rtp_state <= 100;
            end     

            100: begin
                if (tx_req_rdy && rx_data_av == 1'b0) begin
                    rtp_state <= 0;
                    tx_data_av <= 1'b0;
                    rtp_midi_in <= 1'b0;
                end
            end

            70: begin
                case(rx_data)
                    8'h90: begin
                        rtp_state <= 71;//note on
                    end
                    8'h80: begin
                        rtp_state <= 71;//note off
                    end
                endcase
            end
            71: begin
                note_pitch <= rx_data;
                rtp_state <= 100;
            end
        endcase
        //end
    end
end

endmodule