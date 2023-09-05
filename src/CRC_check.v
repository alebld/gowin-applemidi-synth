module CRC_check(
    input clk,
    input rst,

    input [7:0] data,   // Input data byte
    input av,           // Available signal, indicating new data is available
    input stp,          // Stop signal, indicating when to start processing data

    output logic [7:0] data_gd, // Output data byte after CRC check
    output logic rdy,           // Ready signal indicating data is ready to be read
    output logic fin            // Finish signal indicating data processing is complete
);

logic[7:0] buffer[2047:0];     // Internal data buffer
logic[31:0] crc;               // CRC checksum
logic[31:0] crc_next;          // Next state of CRC calculation

logic [7:0] data_i;            // Internal data byte

// Convert data byte to a bus for easy manipulation
assign data_i = {data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7]};

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

// CRC Calculation Logic
// The following block of assign statements computes the next state of the CRC based on the input data byte.
// Each bit of the next CRC state is computed based on the current CRC state and the input data byte.
// This is a common method for calculating CRCs.
// It is using bitwise XOR operations (^) to compute the new CRC state.

// Example for one bit: crc_next[0] = crc[24] ^ crc[30] ^ data_i[0] ^ data_i[6];

shortint begin_ptr;     // Buffer read pointer
shortint end_ptr;       // Buffer write pointer
logic sendout;          // Flag indicating when to send out data
logic [7:0] bdata_gd;   // Buffered data after CRC check
logic brdy;             // Buffered data ready signal
logic bfin;             // Buffered data finish signal

always_ff@(posedge clk or negedge rst) begin
    if (rst == 1'b0) begin
        // Reset internal variables on reset signal
        begin_ptr <= 0;
        end_ptr <= 0;
        rdy <= 1'b0;
        fin <= 1'b0;

        brdy <= 1'b0;
        bfin <= 1'b0;

        sendout <= 1'b0;

        crc <= 32'hFFFFFFFF; // Initialize CRC to all ones
    end else begin
        data_gd <= bdata_gd;
        rdy <= brdy;
        fin <= bfin;

        bdata_gd <= buffer[begin_ptr];
        brdy <= 1'b0;
        bfin <= 1'b0;

        if (sendout) begin
            brdy <= 1'b1;
            if (begin_ptr == end_ptr) begin
                sendout <= 1'b0;
                bfin <= 1'b1;
            end else begin
                begin_ptr <= begin_ptr + 16'd1;
                if (begin_ptr == 2047) begin_ptr <= 0;
            end
        end

        if (stp) begin
            if (crc == 32'hC704DD7B) begin
                // Start outputting the data when the correct CRC is detected
                sendout <= 1'b1;
                end_ptr <= (end_ptr + 16'd2043) % 16'd2048;
            end else begin
                // Drop the data when an incorrect CRC is detected
                begin_ptr <= end_ptr;
            end
            crc <= 32'hFFFFFFFF; // Reset CRC
        end else begin
            if (av) begin
                // Store incoming data in the buffer and update CRC
                buffer[end_ptr] <= data;
                end_ptr <= end_ptr + 16'd1;
                if (end_ptr == 2047) end_ptr <= 0;

                crc <= crc_next; // Update CRC with the next state
            end
        end
    end
end

endmodule
