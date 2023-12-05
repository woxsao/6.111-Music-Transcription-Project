`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module image_sprite #(
  parameter WIDTH=32, HEIGHT=100*13) (
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
  assign sharp = (notes[{system,block}]==6'b100001)||//C#
                 (notes[{system,block}]==6'b100011)||//D#
                 (notes[{system,block}]==6'b100110)||//F#
                 (notes[{system,block}]==6'b101000)||//G#
                 (notes[{system,block}]==6'b101010)||//A#
                 (notes[{system,block}]==6'b101101)||//C#
                 (notes[{system,block}]==6'b101111)||//D#
                 (notes[{system,block}]==6'b110010)||//F#
                 (notes[{system,block}]==6'b110100);//G#

  always_comb begin //duration detector & memory adressing
    if (in_staff) begin
      if (hcount_in<128) begin//treble clef
        image_addr = 100*WIDTH*12+((vcount_in-100)%100)*32+(hcount_in-96);

      end else begin
        block = (hcount_in-128)>>5;
        system = (vcount_in-100)/100;

        
        if (notes[{system,block}][5]==0) begin//rests
          sharp_addr = 0;
          if({system,block}%8==0) begin//1
            if (~(notes[{system,block}+1][5])) begin//checks and of 1
              if (~(notes[{system,block}+2][5]||notes[{system,block}+3][5])) begin//checks beat 2
                if (~(notes[{system,block}+4][5]||notes[{system,block}+5][5]||notes[{system,block}+6][5]||notes[{system,block}+7][5])) begin//checks beats 3 and 4
                  image_addr = 100*WIDTH*5+(vcount_in%100)*32+(hcount_in%32);//whole rest
                end else begin image_addr = 100*WIDTH*6+(vcount_in%100)*32+(hcount_in%32); end//half rest
              end else begin image_addr = 100*WIDTH*8+(vcount_in%100)*32+(hcount_in%32); end//quarter rest
            end else begin image_addr = 100*WIDTH*9+(vcount_in%100)*32+(hcount_in%32); end//eighth rest
          end

          else if ({system,block}%4==2) begin//two and four
            if (~(notes[{system,block}+1][5])) begin//checks and
              if (~(notes[{system,block}-1][5]||notes[{system,block}-2][5])) begin image_addr = 0; end//checks past beat in case of half or whole note
              else begin
                image_addr = 100*WIDTH*8+(vcount_in%100)*32+(hcount_in%32);//quarter rest
              end
            end else begin
              image_addr = 100*WIDTH*9+(vcount_in%100)*32+(hcount_in%32);//eighth rest
            end
          end

          else if({system,block}%8==4) begin//3
            if (~(notes[{system,block}+1][5])) begin//checks and of 3
              if (~(notes[{system,block}+2][5]||notes[{system,block}+3][5])) begin//checks beat 4
                if (~(notes[{system,block}-4][5]||notes[{system,block}-3][5]||notes[{system,block}-2][5]||notes[{system,block}-1][5])) begin//checks beats 1 and 2
                  image_addr = 0;//part of whole rest
                end else begin image_addr = 100*WIDTH*6+(vcount_in%100)*32+(hcount_in%32); end//half rest
              end else begin image_addr = 100*WIDTH*8+(vcount_in%100)*32+(hcount_in%32); end//quarter rest
            end else begin image_addr = 100*WIDTH*9+(vcount_in%100)*32+(hcount_in%32); end//eighth rest
          end

          else if ({system,block}%2==1) begin//ands
            if (notes[{system,block}-1][5]==0) begin image_addr = 0; end
            else begin image_addr = 100*WIDTH*9+(vcount_in%100)*32+(hcount_in%32); end
          end else begin
            image_addr = 100*WIDTH*9+(vcount_in%100)*32+(hcount_in%32);
          end
        end 
        
        
        else begin//notes
          if({system,block}%8==0) begin//1
            if (notes[{system,block}+1]==notes[{system,block}]) begin//checks and of 1
              if (notes[{system,block}+2]==notes[{system,block}] && notes[{system,block}+3]==notes[{system,block}]) begin//checks beat 2
                if (notes[{system,block}+4]==notes[{system,block}] && notes[{system,block}+5]==notes[{system,block}] && notes[{system,block}+6]==notes[{system,block}] && notes[{system,block}+7]==notes[{system,block}]) begin//checks beats 3 and 4
                  image_addr = (vcount_in%100)*32+(hcount_in%32)+dis*WIDTH;//whole note
                end else begin image_addr = 100*WIDTH*1+(vcount_in%100)*32+(hcount_in%32)+dis*WIDTH; end//half note
              end else begin image_addr = 100*WIDTH*3+(vcount_in%100)*32+(hcount_in%32)+dis*WIDTH; end//quarter note
            end else begin image_addr = 100*WIDTH*4+(vcount_in%100)*32+(hcount_in%32)+dis*WIDTH; end//eighth note
          end

          else if ({system,block}%4==2) begin//two and four
            if (notes[{system,block}+1]==notes[{system,block}]) begin//checks and
              if (notes[{system,block}-2]==notes[{system,block}] && notes[{system,block}-1]==notes[{system,block}]) begin image_addr = 0; end//checks past beat in case of half or whole note
              else begin
                image_addr = 100*WIDTH*3+(vcount_in%100)*32+(hcount_in%32)+dis*WIDTH;//quarter note
              end
            end else begin
              image_addr = 100*WIDTH*4+(vcount_in%100)*32+(hcount_in%32)+dis*WIDTH;//eighth note
            end
          end

          else if({system,block}%8==4) begin//3
            if (notes[{system,block}+1]==notes[{system,block}]) begin//checks and of 1
              if (notes[{system,block}+2]==notes[{system,block}] && notes[{system,block}+3]==notes[{system,block}]) begin//checks beat 2
                if (notes[{system,block}-4]==notes[{system,block}] && notes[{system,block}-3]==notes[{system,block}] && notes[{system,block}-2]==notes[{system,block}] && notes[{system,block}-1]==notes[{system,block}]) begin//checks beats 3 and 4
                  image_addr = 0;//part of whole note
                end else begin image_addr = 100*WIDTH*1+(vcount_in%100)*32+(hcount_in%32)+dis*WIDTH; end//half note
              end else begin image_addr = 100*WIDTH*3+(vcount_in%100)*32+(hcount_in%32)+dis*WIDTH; end//quarter note
            end else begin image_addr = 100*WIDTH*4+(vcount_in%100)*32+(hcount_in%32)+dis*WIDTH; end//eighth note
          end

          else if ({system,block}%2==1) begin//ands
            if (notes[{system,block}-1]==notes[{system,block}]) begin image_addr = 0; end
            else begin image_addr = 100*WIDTH*4+(vcount_in%100)*32+(hcount_in%32)+dis*WIDTH; end
          end else begin
            image_addr = 100*WIDTH*4+(vcount_in%100)*32+(hcount_in%32)+dis*WIDTH;
          end
          if (sharp && (image_addr!=0) && (vcount_in%100)<77) begin
            sharp_addr = 100*WIDTH*11+((vcount_in%100)*32+(hcount_in%32)+dis*WIDTH);
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
                          (vcount_in % 100 == 25 && hcount_in>128 && hcount_in%32 >= 11 && hcount_in%32 <= 28 && notes[{system,block}] == 6'b110101 && image_addr!=0) ||//line above staff for A5
                          (vcount_in % 100 == 73 && hcount_in>128 && hcount_in%32 >= 11 && hcount_in%32 <= 28 && (notes[{system,block}] == 6'b100000 || notes[{system,block}] == 6'b100001) && image_addr!=0));//line below staff for C


/*
logic [10:0] hcount_pipe [4-1:0];
always_ff @(posedge pixel_clk_in)begin
  hcount_pipe[0] <= hcount_in;
  for (int i=1; i<4; i = i+1)begin
    hcount_pipe[i] <= hcount_pipe[i-1];
  end
end

logic [9:0] vcount_pipe [4-1:0];
always_ff @(posedge pixel_clk_in)begin
  vcount_pipe[0] <= vcount_in;
  for (int i=1; i<4; i = i+1)begin
    vcount_pipe[i] <= vcount_pipe[i-1];
  end
end
*/

  
  logic [7:0] color;
  logic [23:0] full_color;
  logic [7:0] sharp_color;
  logic [23:0] sharp_full_color;
  
  // Modify the module below to use your BRAMs!
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(8),                       // Specify RAM data width
    .RAM_DEPTH(WIDTH*HEIGHT),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(image.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) image (
    .addra(image_addr),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(color)      // RAM output data, width determined from RAM_WIDTH
  );
  
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(24),                       // Specify RAM data width
    .RAM_DEPTH(2),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(palette.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) palette (
    .addra(color[0]),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(full_color)      // RAM output data, width determined from RAM_WIDTH
  );

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(8),                       // Specify RAM data width
    .RAM_DEPTH(WIDTH*HEIGHT),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(image.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) image2 (
    .addra(sharp_addr),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(sharp_color)      // RAM output data, width determined from RAM_WIDTH
  );
  
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(24),                       // Specify RAM data width
    .RAM_DEPTH(2),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(palette.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) palette2 (
    .addra(sharp_color[0]),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(sharp_full_color)      // RAM output data, width determined from RAM_WIDTH
  );
  
  assign red_out =    staff_lines ? 0 : full_color[23:16]&sharp_full_color[23:16];
  assign green_out =  staff_lines ? 0 : full_color[15:8]&sharp_full_color[15:8];
  assign blue_out =   staff_lines ? 0 : full_color[7:0]&sharp_full_color[7:0];
endmodule
`default_nettype none