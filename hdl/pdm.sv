`timescale 1ns / 1ps
`default_nettype none


module pdm(
            input wire clk_in,
            input wire rst_in,
            input wire signed [7:0] level_in,
            input wire tick_in,
            output logic pdm_out
  );
  //your code here!
  logic signed [8:0] count;
  always_ff @(posedge clk_in)begin
    if(rst_in)begin
      count <= 0;
    end
    else begin
      if(tick_in)begin
        count <= level_in + count - (count[8]?-128:127);
        pdm_out <= ~count[8];
      end
    end
  end
endmodule


`default_nettype wire
