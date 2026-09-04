# High level vhdl floating point library 
simple floating point library for synthesis in fpga coded in object oriented style. This is a synthesizable version of a floating point filter, which has been tested with most common FPGAs

```vhdl
    floating_point_filter : process(clock)
    begin
        if rising_edge(clock) then
        
            create_float_alu(float_alu);
            create_float_to_integer_converter(float_to_integer_converter);
        ------------------------------------------------------------------------
            filter_is_ready <= false;
            CASE filter_counter is
                WHEN 0 => 
                    subtract(float_alu, u, y);
                    filter_counter <= filter_counter + 1;
                WHEN 1 =>
                    if add_is_ready(float_alu) then
                        multiply(float_alu  , get_add_result(float_alu) , filter_gain);
                        filter_counter <= filter_counter + 1;
                    end if;

                WHEN 2 =>
                    if multiplier_is_ready(float_alu) then
                        add(float_alu, get_multiplier_result(float_alu), y);
                        filter_counter <= filter_counter + 1;
                    end if;
                WHEN 3 => 
                    if add_is_ready(float_alu) then
                        y <= get_add_result(float_alu);
                        filter_counter <= filter_counter + 1;
                        filter_is_ready <= true;
                    end if;
                WHEN others =>  -- wait for start
            end CASE;
        ------------------------------------------------------------------------

            if example_filter_input.filter_is_requested then
                convert_integer_to_float(float_to_integer_converter, example_filter_input.filter_input, 15);
            end if;

            if int_to_float_conversion_is_ready(float_to_integer_converter) then
                request_float_filter(float_filter, get_converted_float(float_to_integer_converter));
            end if;

            convert_float_to_integer(float_to_integer_converter, get_filter_output(float_filter), 14);

        end if; --rising_edge
    end process floating_point_filter;	

```

Also includes float to real and real to float conversion functions for simple constant assignment like

float_number <= to_float(3.14);


## Repository layout

| path | contents |
|------|----------|
| `vhdl1993/` | the object-style API used above: word-length-specific packages (`float_word_length_*_bit_pkg`), `float_alu`, `float_to_integer_converter`, `normalizer`/`denormalizer` with a fixed pipeline depth baked into the package name. Legacy, kept building via its own vunit runner, not part of the main suite. |
| `vhdl2008/` | generic, `hfloat_record`-based rewrite: `multiply_add` (fused `a*b + c`; `hfloat` / `fast_hfloat` / `agilex` architectures - see below), `normalizer_generic_pkg`, `denormalizer_generic_pkg`, `float_to_real_conversions_pkg`, `float_to_fixed` (`float_to_fixed_pkg` + entity - `trunc(x * 2**radix)`, sidesteps the Quartus Pro 25.3 denormalizer bug below by reading its width off a generic). This is the actively developed half, e.g. what [`hfloat_test`](https://github.com/johonkanen/float_fpga_hw_test) builds on real Titanium/Agilex hardware. |
| `testbenches/vhdl2008/` | vunit testbenches for `vhdl2008/`. |
| `vhdl1993/testbenches/` | vunit testbenches for `vhdl1993/`. |

Run the active suite (vhdl2008, nvc):

```
python vunit_run_vhdl_float.py -p 8
```

Run the legacy suite (vhdl1993) standalone:

```
python vhdl1993/vunit_run_vhdl_float.py -p 8
```

Add `--gtkwave-fmt ghw` to either if you want waves out of a ghdl run and have gtkwave on `PATH`.

An iir low pass filter has been tested on an example project for the hVHDL project and can be found here
https://hvhdl.readthedocs.io/en/latest/hvhdl_example_project/hvhdl_example_project.html#floating-point-filter-implementation

There is a blog post on the bit level design of the floating point module
https://hardwaredescriptions.com/floating-point-in-vhdl/

The floating point alu is also documented in
https://hardwaredescriptions.com/high-level-floating-point-alu-in-synthesizable-vhdl/

## Soft multiply-add: `multiply_add(hfloat)` / `multiply_add(fast_hfloat)`

`multiply_add` (`vhdl2008/multiply_add_entity.vhd`) is a fused `a*b + c` over
the generic `hfloat_record` (sign, exponent, explicit-leading-1 mantissa - no
hidden bit, no subnormals/inf/NaN, truncated rather than correctly rounded).
Two soft architectures trade logic for latency:

| architecture | latency (core-clock edges) | notes |
|---|---:|---|
| `hfloat` (`multiply_add_arch_hfloat.vhd`) | 8 | sign-magnitude adder + one barrel-shift denormaliser; the reference implementation |
| `fast_hfloat` (`multiply_add_arch_fast_hfloat.vhd`) | 4 | aligns the addend by multiplying it with a one-hot vector (alignment rides the DSP instead of a barrel shifter), fuses magnitude-recovery / slice / normalise into a single stage |

`fast_hfloat`'s alignment range is bounded by `fast_hfloat_pkg.c_align_guard`
(default `12`): operands whose magnitudes differ by more than `c_align_guard`
bits have the smaller one truncated instead of fully summed. At the default,
`fast_hfloat` matches `hfloat` to within `1e-3` relative on a wide random
sweep; `c_align_guard = 20` matches to within `1e-5` (`hfloat`'s own noise
floor) at the cost of a wider datapath.

On Agilex, `fast_hfloat`'s pipeline registers carry **no power-up value** -
an ALM register with an initial value can't be moved by the Hyper-Retimer,
which otherwise pins the whole architecture's Fmax. Verified end to end on
[`hfloat_test`](https://github.com/johonkanen/float_fpga_hw_test) at a
120 MHz core clock:

| board | toolchain | Fmax | bit-exact vs `hfloat` on hardware? |
|---|---|---:|---|
| Titanium Ti60F225 | Efinity 2026.1 | ~180 MHz | yes |
| Agilex 3 (AXC3000) | Quartus Prime Pro 25.3 / 26.1.1 | ~141 MHz | yes |

## Agilex hard-float multiply-add

The `agilex` architecture (`vhdl2008/altera/multiply_add_arch_agilex.vhd`)
maps the same `multiply_add` entity onto the Altera **Native Floating-Point
DSP** hard block, instantiated as a component called `native_fp32`:

```vhdl
use work.multiply_add_pkg.all;
constant ref     : mpya_subtype_record := create_mpya_typeref;      -- fp32
signal   mpya_in : ref.mpya_in'subtype  := ref.mpya_in;
signal   mpya_out: ref.mpya_out'subtype := ref.mpya_out;
...
u_fma : entity work.multiply_add(agilex)
    port map (clock => clk, mpya_in => mpya_in, mpya_out => mpya_out);
...
multiply_add(mpya_in, a, b, c);                 -- a,b,c : std_logic_vector(31 downto 0)
result <= get_mpya_result(mpya_out);            -- valid after the pipeline latency
```

### Latency: 3 clock cycles

The behavioural model `vhdl2008/altera/sim_native_fp32.vhd` (used for simulation
only) has a **3 cycle** input→result latency, and `ready_pipeline` in the
`agilex` architecture asserts `mpya_out.is_ready` **3 cycles** after
`is_requested`. For the synthesised design to behave the same, the real
`native_fp32` IP must be generated with the matching **3 cycle** pipeline:

| register            | setting  |
|---------------------|----------|
| `fp32_mult_a` / `fp32_mult_b` / `fp32_adder_a` input registers | **enabled** |
| `adder_input`        | **enabled** |
| output register     | **enabled** |
| `mult_pipeline`, `mult_2nd_pipeline` | disabled |
| `fp32_adder_a_chainin_pl`, `..._chainin_2nd_pl`, `adder_pl` | disabled |
| all `accum*`         | disabled |

The IP's own default for `fp32_mult_add` mode is a deeper (~5 cycle) pipeline,
so these registers have to be turned off explicitly. Leaving `adder_input`
off as well gives a 2 cycle IP, which then does **not** match the model or
`ready_pipeline`.

### Generating the IP in an Agilex Quartus Prime Pro project

The IP variation must be named `native_fp32` (matching the component in
`multiply_add_arch_agilex.vhd`) and use the plain `fp32_adder_a` port
(`use_chainin=false`).

Command line (`ip-deploy` lives in `<quartus>/sopc_builder/bin`):

```
ip-deploy --component-name=agilex_native_floating_point_dsp \
  --output-name=native_fp32 --output-directory=ip/native_fp32 \
  --family="Agilex 3" --part=<device> \
  --component-parameter=operation_mode=fp32_mult_add \
  --component-parameter=use_chainin=false \
  --component-parameter=fp32_mult_a_clken=0 \
  --component-parameter=fp32_mult_b_clken=0 \
  --component-parameter=fp32_adder_a_clken=0 \
  --component-parameter=adder_input_clken=0 \
  --component-parameter=output_clken=0 \
  --component-parameter=mult_pipeline_clken=no_reg \
  --component-parameter=mult_2nd_pipeline_clken=no_reg \
  --component-parameter=fp32_adder_a_chainin_pl_clken=no_reg \
  --component-parameter=fp32_adder_a_chainin_2nd_pl_clken=no_reg
```

(`*_clken = 0` means "registered, clocked by clk[0]"; `no_reg` removes the
register.) Or in Platform Designer: add *Native Floating-Point DSP Agilex FPGA
IP*, set the operation mode to `fp32_mult_add`, turn chain-in off, and match the
table above under *Registers*.

`quartus_syn` does **not** regenerate IP HDL, so after creating/editing the
`.ip` run:

```
qsys-generate ip/native_fp32/native_fp32.ip --synthesis=VHDL --part=<device>
```

Then add the generated `native_fp32.qip` and
`vhdl2008/altera/multiply_add_arch_agilex.vhd` to the project (and **not**
`sim_native_fp32.vhd`, which is simulation-only).

Verified on an Arrow AXC3000 (Agilex 3 `A3CY100BM16AE7S`): measured hardware
latency = 3 core-clock edges, matching `sim_native_fp32.vhd`.

## Float ↔ integer conversion on Quartus Prime Pro

`vhdl2008/denormalizer_generic_pkg.vhd` (`convert_float_to_integer` /
`request_scaling` / `create_denormalizer`, used for float → fixed-point) **does
not synthesise correctly on Quartus Prime Pro 25.3**. It simulates fine (nvc),
but on hardware the mantissa shift is silently dropped and `get_integer` returns
the raw, un-scaled mantissa — e.g. `1.0` at radix 10 gives `2**23` instead of
`1024`.

Cause: these procedures derive the mantissa width (and the pipeline-stage count)
from a subtype attribute of the `self` formal parameter —

```vhdl
constant mantissa_length : natural := self.denormalizer_pipeline(0).mantissa'length;
```

Quartus evaluates that as `0` for a formal of *unconstrained record* type, even
when the actual bound to `self` is a fully constrained signal built with
`denormalizer_typeref`. `mantissa_length = 0` makes `target_scale` negative, so
`denormalize_float` clamps every shift to 0.

Tested on an AXC3000 and **none** of these work around it (all synthesise clean,
all give `1.0 → 2**23`):

- changing `self` from `out` to `inout`
- using the attribute inline instead of assigning it to a local `constant`
- passing a constrained `hfloat_record` signal (rather than a function-call
  result) as the value to convert — the failing attribute is on `self`, not on
  the input

### What does work

The **non-generic** `denormalizer_pkg`
(`vhdl1993/denormalizer/denormalizer_pkg.vhd` + `float_type_definitions_pkg` +
a `vhdl1993/denormalizer/denormalizer_configuration/denormalizer_with_N_stage_pipe_pkg.vhd`
for the pipeline depth). There `mantissa_length` is a package constant from
`float_type_definitions_pkg` and the record subtype is fixed, so nothing is read
off `self`. Verified on AXC3000 hardware: `1.0 → 1024`, `0.5 → 512`,
`0.1 → 102`, `2**-10 → 1`, `-0.5 → -512` at radix 10, `+5.9 ns` slack @ 100 MHz
with a 2-stage pipe.  It takes a `float_record`, so an IEEE-754 fp32 needs a
small `fp32 → float_record` helper first.

To make `denormalizer_generic_pkg` synthesisable the width must not come from
`self`: pass `mantissa_length` as an argument, carry it in the record (populated
by `denormalizer_typeref`), or make the package generic over it.
