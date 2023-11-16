`timescale 1ns / 1ps
`default_nettype none

module lpf_tb();

  logic clk_in;
  logic sys_rst;
  logic audio_sample_valid;
  logic [7:0] tone_440;
  logic fir_ready_for_input;
  logic fir_output_ready;
  logic [7:0] fir_out;
  localparam PDM_COUNT_PERIOD = 16; //do not change
  localparam NUM_PDM_SAMPLES = 128; //number of pdm in downsample/decimation/average
  sine_generator_440 sine_440(.clk_in(clk_in),
                .rst_in(sys_rst),
                .step_in(audio_sample_valid),
                .amp_out(tone_440));

  fir_filter fir(.audio_in(tone_440),
                .rst_in(sys_rst),
                .clk_in(clk_in),
                .filtered_audio(fir_out),
                .data_ready(fir_output_ready));

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
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
  always_ff @(posedge clk_in)begin
    if (pdm_signal_valid)begin
      pdm_counter         <= (pdm_counter==NUM_PDM_SAMPLES)?0:pdm_counter + 1;
      audio_sample_valid  <= (pdm_counter==NUM_PDM_SAMPLES);
    end else begin
      audio_sample_valid <= 0;
    end
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("lpf_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,lpf_tb);
    $display("Starting Sim"); //print nice message at start
    clk_in = 0;
    sys_rst = 0;
    old_mic_clk = 0;
    sampled_mic_data = 0;
    mic_clk = 0;
    m_clock_counter = 0;
    pdm_counter = 0;

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
