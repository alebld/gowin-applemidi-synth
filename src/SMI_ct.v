//SMI = Serial Management Interface
//Before a register access, PHY devices generally require a preamble of 32 ones to be sent by the MAC on the MDIO line
//During a write command, the MAC provides address and data. For a read command, the PHY takes over the MDIO line during the turnaround bit times

//MDIO PackET FORMAT

//PRE_32
//
//0 1 2 3 4 5 6 7 8 9 A B C D E F
//ST  OP  PA5       RA5       TA
//0 1 2 3 4 5 6 7 8 9 A B C D E F
//D16

//PRE_32 Preamble, 32 bits all '1'

//ST: start field '01'
//OP: read = '01', write = '10' {rw_i : 0 read, 1 write}
//PA5: 5 bits PHY address {phy_adr_i}
//RA5: 5 bits REGISTER address {reg_adr_i}
//TA: Turn around, '10' when writing, 'ZZ' when reading

//D16: data to read or write

module SMI_ct(
    input clk, rst, rw_i, trg_i,            // Input signals: Clock, Reset, Read/Write, Trigger
    [4:0] phy_adr_i, reg_adr_i,            // PHY Address and Register Address
    [15:0] data_i,                       // Data to be written or received
    output logic ready_o, ack_o,           // Output signals: ready_o, ack_onowledge
    logic [15:0] smi_data_o,             // Output data buffer
    inout logic mdio                   // MDIO bidirectional signal
);

    // Counter for managing SMI communication phases
    byte ct;
    
    // Register to control the internal MDIO signal
    reg rmdio;
    
    // Registers to hold transmitted and received data
    reg [31:0] tx_data;
    reg [15:0] rx_data;
    
    // Assign MDIO to be high-impedance (Z) or logic low based on rmdio
    assign mdio = rmdio ? 1'bZ : 1'b0;

    // Combinational logic to expose received data
    always_comb begin
        smi_data_o <= rx_data; // Output received data on smi_data_o
    end

    // Sequential logic for managing SMI communication
    always_ff@(posedge clk or negedge rst)begin
        if(rst == 1'b0)begin
            // Reset internal state on reset signal
            ct <= 0;
            ready_o <= 1'b0;
            ack_o <= 1'b0;
            rmdio <= 1'b1; // Set MDIO to high-impedance by default
        end else begin
            // Increment communication phase counter
            ct <= ct + 8'd1;

            // Communication phase control logic
            if(ct == 0 && trg_i == 1'b0) ct <= 0;
            if(ct == 0 && trg_i == 1'b1)begin
                // Reset communication flags when triggered
                ready_o <= 1'b0;
                ack_o <= 1'b0;
            end

            if(ct == 64)begin
                // Indicate readiness to communicate
                ready_o <= 1'b1;
            end

            if(trg_i == 1'b1 && ready_o == 1'b1)begin
                // Reset ready_o signal after triggering communication
                ready_o <= 1'b0;
            end

            rmdio <= 1'b1; // Default state of rmdio (high-impedance)

            if(ct == 4 && trg_i == 1'b1)begin
                // Prepare SMI data for transmission
                tx_data <= {2'b01, rw_i ? 2'b10 : 2'b01, phy_adr_i, reg_adr_i, rw_i ? 2'b11 : 2'b10, rw_i ? 16'hFFFF : data_i};
            end

            if(ct > 31)begin
                // Shift out bits from tx_data to rmdio
                rmdio <= tx_data[31];
                tx_data <= {tx_data[30:0], 1'b1};
            end

            if(ct == 48 && mdio == 1'b0)begin
                // Indicate completion of read or write operation
                ack_o <= 1'b1;
            end
            
            if(ct > 48)begin
                // Shift in received data from mdio
                rx_data <= {rx_data[14:0], mdio};
            end
        end
    end
endmodule
