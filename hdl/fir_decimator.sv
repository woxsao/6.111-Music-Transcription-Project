`timescale 1ns / 1ps
`default_nettype none
module fir_decimator #(
    parameter WIDTH = 8, 
    parameter DEC_FACTOR = 4
) (
    input wire rst_in,
    input wire signed [15:0] audio_in,
    input wire audio_sample_valid,
    input wire clk_in,
    output logic signed [15:0] dec_output,
    output logic signed [15:0] fir_out,
    output logic dec_output_ready
);

    logic fir_ready;
    logic [3:0] counter;
    logic signed [15:0] fir_output;
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
            //output every 4 fir_outputs from fir1
            
            if (fir_ready) begin
                fir_out <= fir_output;
                if (counter == DEC_FACTOR-1) begin
                    dec_output_ready <= 1; // Assert output ready
                    dec_output <= fir_output; // Output the filtered data
                    counter <= 0; // Reset counter
                end
                else begin
                    dec_output_ready <= 0; // De-assert output ready
                    counter <= counter + 1; // Increment counter
                end
            end
            else begin
                dec_output_ready <= 0;
            end
        end
    end
endmodule
`default_nettype wire