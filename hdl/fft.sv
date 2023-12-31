`timescale 1ns / 1ps
`default_nettype none

module fft (
    input wire clk_in,
    input wire rst_in,
    input wire signed [7:0] in_sample,
    input wire audio_sample_valid,
    output logic fft_ready,
    output logic fft_out_ready,
    output logic fft_out_valid,
    output logic fft_out_last,
    output logic [47:0] fft_out_data
    );
    logic [23:0] fft_out_data_upper;
    logic [23:0] fft_out_data_lower;
  
    logic [15:0] fft_data; //ff_data (made way too large for purpose
    logic       fft_valid; //data valid from fft
    logic       fft_last; //last of the "frame" from fft
    logic [11:0] fft_data_counter;

    assign fft_out_data_upper = fft_out_data[47:24];
    assign fft_out_data_lower = fft_out_data[23:0];

    always_ff @(posedge clk_in)begin
        if (rst_in) begin
            fft_valid <= 0;
            fft_data <=0;
            fft_data_counter <= 0;
            fft_last <= 0;
            //fft_out_data <= 0;
        end else begin
            if (audio_sample_valid) begin
                fft_valid <= 1;
                fft_data <= {8'b0,in_sample};
                fft_data_counter <= fft_data_counter +1; //rollover-auto
                fft_last <= fft_data_counter==4095;
                fft_out_ready <= 1;
            end else begin
                fft_valid <= 0;
	end
        end
    end

    xfft_70_unscaled my_fft ( .aclk(clk_in),
                    .s_axis_data_tdata(fft_data), //in
                    .s_axis_data_tvalid(fft_valid), //in
                    .s_axis_data_tlast(fft_last), //in
                    .s_axis_data_tready(fft_ready), //out
                    .s_axis_config_tdata(0), //in
                    .s_axis_config_tvalid(0), //in
                    .s_axis_config_tready(), //out
                    .m_axis_data_tdata(fft_out_data), //out
                    .m_axis_data_tvalid(fft_out_valid), //out
                    .m_axis_data_tlast(fft_out_last), //out 
                    .m_axis_data_tready(fft_out_ready)); //in

endmodule
`default_nettype wire
