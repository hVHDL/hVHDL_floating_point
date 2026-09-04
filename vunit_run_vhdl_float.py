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

# Legacy, non-generic package tree (superseded by vhdl2008/) lives under
# vhdl1993/ and has its own runner: vhdl1993/vunit_run_vhdl_float.py.

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
