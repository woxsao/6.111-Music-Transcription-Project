`timescale 1ns / 1ps
`default_nettype none

module note_locator (input wire [5:0] note_in, output logic[5:0] disp_out);
  always_comb begin
    case(note_in)
      6'b100010 : disp_out = 6'd4;//D4
      6'b100011 : disp_out = 6'd4;//D#4
      6'b100100 : disp_out = 6'd8;//E4
      6'b100101 : disp_out = 6'd12;//F4
      6'b100110 : disp_out = 6'd12;//F#4
      6'b100111 : disp_out = 6'd16;//G4
      6'b101000 : disp_out = 6'd16;//G#4
      6'b101001 : disp_out = 6'd20;//A4
      6'b101010 : disp_out = 6'd20;//A#4
      6'b101011 : disp_out = 6'd24;//B4
      6'b101100 : disp_out = 6'd28;//C5
      6'b101101 : disp_out = 6'd28;//C#5
      6'b101110 : disp_out = 6'd32;//D5
      6'b101111 : disp_out = 6'd32;//D#5
      6'b110000 : disp_out = 6'd36;//E5
      6'b110001 : disp_out = 6'd40;//F5
      6'b110010 : disp_out = 6'd40;//F#5
      6'b110011 : disp_out = 6'd44;//G5
      6'b110100 : disp_out = 6'd44;//G#5
      6'b110101 : disp_out = 6'd48;//A5
      default: disp_out = 6'b0;//rests and C & C#4
    endcase
  end
endmodule

`default_nettype wire