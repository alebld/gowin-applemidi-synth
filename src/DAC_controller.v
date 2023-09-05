module DAC_controller (
    input clk, rst_n, 
    input signed [15:0] data_i,
    output reg DIN_o, WS_o,
    output BCK_o
);

reg [4:0] cnt;
reg signed [15:0] data;

assign BCK_o = clk;

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin  
        cnt <= 'd0;
    end else begin
        cnt <= cnt + 1'b1;
    end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data <= 16'd0;
    end else begin
        data <= (cnt == 5'd0 | cnt == 5'd16) ? data_i : data << 1; 
    end

end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        WS_o <= 1'b0;
        DIN_o <= 1'b0;
    end else begin
        WS_o <= (cnt == 5'd1) ? 1'b0 : ((cnt == 5'd17) ? 1'b1 : WS_o); 
        DIN_o <= data[15];
    end
end

endmodule