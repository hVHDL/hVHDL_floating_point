echo off
set source=./

ghdl -a --ieee=synopsys --std=08 %source%/float_multiplier/float_multiplier_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/float_arithmetic_operations_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/float_adder/float_adder_pkg.vhd
