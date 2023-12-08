
module note_lookup(
            input wire clk_in,
            input wire rst_in,
            input wire toggle_in,
            input wire [5:0] note_in,
            output logic [159:0][5:0] notes_out
  );
    logic writing
    logic [25:0] eighth_counter;
    logic [7:0] eighth_dex;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            writing <= 0;
            eighth_dex <= 0;
            eighth_counter <= 0;
            notes_out <= 0;
        end else begin
            if (~writing) begin
                if (toggle_in) begin
                    writing <= 1;
                    eighth_dex <= 0;
                    eighth_counter <= 0;
                    notes_out <= 0;
                end
            end else begin
                if (~toggle_in) begin
                    writing <= 0;
                    eighth_dex <= 0;
                    eighth_counter <= 0;
                end else if (eighth_dex<160) begin
                    if (eighth_counter >= 34816000) begin
                        notes_out[eighth_dex] <= note_in;
                        eighth_dex <= eighth_dex + 1;
                        eighth_counter <= 0;
                    end else begin
                        eighth_counter <= eighth_counter + 1;
                    end
                end
            end
        end
    end
endmodule