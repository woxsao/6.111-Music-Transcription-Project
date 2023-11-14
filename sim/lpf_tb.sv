`timescale 1ns / 1ps
`default_nettype none

module lpf_tb();

  logic clk_in;
  logic rst_in;
  logic [7:0] in_sample;
  logic [7:0] out_sample;
  logic audio_sample_valid;
  logic [7:0] tone_440;
  logic clk_locked;
  logic fir_ready_for_input;
  logic fir_output_ready;
  logic [31:0] fir_output_data;
  logic clk_m;
  clk_wiz_139264 macw (.reset(rst_in),
                      .clk_in1(clk_in),
                      .clk_out1(clk_m),
                      .locked(clk_locked)
                    );
  sine_generator_440 sine_440(.clk_in(clk_m),
                .rst_in(rst_in),
                .step_in(audio_sample_valid),
                .amp_out(tone_440));

  fir_compiler_30taps_139264clk fir (.aclk(clk_m),
                                    .s_axis_data_tvalid(audio_sample_valid),
                                    .s_axis_data_tdata(tone_440),
                                    .s_axis_data_tready(fir_ready_for_input),
                                    .m_axis_data_tvalid(fir_output_ready), //fir ready for an input 
                                    .m_axis_data_tdata(fir_output_data)
                                    );

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("lpf_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,lpf_tb);
    $display("Starting Sim"); //print nice message at start
    clk_in = 0;
    rst_in = 0;
    in_sample = 0;
    //out_sample = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    audio_sample_valid = 1;
    //for (int i = 0; i<4096; i=i+1)begin
    //  in_sample = i<<4;
    //  #10;
    //  end
    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire
