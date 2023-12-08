`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module image_sprite #(
  parameter WIDTH=32, HEIGHT=100*11) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire [159:0][5:0] notes,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out
  );

  logic in_staff;
  assign in_staff = ((hcount_in >= 96) && (hcount_in <= 1152)) &&
                    ((vcount_in >= 100) && (vcount_in < 600));// boundaries of the staff drawing space

  logic [4:0] block;//32 sprite wide pieces of a staff line
  logic [2:0] system;//5 staff lines
  logic [$clog2(WIDTH*HEIGHT)-1:0] image_addr;
  logic [$clog2(WIDTH*HEIGHT)-1:0] sharp_addr;

  logic[5:0] dis;
  note_locator where (.note_in(notes[{system,block}]), .disp_out(dis));

  logic sharp;
  assign sharp = (notes[{system,block}]==6'b100001)||//C#4
                 (notes[{system,block}]==6'b100011)||//D#4
                 (notes[{system,block}]==6'b100110)||//F#4
                 (notes[{system,block}]==6'b101000)||//G#4
                 (notes[{system,block}]==6'b101010)||//A#4
                 (notes[{system,block}]==6'b101101)||//C#5
                 (notes[{system,block}]==6'b101111)||//D#5
                 (notes[{system,block}]==6'b110010)||//F#5
                 (notes[{system,block}]==6'b110100);//G#5

  logic nat;
  assign nat = (notes[{system,block}]==6'b100000)||//C4
               (notes[{system,block}]==6'b100010)||//D4
               (notes[{system,block}]==6'b100101)||//F4
               (notes[{system,block}]==6'b100111)||//G4
               (notes[{system,block}]==6'b101001)||//A4
               (notes[{system,block}]==6'b101100)||//C5
               (notes[{system,block}]==6'b101110)||//D5
               (notes[{system,block}]==6'b110001)||//F5
               (notes[{system,block}]==6'b110011);//G5

  logic show_sharp;
  logic show_natural;
  logic found;
  always_comb begin
    if (sharp || nat) begin
      found = 0;
      for (integer i=0;i<8;i=i+1) begin
        if (~found) begin
          if ({system,block}%8==i) begin
            show_sharp = sharp;
            show_natural = 0;
            found = 1;
          end else if (notes[{system,block}-(i+1)]==notes[{system,block}]) begin
            show_sharp = 0;
            show_natural = 0;
            found = 1;
          end else if (sharp && notes[{system,block}-(i+1)]==(notes[{system,block}]-1)) begin
            show_sharp = 1;
            show_natural = 0;
            found = 1;
          end else if (nat && notes[{system,block}-(i+1)]==(notes[{system,block}]+1)) begin
            show_natural = 1;
            show_sharp = 0;
            found = 1;
          end
        end
      end
    end else begin show_sharp = 0; show_natural = 0; end
  end

  always_comb begin //duration detector & memory adressing
    if (in_staff) begin
      if (hcount_in<128) begin//treble clef
        image_addr = 100*WIDTH*10+((vcount_in-100)%100)*32+(hcount_in-96);

      end else begin
        block = (hcount_in-128)>>5;
        system = (vcount_in-100)/100;

        
        if (notes[{system,block}][5]==0) begin//rests
          sharp_addr = 0;
          if({system,block}%8==0) begin//1
            if (~(notes[{system,block}+1][5])) begin//checks and of 1
              if (~(notes[{system,block}+2][5]||notes[{system,block}+3][5])) begin//checks beat 2
                if (~(notes[{system,block}+4][5]||notes[{system,block}+5][5]||notes[{system,block}+6][5]||notes[{system,block}+7][5])) begin//checks beats 3 and 4
                  image_addr = 100*WIDTH*4+(vcount_in%100)*32+(hcount_in%32);//whole rest
                end else begin image_addr = 100*WIDTH*5+(vcount_in%100)*32+(hcount_in%32); end//half rest
              end else begin image_addr = 100*WIDTH*6+(vcount_in%100)*32+(hcount_in%32); end//quarter rest
            end else begin image_addr = 100*WIDTH*7+(vcount_in%100)*32+(hcount_in%32); end//eighth rest
          end

          else if ({system,block}%4==2) begin//two and four
            if (~(notes[{system,block}+1][5])) begin//checks and
              if (~(notes[{system,block}-1][5]||notes[{system,block}-2][5])) begin image_addr = 0; end//checks past beat in case of half or whole note
              else begin
                image_addr = 100*WIDTH*6+(vcount_in%100)*32+(hcount_in%32);//quarter rest
              end
            end else begin
              image_addr = 100*WIDTH*7+(vcount_in%100)*32+(hcount_in%32);//eighth rest
            end
          end

          else if({system,block}%8==4) begin//3
            if (~(notes[{system,block}+1][5])) begin//checks and of 3
              if (~(notes[{system,block}+2][5]||notes[{system,block}+3][5])) begin//checks beat 4
                if (~(notes[{system,block}-4][5]||notes[{system,block}-3][5]||notes[{system,block}-2][5]||notes[{system,block}-1][5])) begin//checks beats 1 and 2
                  image_addr = 0;//part of whole rest
                end else begin image_addr = 100*WIDTH*5+(vcount_in%100)*32+(hcount_in%32); end//half rest
              end else begin image_addr = 100*WIDTH*6+(vcount_in%100)*32+(hcount_in%32); end//quarter rest
            end else begin image_addr = 100*WIDTH*7+(vcount_in%100)*32+(hcount_in%32); end//eighth rest
          end

          else if ({system,block}%2==1) begin//ands
            if (notes[{system,block}-1][5]==0) begin image_addr = 0; end
            else begin image_addr = 100*WIDTH*7+(vcount_in%100)*32+(hcount_in%32); end
          end
        end 
        
        
        else begin//notes
          if({system,block}%8==0) begin//1
            if (notes[{system,block}+1]==notes[{system,block}]) begin//checks and of 1
              if (notes[{system,block}+2]==notes[{system,block}] && notes[{system,block}+3]==notes[{system,block}]) begin//checks beat 2
                if (notes[{system,block}+4]==notes[{system,block}] && notes[{system,block}+5]==notes[{system,block}] && notes[{system,block}+6]==notes[{system,block}] && notes[{system,block}+7]==notes[{system,block}]) begin//checks beats 3 and 4
                  image_addr = (vcount_in%100)*32+(hcount_in%32)+dis*WIDTH;//whole note
                end else begin image_addr = 100*WIDTH*1+(vcount_in%100)*32+(hcount_in%32)+dis*WIDTH; end//half note
              end else begin image_addr = 100*WIDTH*2+(vcount_in%100)*32+(hcount_in%32)+dis*WIDTH; end//quarter note
            end else begin image_addr = 100*WIDTH*3+(vcount_in%100)*32+(hcount_in%32)+dis*WIDTH; end//eighth note
          end

          else if ({system,block}%4==2) begin//two and four
            if (notes[{system,block}+1]==notes[{system,block}]) begin//checks and
              if (notes[{system,block}-2]==notes[{system,block}] && notes[{system,block}-1]==notes[{system,block}]) begin image_addr = 0; end//checks past beat in case of half or whole note
              else begin
                image_addr = 100*WIDTH*2+(vcount_in%100)*32+(hcount_in%32)+dis*WIDTH;//quarter note
              end
            end else begin
              image_addr = 100*WIDTH*3+(vcount_in%100)*32+(hcount_in%32)+dis*WIDTH;//eighth note
            end
          end

          else if({system,block}%8==4) begin//3
            if (notes[{system,block}+1]==notes[{system,block}]) begin//checks and of 1
              if (notes[{system,block}+2]==notes[{system,block}] && notes[{system,block}+3]==notes[{system,block}]) begin//checks beat 2
                if (notes[{system,block}-4]==notes[{system,block}] && notes[{system,block}-3]==notes[{system,block}] && notes[{system,block}-2]==notes[{system,block}] && notes[{system,block}-1]==notes[{system,block}]) begin//checks beats 3 and 4
                  image_addr = 0;//part of whole note
                end else begin image_addr = 100*WIDTH*1+(vcount_in%100)*32+(hcount_in%32)+dis*WIDTH; end//half note
              end else begin image_addr = 100*WIDTH*2+(vcount_in%100)*32+(hcount_in%32)+dis*WIDTH; end//quarter note
            end else begin image_addr = 100*WIDTH*3+(vcount_in%100)*32+(hcount_in%32)+dis*WIDTH; end//eighth note
          end

          else if ({system,block}%2==1) begin//ands
            if (notes[{system,block}-1]==notes[{system,block}]) begin image_addr = 0; end
            else begin image_addr = 100*WIDTH*3+(vcount_in%100)*32+(hcount_in%32)+dis*WIDTH; end
          end

          if (show_sharp && (image_addr!=0) && (vcount_in%100)<77) begin//sharp and natural symbols
            sharp_addr = 100*WIDTH*9+((vcount_in%100)*32+(hcount_in%32)+dis*WIDTH);
          end else if (show_natural && (image_addr!=0)) begin
            sharp_addr = 100*WIDTH*8+((vcount_in%100)*32+(hcount_in%32)+dis*WIDTH);
          end else begin
            sharp_addr = 0;
          end
        end
      end
    end else begin
      image_addr = 0;
      sharp_addr = 0;
    end
  end
  
  logic staff_lines;
  assign staff_lines = in_staff && (
                          (vcount_in % 100 == 33) ||//line 5(F)
                          (vcount_in % 100 == 41) ||//line 4(D)
                          (vcount_in % 100 == 49) ||//line 3(B)
                          (vcount_in % 100 == 57) ||//line 2(G)
                          (vcount_in % 100 == 65) ||//line 1(E)
                          (vcount_in % 100>=33&&vcount_in % 100<=65&&(hcount_in+128) % 256==0&&hcount_in!=128)||//measure lines
                          (vcount_in % 100 == 25 && hcount_in>128 && hcount_in%32 >= 9 && hcount_in%32 <= 26 && notes[{system,block}] == 6'b110101 && image_addr!=0) ||//line above staff for A5
                          (vcount_in % 100 == 73 && hcount_in>128 && hcount_in%32 >= 9 && hcount_in%32 <= 26 && (notes[{system,block}] == 6'b100000 || notes[{system,block}] == 6'b100001) && image_addr!=0));//line below staff for C
  
  logic color;
  logic [7:0] full_color;
  logic sharp_color;
  logic [7:0] sharp_full_color;

  assign full_color = 8'hff*color;
  assign sharp_full_color = 8'hff*sharp_color;

  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(1),
    .RAM_DEPTH(WIDTH*HEIGHT),
    .INIT_FILE(`FPATH(image.mem)))
    echo_buffer (
    .addra(image_addr),
    .clka(pixel_clk_in),
    .wea(0),
    .dina(0),
    .ena(1),
    .regcea(1),
    .rsta(rst_in),
    .douta(color),
    .addrb(sharp_addr),
    .dinb(0),
    .clkb(pixel_clk_in),
    .web(0),
    .enb(1),
    .rstb(rst_in),
    .regceb(1),
    .doutb(sharp_color)
  );
  
  assign red_out =    staff_lines ? 0 : full_color&sharp_full_color;
  assign green_out =  staff_lines ? 0 : full_color&sharp_full_color;
  assign blue_out =   staff_lines ? 0 : full_color&sharp_full_color;

endmodule
`default_nettype none