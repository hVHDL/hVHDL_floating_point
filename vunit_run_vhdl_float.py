#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()

mathlib = VU.add_library("math_library")
mathlib.add_source_files(ROOT / "float_multiplier" / "*.vhd")
mathlib.add_source_files(ROOT / "float_multiplier/float_multiplier_simulation" / "*.vhd")

VU.main()
