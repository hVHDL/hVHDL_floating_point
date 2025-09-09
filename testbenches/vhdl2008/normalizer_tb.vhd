
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    
library vunit_lib;
    context vunit_lib.vunit_context;

entity tb_normalizer is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_normalizer is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic := '0';
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    use ieee.float_pkg.all;

    function to_float32 (a : real) return float32 is
    begin
        return to_float(a, float32'high);
    end to_float32;

    use work.float_typedefs_generic_pkg.all;
    use work.normalizer_generic_pkg.all;

    constant float_zero : hfloat_record :=(sign => '0', exponent => (7 downto 0 => x"00"), mantissa => (23 downto 0 => x"000000"));

    constant init_normalizer : normalizer_record := normalizer_typeref(2, floatref => float_zero);

    signal normalizer : init_normalizer'subtype := init_normalizer;
    signal conv_result : float_zero'subtype := float_zero;
    signal float32_conv_result : float32 := to_float32(0.0);


    signal convref : float32 := to_float32(-4.0);

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        check(convref = float32_conv_result, "conversions did not match ");
        simulation_running <= false;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

------------------------------------------------------------------------
    simulator_clock <= not simulator_clock after clock_per/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_normalizer(normalizer);

            if simulation_counter = 0 then
                to_float(normalizer, -4, 0, float_zero);
            end if;
            if normalizer_is_ready(normalizer) then
                conv_result <= get_normalizer_result(normalizer);
                float32_conv_result <= to_ieee_float32(get_normalizer_result(normalizer));
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
