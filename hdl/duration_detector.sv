`timescale 1ns / 1ps
`default_nettype none
module duration_detector #(
    parameter BPM = 60
)(
    input wire clk_in,
    input wire rst_in,
    input wire [5:0] note_index,
    input wire note_index_ready,

    output logic new_note_ready,
    output logic [5:0] new_note_tone,
    
    output logic eighth_note,
    output logic quarter_note,
    output logic half_note,
    output logic whole_note,
    output logic eighth_rest,
    output logic quarter_rest,
    output logic half_rest,
    output logic whole_rest
);
    logic [5:0] last_tone;
    logic [$clog2((17000*60*5)/BPM)-1:0] counter;
    parameter SIG_PER_QUARTER = 17000*60/BPM;
    parameter SIG_PER_EIGHTH = SIG_PER_QUARTER >> 1'b1;
    parameter SIG_PER_HALF = SIG_PER_QUARTER << 1'b1;
    parameter SIG_PER_WHOLE = SIG_PER_HALF << 1'b1;
    logic [3:0] note_type;
    always_ff @(posedge clk_in)begin
        if(rst_in)begin
            last_tone <= note_index;
            counter <= 0;
            new_note_ready <= 0;
            new_note_tone <= 0;
            eighth_note <= 0;
            quarter_note <= 0;
            half_note <= 0;
            whole_note <= 0;
            eighth_rest <= 0;
            quarter_rest <= 0;
            half_rest<= 0; 
            whole_rest<= 0;
        end
        else if(note_index_ready) begin
            last_tone <= note_index;
            if(note_index != last_tone)begin
                counter <= 0;
                new_note_tone <= last_tone;
                if(counter >= SIG_PER_WHOLE)begin //whole note or rest
                    new_note_ready <= 1;
                    if(last_tone == 0)begin //rest
                        whole_rest <= 1;
                    end
                    else begin
                        whole_note <= 1;
                    end
                end
                else if(counter >= SIG_PER_HALF)begin //half note or rest
                    new_note_ready <= 1;
                    if(last_tone == 0)begin //rest
                        half_rest <= 1;
                    end
                    else begin
                        half_note <= 1;
                    end
                end
                else if (counter >= SIG_PER_QUARTER) begin //quarter note or rest
                    new_note_ready <= 1;
                    if(last_tone == 0)begin //rest
                        quarter_rest <= 1;
                    end
                    else begin
                        quarter_note <= 1;
                    end
                end
                else if (counter >= SIG_PER_EIGHTH) begin //eighth note or rest
                    new_note_ready <= 1;
                    if(last_tone == 0)begin //rest
                        eighth_rest <= 1;
                    end
                    else begin
                        eighth_note <= 1;
                    end
                end

            end
            else begin
                counter <= counter + 1;
                new_note_ready <= 0;
                new_note_ready <= 0;
                eighth_note <= 0;
                quarter_note <= 0;
                half_note <= 0;
                whole_note <= 0;
                eighth_rest <= 0;
                quarter_rest <= 0;
                half_rest<= 0; 
                whole_rest<= 0;
            end
        end
    end

endmodule

`default_nettype wire
