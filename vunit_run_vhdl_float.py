#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()

mathlib = VU.add_library("math_library")
mathlib.add_source_files(ROOT / "float_arithmetic_operations/*.vhd")
mathlib.add_source_files(ROOT / "register_operations" / "*.vhd")

mathlib.add_source_files(ROOT / "normalizer/*.vhd")
mathlib.add_source_files(ROOT / "normalizer/simulate_normalizer/*.vhd")

mathlib.add_source_files(ROOT / "float_to_real_conversions" / "*.vhd")
mathlib.add_source_files(ROOT / "float_to_real_conversions/float_to_real_simulation" / "*.vhd")

mathlib.add_source_files(ROOT / "float_adder/*.vhd")
mathlib.add_source_files(ROOT / "float_adder/adder_simulation/*.vhd")

mathlib.add_source_files(ROOT / "float_multiplier/float_multiplier_simulation/*.vhd")
VU.main()
