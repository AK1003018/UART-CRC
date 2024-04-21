`timescale 1ns / 1ps

module uart_transmitter(
    input wire a,             // clk i/p
    input wire b,           // rst i/p
    input wire [7:0] c,   // dt i/p
    output reg d,         // UART TX o/p
    output reg [7:0] e // Checksum o/p
);

// Internal state variables
reg [3:0] f;
reg [3:0] g;
reg h;

// Baud rate divisor (for 9600 baud rate)
parameter i = 26'h1A2; // Adjust for desired baud rate

// UART data register
reg [9:0] j;

// Checksum register
reg [7:0] k;

// (16-bit CRC-CCITT)
parameter [15:0] l = 16'h1021;

// Initialize st vars
always @(posedge a or posedge b) begin
    if (b) begin
        f <= 4'b0;
        g <= 4'b0;
        h <= 1'b0;
        j <= 10'b0;
        d <= 1'b1; // Idle state (high)
        k <= 8'b0; // Initialize ch_sum register
    end else begin
        // UART frame transmission
        case (f)
            4'b0000: begin
                d <= 1'b0; // Start bit
                h <= 1'b1;
                f <= f + 1;
            end
            4'b0001: begin
                if (h) begin
                    j <= {c, 1'b0}; // Load dt and stop bit
                    g <= 4'b0001;
                    h <= 1'b0;
                end
                d <= j[0]; // o/p LSB of data
                f <= f + 1;
            end
            4'b0010: begin
                d <= j[g]; // o/p data bits
                // Calculate checksum using CRC
                if (g[3:0] <= 8) begin
                    k <= crc_update(j[g], k);
                end
                if (g == 4'b1000) begin
                    f <= f + 1; // Move to stop bit
                end else begin
                    g <= g + 1;
                end
            end
            4'b0011: begin
                d <= 1'b1; // Stop bit
                e <= k; // o/p ch_sum
                f <= 4'b0; // rst count for next frame
            end
            default: begin
                d <= 1'b1; // Default to idle state
                f <= 4'b0; // rst count for next frame
            end
        endcase
    end
end

// CRC update function
function [7:0] crc_update;
    input [7:0] m;
    input [7:0] n;
    reg [15:0] o;
begin
    o = {n, m};
    for (g = 8; g > 0; g = g - 1) begin
        if (o[15] == 1'b1) begin
            o = o ^ l;
        end
        o = {o[14:0], 1'b0};
    end
    crc_update = o[7:0];
end
endfunction

endmodule
