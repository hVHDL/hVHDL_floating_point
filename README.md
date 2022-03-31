# vhdl_float
simple floating point library for synthesis in fpga coded in object oriented style

Also includes float to real and real to float conversion functions for simple constant assignment like

float_number <= to_float(3.14);


run all test benches with vunit+ghdl+gtkwave using

python vunit_run_float.py -p 8 --gtkwave-fmt ghw

An iir low pass filter which uses the Multiplier and adder has been tested successfully on efinix trion fpga

A blog post on the library design can be found at
https://hardwaredescriptions.com/floating-point-in-vhdl/
