`timescale 1ns / 1ps
`default_nettype none

module chained_dec_tb();

  logic clk_in;
  logic sys_rst;
  logic audio_sample_valid;
  logic signed [7:0] tone_750;
  logic fir_ready_for_input;
  logic dec_output_ready;
  logic signed [15:0] dec_out;
  localparam PDM_COUNT_PERIOD = 32; //do not change
  localparam NUM_PDM_SAMPLES = 256; //number of pdm in downsample/decimation/average
  logic pdm_out;
  sine_generator_750 sine_750(.clk_in(clk_in),
                .rst_in(sys_rst),
                .step_in(audio_sample_valid),
                .amp_out(tone_750));
  pdm uut
          ( .clk_in(clk_in),
            .rst_in(sys_rst),
            .level_in(tone_750),
            .tick_in(pdm_signal_valid),
            .pdm_out(pdm_out)
          );
  logic signed [15:0] dec1_out;
  logic dec1_out_ready;
  logic [15:0] preserved_dec1;

/*
  logic fir_ready;
  logic [15:0] fir_output;
  fir_filter #(16) fir1(.audio_in(pdm_out?16'b0000000001111111:16'b1111111110000001),
                .rst_in(sys_rst),
                .valid_in(pdm_signal_valid),
                .clk_in(clk_in),
                .filtered_audio(fir_output),
                .data_ready(fir_ready));

  logic fir_ready2;
  logic [15:0] fir_output2;
  fir_filter #(16) fir2(.audio_in(fir_output),
                .rst_in(sys_rst),
                .valid_in(fir_ready),
                .clk_in(clk_in),
                .filtered_audio(fir_output2),
                .data_ready(fir_ready2));
  logic fir_ready3;
  logic [15:0] fir_output3;
  fir_filter #(16) fir3(.audio_in(fir_output2),
                .rst_in(sys_rst),
                .valid_in(fir_ready2),
                .clk_in(clk_in),
                .filtered_audio(fir_output3),
                .data_ready(fir_ready3));
  logic fir_ready4;
  logic [15:0] fir_output4;
  fir_filter #(16) fir4(.audio_in(fir_output3),
                .rst_in(sys_rst),
                .valid_in(fir_ready3),
                .clk_in(clk_in),
                .filtered_audio(fir_output4),
                .data_ready(fir_ready4));
  */
  fir_decimator #(16) fir_dec1(.rst_in(sys_rst),
    //{16'b1111111110000001}
    //?16'b0000000100000000 : 16'b0
                        .audio_in(pdm_out?16'b0000000001111111:16'b1111111110000001),
                        .audio_sample_valid(pdm_signal_valid),
                        .clk_in(clk_in),
                        .dec_output(dec1_out),
                        .dec_output_ready(dec1_out_ready));
  logic signed [15:0] dec2_out;
  logic dec2_out_ready;
  fir_decimator #(16) fir_dec2(.rst_in(sys_rst),
                        .audio_in(dec1_out),
                        .audio_sample_valid(dec1_out_ready),
                        .clk_in(clk_in),
                        .dec_output(dec2_out),
                        .dec_output_ready(dec2_out_ready));
  logic signed [15:0] dec3_out;
  logic dec3_out_ready;
  fir_decimator #(16) fir_dec3(.rst_in(sys_rst),
                        .audio_in(dec2_out),
                        .audio_sample_valid(dec2_out_ready),
                        .clk_in(clk_in),
                        .dec_output(dec3_out),
                        .dec_output_ready(dec3_out_ready));
  logic signed [15:0] dec4_out;
  logic dec4_out_ready;
  fir_decimator #(16) fir_dec4(.rst_in(sys_rst),
                        .audio_in(dec3_out),
                        .audio_sample_valid(dec3_out_ready),
                        .clk_in(clk_in),
                        .dec_output(dec4_out),
                        .dec_output_ready(dec4_out_ready));
  logic signed [15:0] sampled_dec4_out;
  always_ff @(posedge clk_in)begin
    if(dec4_out_ready)begin
        sampled_dec4_out <= dec4_out;
    end
  end
  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  logic pdm_val;

  logic mic_data;
  always begin
    #100;
    mic_data = !mic_data;
  end
  logic old_mic_clk; //prior mic clock for edge detection
  logic sampled_mic_data; //one bit grabbed/held values of mic
  logic pdm_signal_valid; //single-cycle signal at 4.352 MHz indicating pdm steps
  logic mic_clk;
  logic [8:0] m_clock_counter;
  logic [8:0] pdm_counter;
  assign pdm_signal_valid = mic_clk && ~old_mic_clk;
  logic [20:0] fir_counter_val;

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
        sampled_mic_data    <= pdm_out;
        pdm_counter         <= (pdm_counter==NUM_PDM_SAMPLES)?0:pdm_counter + 1;
        pdm_tally           <= (pdm_counter==NUM_PDM_SAMPLES)?pdm_out
                                                              :pdm_tally+pdm_out;
        audio_sample_valid  <= (pdm_counter==NUM_PDM_SAMPLES);
        mic_audio           <= (pdm_counter==NUM_PDM_SAMPLES)?{~pdm_tally[7],pdm_tally[6:0]}
                                                            :mic_audio;
    end else begin
        audio_sample_valid <= 0;
    end
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("pdm_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,chained_dec_tb);
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
    pdm_val = 0;
    fir_counter_val <= 0;
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
