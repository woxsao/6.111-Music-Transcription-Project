`timescale 1ns / 1ps
`default_nettype none

module lpf_tb();

  logic clk_in;
  logic sys_rst;
  logic audio_sample_valid;
  logic [7:0] tone_440;
  logic fir_ready_for_input;
  logic fir_output_ready;
  logic [31:0] fir_output_data;
  logic [7:0] fir_out;

  sine_generator_440 sine_440(.clk_in(clk_in),
                .rst_in(sys_rst),
                .step_in(audio_sample_valid),
                .amp_out(tone_440));

  fir_filter fir(.audio_in(tone_440),
                .clk_in(clk_in),
                .audio_ready_in(audio_sample_valid),
                .filtered_audio(fir_out),
                .data_ready_out(fir_output_ready));

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  always begin
    #80000;
    audio_sample_valid = 1;
    #5;
    audio_sample_valid = 0;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("lpf_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,lpf_tb);
    $display("Starting Sim"); //print nice message at start
    clk_in = 0;
    sys_rst = 0;
    //out_sample = 0;
    #10;
    sys_rst = 1;
    #10;
    sys_rst = 0;
    //for (int i = 0; i<4096; i=i+1)begin
    //  in_sample = i<<4;
    //  #10;
    //  end
    #10000000;
    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire
