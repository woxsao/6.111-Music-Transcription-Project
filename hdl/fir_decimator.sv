`timescale 1ns / 1ps
`default_nettype none
module fir_decimator #(
    parameter WIDTH = 8
) (
    input wire rst_in,
    input wire signed [WIDTH-1:0] audio_in,
    input wire audio_sample_valid,
    input wire clk_in,
    output logic signed [WIDTH:0] dec_output,
    output logic dec_output_ready
);

    logic signed [7:0] fir_out;
    logic fir_ready;
    logic [3:0] counter;
    logic [WIDTH:0] fir_output;
    fir_filter#(WIDTH) fir1(.audio_in(audio_in),
                .rst_in(rst_in),
                .valid_in(audio_sample_valid),
                .clk_in(clk_in),
                .filtered_audio(fir_output),
                .data_ready(fir_ready));
    always_ff @(posedge clk_in)begin
        if(rst_in)begin
            counter <= 0;
            dec_output_ready <= 0;
            dec_output <= 0;
        end
        else begin
            if(counter >= 4)begin
                counter <= 0;
                dec_output_ready <= 1;
            end
            else begin
                if(fir_ready)begin
                    counter <= counter + 1;
                    dec_output <= fir_output;
                end
                dec_output_ready <= 0;
            end
        end
    end
endmodule
`default_nettype wire