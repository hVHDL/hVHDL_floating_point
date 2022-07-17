LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    context vunit_lib.vunit_context;

    use work.float_type_definitions_pkg.all;
    use work.float_to_real_conversions_pkg.all;
    use work.denormalizer_pkg.all;

entity tb_float_to_integer_converter is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_float_to_integer_converter is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----


    signal test_data_7 : float_record := to_float(1.999);
    constant check_value : integer := integer(2.0**15*1.999);

    function to_integer
    (
        float_number : float_record;
        radix : integer
    )
    return integer
    is
        variable returned_value : float_record;
    begin
        returned_value := denormalize_float(float_number, mantissa_length-radix);
        return integer(get_mantissa(returned_value));
    end to_integer;

    signal denormalizer : denormalizer_record := init_denormalizer;
    signal vastaus : integer := 0;

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
            create_denormalizer(denormalizer);


            check((check_value) = to_integer(test_data_7, 15), "expected " & integer'image(check_value) & ", got " & integer'image(to_integer(test_data_7, 15)));

            CASE simulation_counter is 
                WHEN 0 => request_scaling(denormalizer, to_float(1.0), 12);
                WHEN 1 => request_scaling(denormalizer, to_float(5.0), 12);
                WHEN 2 => request_scaling(denormalizer, to_float(-11.0), 12);
                WHEN 3 => request_scaling(denormalizer, to_float(-0.0), 12);
                WHEN others => -- do nothing
            end CASE;

            if denormalizer_is_ready(denormalizer) then
                vastaus <= get_integer(denormalizer);
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
