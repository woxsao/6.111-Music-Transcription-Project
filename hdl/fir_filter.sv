`timescale 1ns / 1ps
`default_nettype none
module fir_filter #(
    parameter WIDTH = 8
) (
    input wire audio_in,
    input wire clk_in,
    output logic [WIDTH-1:0] filtered_audio
);

    logic [6:0] counter;
    logic signed [(WIDTH+8)-1:0] accumulator;
    logic signed [WIDTH+8-1:0] COEFFICIENTS [0:30];
    logic signed [WIDTH-1:0] delay_line [0:30];
    initial begin
        COEFFICIENTS[0]  = -1;
        COEFFICIENTS[1]  = -2;
        COEFFICIENTS[2]  = -2;
        COEFFICIENTS[3]  = 0;
        COEFFICIENTS[4]  = 5;
        COEFFICIENTS[5]  = 10;
        COEFFICIENTS[6]  = 10;
        COEFFICIENTS[7]  = 0;
        COEFFICIENTS[8]  = -19;
        COEFFICIENTS[9]  = -37;
        COEFFICIENTS[10] = -36;
        COEFFICIENTS[11] = 0;
        COEFFICIENTS[12] = 70;
        COEFFICIENTS[13] = 157;
        COEFFICIENTS[14] = 229;
        COEFFICIENTS[15] = 257;
        COEFFICIENTS[16] = 229;
        COEFFICIENTS[17] = 157;
        COEFFICIENTS[18] = 70;
        COEFFICIENTS[19] = 0;
        COEFFICIENTS[20] = -36;
        COEFFICIENTS[21] = -37;
        COEFFICIENTS[22] = -19;
        COEFFICIENTS[23] = 0;
        COEFFICIENTS[24] = 10;
        COEFFICIENTS[25] = 10;
        COEFFICIENTS[26] = 5;
        COEFFICIENTS[27] = 0;
        COEFFICIENTS[28] = -2;
        COEFFICIENTS[29] = -2;
        COEFFICIENTS[30] = -1;
    end
    always @(posedge clk_in) begin
        for (int i = 30; i > 0; i--)
            delay_line[i] <= delay_line[i - 1];

        delay_line[0] <= audio_in;

        // Calculate the FIR output
        accumulator = 0;
        for (int i = 0; i < 31; i++)
            accumulator += delay_line[i] * COEFFICIENTS[i];
        // Assign filtered output
        filtered_audio <= accumulator >>> 5'b01010; // Scaling the result down by 1024 (2^10)
        

    end

endmodule
`default_nettype wire