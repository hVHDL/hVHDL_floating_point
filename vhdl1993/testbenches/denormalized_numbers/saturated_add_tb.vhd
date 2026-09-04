LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.float_to_real_conversions_pkg.all;
    use work.float_type_definitions_pkg.all;
    use work.float_alu_pkg.all;

entity saturated_add_tb is
  generic (runner_cfg : string);
end;
architecture vunit_simulation of saturated_add_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 400;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal counter        : real             := 1.0;
    signal test_counter   : real             := 1.0;
    signal float_counter  : float_record     := to_float(1.0);
    signal counter2       : real             := 1.0;
    signal test_counter2  : real             := 0.0;
    signal float_counter2 : float_record     := to_float(1.0);
    signal float_alu      : float_alu_record := init_float_alu;
    signal float_alu2     : float_alu_record := init_float_alu;

    signal testi : signed(4 downto 0) := "00001";
    signal testi2 : signed(4 downto 0) := shift_right(testi,4);
    signal testi3 : signed(4 downto 0) := shift_right(testi,5);

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            create_float_alu(float_alu);
            create_float_alu(float_alu2);

            if simulation_counter = 0 then
                add(float_alu       , float_counter  , to_float(3.0));
                multiply(float_alu2 , float_counter2 , to_float(0.5));
            end if;

            if add_is_ready(float_alu) then
                add(float_alu, get_add_result(float_alu), to_float(3.0));
                float_counter <= get_add_result(float_alu);
                counter       <= to_real(get_add_result(float_alu));

                multiply(float_alu2, get_multiplier_result(float_alu2), to_float(0.5));
                float_counter2 <= get_multiplier_result(float_alu2);
                counter2       <= to_real(get_multiplier_result(float_alu2));
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
