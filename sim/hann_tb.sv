`timescale 1ns / 1ps
`default_nettype none

module hann_tb();

  logic clk_in;
  logic rst_in;
  logic signed [7:0] in_sample;
  logic signed [7:0] out_sample;

  hanning_window #(8,4096) uut (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .in_sample(in_sample),
    .out_sample(out_sample)
);

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("hann_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,hann_tb);
    $display("Starting Sim"); //print nice message at start
    clk_in = 0;
    rst_in = 0;
    in_sample = 0;
    //out_sample = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    for (int i = 0; i<4096; i=i+1)begin
      in_sample = i<<4;
      #10;
      end
    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire
