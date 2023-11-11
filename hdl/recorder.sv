`timescale 1ns / 1ps
`default_nettype none


module  recorder(
  input wire clk_in,
  input wire rst_in,
  input wire signed [7:0] audio_in,
  input wire record_in,
  input wire audio_valid_in,
  output logic signed [7:0] single_out,
  output logic signed [7:0] echo_out
  );
  //your code here
  localparam DEPTH = 65536;
  localparam WIDTH = 8;

  typedef enum{ROOT = 0, W1 = 1, W2 = 2, W3 = 3, ECHO1 = 4, ECHO2 = 5} State;
  State state;

  //we've included an instance of a dual port RAM for you:
  //how you use it is up to you.
  logic[15:0] counter;
  logic[15:0] max_audio_addr;
  logic[15:0] lookup_addr;
  logic[15:0] head_pointer;
  logic single_flag;

  logic signed [7:0] head_value;
  logic signed [7:0] w1_value;
  logic signed [7:0] w2_value;

  logic signed [7:0] ram_output;
  always_ff @(posedge clk_in) begin
    if(rst_in)begin
      counter <= 0;
      lookup_addr <= 0;
      state <= ROOT;
      single_flag <= 0;
      echo_out <= 0;
      head_pointer <= 0;
      single_out <= 0;
      head_value <= 0;
      w1_value <= 0;
      w2_value <= 0;
    end
    else begin
      if(record_in)begin
        if(audio_valid_in)
          counter <= counter + 1;
      end
      else begin //playback mode
        single_flag <= 1;
        if(counter != 0)begin //just switched into playback mode
          counter <= 0;
          max_audio_addr <= counter;
        end

        case(state)
          ROOT: begin
            if(audio_valid_in)begin
              lookup_addr <= head_pointer;
              state <= W1;
            end
          end
          W1: begin
            lookup_addr <= head_pointer -1500;
            state <= W2;
          end
          W2: begin
            lookup_addr <= head_pointer - 3000;
            state <= W3;
          end
          W3: begin
            head_value <= ram_output;
            state <= ECHO1;
          end
          ECHO1: begin
            w1_value <= (ram_output);
            state <= ECHO2;
          end
          ECHO2: begin
            w2_value <= (ram_output );
            if(head_pointer < max_audio_addr)
              head_pointer <= head_pointer + 1;
            else if(head_pointer >= max_audio_addr)
              head_pointer <= 0;
            
            state <= ROOT;
          end
        endcase
        echo_out <= head_value + (w1_value>>>1'b1) + (w2_value>>>2'b10);
        single_out <= head_value;
      end
    end
  end
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(8),
    .RAM_DEPTH(65536))
    audio_buffer (
    .addra(counter),
    .clka(clk_in),
    .wea(record_in&&audio_valid_in),
    .dina(audio_in),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(rst_in),
    .douta(),
    .addrb(lookup_addr),
    .dinb(),
    .clkb(clk_in),
    .web(1'b0),
    .enb(single_flag),
    .rstb(rst_in),
    .regceb(1'b1),
    .doutb(ram_output)
  );

endmodule
`default_nettype wire



