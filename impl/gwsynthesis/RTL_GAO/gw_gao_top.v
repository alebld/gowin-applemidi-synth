module gw_gao(
    HP_WS,
    HP_DIN,
    \osc2/step[31] ,
    \osc2/step[30] ,
    \osc2/step[29] ,
    \osc2/step[28] ,
    \osc2/step[27] ,
    \osc2/step[26] ,
    \osc2/step[25] ,
    \osc2/step[24] ,
    \osc2/step[23] ,
    \osc2/step[22] ,
    \osc2/step[21] ,
    \osc2/step[20] ,
    \osc2/step[19] ,
    \osc2/step[18] ,
    \osc2/step[17] ,
    \osc2/step[16] ,
    \osc2/step[15] ,
    \osc2/step[14] ,
    \osc2/step[13] ,
    \osc2/step[12] ,
    \osc2/step[11] ,
    \osc2/step[10] ,
    \osc2/step[9] ,
    \osc2/step[8] ,
    \osc2/step[7] ,
    \osc2/step[6] ,
    \osc2/step[5] ,
    \osc2/step[4] ,
    \osc2/step[3] ,
    \osc2/step[2] ,
    \osc2/step[1] ,
    \osc2/step[0] ,
    \osc3/step[31] ,
    \osc3/step[30] ,
    \osc3/step[29] ,
    \osc3/step[28] ,
    \osc3/step[27] ,
    \osc3/step[26] ,
    \osc3/step[25] ,
    \osc3/step[24] ,
    \osc3/step[23] ,
    \osc3/step[22] ,
    \osc3/step[21] ,
    \osc3/step[20] ,
    \osc3/step[19] ,
    \osc3/step[18] ,
    \osc3/step[17] ,
    \osc3/step[16] ,
    \osc3/step[15] ,
    \osc3/step[14] ,
    \osc3/step[13] ,
    \osc3/step[12] ,
    \osc3/step[11] ,
    \osc3/step[10] ,
    \osc3/step[9] ,
    \osc3/step[8] ,
    \osc3/step[7] ,
    \osc3/step[6] ,
    \osc3/step[5] ,
    \osc3/step[4] ,
    \osc3/step[3] ,
    \osc3/step[2] ,
    \osc3/step[1] ,
    \osc3/step[0] ,
    clk_1p5m_w,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input HP_WS;
input HP_DIN;
input \osc2/step[31] ;
input \osc2/step[30] ;
input \osc2/step[29] ;
input \osc2/step[28] ;
input \osc2/step[27] ;
input \osc2/step[26] ;
input \osc2/step[25] ;
input \osc2/step[24] ;
input \osc2/step[23] ;
input \osc2/step[22] ;
input \osc2/step[21] ;
input \osc2/step[20] ;
input \osc2/step[19] ;
input \osc2/step[18] ;
input \osc2/step[17] ;
input \osc2/step[16] ;
input \osc2/step[15] ;
input \osc2/step[14] ;
input \osc2/step[13] ;
input \osc2/step[12] ;
input \osc2/step[11] ;
input \osc2/step[10] ;
input \osc2/step[9] ;
input \osc2/step[8] ;
input \osc2/step[7] ;
input \osc2/step[6] ;
input \osc2/step[5] ;
input \osc2/step[4] ;
input \osc2/step[3] ;
input \osc2/step[2] ;
input \osc2/step[1] ;
input \osc2/step[0] ;
input \osc3/step[31] ;
input \osc3/step[30] ;
input \osc3/step[29] ;
input \osc3/step[28] ;
input \osc3/step[27] ;
input \osc3/step[26] ;
input \osc3/step[25] ;
input \osc3/step[24] ;
input \osc3/step[23] ;
input \osc3/step[22] ;
input \osc3/step[21] ;
input \osc3/step[20] ;
input \osc3/step[19] ;
input \osc3/step[18] ;
input \osc3/step[17] ;
input \osc3/step[16] ;
input \osc3/step[15] ;
input \osc3/step[14] ;
input \osc3/step[13] ;
input \osc3/step[12] ;
input \osc3/step[11] ;
input \osc3/step[10] ;
input \osc3/step[9] ;
input \osc3/step[8] ;
input \osc3/step[7] ;
input \osc3/step[6] ;
input \osc3/step[5] ;
input \osc3/step[4] ;
input \osc3/step[3] ;
input \osc3/step[2] ;
input \osc3/step[1] ;
input \osc3/step[0] ;
input clk_1p5m_w;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire HP_WS;
wire HP_DIN;
wire \osc2/step[31] ;
wire \osc2/step[30] ;
wire \osc2/step[29] ;
wire \osc2/step[28] ;
wire \osc2/step[27] ;
wire \osc2/step[26] ;
wire \osc2/step[25] ;
wire \osc2/step[24] ;
wire \osc2/step[23] ;
wire \osc2/step[22] ;
wire \osc2/step[21] ;
wire \osc2/step[20] ;
wire \osc2/step[19] ;
wire \osc2/step[18] ;
wire \osc2/step[17] ;
wire \osc2/step[16] ;
wire \osc2/step[15] ;
wire \osc2/step[14] ;
wire \osc2/step[13] ;
wire \osc2/step[12] ;
wire \osc2/step[11] ;
wire \osc2/step[10] ;
wire \osc2/step[9] ;
wire \osc2/step[8] ;
wire \osc2/step[7] ;
wire \osc2/step[6] ;
wire \osc2/step[5] ;
wire \osc2/step[4] ;
wire \osc2/step[3] ;
wire \osc2/step[2] ;
wire \osc2/step[1] ;
wire \osc2/step[0] ;
wire \osc3/step[31] ;
wire \osc3/step[30] ;
wire \osc3/step[29] ;
wire \osc3/step[28] ;
wire \osc3/step[27] ;
wire \osc3/step[26] ;
wire \osc3/step[25] ;
wire \osc3/step[24] ;
wire \osc3/step[23] ;
wire \osc3/step[22] ;
wire \osc3/step[21] ;
wire \osc3/step[20] ;
wire \osc3/step[19] ;
wire \osc3/step[18] ;
wire \osc3/step[17] ;
wire \osc3/step[16] ;
wire \osc3/step[15] ;
wire \osc3/step[14] ;
wire \osc3/step[13] ;
wire \osc3/step[12] ;
wire \osc3/step[11] ;
wire \osc3/step[10] ;
wire \osc3/step[9] ;
wire \osc3/step[8] ;
wire \osc3/step[7] ;
wire \osc3/step[6] ;
wire \osc3/step[5] ;
wire \osc3/step[4] ;
wire \osc3/step[3] ;
wire \osc3/step[2] ;
wire \osc3/step[1] ;
wire \osc3/step[0] ;
wire clk_1p5m_w;
wire tms_pad_i;
wire tck_pad_i;
wire tdi_pad_i;
wire tdo_pad_o;
wire tms_i_c;
wire tck_i_c;
wire tdi_i_c;
wire tdo_o_c;
wire [9:0] control0;
wire gao_jtag_tck;
wire gao_jtag_reset;
wire run_test_idle_er1;
wire run_test_idle_er2;
wire shift_dr_capture_dr;
wire update_dr;
wire pause_dr;
wire enable_er1;
wire enable_er2;
wire gao_jtag_tdi;
wire tdo_er1;

IBUF tms_ibuf (
    .I(tms_pad_i),
    .O(tms_i_c)
);

IBUF tck_ibuf (
    .I(tck_pad_i),
    .O(tck_i_c)
);

IBUF tdi_ibuf (
    .I(tdi_pad_i),
    .O(tdi_i_c)
);

OBUF tdo_obuf (
    .I(tdo_o_c),
    .O(tdo_pad_o)
);

GW_JTAG  u_gw_jtag(
    .tms_pad_i(tms_i_c),
    .tck_pad_i(tck_i_c),
    .tdi_pad_i(tdi_i_c),
    .tdo_pad_o(tdo_o_c),
    .tck_o(gao_jtag_tck),
    .test_logic_reset_o(gao_jtag_reset),
    .run_test_idle_er1_o(run_test_idle_er1),
    .run_test_idle_er2_o(run_test_idle_er2),
    .shift_dr_capture_dr_o(shift_dr_capture_dr),
    .update_dr_o(update_dr),
    .pause_dr_o(pause_dr),
    .enable_er1_o(enable_er1),
    .enable_er2_o(enable_er2),
    .tdi_o(gao_jtag_tdi),
    .tdo_er1_i(tdo_er1),
    .tdo_er2_i(1'b0)
);

gw_con_top  u_icon_top(
    .tck_i(gao_jtag_tck),
    .tdi_i(gao_jtag_tdi),
    .tdo_o(tdo_er1),
    .rst_i(gao_jtag_reset),
    .control0(control0[9:0]),
    .enable_i(enable_er1),
    .shift_dr_capture_dr_i(shift_dr_capture_dr),
    .update_dr_i(update_dr)
);

ao_top u_ao_top(
    .control(control0[9:0]),
    .data_i({HP_WS,HP_DIN,\osc2/step[31] ,\osc2/step[30] ,\osc2/step[29] ,\osc2/step[28] ,\osc2/step[27] ,\osc2/step[26] ,\osc2/step[25] ,\osc2/step[24] ,\osc2/step[23] ,\osc2/step[22] ,\osc2/step[21] ,\osc2/step[20] ,\osc2/step[19] ,\osc2/step[18] ,\osc2/step[17] ,\osc2/step[16] ,\osc2/step[15] ,\osc2/step[14] ,\osc2/step[13] ,\osc2/step[12] ,\osc2/step[11] ,\osc2/step[10] ,\osc2/step[9] ,\osc2/step[8] ,\osc2/step[7] ,\osc2/step[6] ,\osc2/step[5] ,\osc2/step[4] ,\osc2/step[3] ,\osc2/step[2] ,\osc2/step[1] ,\osc2/step[0] ,\osc3/step[31] ,\osc3/step[30] ,\osc3/step[29] ,\osc3/step[28] ,\osc3/step[27] ,\osc3/step[26] ,\osc3/step[25] ,\osc3/step[24] ,\osc3/step[23] ,\osc3/step[22] ,\osc3/step[21] ,\osc3/step[20] ,\osc3/step[19] ,\osc3/step[18] ,\osc3/step[17] ,\osc3/step[16] ,\osc3/step[15] ,\osc3/step[14] ,\osc3/step[13] ,\osc3/step[12] ,\osc3/step[11] ,\osc3/step[10] ,\osc3/step[9] ,\osc3/step[8] ,\osc3/step[7] ,\osc3/step[6] ,\osc3/step[5] ,\osc3/step[4] ,\osc3/step[3] ,\osc3/step[2] ,\osc3/step[1] ,\osc3/step[0] }),
    .clk_i(clk_1p5m_w)
);

endmodule
