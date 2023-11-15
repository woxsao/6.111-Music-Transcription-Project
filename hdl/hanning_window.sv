`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module hanning_window #(
    parameter DATA_WIDTH = 8,
    parameter SAMPLE_COUNT = 4096
)(
    input wire clk_in,
    input wire rst_in,
    input wire [DATA_WIDTH-1:0] in_sample,
    output logic signed [7:0] out_sample,
    output logic signed audio_sample_valid
);
    logic [11:0] coeff_addr;
    logic signed [31:0] post_mult_shift;

    logic signed [7:0] in_sample_pipe;

    logic signed [23:0] stored_coeff;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            out_sample <= 0;
            coeff_addr <= 0;
        end else begin
            coeff_addr <= coeff_addr+1;
            in_sample_pipe <= in_sample;
            post_mult_shift <= (stored_coeff * in_sample_pipe) >> 24;
            out_sample <= post_mult_shift;
        end
        //out_sample <= $cos(2*PI*in_sample);
    end

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(24),                       // Specify RAM data width
        .RAM_DEPTH(4096),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE(`FPATH(coefficients.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) image_BROM (
        .addra(coeff_addr),     // Address bus, width determined from RAM_DEPTH
        .dina(0),       // RAM input data, width determined from RAM_WIDTH
        .clka(clk_in),       // Clock
        .wea(0),         // Write enable
        .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
        .rsta(rst_in),       // Output reset (does not affect memory contents)
        .regcea(1),   // Output register enable
        .douta(stored_coeff)      // RAM output data, width determined from RAM_WIDTH
    );

endmodule

`default_nettype wire