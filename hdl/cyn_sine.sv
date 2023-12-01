`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

//Sine Wave Generator
module sine_generator_750 (
  input wire clk_in,
  input wire rst_in, //clock and reset
  input wire step_in, //trigger a phase step (rate at which you run sine generator)
  output logic signed [7:0] amp,
  output logic signed [7:0] amp_out); //output phase in 2's complement

  parameter PHASE_INCR = 32'b1000_0000_0000_0000_0000_0000_0000_0000>>3; //1/16th of 12 khz is 750 Hz
  logic [31:0] phase;
  logic [7:0] amp;
  logic [7:0] amp_pre;
  assign amp_pre = ({~amp[7],amp[6:0]}); //2's comp output (if not scaling)
  assign amp_out = amp_pre>>>4; //decrease volume so it isn't too loud!
  sine_lut lut_1(.clk_in(clk_in), .phase_in(phase[31:26]), .amp_out(amp));

  always_ff @(posedge clk_in)begin
    if (rst_in)begin
      phase <= 32'b0;
    end else if (step_in)begin
      phase <= phase+PHASE_INCR;
    end
  end
endmodule