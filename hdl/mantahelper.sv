`timescale 1ns / 1ps
`default_nettype none
module mantahelper (
    input wire rst_in,
    input wire mantaready,
    input wire clk_in,
    input wire [159:0][5:0] notes,
    input wire [9:0] vcount,
    input wire [10:0] hcount,
    output logic [15:0] color
);
    logic [6:0] counter;
    logic old_mantaready;
    logic [7:0] color_sprite;
    
    image_sprite #(
        .WIDTH(32),
        .HEIGHT(1100))
        com_sprite_m (
        .pixel_clk_in(clk_in),
        .rst_in(rst_in),
        .hcount_in(hcount),
        .vcount_in(vcount),
        .notes(notes),
        .color_out(color_sprite));
    always_ff @(posedge clk_in)begin
        if(rst_in) begin
            color <= 0;
            old_mantaready <= 0;
        end
        else begin
            if(mantaready && !old_mantaready)begin
                counter <= 0;
                color <= 0;
            end
            if(counter < 16)begin
                color[counter] <= color_sprite == 255?1:0;
                counter <= counter + 1;
            end
            old_mantaready <= mantaready;

        end
    end
endmodule
`default_nettype wire