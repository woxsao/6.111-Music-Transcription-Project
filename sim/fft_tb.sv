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
    logic [15:0] fft_out_data;
    logic signed [7:0] tone_750;
    logic hanning_sample_valid;
    //logic [15:0] rand_data;
    logic [11:0] peak;
    logic peak_valid;

    cyn_sine_generator_750 sine_inst(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .step_in(audio_sample_valid),
        .amp(tone_750)
    );

    hanning_window #(8,4096) hann_inst (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .in_sample(tone_750-128),
        .audio_sample_valid(audio_sample_valid),
        .out_sample(in_sample),
        .hanning_sample_valid(hanning_sample_valid)
    );

    fft fft_inst(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .in_sample(in_sample),
        .audio_sample_valid(hanning_sample_valid),
        .fft_ready(fft_ready),
        .fft_out_ready(fft_out_ready),
        .fft_out_valid(fft_out_valid),
        .fft_out_last(fft_out_last),
        .fft_out_data(fft_out_data)
    );

    peak_finder peak_inst(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .fft_valid_in(fft_out_valid),
        .fft_data_in(fft_out_data),
        .peak_out(peak),
        .peak_valid_out(peak_valid)
    );

    always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("dump.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,fft_tb);
    $display("Starting Sim"); //print nice message at start
    clk_in = 0;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    in_sample = 0;
    //rand_data = 0;
    for (int i = 0; i<20000; i=i+1)begin
      audio_sample_valid = 1;
      #10;
      audio_sample_valid = 0;
      #500;
      //rand_data <= 16'h9F15;
      end
    $display("Simulation finished");
    $finish;
  end

endmodule