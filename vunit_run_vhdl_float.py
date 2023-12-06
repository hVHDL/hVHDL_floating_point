#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()

mathlib = VU.add_library("math_library")
mathlib.add_source_files(ROOT / "float_type_definitions/float_word_length_24_bit_pkg.vhd")
mathlib.add_source_files(ROOT / "float_type_definitions/float_type_definitions_pkg.vhd")
mathlib.add_source_files(ROOT / "float_arithmetic_operations/*.vhd")

mathlib.add_source_files(ROOT / "normalizer/normalizer_configuration/normalizer_with_3_stage_pipe_pkg.vhd")
mathlib.add_source_files(ROOT / "normalizer/*.vhd")

mathlib.add_source_files(ROOT / "denormalizer/denormalizer_configuration/denormalizer_with_3_stage_pipe_pkg.vhd")
mathlib.add_source_files(ROOT / "denormalizer/*.vhd")

mathlib.add_source_files(ROOT / "float_to_real_conversions" / "*.vhd")

mathlib.add_source_files(ROOT / "float_adder/*.vhd")

mathlib.add_source_files(ROOT / "float_multiplier/*.vhd")

mathlib.add_source_files(ROOT / "float_alu/*.vhd")

mathlib.add_source_files(ROOT / "float_first_order_filter/*.vhd")


mathlib.add_source_files(ROOT / "testbenches/simulate_normalizer/*.vhd")
mathlib.add_source_files(ROOT / "testbenches/denormalizer_simulation/*.vhd")
mathlib.add_source_files(ROOT / "testbenches/float_to_real_simulation" / "*.vhd")
mathlib.add_source_files(ROOT / "testbenches/adder_simulation/*.vhd")
mathlib.add_source_files(ROOT / "testbenches/float_multiplier_simulation/*.vhd")
mathlib.add_source_files(ROOT / "testbenches/float_alu_simulation/*.vhd")
mathlib.add_source_files(ROOT / "testbenches/simulate_float_filter/*.vhd")
mathlib.add_source_files(ROOT / "testbenches/float_to_integer_simulation/*.vhd")


VU.main()
