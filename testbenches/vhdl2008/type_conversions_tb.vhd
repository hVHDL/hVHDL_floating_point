
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    
library vunit_lib;
    context vunit_lib.vunit_context;

entity type_conversions_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of type_conversions_tb is

    signal simulation_running  : boolean;
    signal simulator_clock     : std_logic := '0';
    constant clock_per         : time      := 1 ns;
    constant clock_half_per    : time      := 0.5 ns;
    constant simtime_in_clocks : integer   := 150;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    use ieee.float_pkg.all;

    function to_float32 (a : real) return float32 is
    begin
        return to_float(a, float32'high);
    end to_float32;

    constant check_value : real := -84.5;

    use work.float_typedefs_generic_pkg.all;
    use work.float_to_real_conversions_pkg.all;

    function to_hfloat(a : real; mantissa_length : natural := 18) return hfloat_record is
    begin
        return to_hfloat(a,8,mantissa_length);
    end to_hfloat;

    constant hfloat_zero : hfloat_record := to_hfloat(0.0);

    signal float32_conv_result : float32 := to_float32(0.0);
    signal convref             : float32 := to_float32(check_value);
    signal conv_result         : hfloat_zero'subtype := hfloat_zero;

    constant float1 : hfloat_zero'subtype := to_hfloat(-84.5);
    constant float2 : hfloat_zero'subtype := to_hfloat(1.5);
    constant float3 : hfloat_zero'subtype := to_hfloat(84.5/2.0);

    use work.float_typedefs_generic_pkg.to_ieee_float32;

    function float32_to_hfloat (a : float32; hfloatref : hfloat_record) return hfloat_record is
        variable retval : hfloatref'subtype := (
        sign => a(a'high)
        , exponent => signed(a(7 downto 0))-126
        ,mantissa => (others => '0'));
    begin
        for i in a(-1 downto -23)'range loop
            if retval.mantissa'high + i >= 0
            then
                retval.mantissa(retval.mantissa'high + i) := a(i);
            end if;
        end loop;

        retval.mantissa(retval.mantissa'high) := '1';

        return retval;

    end float32_to_hfloat;


    constant ref  : real                := math_pi;
    signal href   : hfloat_zero'subtype := to_hfloat(ref);
    constant fref : float32             := to_float32(ref);
    signal href2  : hfloat_zero'subtype := float32_to_hfloat(fref, hfloat_zero);

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
    simulator_clock <= not simulator_clock after clock_per/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
