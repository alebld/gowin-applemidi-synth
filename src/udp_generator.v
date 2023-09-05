module udp_generator #(parameter bit [31:0] ip_adr = 32'd0)(
    input clk, rst,                    // Clock and reset signals
    input [7:0] data,                  // Input data
    input tx_en,                       // Transmission enable signal
    input req,                         // Request signal
    input [31:0] ip_adr_i,             // Input IP address
    input [15:0] src_port,             // Source port
    input [15:0] dst_port,             // Destination port

    output logic [31:0] head_o,        // Output UDP packet header
    output logic [7:0] data_o,         // Output data to be transmitted
    output logic head_en,              // Header enable signal
    output logic data_en,              // Data enable signal
    output logic fin,                  // Finish signal
    output logic busy,                 // Busy signal
    output logic full                  // Buffer full signal
);

    // Internal memory buffer for outgoing packets
    logic [7:0] buffer[2047:0];

    // Pointers for the circular buffer
    shortint begin_ptr;
    shortint end_ptr;

    // Internal variables for buffer port access
    logic [7:0] buffer_port_i;
    logic [7:0] buffer_port_o;
    logic buffer_wr;

    // State and counters for UDP packet generation
    byte udp_gen_status;
    shortint udp_gen_cnt;

    // Checksum calculation variables
    logic [17:0] checksum;
    logic [17:0] head_checksum;
    logic [15:0] send_checksum;
    logic [15:0] send_head_checksum;

    // Temporary storage for the last input byte
    logic [7:0] lst_in;

    // Packet length, IP addresses, ports, and packet number
    logic [15:0] sendlen;
    logic [31:0] local_ip;
    logic [31:0] local_src_port;
    logic [31:0] local_dst_port;
    logic [15:0] pack_num;
    logic [15:0] head_len;
    logic [15:0] udp_len;

    // Predefined values for UDP packet headers
    logic [7:0] udp_head_p1 [3:0] = {8'h08, 8'h00, 8'h45, 8'h00};
    logic [7:0] udp_head_p2 [3:0] = {8'h40, 8'h00, 8'h40, 8'h11};

    // Combinational logic for calculating various packet fields
    always_comb begin
        head_len <= 16'd28 + sendlen[15:0];
        udp_len <= 16'd8 + sendlen[15:0];
        send_checksum <= 16'hFFEF - checksum[15:0];
        if (checksum[15:0] > 16'hFFEF) begin
            send_checksum <= 16'hFFEF - 16'd1 - checksum[15:0];
        end
        send_head_checksum <= 16'h0000 - head_checksum[15:0];
    end

    // Sequential logic for packet generation and transmission
    always @(posedge clk or negedge rst) begin
        if (rst == 0) begin
            // Reset internal variables and states on reset signal
            begin_ptr <= 0;
            end_ptr <= 0;
            head_en <= 1'b0;
            data_en <= 1'b0;
            fin <= 1'b0;
            buffer_wr <= 1'b0;
            udp_gen_status <= 0;
            checksum <= 18'h00000;
            head_checksum <= 18'h00000;
            sendlen <= 0;
            full <= 0;
        end else begin
            // Store data in the buffer when buffer write is enabled
            buffer_wr <= 1'b0;
            if (buffer_wr && (!full)) begin
                buffer[end_ptr] <= buffer_port_i;
            end
            buffer_port_o <= buffer[begin_ptr];

            // Check if the buffer is full
            full <= (end_ptr + 2048 - begin_ptr) % 2048 > (2048 - 128);

            // Initialize control signals
            head_en <= 1'b0;
            data_en <= 1'b0;
            fin <= 1'b0;
            busy <= (udp_gen_status != 0) || req;

            // Increment UDP generation counter
            udp_gen_cnt <= udp_gen_cnt + 16'd1;

            // Process input data for packet generation
            if (tx_en) begin
                lst_in <= data;
                buffer_wr <= 1'b1;
                buffer_port_i <= data;
                end_ptr <= (end_ptr + 1) % 16'd2048;
                sendlen <= sendlen + 16'd1;

                // Update checksum for transmitted data
                if (sendlen[0] == 1'b1) begin
                    checksum <= {2'b0, checksum[15:0]} + {lst_in, data} + {16'd0, checksum[17:16]};
                end
            end

            // State machine for UDP packet generation and transmission
            case (udp_gen_status)
                0: begin
                    // Wait for a request signal to start packet generation
                    if (req) begin
                        udp_gen_status <= 1;
                        udp_gen_cnt <= 0;
                        local_ip <= ip_adr_i;
                        local_src_port <= src_port;
                        local_dst_port <= dst_port;
                        pack_num <= pack_num + 16'd1;
                        head_checksum <= 18'h0C512;  // Predefined header checksum
                    end
                end
                1:begin 
                    // Calculate checksum for UDP packet header and payload
                    // The UDP checksum is calculated in several steps based on the UDP packet structure.
                    
                    // Step 1: Add length, protocol, source IP, destination IP, source port, and destination port
                    if(udp_gen_cnt == 0) begin
                        checksum <= {2'b0, checksum[15:0]} + {16'd0, checksum[17:16]} + {2'b00, sendlen} + {2'b00, sendlen} + 18'h11;
                    end
                    
                    // Step 2: Add source IP and destination IP
                    if(udp_gen_cnt == 1) begin
                        checksum <= {2'b0, checksum[15:0]} + {16'd0, checksum[17:16]} + {2'b00, ip_adr[31:16]} + {2'b00, ip_adr[15:0]};
                    end
                    if(udp_gen_cnt == 2) begin
                        checksum <= {2'b0, checksum[15:0]} + {16'd0, checksum[17:16]} + {2'b00, local_ip[31:16]} + {2'b00, local_ip[15:0]};
                    end
                    
                    // Step 3: Add source port and destination port
                    if(udp_gen_cnt == 3) begin
                        checksum <= 18'({2'b0, checksum[15:0]} + {16'd0, checksum[17:16]} + {2'b00, local_src_port} + {2'b00, local_dst_port});
                    end
                    
                    // Step 4: Add payload data
                    if(udp_gen_cnt == 4) begin
                        if(sendlen[0] == 1'b1) begin
                            checksum <= {2'b0, checksum[15:0]} + {16'd0, checksum[17:16]} + {lst_in, 8'd00};
                        end
                    end
                    
                    // Steps 5-7: Continue adding zeros to checksum
                    if(udp_gen_cnt >= 5 && udp_gen_cnt <= 7) begin
                        checksum <= {2'b0, checksum[15:0]} + {16'd0, checksum[17:16]};
                    end

                    // Calculate checksum for UDP packet header (head_checksum)
                    // The header checksum is calculated in several steps based on the UDP header structure.

                    // Step 1: Add packet number (ID)
                    if(udp_gen_cnt == 0) begin
                        head_checksum <= {2'b0, head_checksum[15:0]} + {16'd0, head_checksum[17:16]} + {2'b00, pack_num};
                    end
                    
                    // Step 2: Add header length (UDP header length + options, if any)
                    if(udp_gen_cnt == 1) begin
                        head_checksum <= {2'b0, head_checksum[15:0]} + {16'd0, head_checksum[17:16]} + {2'b00, head_len};
                    end
                    
                    // Step 3: Add local IP, source IP, and destination IP
                    if(udp_gen_cnt == 2) begin
                        head_checksum <= {2'b0, head_checksum[15:0]} + {16'd0, head_checksum[17:16]} + {2'b00, local_ip[31:16]} + {2'b00, local_ip[15:0]};
                    end
                    if(udp_gen_cnt == 3) begin
                        head_checksum <= {2'b0, head_checksum[15:0]} + {16'd0, head_checksum[17:16]} + {2'b00, ip_adr[31:16]} + {2'b00, ip_adr[15:0]};
                    end
                    
                    // Steps 4-7: Continue adding zeros to header checksum
                    if(udp_gen_cnt >= 4 && udp_gen_cnt <= 7) begin
                        head_checksum <= {2'b0, head_checksum[15:0]} + {16'd0, head_checksum[17:16]};
                    end

                    // Push header and data to output
                    if(udp_gen_cnt == 0) begin
                        // Push local IP to header
                        head_en <= 1'b1;
                        head_o <= local_ip;
                    end
                    if(udp_gen_cnt == 1) begin
                        // Push length to header
                        head_en <= 1'b1;
                        head_o <= head_len + 14; // 14 is a constant offset for the UDP header length
                    end

                    data_en <= 1'b1;
                    
                    // Here, various fields of the UDP header and payload are assigned to data_o
                    // based on the value of udp_gen_cnt.
                    if(udp_gen_cnt < 4)data_o <= udp_head_p1[3-udp_gen_cnt];
                    if(udp_gen_cnt >= 4 && udp_gen_cnt < 6)data_o <= head_len[(5-udp_gen_cnt)*8 +: 8];
                    if(udp_gen_cnt >= 6 && udp_gen_cnt < 8)data_o <= pack_num[(7-udp_gen_cnt)*8 +: 8];
                    if(udp_gen_cnt >= 8 && udp_gen_cnt < 12)data_o <= udp_head_p2[11-udp_gen_cnt];
                    if(udp_gen_cnt >= 12 && udp_gen_cnt < 14)data_o <= send_head_checksum[(13-udp_gen_cnt)*8 +: 8];
                    if(udp_gen_cnt >= 14 && udp_gen_cnt < 18)data_o <= ip_adr[(17-udp_gen_cnt)*8 +: 8];
                    if(udp_gen_cnt >= 18 && udp_gen_cnt < 22)data_o <= local_ip[(21-udp_gen_cnt)*8 +: 8];
                    if(udp_gen_cnt >= 22 && udp_gen_cnt < 24)data_o <= local_src_port[(23-udp_gen_cnt)*8 +: 8];
                    if(udp_gen_cnt >= 24 && udp_gen_cnt < 26)data_o <= local_dst_port[(25-udp_gen_cnt)*8 +: 8];
                    if(udp_gen_cnt >= 26 && udp_gen_cnt < 28)data_o <= udp_len[(27-udp_gen_cnt)*8 +: 8];
                    if(udp_gen_cnt >= 28 && udp_gen_cnt < 30)data_o <= send_checksum[(29-udp_gen_cnt)*8 +: 8];
                    if(udp_gen_cnt >= 30)data_o <= buffer_port_o;
                    // Finally, update begin_ptr if applicable and transition to the next step
                    if(udp_gen_cnt >= 28 && udp_gen_cnt < 28 + sendlen) begin
                        begin_ptr <= (begin_ptr + 1) % 16'd2048; // Update begin_ptr to consume data
                    end

                    // Transition to the next state when packet generation is complete
                    if(udp_gen_cnt == 29 + sendlen) begin
                        udp_gen_status <= 2; // Set the status to 2 to indicate completion
                        sendlen <= 0;
                    end
                end

                2: begin
                    // Finish transmission
                    fin <= 1'b1;
                    udp_gen_status <= 0;
                    checksum <= 18'h00000;
                end
            endcase
        end
    end


endmodule
