LIBRARY ieee  ;
    USE ieee.NUMERIC_STD.all  ;
    USE ieee.std_logic_1164.all  ;
    use ieee.math_real.all;

library vunit_lib;
    context vunit_lib.vunit_context;

-- float_lut_sine_pkg : the table model against math_real's sin over the
-- whole turn, and the sine computed by multiply_add(agilex) (the native fp32
-- model) against the table model, one request each clock
entity float_lut_sine_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of float_lut_sine_tb is

    use work.multiply_add_pkg.all;
    use work.float_lut_sine_pkg.all;

    signal simulator_clock : std_logic := '0';
    constant clock_per     : time      := 1 ns;

    constant number_of_angles : natural := 20000;

    -- angles over the whole turn : a stride that is not a power of two, so
    -- every table index and both halves of each quadrant are visited, and
    -- the edges of the quadrants
    function get_angle (i : natural) return unsigned is
        constant edges : natural := 8;
        constant edge_angles : unsigned(4*32-1 downto 0) := x"00000000" & x"3FFFFFFF" & x"40000000" & x"BFFFFFFF";
    begin
        if i < 4 then
            return edge_angles(32*(3-i)+31 downto 32*(3-i));
        elsif i < edges then
            return to_unsigned(i-4, 32) + x"7FFFFFFE";
        else
            return resize(to_unsigned(i, 32) * to_unsigned(214_745, 18), 32);
        end if;
    end get_angle;

    function angle_in_radians (angle : unsigned) return real is
    begin
        return 2.0 * math_pi * real(to_integer(angle(31 downto 16))) / 65536.0
             + 2.0 * math_pi * real(to_integer(angle(15 downto 0))) / 2.0**32;
    end angle_in_radians;

    constant mpya_ref : mpya_subtype_record := create_mpya_typeref;
    signal mpya_in  : mpya_ref.mpya_in'subtype  := mpya_ref.mpya_in;
    signal mpya_out : mpya_ref.mpya_out'subtype := mpya_ref.mpya_out;

    signal requested    : natural := 0;
    signal received     : natural := 0;
    signal max_error    : real    := 0.0;
    signal hardware_run : boolean := false;

begin

------------------------------------------------------------------------
    simtime : process
        variable error_now, model_max_error : real := 0.0;
        variable angle : unsigned(31 downto 0);
    begin
        test_runner_setup(runner, runner_cfg);

        while test_suite loop
            if run("lut_model_follows_sine") then
                -- linear interpolation between 256 points a quarter wave :
                -- at most (pi/2/256)**2/8 = 4.7e-6 from the sine
                model_max_error := 0.0;
                for i in 0 to number_of_angles-1 loop
                    angle := get_angle(i);
                    error_now := abs(get_sine_from_quarter_wave_lut(angle) - sin(angle_in_radians(angle)));
                    if error_now > model_max_error then
                        model_max_error := error_now;
                    end if;
                end loop;
                info("lut model max error " & real'image(model_max_error));
                check(model_max_error < 5.0e-6, "lut model within 5e-6 of sin");
                check(model_max_error > 1.0e-6, "the error check sees the interpolation error");

            elsif run("table_values_are_exact_for_known_points") then
                check(to_float32_slv(1.0)  = x"3F800000");
                check(to_float32_slv(-2.0) = x"C0000000");
                check(to_float32_slv(0.5)  = x"3F000000");
                check(to_float32_slv(0.0)  = x"00000000");
                check(abs(to_real(to_float32_slv(math_pi)) - math_pi) < 2.0e-7);
                -- the quarter wave's end points
                check(abs(get_sine_from_quarter_wave_lut(x"00000000")) < 1.0e-7);
                check(abs(get_sine_from_quarter_wave_lut(x"40000000") - 1.0) < 1.0e-6);
                check(abs(get_sine_from_quarter_wave_lut(x"C0000000") + 1.0) < 1.0e-6);

            elsif run("agilex_multiply_add_computes_the_lut_sine") then
                hardware_run <= true;
                wait until received = number_of_angles;
                info("multiply_add(agilex) max error from the model " & real'image(max_error));
                check(max_error < 2.0e-7, "fp32 multiply-add within 2e-7 of the real model");
            end if;
        end loop;

        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;

    simulator_clock <= not simulator_clock after clock_per/2.0;
------------------------------------------------------------------------
    stimulus : process(simulator_clock)
        variable error_now : real;
    begin
        if rising_edge(simulator_clock) then
            init_multiply_add(mpya_in);

            -- one sine requested each clock, the results in the same order
            if hardware_run and requested < number_of_angles then
                request_sine(mpya_in, get_angle(requested));
                requested <= requested + 1;
            end if;

            if mpya_is_ready(mpya_out) then
                error_now := abs(to_real(get_mpya_result(mpya_out)) - get_sine_from_quarter_wave_lut(get_angle(received)));
                if error_now > max_error then
                    max_error <= error_now;
                end if;
                received <= received + 1;
            end if;
        end if; -- rising_edge
    end process stimulus;
------------------------------------------------------------------------
    dut : entity work.multiply_add(agilex)
    port map(
        simulator_clock
        ,mpya_in
        ,mpya_out);
------------------------------------------------------------------------
end vunit_simulation;
