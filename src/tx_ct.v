module tx_ct(
    input clk, rst,
    input [7:0] data,
    input tx_en,
    output logic tx_av,
    output logic tx_bz,
    output logic [1:0] p_txd,
    output logic p_txen
);

// Internal signals and variables
logic[7:0] buffer[2047:0]; // Internal buffer to store data
shortint begin_ptr; // Pointer to the beginning of data in the buffer
shortint end_ptr; // Pointer to the end of data in the buffer
logic[7:0] buffer_out; // Data read from the buffer
byte send_status; // Current transmission status
byte tick; // Timing counter
shortint send_cnt; // Transmission counter
logic int_en; // Internal transmission enable flag
logic[31:0] crc; // CRC calculation variables
logic[31:0] crc_next; // Next CRC calculation variables
logic crc_ct; // CRC calculation control flag
logic [7:0] crc_in; // Data input for CRC calculation
logic [7:0] data_i; // 8-bit data for CRC calculation

// Convert CRC data to 8-bit for calculation
assign data_i = {crc_in[0],crc_in[1],crc_in[2],crc_in[3],crc_in[4],crc_in[5],crc_in[6],crc_in[7]};

// CRC calculation (assign statements for each bit)
assign crc_next[0] = crc[24] ^ crc[30] ^ data_i[0] ^ data_i[6];
assign crc_next[1] = crc[24] ^ crc[25] ^ crc[30] ^ crc[31] ^ data_i[0] ^ data_i[1] ^ data_i[6] ^ data_i[7];
assign crc_next[2] = crc[24] ^ crc[25] ^ crc[26] ^ crc[30] ^ crc[31] ^ data_i[0] ^ data_i[1] ^ data_i[2] ^ data_i[6] ^ data_i[7];
assign crc_next[3] = crc[25] ^ crc[26] ^ crc[27] ^ crc[31] ^ data_i[1] ^ data_i[2] ^ data_i[3] ^ data_i[7];
assign crc_next[4] = crc[24] ^ crc[26] ^ crc[27] ^ crc[28] ^ crc[30] ^ data_i[0] ^ data_i[2] ^ data_i[3] ^ data_i[4] ^ data_i[6];
assign crc_next[5] = crc[24] ^ crc[25] ^ crc[27] ^ crc[28] ^ crc[29] ^ crc[30] ^ crc[31] ^ data_i[0] ^ data_i[1] ^ data_i[3] ^ data_i[4] ^ data_i[5] ^ data_i[6] ^ data_i[7];
assign crc_next[6] = crc[25] ^ crc[26] ^ crc[28] ^ crc[29] ^ crc[30] ^ crc[31] ^ data_i[1] ^ data_i[2] ^ data_i[4] ^ data_i[5] ^ data_i[6] ^ data_i[7];
assign crc_next[7] = crc[24] ^ crc[26] ^ crc[27] ^ crc[29] ^ crc[31] ^ data_i[0] ^ data_i[2] ^ data_i[3] ^ data_i[5] ^ data_i[7];
assign crc_next[8] = crc[0] ^ crc[24] ^ crc[25] ^ crc[27] ^ crc[28] ^ data_i[0] ^ data_i[1] ^ data_i[3] ^ data_i[4];
assign crc_next[9] = crc[1] ^ crc[25] ^ crc[26] ^ crc[28] ^ crc[29] ^ data_i[1] ^ data_i[2] ^ data_i[4] ^ data_i[5];
assign crc_next[10] = crc[2] ^ crc[24] ^ crc[26] ^ crc[27] ^ crc[29] ^ data_i[0] ^ data_i[2] ^ data_i[3] ^ data_i[5];
assign crc_next[11] = crc[3] ^ crc[24] ^ crc[25] ^ crc[27] ^ crc[28] ^ data_i[0] ^ data_i[1] ^ data_i[3] ^ data_i[4];
assign crc_next[12] = crc[4] ^ crc[24] ^ crc[25] ^ crc[26] ^ crc[28] ^ crc[29] ^ crc[30] ^ data_i[0] ^ data_i[1] ^ data_i[2] ^ data_i[4] ^ data_i[5] ^ data_i[6];
assign crc_next[13] = crc[5] ^ crc[25] ^ crc[26] ^ crc[27] ^ crc[29] ^ crc[30] ^ crc[31] ^ data_i[1] ^ data_i[2] ^ data_i[3] ^ data_i[5] ^ data_i[6] ^ data_i[7];
assign crc_next[14] = crc[6] ^ crc[26] ^ crc[27] ^ crc[28] ^ crc[30] ^ crc[31] ^ data_i[2] ^ data_i[3] ^ data_i[4] ^ data_i[6] ^ data_i[7];
assign crc_next[15] =  crc[7] ^ crc[27] ^ crc[28] ^ crc[29] ^ crc[31] ^ data_i[3] ^ data_i[4] ^ data_i[5] ^ data_i[7];
assign crc_next[16] = crc[8] ^ crc[24] ^ crc[28] ^ crc[29] ^ data_i[0] ^ data_i[4] ^ data_i[5];
assign crc_next[17] = crc[9] ^ crc[25] ^ crc[29] ^ crc[30] ^ data_i[1] ^ data_i[5] ^ data_i[6];
assign crc_next[18] = crc[10] ^ crc[26] ^ crc[30] ^ crc[31] ^ data_i[2] ^ data_i[6] ^ data_i[7];
assign crc_next[19] = crc[11] ^ crc[27] ^ crc[31] ^ data_i[3] ^ data_i[7];
assign crc_next[20] = crc[12] ^ crc[28] ^ data_i[4];
assign crc_next[21] = crc[13] ^ crc[29] ^ data_i[5];
assign crc_next[22] = crc[14] ^ crc[24] ^ data_i[0];
assign crc_next[23] = crc[15] ^ crc[24] ^ crc[25] ^ crc[30] ^ data_i[0] ^ data_i[1] ^ data_i[6];
assign crc_next[24] = crc[16] ^ crc[25] ^ crc[26] ^ crc[31] ^ data_i[1] ^ data_i[2] ^ data_i[7];
assign crc_next[25] = crc[17] ^ crc[26] ^ crc[27] ^ data_i[2] ^ data_i[3];
assign crc_next[26] = crc[18] ^ crc[24] ^ crc[27] ^ crc[28] ^ crc[30] ^ data_i[0] ^ data_i[3] ^ data_i[4] ^ data_i[6];
assign crc_next[27] = crc[19] ^ crc[25] ^ crc[28] ^ crc[29] ^ crc[31] ^ data_i[1] ^ data_i[4] ^ data_i[5] ^ data_i[7];
assign crc_next[28] = crc[20] ^ crc[26] ^ crc[29] ^ crc[30] ^ data_i[2] ^ data_i[5] ^ data_i[6];
assign crc_next[29] = crc[21] ^ crc[27] ^ crc[30] ^ crc[31] ^ data_i[3] ^ data_i[6] ^ data_i[7];
assign crc_next[30] = crc[22] ^ crc[28] ^ crc[31] ^ data_i[4] ^ data_i[7];
assign crc_next[31] = crc[23] ^ crc[29] ^ data_i[5];

// Data buffer for CRC calculation
logic [7:0] crc_buffer;

// Logic to calculate tx_av (availability) and tx_bz (busy) signals
always_comb begin
    // Check if there's enough space in the buffer to transmit data
    tx_av <= (end_ptr + 2047 - begin_ptr) % 2048 > 63;
    
    // Enable transmission if tx_av is true and tx_en is asserted
    int_en <= tx_av && tx_en;
    if(crc_ct)
        crc_in<=buffer_out;
    else
        crc_in <= 8'b00000000;
    // Set tx_bz to indicate if the transmitter is busy
    tx_bz <= send_status != 0;
end

// State machine and data transmission logic
always_ff @(posedge clk or negedge rst) begin
    if (rst == 1'b0) begin
        // Reset pointers and status when reset is active
        begin_ptr <= 0;
        end_ptr <= 0;
        send_status <= 0;
    end else begin
        p_txen <= 1'b0;
        tick <= tick + 8'd1;
        if (tick == 3) begin
            tick <= 0;
        end
        if(int_en)begin
            buffer[begin_ptr] <= data;
            begin_ptr <= begin_ptr + 16'd1;
            if(begin_ptr == 2047)begin_ptr<=0;
        end
        // Transmission logic based on send_status
        case (send_status)
            0: begin // State 0 - Idle, waiting for tx_en
                if (begin_ptr != end_ptr) begin
                    // Move to the next state when data is available
                    send_status <= 1;
                    send_cnt <= 0;
                    crc <= 32'hFFFFFFFF; // Initialize CRC
                end
            end
            
            1: begin // State 1 - Send preamble and SFD
                send_cnt <= send_cnt + 8'd1;
                p_txd <= 2'b01;
                p_txen <= 1'b1;
                if (send_cnt == 31) begin
                    p_txd <= 2'b11;
                    send_status <= 2; // Move to the next state
                    send_cnt <= 0;
                    tick <= 0;
                    crc_ct <= 1'b1;
                end
            end
            
            2: begin // State 2 - Send payload
                if (tick == 0) crc <= crc_next; // Calculate CRC
                
                buffer_out <= {2'bXX, buffer_out[7:2]}; // Shift data from buffer
                p_txd <= buffer_out[1:0];
                p_txen <= 1'b1;
                if (tick == 2) begin
                    end_ptr <= end_ptr + 16'd1; // Move the end pointer
                    if (end_ptr == 2047) end_ptr <= 0;
                end
                
                if (tick == 3 && send_cnt < 96) send_cnt <= send_cnt + 8'd1;
                
                if (tick == 3 && (end_ptr - begin_ptr) % 2048 == 0) begin
                    crc_ct <= 1'b0; // Disable CRC calculation
                    if (send_cnt < 63)
                        send_status <= 3; // Move to the next state
                    else begin
                        send_status <= 4; // Move to the next state
                        send_cnt <= 0;
                        
                        // Calculate and append CRC to the transmission
                        crc_buffer <= ~{crc[24], crc[25], crc[26], crc[27], crc[28], crc[29], crc[30], crc[31]};
                        crc <= {crc[23:0], 8'hXX};
                    end
                end
            end
            
            3: begin // State 3 - Send padding
                if (tick == 0) crc <= crc_next; // Calculate CRC
                
                p_txd <= 0; // Send padding
                p_txen <= 1'b1;
                if (tick == 3) begin
                    send_cnt <= send_cnt + 8'd1;
                    if (send_cnt == 63) begin
                        send_status <= 4; // Move to the next state
                        send_cnt <= 0;
                        
                        // Calculate and append CRC to the transmission
                        crc_buffer <= ~{crc[24], crc[25], crc[26], crc[27], crc[28], crc[29], crc[30], crc[31]};
                        crc <= {crc[23:0], 8'hXX};
                    end
                end
            end
            
            4: begin // State 4 - Send CRC
                p_txd <= crc_buffer[1:0];
                crc_buffer <= {2'bXX, crc_buffer[7:2]}; // Shift CRC data
                p_txen <= 1'b1;
                
                if (tick == 3) begin
                    // Calculate and append CRC to the transmission
                    crc_buffer <= ~{crc[24], crc[25], crc[26], crc[27], crc[28], crc[29], crc[30], crc[31]};
                    crc <= {crc[23:0], 8'hXX};
                    
                    send_cnt <= send_cnt + 8'd1;
                    if (send_cnt == 3) begin
                        send_status <= 5; // Move to the next state
                        send_cnt <= 0;
                    end
                end
            end
            
            5: begin // State 5 - Wait for 4 cycles
                p_txd <= 2'bXX;
                p_txen <= 1'b0;
                if (tick == 3) begin
                    send_status <= 0; // Return to idle state
                end
            end
        endcase
        
        if (tick == 3) begin
            buffer_out <= buffer[end_ptr]; // Read data from the buffer
        end
    end
end


endmodule