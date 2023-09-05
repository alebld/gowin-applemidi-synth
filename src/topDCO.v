module top(
    input clk, rst_n,
    output HP_BCK, HP_WS, HP_DIN, 
    output PA_EN,
    output reg led

);

wire [6:0] note1, note2, note3, note4;
wire [15:0] snd1, snd2, snd3, snd4;
wire [15:0] dac_data;

wire clk_6m_w;
wire clk_1p5m_w;

assign PA_EN = 1'b1;

Gowin_rPLL pll_27m_6m (
    .clkout(clk_6m_w), 
    .reset(~rst_n), 
    .clkin(clk)
);

Gowin_CLKDIV clk_div4(
    .clkout(clk_1p5m_w), //output clkout
    .hclkin(clk_6m_w), //input hclkin
    .resetn(rst_n) //input resetn
);

sound_controller (
    .rst_n(rst_n),
    .clk(clk_1p5m_w),
    .note1_o(note1),
    .note2_o(note2),
    .note3_o(note3),
    .note4_o(note4)
);

sine_nco osc1 (
    .clk(clk_1p5m_w),
    .rst_n(rst_n),
    .note_i(note1),
    .value_o(snd1)
);

sine_nco osc2 (
    .clk(clk_1p5m_w),
    .rst_n(rst_n),
    .note_i(note2),
    .value_o(snd2)
);

sine_nco osc3 (
    .clk(clk_1p5m_w),
    .rst_n(rst_n),
    .note_i(note3),
    .value_o(snd3)
);

sine_nco osc4 (
    .clk(clk_1p5m_w),
    .rst_n(rst_n),
    .note_i(note4),
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
    .rst_n(rst_n),
    .data_i(dac_data),
    .BCK_o(HP_BCK),
    .DIN_o(HP_DIN), 
    .WS_o(HP_WS)
);

reg [23:0] counter;

always @(posedge clk or negedge rst_n) begin // Counter block
    if (!rst_n)
        counter <= 24'd0;
    else if (counter < 24'd1349_9999)       // 0.5s delay
        counter <= counter + 1'b1;
    else
        counter <= 24'd0;
end

always @(posedge clk or negedge rst_n) begin // Toggle LED
    if (!rst_n)
        led <= 1'b1;
    else if (counter == 24'd1349_9999)       // 0.5s delay
        led <= ~led;                         // ToggleLED
end

endmodule