echo off
set source=./

ghdl -a --ieee=synopsys --std=08 %source%/float_type_definitions/float_type_definitions_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/normalizer/normalizer_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/denormalizer/denormalizer_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/float_to_real_conversions/float_to_real_conversions_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/float_arithmetic_operations/float_arithmetic_operations_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/float_adder/float_adder_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/float_multiplier/float_multiplier_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/float_first_order_filter/float_first_order_filter_pkg.vhd
