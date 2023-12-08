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
        bin_floor[1] = 133;
        bin_floor[2] = 141;
        bin_floor[3] = 149;
        bin_floor[4] = 158;
        bin_floor[5] = 168;
        bin_floor[6] = 178;
        bin_floor[7] = 188;
        bin_floor[8] = 200;
        bin_floor[9] = 212;
        bin_floor[10] = 224;
        bin_floor[11] = 238;
        bin_floor[12] = 252;
        bin_floor[13] = 267;
        bin_floor[14] = 283;
        bin_floor[15] = 299;
        bin_floor[16] = 317;
        bin_floor[17] = 336;
        bin_floor[18] = 356;
        bin_floor[19] = 377;
        bin_floor[20] = 400;
        bin_floor[21] = 424;
        bin_floor[22] = 449;
    end

    logic [4:0] counter;
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
                    counter <= 0;
                    finding <= 1'b1;
                end
                else if(finding)begin
                    if (counter > 21) begin
                        finding <= 0;
                        note_index <= 0;
                        counter <= 0;
                    end else begin
                        if (bin_floor[counter+1] >= bin_index && bin_index >= bin_floor[counter]) begin
                        note_index <= {1'b1,counter};
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
