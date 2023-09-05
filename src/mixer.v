module mixer4 (
    
    input signed [15:0] snd1_i, snd2_i, snd3_i, snd4_i,
    output signed [15:0] data_o
);

assign data_o = (snd1_i >>> 3) + (snd2_i >>> 3) + (snd3_i >>> 3) + (snd4_i >>> 3);

endmodule