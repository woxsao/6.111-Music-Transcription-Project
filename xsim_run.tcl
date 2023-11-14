# Read in all IP
#read_ip ./ip/clk_wiz_7425/clk_wiz_7425.xci
read_ip ./ip/clk_wiz_69632/clk_wiz_69632.xci
#read_ip ./ip/clk_wiz_139264/clk_wiz_139264.xci
#read_ip ./ip/fir_compiler_10taps_69632clk/fir_compiler_10taps_69632clk.xci
#read_ip ./ip/fir_compiler_10taps_139264clk/fir_compiler_10taps_139264clk.xci
read_ip ./ip/fir_compiler_30taps_69632clk/fir_compiler_30taps_69632clk.xci
#read_ip ./ip/fir_compiler_30taps_139264clk/fir_compiler_30taps_139264clk.xci
#read_ip ./ip/fir_compiler_60taps_69632clk/fir_compiler_10taps_69632clk.xci
#read_ip ./ip/fir_compiler_60taps_139264clk/fir_compiler_60taps_139264clk.xci
generate_target all [get_ips]
synth_ip [get_ips]
open_vcd
log_vcd  *
run all
close_vcd
quit