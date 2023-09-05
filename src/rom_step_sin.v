module rom_step_sin (
    input clk, rst_n,
    input [6:0] addr_i,
    output reg signed [31:0] step_o
);

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n) begin
        step_o <= 32'd0;
    end else begin
        case(addr_i)
7'd0: step_o <= 32'd0;
7'd1: step_o <= 32'd39371;
7'd2: step_o <= 32'd41712;
7'd3: step_o <= 32'd44192;
7'd4: step_o <= 32'd46820;
7'd5: step_o <= 32'd49604;
7'd6: step_o <= 32'd52553;
7'd7: step_o <= 32'd55678;
7'd8: step_o <= 32'd58989;
7'd9: step_o <= 32'd62497;
7'd10: step_o <= 32'd66213;
7'd11: step_o <= 32'd70150;
7'd12: step_o <= 32'd74322;
7'd13: step_o <= 32'd78741;
7'd14: step_o <= 32'd83423;
7'd15: step_o <= 32'd88384;
7'd16: step_o <= 32'd93639;
7'd17: step_o <= 32'd99208;
7'd18: step_o <= 32'd105107;
7'd19: step_o <= 32'd111357;
7'd20: step_o <= 32'd117978;
7'd21: step_o <= 32'd124994;
7'd22: step_o <= 32'd132426;
7'd23: step_o <= 32'd140301;
7'd24: step_o <= 32'd148643;
7'd25: step_o <= 32'd157482;
7'd26: step_o <= 32'd166846;
7'd27: step_o <= 32'd176768;
7'd28: step_o <= 32'd187279;
7'd29: step_o <= 32'd198415;
7'd30: step_o <= 32'd210213;
7'd31: step_o <= 32'd222713;
7'd32: step_o <= 32'd235957;
7'd33: step_o <= 32'd249987;
7'd34: step_o <= 32'd264852;
7'd35: step_o <= 32'd280601;
7'd36: step_o <= 32'd297287;
7'd37: step_o <= 32'd314964;
7'd38: step_o <= 32'd333693;
7'd39: step_o <= 32'd353536;
7'd40: step_o <= 32'd374558;
7'd41: step_o <= 32'd396830;
7'd42: step_o <= 32'd420427;
7'd43: step_o <= 32'd445427;
7'd44: step_o <= 32'd471913;
7'd45: step_o <= 32'd499975;
7'd46: step_o <= 32'd529705;
7'd47: step_o <= 32'd561202;
7'd48: step_o <= 32'd594573;
7'd49: step_o <= 32'd629929;
7'd50: step_o <= 32'd667386;
7'd51: step_o <= 32'd707071;
7'd52: step_o <= 32'd749115;
7'd53: step_o <= 32'd793660;
7'd54: step_o <= 32'd840854;
7'd55: step_o <= 32'd890854;
7'd56: step_o <= 32'd943826;
7'd57: step_o <= 32'd999949;
7'd58: step_o <= 32'd1059409;
7'd59: step_o <= 32'd1122405;
7'd60: step_o <= 32'd1189147;
7'd61: step_o <= 32'd1259857;
7'd62: step_o <= 32'd1334772;
7'd63: step_o <= 32'd1414142;
7'd64: step_o <= 32'd1498231;
7'd65: step_o <= 32'd1587321;
7'd66: step_o <= 32'd1681707;
7'd67: step_o <= 32'd1781707;
7'd68: step_o <= 32'd1887652;
7'd69: step_o <= 32'd1999899;
7'd70: step_o <= 32'd2118819;
7'd71: step_o <= 32'd2244810;
7'd72: step_o <= 32'd2378294;
7'd73: step_o <= 32'd2519714;
7'd74: step_o <= 32'd2669544;
7'd75: step_o <= 32'd2828283;
7'd76: step_o <= 32'd2996463;
7'd77: step_o <= 32'd3174641;
7'd78: step_o <= 32'd3363415;
7'd79: step_o <= 32'd3563414;
7'd80: step_o <= 32'd3775305;
7'd81: step_o <= 32'd3999797;
7'd82: step_o <= 32'd4237637;
7'd83: step_o <= 32'd4489620;
7'd84: step_o <= 32'd4756588;
7'd85: step_o <= 32'd5039428;
7'd86: step_o <= 32'd5339088;
7'd87: step_o <= 32'd5656566;
7'd88: step_o <= 32'd5992924;
            default : step_o <= 32'd0;
        endcase
    end
end


endmodule