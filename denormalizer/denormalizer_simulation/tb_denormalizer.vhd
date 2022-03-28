LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.float_type_definitions_pkg.all;
    use work.denormalizer_pkg.all;
    use work.float_to_real_conversions_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity tb_denormalizer is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_denormalizer is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    signal larger  : float_record := to_float(8563.0);
    signal smaller : float_record := to_float(37.0);

    signal test_float : float_record := to_float(1.65);
    signal test_denormalizer : float_record := denormalize_float(test_float,3);

    signal denormalizer_array : float_array(0 to 2) := (zero, zero, zero);
    signal target_scale : integer range 0 to mantissa_length := 0;
    signal shift_register : std_logic_vector(2 downto 0) := (others => '0');

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        simulation_running <= false;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

------------------------------------------------------------------------
    sim_clock_gen : process
    begin
        simulator_clock <= '0';
        wait for clock_half_per;
        while simulation_running loop
            wait for clock_half_per;
                simulator_clock <= not simulator_clock;
            end loop;
        wait;
    end process;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            shift_register <= shift_register(shift_register'left-1 downto 0) & '0';
            denormalizer_array(1) <= denormalize_float(denormalizer_array(0), target_scale);
            denormalizer_array(2) <= denormalize_float(denormalizer_array(1), target_scale);

            CASE simulation_counter is
                WHEN 3 => 
                    shift_register(0) <= '1';
                    if get_exponent(larger) < get_exponent(smaller) then
                        denormalizer_array(0) <= smaller;
                        target_scale <= get_exponent(smaller);
                    else
                        denormalizer_array(0) <= larger;
                        target_scale <= get_exponent(larger);
                    end if;
                WHEN others => -- do nothing
            end CASE;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
