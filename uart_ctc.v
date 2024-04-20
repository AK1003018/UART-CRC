module uart_transmitter (
    input clk,           // clk i/p
    input reset,         // rst i/p
  input [7:0] data_in, // dt i/p
    output reg tx_data,  // UART TX o/p
  output reg [7:0] checksum_out // Checksum o/p
);

// Internal state variables
reg [3:0] count;
reg [3:0] bit_count;
reg start_bit;

parameter BAUD_DIVISOR = 26'h1A2; // Adjust for desired baud rate

// UART data register
reg [9:0] uart_data_reg;

// Ch_sum register
reg [7:0] checksum_reg;

// 16-bit CRC-CCITT)
parameter [15:0] CRC_POLYNOMIAL = 16'h1021;

// Initialize state variables
always @(posedge clk or posedge reset) begin
    if (reset) begin
        count <= 4'b0;
        bit_count <= 4'b0;
        start_bit <= 1'b0;
        uart_data_reg <= 10'b0;
        tx_data <= 1'b1; // Idle state (high)
        checksum_reg <= 8'b0; // Initialize ch_sum register
    end else begin
        // UART frame transmission
        case (count)
            4'b0000: begin
                tx_data <= 1'b0; // Start bit
                start_bit <= 1'b1;
                count <= count + 1;
            end
            4'b0001: begin
                if (start_bit) begin
                    uart_data_reg <= {data_in, 1'b0}; // Load data and stop bit
                    bit_count <= 4'b0001;
                    start_bit <= 1'b0;
                end
              tx_data <= uart_data_reg[0]; // o/p LSB of data
                count <= count + 1;
            end
            4'b0010: begin
              tx_data <= uart_data_reg[bit_count]; // o/p data bits
                // Calculate ch_sum using CRC
                if (bit_count[3:0] <= 8) begin
                    checksum_reg <= crc_update(uart_data_reg[bit_count], checksum_reg);
                end
                if (bit_count == 4'b1000) begin
                    count <= count + 1; // Move to stop bit
                end else begin
                    bit_count <= bit_count + 1;
                end
            end
            4'b0011: begin
                tx_data <= 1'b1; // Stop bit
                checksum_out <= checksum_reg; // o/p checksum
                count <= 4'b0; // rst count for next frame
            end
            default: begin
                tx_data <= 1'b1; // Default to idle state
                count <= 4'b0; // rst count for next frame
            end
        endcase
    end
end

// CRC update function
function [7:0] crc_update;
    input [7:0] data_in;
    input [7:0] crc_in;
    reg [15:0] crc_reg;
begin
    crc_reg = {crc_in, data_in};
    for (bit_count = 8; bit_count > 0; bit_count = bit_count - 1) begin
        if (crc_reg[15] == 1'b1) begin
            crc_reg = crc_reg ^ CRC_POLYNOMIAL;
        end
        crc_reg = {crc_reg[14:0], 1'b0};
    end
    crc_update = crc_reg[7:0];
end
endfunction

endmodule
