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
  input wire clk_2,
  input wire rst_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire toggle_in,
  input wire [1:0] BPM,
  input wire [5:0] note_in,
  output logic metronome,
  output logic [7:0] color_out
  );

  logic writing;
  logic [25:0] eighth_counter;
  logic [7:0] eighth_dex;
  logic [7:0][5:0] curr_measure;
  logic [7:0][5:0] writ_measure;
  logic new_note;
  logic back_now_yall;
  logic [5:0] real_smooth;

  logic [25:0] za_warudo;//mudamudamuda
  always_comb begin
    case(BPM)
      2'b10 : za_warudo = 18562500;//120
      2'b01 : za_warudo = 27843750;//80
      default: za_warudo = 37125000;//60
    endcase
  end
  assign metronome = writing && (eighth_counter <= 200000);
  logic [4:0] block;//32 sprite wide pieces of a staff line
  logic [2:0] system;//5 staff lines
  always_ff @(posedge clk_2) begin
        if (rst_in) begin
            writing <= 0;
            eighth_dex <= 0;
            eighth_counter <= 0;
            back_now_yall <= 1;
            writ_measure <= 0;
            real_smooth <= 0;
        end else if (back_now_yall) begin
          if (real_smooth<19) begin
            new_note <= 1;
            eighth_dex <= eighth_dex + 8;
            real_smooth <= real_smooth +1;
          end else begin
            new_note <= 0;
            eighth_dex <= 0;
            back_now_yall <= 0;
          end
        end else begin
            if (~writing) begin
                if (toggle_in) begin
                    writing <= 1;
                    eighth_dex <= 0;
                    eighth_counter <= 0;
                    back_now_yall <= 1;
                    writ_measure <= 0;
                    new_note <= 0;
                    writ_measure <= 0;
                    real_smooth <= 0;
                end
            end else begin
                if (~toggle_in) begin
                    writing <= 0;
                    eighth_dex <= 0;
                    eighth_counter <= 0;
                    new_note <= 0;
                end else if (eighth_dex<160) begin
                    if (eighth_counter >= za_warudo) begin
                        writ_measure[eighth_dex[2:0]] <= note_in;
                        new_note <= 1;
                        eighth_counter <= 0;
                    end else if (new_note) begin
                      if (eighth_dex[2:0] == 3'b111) begin
                        writ_measure <= 0;
                      end
                      eighth_dex <= eighth_dex + 1;
                      eighth_counter <= eighth_counter + 1;
                      new_note <= 0;
                    end else begin
                        eighth_counter <= eighth_counter + 1;
                        new_note <= 0;
                    end
                end
                back_now_yall <= 0;
            end
        end
    end

  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(48),
    .RAM_DEPTH(20))
    note_mem (
    .addra(eighth_dex[7:3]),
    .clka(clk_2),
    .wea(new_note),
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
    .rstb(),
    .regceb(1),
    .doutb(curr_measure)
  );

  logic in_staff;
  assign in_staff = ((hcount_in >= 96) && (hcount_in <= 1152)) &&
                    ((vcount_in >= 100) && (vcount_in < 600));// boundaries of the staff drawing space

  logic [$clog2(WIDTH*HEIGHT)-1:0] image_addr;
  logic [$clog2(WIDTH*HEIGHT)-1:0] sharp_addr;

  logic[10:0] dis;
  note_locator where (.note_in(curr_measure[block[2:0]]), .disp_out(dis));

  logic sharp;
  logic nat;
  assign sharp = (curr_measure[block[2:0]]==6'b100001)||//C#4
                 (curr_measure[block[2:0]]==6'b100011)||//D#4
                 (curr_measure[block[2:0]]==6'b100110)||//F#4
                 (curr_measure[block[2:0]]==6'b101000)||//G#4
                 (curr_measure[block[2:0]]==6'b101010)||//A#4
                 (curr_measure[block[2:0]]==6'b101101)||//C#5
                 (curr_measure[block[2:0]]==6'b101111)||//D#5
                 (curr_measure[block[2:0]]==6'b110010)||//F#5
                 (curr_measure[block[2:0]]==6'b110100);//G#5
  assign nat = (curr_measure[block[2:0]]==6'b100000)||//C4
               (curr_measure[block[2:0]]==6'b100010)||//D4
               (curr_measure[block[2:0]]==6'b100101)||//F4
               (curr_measure[block[2:0]]==6'b100111)||//G4
               (curr_measure[block[2:0]]==6'b101001)||//A4
               (curr_measure[block[2:0]]==6'b101100)||//C5
               (curr_measure[block[2:0]]==6'b101110)||//D5
               (curr_measure[block[2:0]]==6'b110001)||//F5
               (curr_measure[block[2:0]]==6'b110011);//G5

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
          end else if (curr_measure[block[2:0]-(i+1)]==curr_measure[block[2:0]]) begin
            show_sharp = 0;
            show_natural = 0;
            found = 1;
          end else if (sharp && curr_measure[block[2:0]-(i+1)]==(curr_measure[block[2:0]]-1)) begin
            show_sharp = 1;
            show_natural = 0;
            found = 1;
          end else if (nat && curr_measure[block[2:0]-(i+1)]==(curr_measure[block[2:0]]+1)) begin
            show_natural = 1;
            show_sharp = 0;
            found = 1;
          end
        end
      end
    end else begin show_sharp = 0; show_natural = 0; end
  end

  logic [$clog2(WIDTH*HEIGHT)-1:0] frame;
  logic [$clog2(WIDTH*HEIGHT)-1:0] sframe;
  logic show_note, show_acc;
  logic clef;

  //assign block = (hcount_in-128)>>5;
  //assign system = (vcount_in-100)/25>>2;

  assign image_addr = (show_note)? {frame,5'b0000}+{(vcount_in%100),5'b0000}+(hcount_in[4:0])+dis : (clef)? 32000+{(vcount_in%100),5'b0000}+(hcount_in[4:0]) : 0;
  assign sharp_addr = (show_acc && show_note)? 25600+sframe+{(vcount_in%100),5'b0000}+(hcount_in[4:0])+dis : 0;

  always_comb begin //duration detector & memory adressing
    if (in_staff) begin
      if (hcount_in<128) begin//treble clef
        clef = 1;
        show_acc = 0;
        show_note = 0;
      end else begin
        clef = 0;
        block = (hcount_in-128)>>5;
        system = (vcount_in-100)/25>>2;
        if (curr_measure[block[2:0]][5]==0) begin//rests
          show_acc = 0;
          if(block%8==0) begin//1
            show_note = 1; 
            if (~(curr_measure[block[2:0]+1][5])) begin//checks and of 1
              if (~(curr_measure[block[2:0]+2][5]||curr_measure[block[2:0]+3][5])) begin//checks beat 2
                if (~(curr_measure[block[2:0]+4][5]||curr_measure[block[2:0]+5][5]||curr_measure[block[2:0]+6][5]||curr_measure[block[2:0]+7][5])) begin//checks beats 3 and 4
                  frame = 400;//whole rest
                end else begin frame = 500; end//half rest
              end else begin frame = 600; end//quarter rest
            end else begin frame = 700; end//eighth rest
          end

          else if (block%4==2) begin//two and four
            if (~(curr_measure[block[2:0]+1][5])) begin//checks and
              if (~(curr_measure[block[2:0]-1][5]||curr_measure[block[2:0]-2][5])) begin show_note = 0; end//checks past beat in case of half or whole note
              else begin
                frame = 600;//quarter rest
                show_note = 1; 
              end
            end else begin
              frame = 700;//eighth rest
              show_note = 1; 
            end
          end

          else if(block%8==4) begin//3
            if (~(curr_measure[block[2:0]+1][5])) begin//checks and of 3
              if (~(curr_measure[block[2:0]+2][5]||curr_measure[block[2:0]+3][5])) begin//checks beat 4
                if (~(curr_measure[block[2:0]-4][5]||curr_measure[block[2:0]-3][5]||curr_measure[block[2:0]-2][5]||curr_measure[block[2:0]-1][5])) begin//checks beats 1 and 2
                  show_note = 0;//part of whole rest
                end else begin frame = 500; show_note = 1; end//half rest
              end else begin frame = 600; show_note = 1; end//quarter rest
            end else begin frame = 700; show_note = 1; end//eighth rest
          end

          else if (block%2==1) begin//ands
            if (curr_measure[block[2:0]-1][5]==0) begin show_note = 0; end
            else begin frame = 700; show_note = 1; end
          end
        end 
        
        
        else begin//notes
          if({system,block}%8==0) begin//1
            show_note = 1;
            if (curr_measure[block[2:0]+1]==curr_measure[block[2:0]]) begin//checks and of 1
              if (curr_measure[block[2:0]+2]==curr_measure[block[2:0]] && curr_measure[block[2:0]+3]==curr_measure[block[2:0]]) begin//checks beat 2
                if (curr_measure[block[2:0]+4]==curr_measure[block[2:0]] && curr_measure[block[2:0]+5]==curr_measure[block[2:0]] && curr_measure[block[2:0]+6]==curr_measure[block[2:0]] && curr_measure[block[2:0]+7]==curr_measure[block[2:0]]) begin//checks beats 3 and 4
                  frame = 0;//whole note
                end else begin frame = 100; end//half note
              end else begin frame = 200; end//quarter note
            end else begin frame = 300; end//eighth note
          end

          else if ({system,block}%4==2) begin//two and four
            if (curr_measure[block[2:0]+1]==curr_measure[block[2:0]]) begin//checks and
              if (curr_measure[block[2:0]-2]==curr_measure[block[2:0]] && curr_measure[block[2:0]-1]==curr_measure[block[2:0]]) begin show_note = 0; end//checks past beat in case of half or whole note
              else begin
                frame = 200;//quarter note
                show_note = 1; 
              end
            end else begin
              frame = 300;//eighth note
              show_note = 1; 
            end
          end

          else if({system,block}%8==4) begin//3
            if (curr_measure[block[2:0]+1]==curr_measure[block[2:0]]) begin//checks and of 1
              if (curr_measure[block[2:0]+2]==curr_measure[block[2:0]] && curr_measure[block[2:0]+3]==curr_measure[block[2:0]]) begin//checks beat 2
                if (curr_measure[block[2:0]-4]==curr_measure[block[2:0]] && curr_measure[block[2:0]-3]==curr_measure[block[2:0]] && curr_measure[block[2:0]-2]==curr_measure[block[2:0]] && curr_measure[block[2:0]-1]==curr_measure[block[2:0]]) begin//checks beats 3 and 4
                  show_note = 0;//part of whole note
                end else begin frame = 100; show_note = 1; end//half note
              end else begin frame = 200; show_note = 1; end//quarter note
            end else begin frame = 300; show_note = 1; end//eighth note
          end

          else if ({system,block}%2==1) begin//ands
            if (curr_measure[block[2:0]-1]==curr_measure[block[2:0]]) begin show_note = 0; end
            else begin frame = 300; show_note = 1; end
          end

          if (show_sharp && (vcount_in%100)<77) begin//sharp and natural symbols
            sframe = 3200;
            show_acc = 1;
          end else if (show_natural) begin
            sframe = 0;
            show_acc = 1;
          end else begin
            show_acc = 0;
          end
        end
      end
    end else begin
      show_note = 0;
      show_acc = 0;
      clef = 0;
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
                          (vcount_in % 100 == 25 && hcount_in>128 && hcount_in%32 >= 9 && hcount_in%32 <= 26 && curr_measure[block[2:0]] == 6'b110101 && image_addr!=0) ||//line above staff for A5
                          (vcount_in % 100 == 73 && hcount_in>128 && hcount_in%32 >= 9 && hcount_in%32 <= 26 && (curr_measure[block[2:0]] == 6'b100000 || curr_measure[block[2:0]] == 6'b100001) && image_addr!=0));//line below staff for C
  
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