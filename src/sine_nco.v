module sine_nco (
    input clk, rst_n,
    input [7:0] note_i,
    
    output signed [15:0] value_o
);

localparam W = 32;
localparam P = 9;

reg signed [W-1:0] phase;
wire signed [W-1:0] step;

reg [P-1:0] sin_addr;

rom_step_sin (
    .clk(clk),
    .rst_n(rst_n),
    .addr_i(note_i),
    .step_o(step)
);

rom_lut_sin (
    .clk(clk),
    .rst_n(rst_n),
    .addr_i(sin_addr),
    .value_o(value_o)
);


always@(posedge clk or negedge rst_n)
begin
    if (!rst_n) begin
        phase <= 'd0;
    end else begin
        phase <= phase + step;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n) begin
        sin_addr <= 'd0;
    end else begin
        sin_addr <= (step == 0) ? 'd0 : phase[W-1:W-P];
    end
end

endmodule