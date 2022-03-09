echo off
set source=./

ghdl -a --ieee=synopsys --std=08 %source%/float_multiplier/float_multiplier_pkg.vhd
