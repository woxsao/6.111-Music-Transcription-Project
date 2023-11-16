`timescale 1ns / 1ps
`default_nettype none
module fir_filter #(
    parameter WIDTH = 8
) (
    input wire rst_in,
    input wire [WIDTH-1:0] audio_in,
    input wire clk_in,
    output logic [WIDTH-1:0] filtered_audio,
    output logic data_ready
);

    logic [6:0] counter;
    logic signed [(WIDTH+8)-1:0] accumulator;
    logic signed [WIDTH+8-1:0] COEFFICIENTS [0:31];
    //logic [31:0] delay_line;

    initial begin
        COEFFICIENTS[0] = 18;
        COEFFICIENTS[1] = -185;
        COEFFICIENTS[2] = -374;
        COEFFICIENTS[3] = 26;
        COEFFICIENTS[4] = 392;
        COEFFICIENTS[5] = -229;
        COEFFICIENTS[6] = -514;
        COEFFICIENTS[7] = 578;
        COEFFICIENTS[8] = 554;
        COEFFICIENTS[9] = -1150;
        COEFFICIENTS[10] = -363;
        COEFFICIENTS[11] = 2060;
        COEFFICIENTS[12] = -375;
        COEFFICIENTS[13] = -3821;
        COEFFICIENTS[14] = 3327;
        COEFFICIENTS[15] = 16037;
        COEFFICIENTS[16] = 16037;
        COEFFICIENTS[17] = 3327;
        COEFFICIENTS[18] = -3821;
        COEFFICIENTS[19] = -375;
        COEFFICIENTS[20] = 2060;
        COEFFICIENTS[21] = -363;
        COEFFICIENTS[22] = -1150;
        COEFFICIENTS[23] = 554;
        COEFFICIENTS[24] = 578;
        COEFFICIENTS[25] = -514;
        COEFFICIENTS[26] = -229;
        COEFFICIENTS[27] = 392;
        COEFFICIENTS[28] = 26;
        COEFFICIENTS[29] = -374;
        COEFFICIENTS[30] = -185;
        COEFFICIENTS[31] = 18;
    end
    always_ff @(posedge clk_in) begin
        if(rst_in)begin
            data_ready <= 0;
            counter <= 0;
            filtered_audio <= 0; // Assign filtered_audio after counter reaches 32
            accumulator <= 0; // Reset accumulator after counter reaches 32 
        end 
        else begin
            if (counter >= 32) begin
                data_ready <= 1;
                counter <= 1;
                filtered_audio <= accumulator>>>5'b01010; // Assign filtered_audio after counter reaches 32
                accumulator <= audio_in* COEFFICIENTS[0]; // Reset accumulator after counter reaches 32
            end else begin
                data_ready <= 0;
                accumulator <= accumulator + (audio_in * COEFFICIENTS[counter]); // Perform FIR operation here
                counter <= counter + 1;
            end
        end
    end


endmodule
`default_nettype wire