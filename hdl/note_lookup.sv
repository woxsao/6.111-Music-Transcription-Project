`timescale 1ns / 1ps
`default_nettype none


module note_lookup(
            input wire clk_in,
            input wire rst_in,
            input wire [12:0] bin_index,
            input wire ready_in,
            output logic [5:0] note_index
  );
  
    logic [9:0] bin_floor [21:0];
    initial begin
        bin_floor[0] = 126;
        bin_floor[1] = 131;
        bin_floor[2] = 139;
        bin_floor[3] = 147;
        bin_floor[4] = 156;
        bin_floor[5] = 166;
        bin_floor[6] = 176;
        bin_floor[7] = 186;
        bin_floor[8] = 198;
        bin_floor[9] = 210;
        bin_floor[10] = 222;
        bin_floor[11] = 236;
        bin_floor[12] = 250;
        bin_floor[13] = 265;
        bin_floor[14] = 281;
        bin_floor[15] = 297;
        bin_floor[16] = 315;
        bin_floor[17] = 333;
        bin_floor[18] = 354;
        bin_floor[19] = 374;
        bin_floor[20] = 398;
        bin_floor[21] = 420;
        bin_floor[22] = 440;
    end

    logic [4:0] counter;
    logic [4:0] counter_minus;
    assign counter_minus = counter -1;
    logic finding;
    always_ff @(posedge clk_in) begin
        if(rst_in)begin
            note_index <= 0;
            counter <= 0;
            finding <= 0;
        end
        else begin
            if(bin_index<120) begin 
                note_index <= 0;
            end else begin
                if(ready_in && ~finding)begin
                    counter <= 1;
                    finding <= 1'b1;
                end
                else if(finding)begin
                    if (counter > 21) begin
                        finding <= 0;
                        note_index <= 0;
                        counter <= 1;
                    end else begin
                        if (bin_index <= bin_floor[counter]) begin
                            note_index <= {1'b1,counter_minus};
                            finding <= 0;
                        end
                        counter <= counter + 1;
                    end
                end
            end
        end
    end

endmodule


`default_nettype wire