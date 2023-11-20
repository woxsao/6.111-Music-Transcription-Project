`timescale 1ns / 1ps
`default_nettype none

module lpf_tb();

  logic clk_in;
  logic sys_rst;
  logic audio_sample_valid;
  logic signed [7:0] tone_440;
  logic fir_ready_for_input;
  logic dec_output_ready;
  logic signed [15:0] dec_out;
  localparam PDM_COUNT_PERIOD = 32; //do not change
  localparam NUM_PDM_SAMPLES = 256; //number of pdm in downsample/decimation/average
  sine_generator_440 sine_440(.clk_in(clk_in),
                .rst_in(sys_rst),
                .step_in(audio_sample_valid),
                .amp_out(tone_440));

  fir_filter #(16) fir(.audio_in(mic_data?{8'b1111_1111}:8'b0),
                .rst_in(sys_rst),
                .valid_in(pdm_signal_valid),
                .clk_in(clk_in),
                .filtered_audio(dec_out),
                .data_ready(dec_output_ready));
  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  logic mic_data;
  always begin
    #10000;
    mic_data = !mic_data;
  end
  logic old_mic_clk; //prior mic clock for edge detection
  logic sampled_mic_data; //one bit grabbed/held values of mic
  logic pdm_signal_valid; //single-cycle signal at 4.352 MHz indicating pdm steps
  logic mic_clk;
  logic [8:0] m_clock_counter;
  logic [8:0] pdm_counter;
  assign pdm_signal_valid = mic_clk && ~old_mic_clk;


  //generate clock signal for microphone
  //microphone signal at ~4.352 MHz
  always_ff @(posedge clk_in)begin
    mic_clk <= m_clock_counter < PDM_COUNT_PERIOD/2;
    m_clock_counter <= (m_clock_counter==PDM_COUNT_PERIOD-1)?0:m_clock_counter+1;
    old_mic_clk <= mic_clk;
  end
  logic [7:0] pdm_tally;
  logic signed [7:0] mic_audio;
  always_ff @(posedge clk_in)begin
    if (pdm_signal_valid)begin
      sampled_mic_data    <= mic_data;
      pdm_counter         <= (pdm_counter==NUM_PDM_SAMPLES)?0:pdm_counter + 1;
      pdm_tally           <= (pdm_counter==NUM_PDM_SAMPLES)?mic_data
                                                            :pdm_tally+mic_data;
      audio_sample_valid  <= (pdm_counter==NUM_PDM_SAMPLES);
      mic_audio           <= (pdm_counter==NUM_PDM_SAMPLES)?{~pdm_tally[7],pdm_tally[6:0]}
                                                            :mic_audio;
    end else begin
      audio_sample_valid <= 0;
    end
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("lpf_decimator_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,lpf_tb);
    $display("Starting Sim"); //print nice message at start
    clk_in = 0;
    mic_data = 0;
    sys_rst = 0;
    old_mic_clk = 0;
    sampled_mic_data = 0;
    mic_clk = 0;
    m_clock_counter = 0;
    pdm_counter = 0;
    pdm_tally = 0;
    mic_audio = 0;
    //out_sample = 0;
    #10;
    sys_rst = 1;
    #10;
    sys_rst = 0;
    #1000000;
    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire
