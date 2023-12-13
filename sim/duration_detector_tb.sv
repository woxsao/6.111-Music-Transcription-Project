`timescale 1ns / 1ps
`default_nettype none

module duration_detector_tb();

    logic clk_in;
    logic rst_in;
    logic [5:0] note_index;
    logic note_index_ready;

    logic new_note_ready;
    logic [5:0] new_note_tone;
    logic eighth_note;
    logic quarter_note;
    logic half_note;
    logic whole_note;
    logic eighth_rest;
    logic quarter_rest;
    logic half_rest;
    logic whole_rest;
    duration_detector #(120) durationdect (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .note_index(note_index),
        .note_index_ready(note_index_ready),
        .new_note_ready(new_note_ready),
        .new_note_tone(new_note_tone),

        .eighth_note(eighth_note),
        .quarter_note(quarter_note),
        .half_note(half_note),
        .whole_note(whole_note),

        .eighth_rest(eighth_rest),
        .quarter_rest(quarter_rest),
        .half_rest(half_rest),
        .whole_rest(whole_rest)
    );

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("duration_detector_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,durationdect);
    $display("Starting Sim"); //print nice message at start
    clk_in = 0;
    rst_in = 0;
    //out_sample = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    note_index = 10;
    note_index_ready = 1;
    #119600;
    note_index = 20;
    note_index_ready = 1;
    #119600;
    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire
