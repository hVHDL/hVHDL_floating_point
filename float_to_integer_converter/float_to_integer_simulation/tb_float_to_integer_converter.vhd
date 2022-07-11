LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    context vunit_lib.vunit_context;

    use work.float_type_definitions_pkg.all;
    use work.float_to_real_conversions_pkg.all;
    use work.float_type_definitions_pkg.all;

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

    function to_radix15
    (
        float_number : float_record
    )
    return integer
    is
        variable returned_value : float_record := to_float(0.0);
    begin
        returned_value := denormalize_float(float_number, mantissa_high+1-15);
        return integer(get_mantissa(returned_value));
    end to_radix15;

    signal output : float_record := zero;

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

            check(integer(2.0**15*1.999) = to_radix15(test_data_7), "expected 32768, got " & integer'image(to_radix15(test_data_7)));
            output <= denormalize_float(to_float(1.0), mantissa_high+1-15);


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
