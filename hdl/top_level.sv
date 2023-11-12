`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module top_level(
  input wire clk_100mhz,
  input wire [15:0] sw, //all 16 input slide switches
  input wire [3:0] btn, //all four momentary button switches
  output logic [15:0] led, //16 green output LEDs (located right above switches)
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1, //rgb led
  output logic spkl, spkr, //speaker outputs
  output logic mic_clk, //microphone clock
  input wire  mic_data //microphone data
  );
  assign led = sw; //for debugging
  //shut up those rgb LEDs (active high):
  assign rgb1= 0;
  assign rgb0 = 0;

  logic sys_rst;
  assign sys_rst = btn[0];

  logic clk_m;
  logic fir_input_valid;
  logic fir_output_ready;
  logic fir_ready_for_input;
  assign fir_ready_for_input = 1;
  logic [31:0] fir_output_data;
  //audio_clk_wiz macw (.clk_in(clk_100mhz), .clk_out(clk_m)); //98.3MHz
  logic clk_locked;
  clk_wiz_69632 macw (.reset(sys_rst),
                      .clk_in1(clk_100mhz),
                      .clk_out1(clk_m),
                      .locked(clk_locked)
                    ); //69.632 MHz
  fir_compiler_10taps_69632clk fir (.aclk(clk_m),
                                    .s_axis_data_tvalid(fir_input_valid),
                                    .s_axis_data_tdata({8'b0, mic_audio}),
                                    .s_axis_data_tready(fir_ready_for_input),
                                    .m_axis_data_tvalid(fir_output_ready), //fir ready for an input 
                                    .m_axis_data_tdata(fir_output_data)
                                    );


  logic record; //signal used to trigger recording
  //definitely want this debounced:
  debouncer rec_deb(  .clk_in(clk_m),
                      .rst_in(sys_rst),
                      .dirty_in(btn[1]),
                      .clean_out(record));

  //logic for controlling PDM associated modules:
  logic [8:0] m_clock_counter; //used for counting for mic clock generation
  logic audio_sample_valid;//single-cycle enable for samples at ~12 kHz (approx)
  logic signed [7:0] mic_audio; //audio from microphone 8 bit unsigned at 12 kHz
  logic[7:0] audio_data; //raw scaled audio data

  //logic for interfacing with the microphone and generating 3.072 MHz signals
  logic [7:0] pdm_tally;
  logic [8:0] pdm_counter;

  localparam PDM_COUNT_PERIOD = 32; //do not change
  localparam NUM_PDM_SAMPLES = 256; //number of pdm in downsample/decimation/average

  logic old_mic_clk; //prior mic clock for edge detection
  logic sampled_mic_data; //one bit grabbed/held values of mic
  logic pdm_signal_valid; //single-cycle signal at 3.072 MHz indicating pdm steps

  assign pdm_signal_valid = mic_clk && ~old_mic_clk;


  //logic to produce 25 MHz step signal for PWM module
  logic [1:0] pwm_counter;
  logic pwm_step; //single-cycle pwm step
  assign pwm_step = (pwm_counter==2'b11);

  always_ff @(posedge clk_m)begin
    pwm_counter <= pwm_counter+1;
  end

  //generate clock signal for microphone
  //microphone signal at ~3.072 MHz
  always_ff @(posedge clk_m)begin
    mic_clk <= m_clock_counter < PDM_COUNT_PERIOD/2;
    m_clock_counter <= (m_clock_counter==PDM_COUNT_PERIOD-1)?0:m_clock_counter+1;
    old_mic_clk <= mic_clk;
  end
  //generate audio signal (samples at ~12 kHz
  logic [3:0] audio_counter;
  always_ff @(posedge clk_m)begin
    if(audio_counter < 8)begin
      audio_counter <= audio_counter + 1;
      fir_input_valid <= 1;
      mic_audio[audio_counter] <= mic_data;
    end
    else begin
      audio_counter <= 0;
      fir_input_valid <= 0;
    end
  end
  /*always_ff @(posedge clk_m)begin
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
  end*/

  logic [7:0] tone_750; //output of sine wave of 750Hz
  logic [7:0] tone_440; //output of sine wave of 440 Hz
  logic [7:0] single_audio; //recorder non-echo output
  logic [7:0] echo_audio; //recorder echo output

  sine_generator_750 sine_750(.clk_in(clk_m),
                .rst_in(sys_rst),
                .step_in(audio_sample_valid),
                .amp_out(tone_750));
  //generate a 440 Hz tone
  //assign tone_440 = 0; //replace and make instance of sine generator for 440 Hz
  sine_generator_440 sine_440(.clk_in(clk_m),
                .rst_in(sys_rst),
                .step_in(audio_sample_valid),
                .amp_out(tone_440));
  recorder my_recorder(
    .clk_in(clk_m), //system clock
    .rst_in(sys_rst),//global reset
    .record_in(record), //button indicating whether to record or not
    .audio_valid_in(audio_sample_valid), //12 kHz audio sample valid signal
    .audio_in(mic_audio), //8 bit signed data from microphone
    .single_out(single_audio), //played back audio (8 bit signed at 12 kHz)
    .echo_out(echo_audio) //played back audio (8 bit signed at 12 kHz)
  );


  //choose which signal to play:
  logic [7:0] audio_data_sel;

  always_comb begin
    if          (sw[0])begin
      audio_data_sel = tone_750; //signed
    end else if (sw[1])begin
      audio_data_sel = tone_440; //signed
    end else if (sw[5])begin
      audio_data_sel = mic_audio; //signed
    end else if (sw[6])begin
      audio_data_sel = single_audio; //signed
    end else if (sw[7])begin
      audio_data_sel = echo_audio; //signed
    end else begin
      audio_data_sel = mic_audio; //signed
    end
  end


  logic signed [7:0] vol_out; //can be signed or not signed...doesn't really matter
  // all this does is convey the output of vol_out to the input of the pdm
  // since it isn't used directly with any sort of math operation its signedness
  // is not as important.
  volume_control vc (.vol_in(sw[15:13]),.signal_in(audio_data_sel), .signal_out(vol_out));

  //PWM:
  logic pwm_out_signal; //an inherently digital signal (0 or 1..no need to make signed)
  //the "value" is encoded using Pulse Width Modulation
  //PDM:
  logic pdm_out_signal; //an inherently digital signal (0 or 1..no need to make signed)
  //the value is encoded using Pulse Density Modulation
  logic audio_out; //value that drives output channels directly

  //already implemented for you:
  pwm my_pwm(
    .clk_in(clk_m),
    .rst_in(sys_rst),
    .level_in(vol_out),
    .tick_in(pwm_step),
    .pwm_out(pwm_out_signal)
  );

  //you build (currently empty):
  pdm my_pdm(
    .clk_in(clk_m),
    .rst_in(sys_rst),
    .level_in(vol_out),
    .tick_in(pdm_signal_valid),
    .pdm_out(pdm_out_signal)
  );

  always_comb begin
    case (sw[4:3])
      2'b00: audio_out = pwm_out_signal;
      2'b01: audio_out = pdm_out_signal;
      2'b10: audio_out = sampled_mic_data;
      2'b11: audio_out = 0;
    endcase
  end

  assign spkl = audio_out;
  assign spkr = audio_out;

endmodule // top_level

//Volume Control
module volume_control (
  input wire [2:0] vol_in,
  input wire signed [7:0] signal_in,
  output logic signed [7:0] signal_out);
    logic [2:0] shift;
    assign shift = 3'd7 - vol_in;
    assign signal_out = signal_in>>>shift;
endmodule

`default_nettype wire