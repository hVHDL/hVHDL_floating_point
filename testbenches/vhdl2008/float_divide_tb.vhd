-- float_divide_tb - vunit accuracy/regression sweep for float_divide(lut).
-- Same style as hVHDL_floating_point's fast_multiply_add_tb.vhd: a real-
-- valued reference pipeline shadows the DUT's own pipeline depth, so
-- there's no need to hand-derive the exact register count.
--
-- Stimuli are encoded real -> ieee.float_pkg float32 -> hfloat, exactly
-- like fast_multiply_add_tb.vhd, rather than via
-- float_to_real_conversions_pkg.to_hfloat(real, exp, mant) directly -
-- that path once had a real bug here (get_mantissa's real_exp=0 branch
-- reported 2x magnitude for ~59% of inputs, since fixed), and this
-- testbench keeps using the ieee.float_pkg route fast_multiply_add_tb.vhd
-- already established rather than reintroducing the other path.
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;
    use ieee.float_pkg.all;

library vunit_lib;
    context vunit_lib.vunit_context;

entity float_divide_tb is
  generic (runner_cfg : string);
end entity;

architecture vunit_simulation of float_divide_tb is

    use work.float_typedefs_generic_pkg.all;
    use work.float_to_real_conversions_pkg.all;
    use work.float_divide_pkg.all;

    function to_float32 (a : real) return float32 is
    begin
        return to_float(a, float32'high);
    end function;

    function to_hfloat (a : real) return hfloat_record is
    begin
        return to_hfloat(to_float32(a), hfloat32_ref);
    end function;

    signal simulation_running  : boolean;
    signal simulator_clock     : std_logic := '0';
    constant clock_per         : time      := 1 ns;
    constant simtime_in_clocks : integer   := 20000;

    signal simulation_counter : natural := 0;

    constant div_ref : float_divide_typeref := create_float_divide_typeref(hfloat32_ref);
    signal   div_in  : div_ref.divide_in'subtype  := div_ref.divide_in;
    signal   div_out : div_ref.divide_out'subtype := div_ref.divide_out;

    signal ref_a, ref_b : real := 1.0;
    signal ref_pipeline : real_vector(5 downto 0) := (others => 1.0);

    signal rel_error       : real := 0.0;
    signal max_rel_error   : real := 0.0;
    signal rel_error_count : real := 0.0;
    signal total_count     : real := 0.0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        check(total_count > 0.0, "no results were ever checked");
        check(rel_error_count = 0.0, "error count " & real'image(rel_error_count)
            & "  max_rel_error " & real'image(max_rel_error));
        simulation_running <= false;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;

    simulator_clock <= not simulator_clock after clock_per/2.0;
------------------------------------------------------------------------

    stimulus : process (simulator_clock)
        variable seed1 : positive := 1;
        variable seed2 : positive := 1;
        variable rand1, rand2, rand_exp1, rand_exp2 : real := 0.0;
        variable a, b : real;

        procedure request_divide_real (signal self_in : out div_ref.divide_in'subtype; a, b : real) is
        begin
            request_divide(self_in, to_std_logic(to_hfloat(a)), to_std_logic(to_hfloat(b)));
            ref_a <= a;
            ref_b <= b;
        end procedure;

        variable v_rel_error : real := 0.0;
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            init_float_divide(div_in);

            -- shadows whatever the DUT's a/b were on entry, one cycle
            -- behind ref_a/ref_b for the same reason mpy_a/mpy_b lag the
            -- request by a cycle - see fast_multiply_add_tb.vhd
            ref_pipeline <= ref_pipeline(ref_pipeline'left-1 downto 0) & (ref_a/ref_b);

            uniform(seed1, seed2, rand1);
            uniform(seed1, seed2, rand2);
            uniform(seed1, seed2, rand_exp1);
            uniform(seed1, seed2, rand_exp2);

            -- both operands' magnitudes spread across ~6 decades, either sign
            a := (rand1 - 0.5) * 2.0 * (10.0 ** (rand_exp1 * 6.0 - 3.0));
            b := (rand2 - 0.5) * 2.0 * (10.0 ** (rand_exp2 * 6.0 - 3.0));
            if abs(b) < 1.0e-6 then b := 1.0e-6; end if;

            if simulation_counter >= 20 then
                request_divide_real(div_in, a, b);
            end if;

            -- a handful of exact/simple cases, overriding the random stream
            case simulation_counter is
                when  40 => request_divide_real(div_in,   1.0,  1.0);
                when  50 => request_divide_real(div_in,   8.0,  2.0);
                when  60 => request_divide_real(div_in,  -8.0,  2.0);
                when  70 => request_divide_real(div_in,   8.0, -2.0);
                when  80 => request_divide_real(div_in,  -8.0, -2.0);
                when  90 => request_divide_real(div_in,   1.0,  8.0);
                when 100 => request_divide_real(div_in,   1.0, -8.0);
                when 110 => request_divide_real(div_in,   3.0,  7.0);
                when 120 => request_divide_real(div_in,  22.0,  7.0);
                when 130 => request_divide_real(div_in, 1.0e6, 1.0e-6);
                when 140 => request_divide_real(div_in, 1.0e-6, 1.0e6);
                when others => -- do nothing
            end case;

            if float_divide_is_ready(div_out) then
                v_rel_error := (to_real(to_hfloat(get_divide_result(div_out), hfloat32_ref))
                                - ref_pipeline(3)) / ref_pipeline(3);
                rel_error   <= v_rel_error;
                total_count <= total_count + 1.0;
                if abs(v_rel_error) > max_rel_error then
                    max_rel_error <= abs(v_rel_error);
                end if;
                if abs(v_rel_error) > 1.0e-3 then
                    rel_error_count <= rel_error_count + 1.0;
                    report "mismatch: expected " & real'image(ref_pipeline(3))
                         & "  rel_error " & real'image(v_rel_error) severity warning;
                end if;
            end if;

        end if; -- rising_edge
    end process stimulus;
------------------------------------------------------------------------
    dut : entity work.float_divide
    generic map (floatref => hfloat32_ref)
    port map (
        clock      => simulator_clock,
        divide_in  => div_in,
        divide_out => div_out
    );
------------------------------------------------------------------------
end architecture vunit_simulation;
