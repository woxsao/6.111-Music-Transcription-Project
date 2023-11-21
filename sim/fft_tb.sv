`timescale 1ns / 1ps
`default_nettype none

module fft_tb();

    logic clk_in;
    logic rst_in;
    logic signed [7:0] in_sample;
    logic audio_sample_valid;
    logic fft_ready;
    logic fft_out_ready;
    logic fft_out_valid;
    logic fft_out_last;
    logic [31:0] fft_out_data;  
    logic signed [7:0] amp_out;
    logic hanning_sample_valid;

    sine_generator_750 sine_inst(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .step_in(audio_sample_valid),
        .amp_out(amp_out)
    ); 

    hanning_window #(8,4096) uut (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .in_sample(amp_out),
        .audio_sample_valid(audio_sample_valid),
        .out_sample(in_sample),
        .hanning_sample_valid(hanning_sample_valid)
    );

    fft fft_inst(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .in_sample(in_sample),
        .audio_sample_valid(audio_sample_valid),
        .fft_ready(fft_ready),
        .fft_out_ready(fft_out_ready),
        .fft_out_valid(fft_out_valid),
        .fft_out_last(fft_out_last),
        .fft_out_data(fft_out_data)
    );

    always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("fft_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,fft_tb);
    $display("Starting Sim"); //print nice message at start
    clk_in = 0;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    for (int i = 0; i<4096; i=i+1)begin
      audio_sample_valid = 1;
      #10;
      end
    $display("Simulation finished");
    $finish;
  end
    

  

endmodule