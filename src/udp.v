`include "rmii.sv"

// Definition of the UDP module with input and output parameters
module udp
#(
    parameter bit [31:0] ip_adr = 32'd0,                 // Default IP address
    parameter bit [47:0] mac_adr = 48'd0,                // Default MAC address
    
    parameter int arp_refresh_interval = 50000000*2,     // ARP refresh interval
    parameter int arp_max_life_time = 50000000*10        // Maximum ARP entry lifetime
)(
    input clk1m,                                        // 1 MHz clock input
    input rst,                                          // Reset input

    output logic clk50m,                                // 50 MHz clock output
    output logic ready,                                 // Ready signal output

    rmii netrmii,                                      // RMII interface signals

    output logic phyrst,                                // PHY reset signal output

    output logic [31:0] rx_head_o,                      // RX head output
    output logic rx_head_av_o,                           // RX head available signal output
    output logic [7:0] rx_data_o,                       // RX data output
    output logic rx_data_av_o,                          // RX data available signal output
    input logic rx_head_rdy_i,                          // RX head ready input
    input logic rx_data_rdy_i,                          // RX data ready input

    input logic [31:0] tx_ip_i,                         // TX IP address input
    input logic [15:0] tx_src_port_i,                   // TX source port input
    input logic [15:0] tx_dst_port_i,                   // TX destination port input
    input logic tx_req_i,                               // TX request input
    input logic [7:0] tx_data_i,                        // TX data input
    input logic tx_data_av_i,                           // TX data available input

    output logic tx_req_rdy_o,                          // TX request ready signal output
    output logic tx_data_rdy_o                          // TX data ready signal output
);

// Declaration of internal signals and registers
logic rphyrst;

// Assigning netrmii.mdc to the 1 MHz clock
assign netrmii.mdc = clk1m;

/////////////////////////////////////////////////////////////////////////////////////// MDIO MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////     
    
//SMI = Serial Management Interface
//Before a register access, PHY devices generally require a preamble of 32 ones to be sent by the MAC on the MDIO line
//During a write command, the MAC provides address and data. For a read command, the PHY takes over the MDIO line during the turnaround bit times

logic phy_rdy;
logic SMI_trg;
logic SMI_ack;
logic SMI_ready;
logic SMI_rw;
logic [4:0] SMI_adr;
logic [15:0] SMI_data;
logic [15:0] SMI_wdata;

byte SMI_status;

// Assigning ready signal
assign ready = phy_rdy;

// Instantiating an SMI controller module 'SMI_ct' for PHY communication
SMI_ct ct(
    .clk(clk1m),              // 1 MHz clock input for SMI
    .rst(rphyrst),            // PHY reset signal
    .rw_i(SMI_rw),              // Read/Write control signal for SMI
    .trg_i(SMI_trg),            // SMI trigger signal
    .ready_o(SMI_ready),        // SMI ready signal
    .ack_o(SMI_ack),            // SMI acknowledge signal
    .phy_adr_i(5'd1),           // PHY address for SMI communication
    .reg_adr_i(SMI_adr),        // Register address for SMI communication
    .data_i(SMI_wdata),         // Data to be written via SMI
    .smi_data_o(SMI_data),      // Data received from SMI
    .mdio(netrmii.mdio)       // MDIO interface for SMI
);

// Always block for handling PHY initialization and SMI communication
always_ff@(posedge clk1m or negedge rst) begin
    if (rst == 1'b0) begin
        phy_rdy <= 1'b0;
        rphyrst <= 1'b0;
        SMI_trg <= 1'b0;
        SMI_adr <= 5'd1;
        SMI_rw <= 1'b1;
        SMI_status <= 0;
    end else begin
        rphyrst <= 1'b1;
        if (phy_rdy == 1'b0) begin
            SMI_trg <= 1'b1;
            if (SMI_ack && SMI_ready) begin
                case (SMI_status)
                    0: begin
                        //Set Register 31 Page Select Register to 7
                        SMI_adr <= 5'd31;
                        SMI_wdata <= 16'h7;
                        SMI_rw <= 1'b0; //write

                        SMI_status <= 1;
                    end
                    1: begin
                        //Set Page 7 Register 16 RMII Mode Setting Register to 1111 1111 1111 1110
                        //Rg_rmii_clkdir = 1 --- Set TXC of Input type
                        //Rg_rmii_tx_offset = 1111 (Default)
                        //RG_rmii_r_offset = 1111 (Default)
                        //RMII Mode = 1 --- Set Reduced MII Mode
                        //Rg_rmii_rxdv_sel = 1 --- Set CRS/CRS_DV pin as RXDV signal
                        //Rg_rmii_rxdsel = 1 --- Set RMII data with SSD error
                        
                        SMI_adr <= 5'd16;
                        SMI_wdata <= 16'hFFE;

                        SMI_status <= 2;
                    end
                    2: begin
                        //
                        SMI_rw <= 1'b1; //read
                        
                        SMI_status <= 3;
                    end
                    3: begin
                        //Set Register 31 Page Select Register to 0
                        SMI_adr <= 5'd31;
                        SMI_wdata <= 16'h0;
                        SMI_rw <= 1'b0; //write

                        SMI_status <= 4;
                    end
                    4: begin
                        //Reads Register 1 Basic Mode Status Register
                        SMI_adr <= 5'd1;
                        SMI_rw <= 1'b1; //read

                        SMI_status <= 5;
                    end
                    5: begin
                        // If Link Status == 1 (Valid Link established) the PHY is ready
                        if (SMI_data[2]) begin
                            phy_rdy <= 1'b1;
                            SMI_trg <= 1'b0;
                        end
                    end
                endcase
            end
        end
    end
end

/////////////////////////////////////////////////////////////////////////////////////// RX PREAMBLE ///////////////////////////////////////////////////////////////////////////////////////  

// Assigning the PHY reset signal to 'phyrst' output
assign phyrst = rphyrst;

// Assigning the 50 MHz clock from RMII interface to 'clk50m' output
assign clk50m = netrmii.clk50m;

// Declaration of signals and variables related to the RX FIFO and data reception
logic arp_rpy_fin;
byte rx_state;
byte cnt;
logic[7:0] rx_data_s;
logic crs;
assign crs = netrmii.rx_crs; //Carrier sense is high when transmitting, receiving, or the medium is otherwise sensed as being in use
logic[1:0] rxd;
assign rxd = netrmii.rxd; //
byte rx_cnt;
byte tick;

logic fifo_in;
logic[7:0] fifo_d;

//This section checks for the PREAMBLE (7 bytes of alternating 0 and 1, 0x55) and the SFD (0x5D) and then fills the fifo_d with the message

//RX comes 2 bits at a time, RX_DATA_S gets filled in 4 ticks and assigned to fifo_d, fifo_in is true at the end of the 4 ticks if we are receiving data after the PREAMBLE + SFD (rx_state = 3)
always_comb begin
    fifo_in <= (tick == 0 && rx_state == 3);
    fifo_d <= rx_data_s;
end

logic fifo_drop;

// Clock-sensitive block to handle RX data processing and FIFO management
always @(posedge clk50m or negedge phy_rdy) begin
    if(phy_rdy==1'b0)begin
        cnt <= 0;
    end else begin
        
        if (crs == 1'b1) begin
            
            tick <= tick + 8'd1;
            if (tick == 3) tick <= 0;
            rx_data_s <= {rxd,rx_data_s[7:2]};
        end
        rx_cnt <= 0;
        fifo_drop <= 1'b0;
        if (crs == 1'b0) begin
            rx_state <= 0;
            rx_data_s <= 8'b00XXXXXX;
        end

        // State machine for handling different stages of RX data reception
        case(rx_state)
            0:begin
                rx_state <= 1;
            end
            1:begin // Detection of preamble and phase
                if(rx_data_s[7:0] == 8'h55) begin
                    rx_state <= 2;
                end
            end
            2:begin
                // Case 2: Detecting the presence of the preamble and sync word
                tick <= 1;  // Set 'tick' to 1 for synchronization
                if (rx_data_s == 8'h55) begin
                    // Check if the received byte matches the preamble (0x55)
                    rx_cnt <= rx_cnt + 8'd1; // Increment the RX counter
                end else begin
                    if (rx_data_s == 8'hD5 && rx_cnt > 26) begin
                        // Check if the received byte is the sync word (0xD5)
                        // and if enough preamble bytes have been received
                        rx_state <= 3; // Move to the next state for data reception
                        tick <= 1;     // Reset 'tick' for the next phase
                    end else begin
                        rx_state <= 0; // Reset the state if conditions are not met
                    end
                end
            end

            3:begin
                // Case 3: Receiving data and checking for carrier sense
                if (crs == 1'b0)
                    fifo_drop <= 1'b1; // Indicate FIFO drop if carrier sense is lost
            end
        endcase
    end
end

/////////////////////////////////////////////////////////////////////////////////////// ETHERNET, IPV4 UDP AND ARP RX MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////  
    
logic [7:0] rx_data_gd; // Buffer for received data
logic rx_data_rdy;      // Signal indicating the availability of received data
logic rx_data_fin;      // Signal indicating the end of received data

shortint rx_data_byte_cnt; // Counter for received data bytes
byte ethernet_resolve_status; // Status for Ethernet resolution process

logic [47:0] rx_info_buf; // Buffer for received information

logic [47:0] rx_src_mac; // Source MAC address of the received packet
logic [15:0] rx_type;   // Type information from the received packet

// ARP request handling and status signals
// 0: No request, 1: Undefined
// 2: Request from slot 0, 3: Request from slot 1
// 4: Need reply to slot 0, 5: Need reply to slot 1
logic [2:0] arp_request;

// ARP list status
// 0: Not ready, 1: Ready
logic [1:0] arp_list;

// ARP entry lifetime status for slots 0 and 1
int arp_life_time[1:0];

logic [47:0] arp_mac_0; // ARP MAC address for slot 0
logic [47:0] arp_mac_1; // ARP MAC address for slot 1
logic [31:0] arp_ip_0;  // ARP IP address for slot 0
logic [31:0] arp_ip_1;  // ARP IP address for slot 1

logic [1:0] arp_clean; // ARP cleanup status

shortint head_len; // Length of the packet header

logic [17:0] checksum; // Checksum for data integrity

logic [31:0] src_ip; // Source IP address
logic [31:0] dst_ip; // Destination IP address
logic [15:0] src_port; // Source port number
logic [15:0] dst_port; // Destination port number

logic [15:0] idf; // Identifier field for packet identification
logic [15:0] udp_len; // Length of the UDP packet

shortint rx_head_fifo_head_int; // Integer representation of the RX head FIFO head
shortint rx_head_fifo_head; // RX head FIFO head
shortint rx_head_fifo_tail = 0; // RX head FIFO tail
logic [31:0] rx_head_fifo[127:0]; // RX head FIFO storage

logic [31:0] rx_head_data_i_port; // Port for RX head data input
logic rx_head_data_i_en; // Enable signal for RX head data input
logic [7:0] rx_head_data_i_adr; // Address for RX head data input

// Task to push data into the RX header FIFO
task rx_head_fifo_push(input [31:0] data);
    rx_head_data_i_port <= data; // Set the input data port
    rx_head_data_i_en <= 1'b1;  // Enable the data input
    rx_head_data_i_adr <= rx_head_fifo_head_int[7:0]; // Set the data address

    rx_head_fifo_head_int <= rx_head_fifo_head_int + 16'd1; // Increment the head index
    if (rx_head_fifo_head_int == 127)
        rx_head_fifo_head_int <= 0; // Wrap around if the index exceeds the FIFO size
endtask

shortint rx_data_fifo_head_int; // Integer representation of the RX data FIFO head
shortint rx_data_fifo_head; // RX data FIFO head
shortint rx_data_fifo_tail = 0; // RX data FIFO tail
logic [7:0] rx_data_fifo[8191:0]; // RX data FIFO storage

logic [7:0] rx_data_fifo_i_port; // Port for RX data input
logic rx_data_fifo_i_en; // Enable signal for RX data input
logic [12:0] rx_data_fifo_i_adr; // Address for RX data input

// Task to push data into the RX data FIFO
task rx_data_fifo_push(input [7:0] data);
    rx_data_fifo_i_port <= data; // Set the input data port
    rx_data_fifo_i_en <= 1'b1;  // Enable the data input
    rx_data_fifo_i_adr <= rx_data_fifo_head_int[12:0]; // Set the data address

    rx_data_fifo_head_int <= rx_data_fifo_head_int + 16'd1; // Increment the head index
    if (rx_data_fifo_head_int == 8191)
        rx_data_fifo_head_int <= 0; // Wrap around if the index exceeds the FIFO size
endtask

logic rx_fin; // Signal indicating the end of packet reception


always_ff@(posedge clk50m or negedge phy_rdy) begin
    if (phy_rdy == 1'b0) begin
        // When PHY is not ready, reset various signals and statuses
        ethernet_resolve_status <= 0;
        rx_head_fifo_head <= 0;
        rx_head_fifo_head_int <= 0;
        rx_data_fifo_head <= 0;
        rx_data_fifo_head_int <= 0;
        arp_list <= 2'b00; // Reset ARP list status
    end else begin
        // Handle ARP list and ARP entry lifetimes
        if (arp_list[0] == 1'b1) begin
            //ARP 0 ready
            if (arp_life_time[0] != 0)
                arp_life_time[0] <= arp_life_time[0] - 1;
            else
                arp_list[0] <= 1'b0;
        end else
            arp_life_time[0] <= arp_max_life_time;
        
        if (arp_list[1] == 1'b1) begin
            //ARP 1 ready
            if (arp_life_time[1] != 0)
                arp_life_time[1] <= arp_life_time[1] - 1;
            else
                arp_list[1] <= 1'b0;
        end else
            arp_life_time[1] <= arp_max_life_time;

        // Handle ARP cleanup
        if (arp_clean[1])
            arp_list[1] <= 1'b0;
        if (arp_clean[0])
            arp_list[0] <= 1'b0;

        // Push data into RX head and RX data FIFOs
        if (rx_head_data_i_en)
            rx_head_fifo[rx_head_data_i_adr] <= rx_head_data_i_port;
        rx_head_data_i_en <= 1'b0;
        if (rx_data_fifo_i_en)
            rx_data_fifo[rx_data_fifo_i_adr] <= rx_data_fifo_i_port;
        rx_data_fifo_i_en <= 1'b0;

        rx_fin <= rx_data_fin; // Update RX finish signal

        // Handle checksum calculation
        if (rx_data_byte_cnt[0] == 1'b0) begin
            checksum <= {2'b0, checksum[15:0]} + {2'b0, rx_info_buf[15:0]} + {15'd0, checksum[17:16]};
        end
        if (rx_data_byte_cnt == 14)
            checksum <= 0;

        // Handle ARP request status transitions
        if (arp_request > 3 && arp_rpy_fin)
            arp_request <= 0;

        rx_data_byte_cnt <= rx_data_byte_cnt + 8'd1;
        rx_info_buf <= {rx_info_buf[39:0], rx_data_gd};

        // Process Ethernet resolution status

        //0: MAC DESTINATION 6 bytes
        //1: MAC SOURCE 6 bytes
        //1: ETHERTYPE 2 bytes
        // : PAYLOAD
        // : CRC 4 bytes
        // : InterPacket Gap 12 bytes
        
        //rx_info_buf contains the last 6 bytes received

        case (ethernet_resolve_status)
            0:begin
                // State 0: Check for a valid MAC address
                if (rx_data_byte_cnt == 6) begin
                    if ((rx_info_buf == mac_adr) || (rx_info_buf == 48'hFFFFFFFFFFFF))
                        ethernet_resolve_status <= 1; // Valid MAC address, proceed to the next state
                    else
                        ethernet_resolve_status <= 100; // Invalid MAC address, reset status
                end
            end
            1:begin
                // State 1: Handle Ethernet packet reception
                // - Prepare to respond to RX FIFO
                // - Parse and process Ethernet packet type
                rx_head_fifo_head_int <= rx_head_fifo_head;
                rx_data_fifo_head_int <= rx_data_fifo_head;

                if (rx_data_byte_cnt == 12) begin
                    rx_src_mac <= rx_info_buf; // Store the source MAC address
                end
                if (rx_data_byte_cnt == 14) begin
                    ethernet_resolve_status <= 100; // Reset status
                    if (rx_info_buf[15:0] == 16'h0800) // EtherType = 0x800: IP packet processing (receive UDP, ignore fragmentation)
                        ethernet_resolve_status <= 20; // Proceed to IP packet processing state
                    if (rx_info_buf[15:0] == 16'h0806) // EtherType = 0x806: ARP packet processing
                        ethernet_resolve_status <= 30; // Proceed to ARP packet processing state
                end
            end
            20:begin
                // State 20: IP packet processing
                // - Check if FIFO is full
                // - Calculate packet length (head_len)
                // - Handle checksum verification
                if ((rx_data_fifo_tail + 127 - rx_data_fifo_head_int) % 128 < 4)
                    ethernet_resolve_status <= 100; // Reject if FIFO is full
                if ((rx_data_fifo_tail + 8191 - rx_data_fifo_head_int) % 8192 < 1600)
                    ethernet_resolve_status <= 100; // Reject if FIFO space for data is insufficient
                
                //First 6 bytes of payload
                //1 0 2 3 4 5 6 7 8 9 A B C D E F
                //VER     IHL     DHCP        ECN
                //1 0 2 3 4 5 6 7 8 9 A B C D E F
                //Total Length
                //1 0 2 3 4 5 6 7 8 9 A B C D E F
                //IDentiFication

                if (rx_data_byte_cnt == 20) begin
                    //VERsion == 4 (IPV4)
                    if (rx_info_buf[47:44] != 4'd4) begin
                        ethernet_resolve_status <= 100; // Reject if not IPv4
                    end
                    //Internet Header Length: number of 32 bits words in the header
                    head_len <= rx_info_buf[43:40] * 4; // Calculate packet header length in bytes
                    idf <= rx_info_buf[15:0]; // Store the identification field
                end
                //Next 6 bytes of payload
                if (rx_data_byte_cnt == 26) begin
                    //Checks if PROTOCOL field = 0x11 (UDP)
                    if (rx_info_buf[23:16] != 8'h11)
                        ethernet_resolve_status <= 100; // Reject if not UDP packet
                end
                //Next 4 bytes (source IP address)
                if (rx_data_byte_cnt == 30) begin
                    src_ip <= rx_info_buf[31:0]; // Store source IP address
                end
                //Next 4 bytes (destination IP address)
                if (rx_data_byte_cnt == 34) begin
                    if (rx_info_buf[31:0] != ip_adr && rx_info_buf[31:0] != 32'hFFFFFFFF)
                        ethernet_resolve_status <= 100; // Reject if destination IP does not match or is broadcast

                    dst_ip <= rx_info_buf[31:0]; // Store destination IP address

                    // Verify checksum
                    if ((checksum[17:0] + {2'd0, rx_info_buf[15:0]} != 18'h0FFFF) &&
                        (checksum[17:0] + {2'd0, rx_info_buf[15:0]} != 18'h1FFFE) &&
                        (checksum[17:0] + {2'd0, rx_info_buf[15:0]} != 18'h2FFFD))
                        ethernet_resolve_status <= 100; // Checksum invalid, reject
                end
                //
                if (rx_data_byte_cnt == head_len + 14) begin
                    ethernet_resolve_status <= 21; // Proceed to next state for UDP packet processing

                    // Calculate and verify the checksum
                    if (rx_data_byte_cnt != 34)
                        checksum <= src_ip[15:0] + src_ip[31:16] + dst_ip[15:0] + dst_ip[31:16] + 16'h0011;
                    else
                        checksum <= src_ip[15:0] + src_ip[31:16] + rx_info_buf[15:0] + rx_info_buf[31:16] + 16'h0011;
                end
            end

            21:begin
                // State 21: UDP packet processing (Continuation)
                // - Push various headers into the RX head FIFO
                // - Process source and destination ports, length, and data
                if (rx_data_byte_cnt == head_len + 18) begin
                    rx_head_fifo_push(src_ip); // Push source IP into RX head FIFO
                end
                if (rx_data_byte_cnt == head_len + 19) begin
                    rx_head_fifo_push(dst_ip); // Push destination IP into RX head FIFO
                end
                if (rx_data_byte_cnt == head_len + 21) begin
                    rx_head_fifo_push({src_port, dst_port}); // Push source and destination ports into RX head FIFO
                end
                if (rx_data_byte_cnt == head_len + 22) begin
                    rx_head_fifo_push({idf, udp_len - 8}); // Push identification field and UDP length into RX head FIFO
                end

                //First 6 bytes of UDP header
                if (rx_data_byte_cnt == head_len + 20) begin
                    src_port <= rx_info_buf[47:32]; // Store source port
                    dst_port <= rx_info_buf[31:16]; // Store destination port
                    udp_len <= rx_info_buf[15:0]; // Store UDP length
                end
                
                //(upd_len includes the length of the header)
                if (rx_data_byte_cnt > head_len + 22 && udp_len != 8) begin
                    rx_data_fifo_push(rx_info_buf[7:0]); // Push UDP data into RX data FIFO if not empty
                end

                if (rx_data_byte_cnt == head_len + 14 + udp_len) begin
                    if (rx_data_byte_cnt[0] == 1'b1) begin
                        if ((checksum[17:0] + {2'd0, rx_info_buf[7:0], 8'd0} + udp_len != 18'h0FFFF) &&
                            (checksum[17:0] + {2'd0, rx_info_buf[7:0], 8'd0} + udp_len != 18'h1FFFE) &&
                            (checksum[17:0] + {2'd0, rx_info_buf[7:0], 8'd0} + udp_len != 18'h2FFFD))
                            ethernet_resolve_status <= 100; // Checksum invalid, reject
                        else begin
                            ethernet_resolve_status <= 29; // Proceed to next state
                            // Move head and data pointers
                            rx_head_fifo_head <= rx_head_fifo_head_int;
                            if (udp_len != 8)
                                rx_data_fifo_head <= rx_data_fifo_head_int == 8191 ? 16'd0 : rx_data_fifo_head_int + 16'd1;
                        end
                    end else begin
                        if ((checksum[17:0] + {2'd0, rx_info_buf[15:0]} + udp_len != 18'h0FFFF) &&
                            (checksum[17:0] + {2'd0, rx_info_buf[15:0]} + udp_len != 18'h1FFFE) &&
                            (checksum[17:0] + {2'd0, rx_info_buf[15:0]} + udp_len != 18'h2FFFD))
                            ethernet_resolve_status <= 100; // Checksum invalid, reject
                        else begin
                            ethernet_resolve_status <= 29; // Proceed to next state
                            // Move head and data pointers
                            rx_head_fifo_head <= rx_head_fifo_head_int;
                            if (udp_len != 8)
                                rx_data_fifo_head <= rx_data_fifo_head_int == 8191 ? 16'd0 : rx_data_fifo_head_int + 16'd1;
                        end
                    end
                end
            end
            29:begin
                // State 29: Placeholder for additional processing if needed

            end

            30:begin
                // State 30: ARP packet processing
                // - Check and respond to ARP request
                // - Only respond to ARP packets of a specific format
                //Bytes
                //0 1 HTYPE Hardware Type (for Ethernet 0x0001)
                //2 3 PTYPE Protocol Type (for IPV4 0x0800)
                //4 HLEN Hardware Length (for Ethernet 0x06)
                //5 PLEN Protocol Length (for IPV4 0x04)
                //6 7 OPER Operation (request = 0x0001, reply = 0x0002)
                //8 9 10 11 12 13 SHA Sender Hardware Address
                //14 15 16 17 SPA Sender Protocol Address
                //18 19 20 21 22 23 THA Target Hardware Address
                //24 25 26 27 TPA Target Protocol Address
                
                if (rx_data_byte_cnt == 20) begin
                    if (rx_info_buf == 48'h000108000604)
                        ethernet_resolve_status <= 31; // Valid ARP packet, proceed to next state (31)
                    else
                        ethernet_resolve_status <= 100; // Reject if ARP packet format doesn't match
                end
            end

            31:begin
                // State 31: ARP response
                // - Write MAC and IP address into ARP table
                // - Respond to ARP request with ARP reply
                // - Check if the ARP request is for its own IP address
                //arp_request = (0 no request) (1 undefined) (2 request from mac 0) (3 request from mac 1) (4 need reply to mac 0) (5 need reply to mac 1)
                if (rx_data_byte_cnt == 22) begin
                    // If it's an ARP request (OPER = 0x0001) and no pending requests, update ARP request state (2)
                    if (rx_info_buf[15:0] == 16'h0001 && arp_request == 0) begin
                        //If the MAC is not in ARP table, defaults to ARP 0, otherwise goes to relative ARP sequence
                        arp_request <= 2; 
                        if (arp_list[1] && arp_mac_1 == rx_src_mac)
                            arp_request <= 3;
                    end
                end
                //Sender Hardware and Protocol Address
                if (rx_data_byte_cnt == 32) begin
                    //if sender address is not in ARP table
                    if (rx_src_mac != arp_mac_0 && rx_src_mac != arp_mac_1) begin
                        // Shifts ARP by 1
                        arp_mac_1 <= arp_mac_0;
                        arp_ip_1 <= arp_ip_0;
                        arp_list[1] <= arp_list[0];
                        arp_life_time[1] <= arp_life_time[0];
                        //Adds new address to ARP 0
                        arp_mac_0 <= rx_src_mac;
                        arp_ip_0 <= rx_info_buf[31:0]; //SPA
                        arp_list[0] <= 1'b1;
                        arp_life_time[0] <= arp_max_life_time;
                    end
                    //if sender MAC address is ARP 0, updates IP address of ARP 0
                    if (rx_src_mac == arp_mac_0) begin
                        arp_ip_0 <= rx_info_buf[31:0]; //SPA
                        arp_list[0] <= 1'b1;
                        arp_life_time[0] <= arp_max_life_time;
                    end
                    //if [...] for ARP 1
                    if (rx_src_mac == arp_mac_1) begin
                        arp_ip_1 <= rx_info_buf[31:0]; //SPA
                        arp_list[1] <= 1'b1;
                        arp_life_time[1] <= arp_max_life_time;
                    end
                end
                //Target Hardware and Protocol Address
                if (rx_data_byte_cnt == 42) begin
                    // Check if the ARP request is for its own IP address (TPA == ip_adr)
                    if (rx_info_buf[31:0] == ip_adr && arp_request >= 2) begin
                        //Begins "need reply" sequence for relative ARP address
                        arp_request <= arp_request + 3'd2;
                    end else begin
                        //Otherwise resets the sequence
                        arp_request <= 0;
                    end
                end
            end

        endcase


        // Reset data byte count when data is not ready
        if (rx_data_rdy == 1'b0)
            rx_data_byte_cnt <= 0;

        // Reset Ethernet resolution status when the reception is complete
        if (rx_fin)
            ethernet_resolve_status <= 0;
    end
end

logic read_head;
logic read_data;

// Assign values to read_head and read_data based on input conditions
always_comb begin
    read_head <= rx_head_rdy_i && rx_head_av_o;
    read_data <= rx_data_rdy_i && rx_data_av_o;
end

// Process data based on clock and PHY status
always_ff@(posedge clk50m or negedge phy_rdy) begin
    if (phy_rdy == 1'b0) begin
        // If PHY is not ready, reset FIFO tail pointers and output availability
        rx_head_fifo_tail <= 0;
        rx_data_fifo_tail <= 0;
        rx_head_av_o <= 1'b0;
        rx_data_av_o <= 1'b0;
    end else begin
        // Update FIFO output availability based on head and tail pointers
        rx_head_av_o <= rx_head_fifo_head != rx_head_fifo_tail;
        if (read_head) rx_head_av_o <= rx_head_fifo_head != (rx_head_fifo_tail + 1) % 128;

        // Increment the tail pointer for the head FIFO if read condition is met
        if (read_head) rx_head_fifo_tail <= (rx_head_fifo_tail + 1) % 16'd128;

        // Output data from head FIFO and update tail pointer
        rx_head_o <= rx_head_fifo[rx_head_fifo_tail];
        if (read_head) rx_head_o <= rx_head_fifo[(rx_head_fifo_tail + 1) % 128];

        // Update FIFO output availability based on head and tail pointers
        rx_data_av_o <= rx_data_fifo_head != rx_data_fifo_tail;
        if (read_data) rx_data_av_o <= rx_data_fifo_head != (rx_data_fifo_tail + 1) % 8192;

        // Increment the tail pointer for the data FIFO if read condition is met
        if (read_data) rx_data_fifo_tail <= (rx_data_fifo_tail + 1) % 16'd8192;

        // Output data from data FIFO and update tail pointer
        rx_data_o <= rx_data_fifo[rx_data_fifo_tail];
        if (read_data) rx_data_o <= rx_data_fifo[(rx_data_fifo_tail + 1) % 8192];
    end
end

// CRC check module instantiation
CRC_check crc(
    .clk(clk50m),
    .rst(phy_rdy),
    .data(fifo_d),
    .av(fifo_in),
    .stp(fifo_drop),
    .data_gd(rx_data_gd),
    .rdy(rx_data_rdy),
    .fin(rx_data_fin)
);

/////////////////////////////////////////////////////////////////////////////////////// ETHERNET FRAME TX MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////  
    
// ARP packet response related logic
logic test_tx_en;
logic [7:0] test_data;
byte arp_rpy_status;
shortint arp_rpy_cnt;

// Initialize ARP header data
logic [7:0] arp_head [8:0] = {8'h08,8'h06,8'h00,8'h01,8'h08,8'h00,8'h06,8'h04,8'h00};

// TX (transmit) module instantiation
tx_ct ctct(
    .clk(clk50m),
    .rst(phy_rdy),
    .data(test_data),
    .tx_en(test_tx_en),
    .tx_bz(tx_bz),
    .tx_av(tx_av),
    .p_txd(netrmii.txd),
    .p_txen(netrmii.txen)
);
    
/////////////////////////////////////////////////////////////////////////////////////// ETHERNET PAYLOAD AND ARP RESPONSE TX MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////  
    
// Initialize sending port and other variables
logic [15:0] sendport = 16'h1234;
logic [47:0] tar_mac_buf;
logic [31:0] tar_ip_buf;
logic [15:0] len_buf;

// Sending data format: Destination Address (32B), Source Address (16B), Length (16B)
// Length includes the MAC address

// TX head and data FIFOs
logic [31:0] tx_head_fifo[63:0];
shortint tx_head_fifo_head = 0;
shortint tx_head_fifo_tail = 0;
logic [31:0] tx_head_data_i_port;
logic [31:0] tx_head_data_o_port;
logic tx_head_data_i_en;
logic [6:0] tx_head_data_i_adr;

logic [7:0] tx_data_fifo[8191:0];
shortint tx_data_fifo_head = 0;
shortint tx_data_fifo_tail = 0;
logic [7:0] tx_data_data_i_port;
logic [7:0] tx_data_data_o_port;
logic tx_data_data_i_en;
logic [12:0] tx_data_data_i_adr;

// Assign data for tx_head_data_o_port and tx_data_data_o_port based on FIFO tail pointers
always_ff@(posedge clk50m) begin
    tx_head_data_o_port <= tx_head_fifo[tx_head_fifo_tail];
    tx_data_data_o_port <= tx_data_fifo[tx_data_fifo_tail];
end

// ARP-related variables
logic arp_lst_refresh;        // Indicates ARP list refresh
int arp_refresh_cnt;          // Counter for ARP list refresh
logic [31:0] arp_target_ip;   // Target IP address for ARP request
logic [47:0] arp_target_mac;  // Target MAC address for ARP request
int longdelay;                // Long delay counter

// Process ARP-related logic based on clock and PHY status
always_ff@(posedge clk50m or negedge phy_rdy) begin
    if (phy_rdy == 1'b0) begin
        // Reset ARP-related variables when PHY is not ready
        arp_refresh_cnt <= 0;
        arp_rpy_status <= 0;
        arp_clean <= 2'b00;
        tx_head_fifo_tail <= 0;
        tx_data_fifo_tail <= 0;
    end else begin
        arp_rpy_fin <= 1'b0;
        test_tx_en <= 1'b0;
        arp_rpy_cnt <= arp_rpy_cnt + 16'd1;
        arp_clean <= 2'b00;

        case (arp_rpy_status)
            0: begin
                // Case 0: Handling ARP Requests and Refresh
                if (arp_request > 3) begin
                    arp_rpy_status <= 1;
                    arp_rpy_cnt <= 0;
                end else begin
                    if (tx_head_fifo_head != tx_head_fifo_tail) begin
                        // Data to send exists; request ARP if necessary
                        arp_rpy_cnt <= 0;
                        arp_target_ip <= tx_head_data_o_port;
                        arp_rpy_status <= 2;
                        longdelay <= 50000; // 1ms
                        if (tx_head_data_o_port == arp_ip_0 && arp_list[0]) begin
                            tx_head_fifo_tail <= (tx_head_fifo_tail + 1) % 16'd64;
                            arp_target_mac <= arp_mac_0;
                            arp_rpy_status <= 3;
                        end
                        if (tx_head_data_o_port == arp_ip_1 && arp_list[1]) begin
                            tx_head_fifo_tail <= (tx_head_fifo_tail + 1) % 16'd64;
                            arp_target_mac <= arp_mac_1;
                            arp_rpy_status <= 3;
                        end
                        if (tx_head_data_o_port == 32'hFFFFFFFF) begin
                            tx_head_fifo_tail <= (tx_head_fifo_tail + 1) % 16'd64;
                            arp_target_mac <= 48'hFFFFFFFFFFFF;
                            arp_rpy_status <= 3;
                        end
                    end else begin
                        // Regular ARP refresh request handling
                        arp_refresh_cnt <= arp_refresh_cnt + 1;
                        if (arp_refresh_cnt >= arp_refresh_interval) begin
                            arp_refresh_cnt <= 0;

                            if (arp_list != 2'b00) begin
                                arp_rpy_status <= 2;
                                arp_rpy_cnt <= 0;
                            end

                            if (arp_list == 2'b11) begin
                                arp_lst_refresh <= ~arp_lst_refresh;
                                arp_clean[~arp_lst_refresh] <= 1'b1;

                                if (arp_lst_refresh == 0) begin
                                    arp_target_ip <= arp_ip_1;
                                end else begin
                                    arp_target_ip <= arp_ip_0;
                                end
                            end
                            if (arp_list == 2'b10) begin
                                arp_clean[1] <= 1'b1;
                                arp_target_ip <= arp_ip_1;
                            end
                            if (arp_list == 2'b01) begin
                                arp_clean[0] <= 1'b1;
                                arp_target_ip <= arp_ip_0;
                            end
                        end
                    end
                end
            end

            1: begin
                // Case 1: Transmitting ARP Reply
                test_tx_en <= 1'b1;
                if (arp_rpy_cnt < 6)
                    test_data <= arp_request == 4 ? arp_mac_0[(5 - arp_rpy_cnt) * 8 +: 8] : arp_mac_1[(5 - arp_rpy_cnt) * 8 +: 8];
                if (arp_rpy_cnt >= 6 && arp_rpy_cnt < 12)
                    test_data <= mac_adr[(11 - arp_rpy_cnt) * 8 +: 8];
                if (arp_rpy_cnt >= 12 && arp_rpy_cnt < 21)
                    test_data <= arp_head[20 - arp_rpy_cnt];
                if (arp_rpy_cnt == 21)
                    test_data <= 8'h02;
                if (arp_rpy_cnt >= 22 && arp_rpy_cnt < 28)
                    test_data <= mac_adr[(27 - arp_rpy_cnt) * 8 +: 8];
                if (arp_rpy_cnt >= 28 && arp_rpy_cnt < 32)
                    test_data <= ip_adr[(31 - arp_rpy_cnt) * 8 +: 8];
                if (arp_rpy_cnt >= 32 && arp_rpy_cnt < 38)
                    test_data <= arp_request == 4 ? arp_mac_0[(37 - arp_rpy_cnt) * 8 +: 8] : arp_mac_1[(37 - arp_rpy_cnt) * 8 +: 8];
                if (arp_rpy_cnt >= 38 && arp_rpy_cnt < 42)
                    test_data <= arp_request == 4 ? arp_ip_0[(41 - arp_rpy_cnt) * 8 +: 8] : arp_ip_1[(41 - arp_rpy_cnt) * 8 +: 8];
                if (arp_rpy_cnt == 42)
                    arp_rpy_fin <= 1'b1;
                if (arp_rpy_cnt >= 42) begin
                    test_tx_en <= 1'b0;
                end
                if (arp_rpy_cnt == 46)
                    arp_rpy_status <= 10;
            end

            2: begin
                // Case 2: Sending ARP Request
                test_tx_en <= 1'b1;
                if (arp_rpy_cnt < 6)
                    test_data <= 8'hFF;
                if (arp_rpy_cnt >= 6 && arp_rpy_cnt < 12)
                    test_data <= mac_adr[(11 - arp_rpy_cnt) * 8 +: 8];
                if (arp_rpy_cnt >= 12 && arp_rpy_cnt < 21)
                    test_data <= arp_head[20 - arp_rpy_cnt];
                if (arp_rpy_cnt == 21)
                    test_data <= 8'h01;
                if (arp_rpy_cnt >= 22 && arp_rpy_cnt < 28)
                    test_data <= mac_adr[(27 - arp_rpy_cnt) * 8 +: 8];
                if (arp_rpy_cnt >= 28 && arp_rpy_cnt < 32)
                    test_data <= ip_adr[(31 - arp_rpy_cnt) * 8 +: 8];
                if (arp_rpy_cnt >= 32 && arp_rpy_cnt < 38)
                    test_data <= 8'h00;
                if (arp_rpy_cnt >= 38 && arp_rpy_cnt < 42)
                    test_data <= arp_target_ip[(41 - arp_rpy_cnt) * 8 +: 8];
                if (arp_rpy_cnt == 42)
                    arp_rpy_fin <= 1'b1;
                if (arp_rpy_cnt >= 42) begin
                    test_tx_en <= 1'b0;
                end
                if (arp_rpy_cnt == 46)
                    arp_rpy_status <= 10;
            end

            3: begin
                // Case 3: Sending Ethernet Payload
                if (arp_rpy_cnt == 1) begin
                    tx_head_fifo_tail <= (tx_head_fifo_tail + 1) % 16'd64;
                    len_buf <= tx_head_data_o_port[15:0];
                end

                test_tx_en <= 1'b1;
                if (arp_rpy_cnt < 6)
                    test_data <= arp_target_mac[(5 - arp_rpy_cnt) * 8 +: 8];
                if (arp_rpy_cnt >= 6 && arp_rpy_cnt < 12)
                    test_data <= mac_adr[(11 - arp_rpy_cnt) * 8 +: 8];
                if (arp_rpy_cnt >= 12 && arp_rpy_cnt < len_buf) begin
                    test_data <= tx_data_data_o_port;
                end
                if (arp_rpy_cnt >= 11 && arp_rpy_cnt < len_buf - 1)
                    tx_data_fifo_tail <= (tx_data_fifo_tail + 1) % 16'd8192;
                if (arp_rpy_cnt == len_buf - 1) begin
                    arp_rpy_status <= 10;
                end
            end

            10: begin
                // Case 10: Long Delay
                if (longdelay) longdelay <= longdelay - 1;
                if (tx_bz == 1'b0 && longdelay == 0)
                    arp_rpy_status <= 0;
            end
        endcase

    end
end

/////////////////////////////////////////////////////////////////////////////////////// UDP OVER IPV4 TX MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////  
    
// Declare signals for outbound packet generation
logic [31:0] ob_head_o;    // Outbound packet header
logic [7:0]  ob_data_o;    // Outbound packet data
logic ob_head_en;          // Outbound packet header enable
logic ob_data_en;          // Outbound packet data enable
logic ob_fin;              // Outbound packet finished signal
logic ob_busy;             // Outbound packet generator busy signal
logic ob_full;             // Outbound packet generator full signal
shortint head_cnt;         // Counter for packet header
shortint data_cnt;         // Counter for packet data

// Instantiate a UDP packet generator module
udp_generator #(.ip_adr(ip_adr)) udp_gen (
    .clk(clk50m),
    .rst(phy_rdy),
    .data(tx_data_i),
    .tx_en(tx_data_av_i),
    .req(tx_req_i),
    .ip_adr_i(tx_ip_i),
    .src_port(tx_src_port_i),
    .dst_port(tx_dst_port_i),
    .head_o(ob_head_o),
    .data_o(ob_data_o),
    .head_en(ob_head_en),
    .data_en(ob_data_en),
    .fin(ob_fin),
    .busy(ob_busy),
    .full(ob_full)
);

// Combinational logic for indicating readiness to send data
always_comb begin
    tx_req_rdy_o <= ~ob_busy; // Indicates readiness to send packet request
    tx_data_rdy_o <= ~ob_full; // Indicates readiness to send packet data
end

// Sequential logic for packet generation
always @(posedge clk50m or negedge phy_rdy) begin
    if (phy_rdy == 0) begin
        // Reset counters and FIFO pointers when PHY is not ready
        head_cnt <= 0;
        data_cnt <= 0;
        tx_data_fifo_head <= 0;
        tx_head_fifo_head <= 0;
    end else begin
        if (ob_head_en)
            head_cnt <= head_cnt + 16'd1; // Increment header counter
        
        if (ob_data_en)
            data_cnt <= data_cnt + 16'd1; // Increment data counter
        
        if (ob_fin) begin
            // Reset counters and update FIFO pointers when a packet is finished
            head_cnt <= 0;
            data_cnt <= 0;
            tx_data_fifo_head <= (tx_data_fifo_head + data_cnt) % 16'd8192;
            tx_head_fifo_head <= (tx_head_fifo_head + head_cnt) % 16'd64;
        end

        if (ob_data_en) begin
            // Store outbound data in the data FIFO
            tx_data_fifo[(tx_data_fifo_head + data_cnt) % 8192] <= ob_data_o;
        end

        if (ob_head_en) begin
            // Store outbound header in the header FIFO
            tx_head_fifo[(tx_head_fifo_head + head_cnt) % 64] <= ob_head_o;
        end
    end
end

endmodule
