echo off
set source=%1

ghdl -a --ieee=synopsys --std=08 %source%/float_type_definitions/float_word_length_16_bit_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/float_type_definitions/float_type_definitions_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/float_arithmetic_operations/float_arithmetic_operations_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/normalizer/normalizer_configuration/normalizer_with_4_stage_pipe_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/normalizer/normalizer_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/denormalizer/denormalizer_configuration/denormalizer_with_4_stage_pipe_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/denormalizer/denormalizer_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/float_to_real_conversions/float_to_real_functions_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/float_to_real_conversions/float_to_real_conversions_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/float_adder/float_adder_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/float_multiplier/float_multiplier_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/float_to_integer_converter/float_to_integer_converter_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/float_alu/float_alu_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/float_first_order_filter/float_first_order_filter_pkg.vhd
