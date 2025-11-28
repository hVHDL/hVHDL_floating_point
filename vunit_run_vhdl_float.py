#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit
import argparse

# Parse extra arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    "--dump-arrays",
    action="store_true",
    help="Enable dumping arrays in the NVC simulator"
)
args, vunit_args = parser.parse_known_args()
# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv(vunit_args)
# from_argv(compile_builtins=False)

float_lib = VU.add_library("float_lib")
float_lib.add_source_files(ROOT / "float_type_definitions/float_word_length_24_bit_pkg.vhd")
float_lib.add_source_files(ROOT / "float_type_definitions/float_type_definitions_pkg.vhd")
float_lib.add_source_files(ROOT / "float_arithmetic_operations/float_arithmetic_operations_pkg.vhd")

float_lib.add_source_files(ROOT / "normalizer/normalizer_configuration/normalizer_with_1_stage_pipe_pkg.vhd")
float_lib.add_source_files(ROOT / "normalizer/normalizer_pkg.vhd")

float_lib.add_source_files(ROOT / "denormalizer/denormalizer_configuration/denormalizer_with_1_stage_pipe_pkg.vhd")
float_lib.add_source_files(ROOT / "denormalizer/denormalizer_pkg.vhd")

float_lib.add_source_files(ROOT / "float_to_real_conversions/float_to_real_functions_pkg.vhd")
float_lib.add_source_files(ROOT / "float_to_real_conversions/float_to_real_conversions_pkg.vhd")

float_lib.add_source_files(ROOT / "float_adder/float_adder_pkg.vhd")

float_lib.add_source_files(ROOT / "float_multiplier/float_multiplier_pkg.vhd")

float_lib.add_source_files(ROOT / "float_alu/float_alu_pkg.vhd")

float_lib.add_source_files(ROOT / "float_first_order_filter/float_first_order_filter_pkg.vhd")


float_lib.add_source_files(ROOT / "testbenches/simulate_normalizer/*.vhd")
float_lib.add_source_files(ROOT / "testbenches/denormalizer_simulation/*.vhd")
float_lib.add_source_files(ROOT / "testbenches/float_to_real_simulation" / "*.vhd")
float_lib.add_source_files(ROOT / "testbenches/adder_simulation/*.vhd")
float_lib.add_source_files(ROOT / "testbenches/float_multiplier_simulation/*.vhd")
float_lib.add_source_files(ROOT / "testbenches/float_alu_simulation/*.vhd")
float_lib.add_source_files(ROOT / "testbenches/simulate_float_filter/*.vhd")
float_lib.add_source_files(ROOT / "testbenches/float_to_integer_simulation/*.vhd")

float_lib.add_source_files(ROOT / "testbenches/float_fused_multiply_add/fused_multiply_add_tb.vhd")

float_lib.add_source_files(ROOT / "testbenches/tb_float_comparisons.vhd")

#denormalized numbers tests, not yet developed

denormal = VU.add_library("denormal")
denormal.add_source_files(ROOT / "float_type_definitions/float_word_length_20_bit_pkg.vhd")
denormal.add_source_files(ROOT / "float_type_definitions/float_type_definitions_pkg.vhd")
denormal.add_source_files(ROOT / "float_arithmetic_operations/float_arithmetic_operations_pkg.vhd")

denormal.add_source_files(ROOT / "normalizer/normalizer_configuration/normalizer_with_1_stage_pipe_pkg.vhd")
denormal.add_source_files(ROOT / "normalizer/normalizer_pkg.vhd")

denormal.add_source_files(ROOT / "denormalizer/denormalizer_configuration/denormalizer_with_1_stage_pipe_pkg.vhd")
denormal.add_source_files(ROOT / "denormalizer/denormalizer_pkg.vhd")

denormal.add_source_files(ROOT / "float_to_real_conversions/float_to_real_functions_pkg.vhd")
denormal.add_source_files(ROOT / "float_to_real_conversions/float_to_real_conversions_pkg.vhd")

denormal.add_source_files(ROOT / "float_adder/float_adder_pkg.vhd")
denormal.add_source_files(ROOT / "float_multiplier/float_multiplier_pkg.vhd")
denormal.add_source_files(ROOT / "float_alu/float_alu_pkg.vhd")
denormal.add_source_files(ROOT / "float_first_order_filter/float_first_order_filter_pkg.vhd")

denormal.add_source_files(ROOT / "testbenches/simulate_normalizer/*.vhd")
denormal.add_source_files(ROOT / "testbenches/denormalizer_simulation/*.vhd")
denormal.add_source_files(ROOT / "testbenches/float_to_real_simulation" / "*.vhd")
denormal.add_source_files(ROOT / "testbenches/adder_simulation/*.vhd")
denormal.add_source_files(ROOT / "testbenches/float_multiplier_simulation/*.vhd")
denormal.add_source_files(ROOT / "testbenches/float_alu_simulation/*.vhd")
denormal.add_source_files(ROOT / "testbenches/simulate_float_filter/*.vhd")
denormal.add_source_files(ROOT / "testbenches/float_to_integer_simulation/*.vhd")

# denormal.add_source_files(ROOT / "testbenches/denormalized_numbers/tb_denormal_conversions.vhd")
denormal.add_source_files(ROOT / "testbenches/denormalized_numbers/saturated_add_tb.vhd")

generic_lib = VU.add_library("generic_lib")
generic_lib.add_source_files(ROOT / "vhdl2008/float_typedefs_generic_pkg.vhd")
generic_lib.add_source_files(ROOT / "vhdl2008/normalizer_generic_pkg.vhd")
generic_lib.add_source_files(ROOT / "vhdl2008/denormalizer_generic_pkg.vhd")
generic_lib.add_source_files(ROOT / "vhdl2008/float_multiplier_generic_pkg.vhd")
generic_lib.add_source_files(ROOT / "vhdl2008/float_adder_generic_pkg.vhd")
generic_lib.add_source_files(ROOT / "vhdl2008/float_to_real_conversions_pkg.vhd")
generic_lib.add_source_files(ROOT / "vhdl2008/multiply_add_entity.vhd")
generic_lib.add_source_files(ROOT / "vhdl2008/multiply_add_arch_hfloat.vhd")
generic_lib.add_source_files(ROOT / "vhdl2008/multiply_add_arch_fast_hfloat.vhd")

generic_lib.add_source_files(ROOT / "vhdl2008/fast_hfloat_pkg.vhd")

generic_lib.add_source_files(ROOT / "vhdl2008/altera/multiply_add_arch_agilex.vhd")
generic_lib.add_source_files(ROOT / "vhdl2008/altera/sim_native_fp32.vhd")

generic_lib.add_source_files(ROOT / "testbenches/vhdl2008/normalizer_tb.vhd")
generic_lib.add_source_files(ROOT / "testbenches/vhdl2008/mult_add_entity_tb.vhd")
generic_lib.add_source_files(ROOT / "testbenches/vhdl2008/fast_multiply_add_tb.vhd")
generic_lib.add_source_files(ROOT / "testbenches/vhdl2008/fast_multiply_add_pkg_tb.vhd")
generic_lib.add_source_files(ROOT / "testbenches/vhdl2008/fast_multiply_add_v2_tb.vhd")

generic_lib.add_source_files(ROOT / "testbenches/vhdl2008/mult_add_entity_agilex_tb.vhd")

generic_lib.add_source_files(ROOT / "testbenches/vhdl2008/type_conversions_tb.vhd")


if args.dump_arrays:
    VU.set_sim_option("nvc.sim_flags", ["-w", "--dump-arrays"])

VU.main()
