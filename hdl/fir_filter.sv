`timescale 1ns / 1ps
`default_nettype none
module fir_filter #(
    parameter WIDTH = 8
) (
    input wire rst_in,
    input wire signed [WIDTH-1:0] audio_in,
    input wire valid_in,
    input wire clk_in,
    output logic [WIDTH-1:0] filtered_audio,
    output logic data_ready
);

    logic [6:0] counter;
    //logic signed [(WIDTH+8)-1:0] accumulator;
    logic signed [50:0] accumulator;
    logic signed [WIDTH+8-1:0] COEFFICIENTS [0:31];
    logic signed [WIDTH-1:0] delay_line [0:31];
    logic signed [WIDTH-1:0] delay_line_counter;
    logic signed [(WIDTH+8)-1:0] dbg2;
    logic signed [WIDTH+8-1:0] coeff;
    integer i;
    logic multiply = 0;
    initial begin
        COEFFICIENTS[0] = -1;
        COEFFICIENTS[1] = -2;
        COEFFICIENTS[2] = -2;
        COEFFICIENTS[3] = 0;
        COEFFICIENTS[4] = 5;
        COEFFICIENTS[5] = 10;
        COEFFICIENTS[6] = 10;
        COEFFICIENTS[7] = 0;
        COEFFICIENTS[8] = -19;
        COEFFICIENTS[9] = -37;
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
    always_ff @(posedge clk_in) begin
        if(rst_in)begin
            data_ready <= 0;
            counter <= 0;
            filtered_audio <= 0; // Assign filtered_audio after counter reaches 32
            accumulator <= 0; // Reset accumulator after counter reaches 32 
            delay_line_counter <= 0;
            dbg2 <= 0;
            coeff <= 0;
        end 
        else begin
            if(valid_in) begin
                delay_line[0] <= audio_in[7:0];
                for(i = 1; i < 32; i = i+1)begin //this breaks shit
                    delay_line[i] <= delay_line[i-1];
                end
                multiply <= 1;
                counter <= 0;
                accumulator <= 0;
                data_ready <= 0;
            end
            else if(multiply)begin
                if(counter >= 32)begin
                    data_ready <= 1;
                    filtered_audio <= accumulator;
                    multiply <= 0;
                    accumulator <= 0;
                end
                else begin
                    data_ready <= 0;
                    delay_line_counter <= delay_line[2];
                    dbg2 <= accumulator + (COEFFICIENTS[counter]*delay_line[counter]);
                    coeff <= COEFFICIENTS[counter];
                    accumulator <= accumulator + (COEFFICIENTS[counter]*delay_line[counter]);
                    counter <= counter + 1;
                end
            end
            else begin
                data_ready <= 0;
            end
        end
    end


endmodule
`default_nettype wire