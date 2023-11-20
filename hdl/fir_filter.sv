`timescale 1ns / 1ps
`default_nettype none
module fir_filter #(
    parameter WIDTH = 8
) (
    input wire rst_in,
    input wire signed [WIDTH-1:0] audio_in,
    input wire valid_in,
    input wire clk_in,
    output logic signed [WIDTH-1:0] filtered_audio,
    output logic data_ready
);

    logic [6:0] counter;
    logic signed [(WIDTH+8)-1:0] accumulator;
    //logic signed [50:0] accumulator;
    logic signed [WIDTH+8-1:0] COEFFICIENTS [31:0];
    logic signed [WIDTH-1:0] delay_line [31:0];
    logic signed [(WIDTH+8)-1:0] dbg2;
    logic signed [WIDTH+8-1:0] coeff;
    logic signed [WIDTH-1:0] cur;
    logic multiply;
    initial begin
        COEFFICIENTS[0] = -1;
        COEFFICIENTS[1] = -2;
        COEFFICIENTS[2] = -3;
        COEFFICIENTS[3] = -5;
        COEFFICIENTS[4] = -6;
        COEFFICIENTS[5] = -5;
        COEFFICIENTS[6] = 0;
        COEFFICIENTS[7] = 10;
        COEFFICIENTS[8] = 25;
        COEFFICIENTS[9] = 45;
        COEFFICIENTS[10] = 67;
        COEFFICIENTS[11] = 90;
        COEFFICIENTS[12] = 110;
        COEFFICIENTS[13] = 123;
        COEFFICIENTS[14] = 128;
        COEFFICIENTS[15] = 123;
        COEFFICIENTS[16] = 110;
        COEFFICIENTS[17] = 90;
        COEFFICIENTS[18] = 67;
        COEFFICIENTS[19] = 45;
        COEFFICIENTS[20] = 25;
        COEFFICIENTS[21] = 10;
        COEFFICIENTS[22] = 0;
        COEFFICIENTS[23] = -5;
        COEFFICIENTS[24] = -6;
        COEFFICIENTS[25] = -5;
        COEFFICIENTS[26] = -3;
        COEFFICIENTS[27] = -2;
        COEFFICIENTS[28] = -1;
        COEFFICIENTS[29] = 0;
        COEFFICIENTS[30] = 0;
        COEFFICIENTS[31] = 0;
    end
    always_ff @(posedge clk_in) begin
        if(rst_in)begin
            data_ready <= 0;
            counter <= 0;
            filtered_audio <= 0; // Assign filtered_audio after counter reaches 32
            accumulator <= 0; // Reset accumulator after counter reaches 32 
            dbg2 <= 0;
            coeff <= 0;
            multiply <= 0;
        end 
        else begin
            if(valid_in) begin
                delay_line[0] <= audio_in;
                cur <= audio_in;
                multiply <= 1;
                counter <= 0;
                accumulator <= 0;
                data_ready <= 0;
            end
            else if(multiply)begin
                if(counter >= 29)begin
                    data_ready <= 1;
                    filtered_audio <= accumulator;
                    multiply <= 0;
                    accumulator <= 0;
                end
                else begin
                    data_ready <= 0;
                    dbg2 <= accumulator + (COEFFICIENTS[counter]*delay_line[counter]);//debug line
                    coeff <= COEFFICIENTS[counter]; //debug line
                    delay_line[counter] <= (counter ==0) ? cur:delay_line[counter-1]; //circular shift
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