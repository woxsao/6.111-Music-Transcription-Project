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
    logic signed [23:0] accumulator_rounded;
    logic signed [15:0] accumulator_rounded_shifted;
    assign accumulator_rounded = ((accumulator) + { {(16){1'b0}}, 1'b1, {(24-16-1){1'b0}} });
    assign accumulator_rounded_shifted = (accumulator_rounded > 0)? {7'b0,accumulator_rounded[23:15]}: {7'b1111111,accumulator_rounded[23:15]};
    initial begin
        COEFFICIENTS[0] = 208;
        COEFFICIENTS[1] = 136;
        COEFFICIENTS[2] = 55;
        COEFFICIENTS[3] = -145;
        COEFFICIENTS[4] = -438;
        COEFFICIENTS[5] = -739;
        COEFFICIENTS[6] = -913;
        COEFFICIENTS[7] = -812;
        COEFFICIENTS[8] = -317;
        COEFFICIENTS[9] = 603;
        COEFFICIENTS[10] = 1869;
        COEFFICIENTS[11] = 3285;
        COEFFICIENTS[12] = 4588;
        COEFFICIENTS[13] = 5505;
        COEFFICIENTS[14] = 5836;
        COEFFICIENTS[15] = 5505;
        COEFFICIENTS[16] = 4588;
        COEFFICIENTS[17] = 3285;
        COEFFICIENTS[18] = 1869;
        COEFFICIENTS[19] = 603;
        COEFFICIENTS[20] = -317;
        COEFFICIENTS[21] = -812;
        COEFFICIENTS[22] = -913;
        COEFFICIENTS[23] = -739;
        COEFFICIENTS[24] = -438;
        COEFFICIENTS[25] = -145;
        COEFFICIENTS[26] = 55;
        COEFFICIENTS[27] = 136;
        COEFFICIENTS[28] = 208;

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
                    //accumulator_rounded <= accumulator[23:0] + { {(16){1'b0}}, 1'b1, {(24-16-1){1'b0}} };
                    filtered_audio <= accumulator_rounded_shifted;
                    //filtered_audio <= accumulator[15:0];
                    multiply <= 0;
                    accumulator <= 0;
                end
                else begin
                    data_ready <= 0;
                    dbg2 <= (COEFFICIENTS[counter]*delay_line[counter]);//debug line
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