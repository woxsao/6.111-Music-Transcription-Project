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
  input wire  mic_data, //microphone data
  output logic [3:0] ss0_an,//anode control for upper four digits of seven-seg display
  output logic [3:0] ss1_an,//anode control for lower four digits of seven-seg display
  output logic [6:0] ss0_c, //cathode controls for the segments of upper four digits
  output logic [6:0] ss1_c //cathod controls for the segments of lower four digits
  );
  assign led = sw; //for debugging
  //shut up those rgb LEDs (active high):
  assign rgb1= 0;
  assign rgb0 = 0;

  logic sys_rst;
  assign sys_rst = btn[0];

  logic clk_m;
  logic clk_locked;
  //audio_clk_wiz macw (.clk_in(clk_100mhz), .clk_out(clk_m)); //98.3MHz
  clk_wiz_69632 macw (.reset(sys_rst),
                      .clk_in1(clk_100mhz),
                      .clk_out1(clk_m),
                      .locked(clk_locked)
                    ); //69.632 MHz


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



  logic signed [15:0] dec1_out;
  logic dec1_out_ready;
  logic signed [15:0] fir1_out;
  fir_decimator #(16) fir_dec1(.rst_in(sys_rst),
                        .audio_in(mic_data?16'b0000000001111111:0),
                        .audio_sample_valid(pdm_signal_valid),
                        .clk_in(clk_m),
                        .dec_output(dec1_out),
                        .fir_out(fir1_out),
                        .dec_output_ready(dec1_out_ready));
  logic signed [15:0] dec2_out;
  logic dec2_out_ready;
  logic signed [15:0] fir2_out;
  fir_decimator #(16) fir_dec2(.rst_in(sys_rst),
                        .audio_in(dec1_out),
                        .audio_sample_valid(dec1_out_ready),
                        .clk_in(clk_m),
                        .dec_output(dec2_out),
                        .fir_out(fir2_out),
                        .dec_output_ready(dec2_out_ready));
  logic signed [15:0] dec3_out;
  logic dec3_out_ready;
  logic signed [15:0] fir3_out;
  fir_decimator #(16) fir_dec3(.rst_in(sys_rst),
                        .audio_in(dec2_out),
                        .audio_sample_valid(dec2_out_ready),
                        .clk_in(clk_m),
                        .dec_output(dec3_out),
                        .fir_out(fir3_out),
                        .dec_output_ready(dec3_out_ready));
  logic signed [15:0] dec4_out;
  logic dec4_out_ready;
  logic signed [15:0] fir4_out;
  fir_decimator #(16,4) fir_dec4(.rst_in(sys_rst),
                        .audio_in(dec3_out),
                        .audio_sample_valid(dec3_out_ready),
                        .clk_in(clk_m),
                        .dec_output(dec4_out),
                        .fir_out(fir4_out),
                        .dec_output_ready(dec4_out_ready));
                        
  localparam PDM_COUNT_PERIOD = 32; //do not change
  localparam NUM_PDM_SAMPLES = 256; //number of pdm in downsample/decimation/average

  logic old_mic_clk; //prior mic clock for edge detection
  logic sampled_mic_data; //one bit grabbed/held values of mic
  logic pdm_signal_valid; //single-cycle signal at 4.352 MHz indicating pdm steps
  logic pwm_out_signal;
  assign pdm_signal_valid = mic_clk && ~old_mic_clk;


  //generate clock signal for microphone
  //microphone signal at ~4.352 MHz
  always_ff @(posedge clk_m)begin
    mic_clk <= m_clock_counter < PDM_COUNT_PERIOD/2;
    m_clock_counter <= (m_clock_counter==PDM_COUNT_PERIOD-1)?0:m_clock_counter+1;
    old_mic_clk <= mic_clk;
  end
  //generate audio signal (samples at ~17 kHz
  always_ff @(posedge clk_m)begin
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

  logic [7:0] tone_440; //output of sine wave of 440 Hz

  //generate a 440 Hz tone
  //assign tone_440 = 0; //replace and make instance of sine generator for 440 Hz
  sine_generator_440 sine_440(.clk_in(clk_m),
                .rst_in(sys_rst),
                .step_in(audio_sample_valid),
                .amp_out(tone_440));


  //choose which signal to play:
  logic [7:0] audio_data_sel;
 
  always_comb begin
    if          (sw[0])begin
      audio_data_sel = tone_440; //signed
    end else if (sw[1])begin
      audio_data_sel = dec3_out[7:0]; //signed
    end else if (sw[5])begin
      audio_data_sel = dec1_out; //signed
    end else if (sw[6])begin
      audio_data_sel = dec2_out;
    end else if (sw[7])begin
      audio_data_sel = dec3_out; //signed
    end else begin
      audio_data_sel = dec4_out>>>2; //signed
    end
  end

  logic signed [7:0] hw_output;
  logic hw_valid;
  logic signed [24:0] stored_coeff;
  hanning_window hw(
                    .clk_in(clk_m),
                    .rst_in(sys_rst),
                    //.in_sample(dec4_out>>>8),
                    .in_sample(tone_440),
		    .audio_sample_valid(dec4_out_ready),
                    .out_sample(hw_output),
                    .hanning_sample_valid(hw_valid),
                    .stored_coeff(stored_coeff)
                    );
  logic fft_ready;
  logic fft_out_ready;
  logic fft_out_valid;
  logic fft_out_last;
  logic [15:0] fft_out_data;
  fft fft_inst(
        .clk_in(clk_m),
        .rst_in(sys_rst),
        .in_sample(hw_output),
        .audio_sample_valid(hw_valid),
        .fft_ready(fft_ready),
        .fft_out_ready(fft_out_ready),
        .fft_out_valid(fft_out_valid),
        .fft_out_last(fft_out_last),
        .fft_out_data(fft_out_data)
    );
  logic [11:0] peak_out;
  logic peak_valid_out;
  peak_finder(
            .clk_in(clk_m),
            .rst_in(sys_rst),
            .fft_valid_in(fft_out_valid),
            .fft_data_in(fft_out_data),
            .peak_out(peak_out),
            .peak_valid_out(peak_valid_out)
  );
  logic signed [7:0] vol_out; //can be signed or not signed...doesn't really matter
  // all this does is convey the output of vol_out to the input of the pdm
  // since it isn't used directly with any sort of math operation its signedness
  // is not as important.
  volume_control vc (.vol_in(sw[15:13]),.signal_in(audio_data_sel), .signal_out(vol_out));

  logic pdm_out_signal;
  logic audio_out; //value that drives output channels directly


  //you build (currently empty):
  pdm my_pdm(
    .clk_in(clk_m),
    .rst_in(sys_rst),
    .level_in(vol_out),
    .tick_in(pdm_signal_valid),
    .pdm_out(pdm_out_signal)
  );
  //logic to produce 25 MHz step signal for PWM module
  logic [1:0] pwm_counter;
  logic pwm_step; //single-cycle pwm step
  assign pwm_step = (pwm_counter==2'b11);

  always_ff @(posedge clk_m)begin
    pwm_counter <= pwm_counter+1;
  end
  pwm my_pwm(
    .clk_in(clk_m),
    .rst_in(sys_rst),
    .level_in(vol_out),
    .tick_in(pwm_step),
    .pwm_out(pwm_out_signal)
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
  
  logic [6:0] ss_c;
  seven_segment_controller mssc(.clk_in(clk_m),
                                .rst_in(sys_rst),
                                .val_in({peak_out,fft_out_data}),
                                .cat_out(ss_c),
                                .an_out({ss0_an, ss1_an}));
  
  assign ss0_c = ss_c; //control upper four digit's cathodes!
  assign ss1_c = ss_c; //same as above but for lower four digits!

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
