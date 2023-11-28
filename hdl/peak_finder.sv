`timescale 1ns / 1ps
`default_nettype none

module peak_finder(
            input wire clk_in,
            input wire rst_in,
            input wire fft_valid_in,
            input wire [15:0] fft_data_in,
            output logic peak_out,
            output logic peak_valid_out
  );
  logic [12:0] counter;

  logic [12:0] max_count;
  logic [15:0] max_peak;

  logic [15:0] cur_peak;


  always_ff @(posedge clk_in)begin
    if(rst_in)begin
      counter <= 0;
      max_count <= 0;
      max_peak <= 0;
      cur_peak <= 0;
    end else begin
      if(fft_valid_in)begin
        counter <= counter + 1;
        if (counter < 300) begin
            if (cur_peak > max_peak) begin
                max_count <= counter-1;
                max_peak <= cur_peak;
            end
            cur_peak <= fft_data_in[7:0] * fft_data_in[7:0] + fft_data_in[15:8] * fft_data_in[15:8];
        end else begin
            if (counter == 301) begin
                peak_out <= max_count;
                peak_valid_out <= 1;
                max_count <= 0;
                max_peak <= 0;
                cur_peak <= 0;
            end else begin
                peak_valid_out <= 0;
            end
        end
    end
      
    end
  end
endmodule


`default_nettype wire