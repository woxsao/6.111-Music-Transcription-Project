`timescale 1ns / 1ps
`default_nettype none

module note_lookup_tb();

  logic clk_in;
  logic rst_in;
  logic [5:0] note_index;
  note_lookup note_lookup(
                            .clk_in(clk_in),
                            .rst_in(rst_in),
                            .bin_index(107),
                            .ready_in(1),
                            .note_index(note_index)
                        );

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("note_lookup_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,note_lookup);
    $display("Starting Sim"); //print nice message at start
    clk_in = 0;
    rst_in = 0;
    //out_sample = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    #10000;
    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire
