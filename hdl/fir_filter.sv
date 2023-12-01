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
    logic signed [WIDTH+8-1:0] COEFFICIENTS [28:0];
    logic signed [WIDTH-1:0] delay_line [28:0];
    logic signed [(WIDTH+8)-1:0] dbg2;
    logic signed [WIDTH+8-1:0] coeff;
    logic signed [WIDTH-1:0] cur;
    logic multiply;
    logic signed [23:0] accumulator_rounded;
    logic signed [15:0] accumulator_rounded_shifted;
    assign accumulator_rounded = ((accumulator) + { {(16){1'b0}}, 1'b1, {(24-16-1){1'b0}} });
    assign accumulator_rounded_shifted = (accumulator_rounded > 0)? {7'b0,accumulator_rounded[23:15]}: {7'b1111111,accumulator_rounded[23:15]};
    initial begin
        /*COEFFICIENTS[0] = 42;
        COEFFICIENTS[1] = -70;
        COEFFICIENTS[2] = -206;
        COEFFICIENTS[3] = -415;
        COEFFICIENTS[4] = -652;
        COEFFICIENTS[5] = -833;
        COEFFICIENTS[6] = -853;
        COEFFICIENTS[7] = -603;
        COEFFICIENTS[8] = -18;
        COEFFICIENTS[9] = 904;
        COEFFICIENTS[10] = 2074;
        COEFFICIENTS[11] = 3325;
        COEFFICIENTS[12] = 4443;
        COEFFICIENTS[13] = 5218;
        COEFFICIENTS[14] = 5495;
        COEFFICIENTS[15] = 5218;
        COEFFICIENTS[16] = 4443;
        COEFFICIENTS[17] = 3325;
        COEFFICIENTS[18] = 2074;
        COEFFICIENTS[19] = 904;
        COEFFICIENTS[20] = -18;
        COEFFICIENTS[21] = -603;
        COEFFICIENTS[22] = -853;
        COEFFICIENTS[23] = -833;
        COEFFICIENTS[24] = -652;
        COEFFICIENTS[25] = -415;
        COEFFICIENTS[26] = -206;
        COEFFICIENTS[27] = -70;
        COEFFICIENTS[28] = 42;*/
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
            if(valid_in && !multiply) begin
                delay_line[28] <= audio_in;
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
                    //filtered_audio <= accumulator_rounded[15:0];
                    //filtered_audio <= accumulator[23]?{2'b11,accumulator[23:10]}: accumulator[23:10];
                    filtered_audio <= accumulator[23:8];
                    multiply <= 0;
                    accumulator <= 0;
                end
                else begin
                    data_ready <= 0;
                    dbg2 <= (COEFFICIENTS[counter]*delay_line[counter]);//debug line
                    coeff <= COEFFICIENTS[counter]; //debug line
                    delay_line[counter] <= (counter ==28) ? delay_line[28]:delay_line[counter+1]; //circular shift
                    //accumulator <= accumulator + (COEFFICIENTS[counter]*delay_line[28-counter]);
                    accumulator <= $signed(accumulator) + ($signed(COEFFICIENTS[counter])*$signed(delay_line[counter]));
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