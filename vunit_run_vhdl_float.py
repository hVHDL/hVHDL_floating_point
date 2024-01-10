#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()

mathlib = VU.add_library("mathlib")
mathlib.add_source_files(ROOT / "float_type_definitions/float_word_length_24_bit_pkg.vhd")
mathlib.add_source_files(ROOT / "float_type_definitions/float_type_definitions_pkg.vhd")
mathlib.add_source_files(ROOT / "float_arithmetic_operations/float_arithmetic_operations_pkg.vhd")

mathlib.add_source_files(ROOT / "normalizer/normalizer_configuration/normalizer_with_1_stage_pipe_pkg.vhd")
mathlib.add_source_files(ROOT / "normalizer/normalizer_pkg.vhd")

mathlib.add_source_files(ROOT / "denormalizer/denormalizer_configuration/denormalizer_with_1_stage_pipe_pkg.vhd")
mathlib.add_source_files(ROOT / "denormalizer/denormalizer_pkg.vhd")

mathlib.add_source_files(ROOT / "float_to_real_conversions/float_to_real_functions_pkg.vhd")
mathlib.add_source_files(ROOT / "float_to_real_conversions/float_to_real_conversions_pkg.vhd")

mathlib.add_source_files(ROOT / "float_adder/float_adder_pkg.vhd")

mathlib.add_source_files(ROOT / "float_multiplier/float_multiplier_pkg.vhd")

mathlib.add_source_files(ROOT / "float_alu/float_alu_pkg.vhd")

mathlib.add_source_files(ROOT / "float_first_order_filter/float_first_order_filter_pkg.vhd")


mathlib.add_source_files(ROOT / "testbenches/simulate_normalizer/*.vhd")
mathlib.add_source_files(ROOT / "testbenches/denormalizer_simulation/*.vhd")
mathlib.add_source_files(ROOT / "testbenches/float_to_real_simulation" / "*.vhd")
mathlib.add_source_files(ROOT / "testbenches/adder_simulation/*.vhd")
mathlib.add_source_files(ROOT / "testbenches/float_multiplier_simulation/*.vhd")
mathlib.add_source_files(ROOT / "testbenches/float_alu_simulation/*.vhd")
mathlib.add_source_files(ROOT / "testbenches/simulate_float_filter/*.vhd")
mathlib.add_source_files(ROOT / "testbenches/float_to_integer_simulation/*.vhd")

#denormalized numbers tests

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


VU.main()
