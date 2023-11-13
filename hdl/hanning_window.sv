`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module hanning_window #(
    parameter DATA_WIDTH = 8,
    parameter SAMPLE_COUNT = 4096
)(
    input wire clk_in,
    input wire rst_in,
    input wire [DATA_WIDTH-1:0] in_sample,
    output logic [DATA_WIDTH-1:0] out_sample,
    output real cosout
);
    // array where each element is data type logic and width 8, and there are 4096 elements
    //logic [DATA_WIDTH-1:0] window[SAMPLE_COUNT-1:0];
    real PI;
    assign PI = 3.141592;
    logic [11:0] i;

    //real cosout;
    //assign cosout = $cos((2*PI*in_sample/256))*100;
    assign cosout = 0.5 * (1 - $cos(2 * PI * i / (SAMPLE_COUNT - 1)));
    
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            out_sample <= 0;
            i <= 0;
        end else begin
            i <= i+1;
            // Hann window function
            // for (int i = 0; i < SAMPLE_COUNT; i++) begin
            //     //out_sample <= cosout;
            //     out_sample <= cosout;
            // end
            out_sample <= cosout * in_sample;
        end
        //out_sample <= $cos(2*PI*in_sample);
    end

endmodule

`default_nettype wire