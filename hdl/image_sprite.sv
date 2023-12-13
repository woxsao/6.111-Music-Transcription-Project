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
  input wire [5:0] note_in,
  input wire [7:0] note_type,
  input wire new_note_in,
  output logic [7:0] color_out
  );

  logic writing;
  logic [7:0] eighth_dex;
  logic [7:0] leighth_dex;
  logic [7:0][8:0] curr_measure;
  logic [7:0][8:0] writ_measure;
  logic back_now_yall;
  logic send;
  logic [4:0] block;//32 sprite wide pieces of a staff line
  logic [2:0] system;//5 staff lines
  always_ff @(posedge pixel_clk_in) begin
    if (rst_in) begin
            eighth_dex <= 0;
            back_now_yall <= 1;
            writ_measure <= 0;
            send <= 0;
    end else begin
      if (new_note_in) begin
        if (note_type != 0) begin
          send <= 1;
          if (note_type[0]) begin 
            writ_measure[eighth_dex[2:0]] <= {1,3'b000,note_in};
            eighth_dex <= eighth_dex+1;
          end else if (note_type[1]) begin 
            writ_measure[eighth_dex[2:0]] <= {1,3'b001,note_in};
            eighth_dex <= eighth_dex+2;
          end else if (note_type[2]) begin 
            writ_measure[eighth_dex[2:0]] <= {1,3'b010,note_in};
            eighth_dex <= eighth_dex+4;
          end else if (note_type[3]) begin 
            writ_measure[eighth_dex[2:0]] <= {1,3'b011,note_in};
            eighth_dex <= eighth_dex+8;
          end else if (note_type[4]) begin 
            writ_measure[eighth_dex[2:0]] <= {1,3'b100,note_in};
            eighth_dex <= eighth_dex+1;
          end else if (note_type[5]) begin 
            writ_measure[eighth_dex[2:0]] <= {1,3'b101,note_in};
            eighth_dex <= eighth_dex+2;
          end else if (note_type[6]) begin 
            writ_measure[eighth_dex[2:0]] <= {1,3'b110,note_in};
            eighth_dex <= eighth_dex+4;
          end else if (note_type[7]) begin 
            writ_measure[eighth_dex[2:0]] <= {1,3'b111,note_in};
            eighth_dex <= eighth_dex+8;
          end
        end
      end else if (send) begin
        send <= 0;
        if (leighth_dex[7:3]!=eighth_dex[7:3]) begin
          writ_measure <= 0;
        end
      end
    end
  end


  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(80),
    .RAM_DEPTH(20))
    note_mem (
    .addra(eighth_dex[7:3]),
    .clka(pixel_clk_in),
    .wea(send),
    .dina(writ_measure),
    .ena(1),
    .regcea(1),
    .rsta(back_now_yall),
    .douta(),
    
    .addrb({system,block[4:3]}),
    .dinb(0),
    .clkb(pixel_clk_in),
    .web(0),
    .enb(1),
    .rstb(back_now_yall),
    .regceb(1),
    .doutb(curr_measure)
  );

  logic in_staff;
  assign in_staff = ((hcount_in >= 96) && (hcount_in <= 1152)) &&
                    ((vcount_in >= 100) && (vcount_in < 600));// boundaries of the staff drawing space

  logic [$clog2(WIDTH*HEIGHT)-1:0] image_addr;
  logic [$clog2(WIDTH*HEIGHT)-1:0] sharp_addr;

  logic[10:0] dis;
  note_locator where (.note_in(curr_measure[block[2:0]][5:0]), .disp_out(dis));

  logic sharp;
  logic nat;
  assign sharp = (curr_measure[block[2:0]][5:0]==6'b100001)||//C#4
                 (curr_measure[block[2:0]][5:0]==6'b100011)||//D#4
                 (curr_measure[block[2:0]][5:0]==6'b100110)||//F#4
                 (curr_measure[block[2:0]][5:0]==6'b101000)||//G#4
                 (curr_measure[block[2:0]][5:0]==6'b101010)||//A#4
                 (curr_measure[block[2:0]][5:0]==6'b101101)||//C#5
                 (curr_measure[block[2:0]][5:0]==6'b101111)||//D#5
                 (curr_measure[block[2:0]][5:0]==6'b110010)||//F#5
                 (curr_measure[block[2:0]][5:0]==6'b110100);//G#5
  assign nat = (curr_measure[block[2:0]][5:0]==6'b100000)||//C4
               (curr_measure[block[2:0]][5:0]==6'b100010)||//D4
               (curr_measure[block[2:0]][5:0]==6'b100101)||//F4
               (curr_measure[block[2:0]][5:0]==6'b100111)||//G4
               (curr_measure[block[2:0]][5:0]==6'b101001)||//A4
               (curr_measure[block[2:0]][5:0]==6'b101100)||//C5
               (curr_measure[block[2:0]][5:0]==6'b101110)||//D5
               (curr_measure[block[2:0]][5:0]==6'b110001)||//F5
               (curr_measure[block[2:0]][5:0]==6'b110011);//G5

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
          end else if (curr_measure[block[2:0]-(i+1)][5:0]==curr_measure[block[2:0]][5:0]) begin
            show_sharp = 0;
            show_natural = 0;
            found = 1;
          end else if (sharp && curr_measure[block[2:0]-(i+1)][5:0]==(curr_measure[block[2:0]][5:0]-1)) begin
            show_sharp = 1;
            show_natural = 0;
            found = 1;
          end else if (nat && curr_measure[block[2:0]-(i+1)][5:0]==(curr_measure[block[2:0]][5:0]+1)) begin
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
        image_addr = 32000+{(vcount_in%100),5'b0000}+(hcount_in[4:0]);
        sharp_addr = 0;
      end else if (curr_measure[block[2:0]][9]) begin
        image_addr = curr_measure[block[2:0]][8:6]*3200+{(vcount_in%100),5'b0000}+(hcount_in[4:0]);
        if (show_sharp && (vcount_in%100)<77) begin//sharp and natural symbols
            sharp_addr = 9*3200+{(vcount_in%100),5'b0000}+(hcount_in[4:0]);
          end else if (show_natural) begin
            sharp_addr = 8*3200+{(vcount_in%100),5'b0000}+(hcount_in[4:0]);
          end else begin
            sharp_addr = 0;
          end
      end else begin
        image_addr = 0;
        sharp_addr = 0;
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
                          (vcount_in % 100 == 25 && hcount_in>128 && hcount_in%32 >= 9 && hcount_in%32 <= 26 && curr_measure[block[2:0]][5:0] == 6'b110101 && image_addr!=0) ||//line above staff for A5
                          (vcount_in % 100 == 73 && hcount_in>128 && hcount_in%32 >= 9 && hcount_in%32 <= 26 && (curr_measure[block[2:0]][5:0] == 6'b100000 || curr_measure[block[2:0]][5:0] == 6'b100001) && image_addr!=0));//line below staff for C
  
  logic color;
  logic sharp_color;

  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(1),
    .RAM_DEPTH(WIDTH*HEIGHT),
    .INIT_FILE(`FPATH(image.mem)))
    sprite_mem (
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
  
  assign color_out = staff_lines ? 0 : 8'hff*(color & sharp_color);

endmodule
`default_nettype none