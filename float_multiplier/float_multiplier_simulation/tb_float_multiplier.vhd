LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.register_operations_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity tb_float_multiplier is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_float_multiplier is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    constant bit_width : integer := 23;

------------------------------------------------------------------------
    function mult
    (
        left,right : natural
    )
    return unsigned 
    is
        variable result : unsigned(bit_width*2+1 downto 0) := (others => '0');

    begin
        result := to_unsigned(left, bit_width+1) * to_unsigned(right,bit_width+1);
        
        return result(45 downto 23);
    end mult;

------------------------------------------------------------------------
    function "*"
    (
        left, right : float_record
    ) return float_record
    is
        variable result : float_record := zero;
    begin

        result.sign     := left.sign xor right.sign;
        result.exponent := left.exponent + right.exponent;
        result.mantissa := mult(to_integer(left.mantissa) , to_integer(right.mantissa));
        return result;
        
    end function;

------------------------------------------------------------------------
    function "-"
    (
        right : float_record
    )
    return float_record
    is
        variable returned_float : float_record;
    begin
         returned_float := (sign     => not right.sign,
                            exponent => right.exponent,
                            mantissa => right.mantissa);
        return returned_float;
    end "-";

------------------------------------------------------------------------
    signal test : unsigned(22 downto 0) := mult(2**24-1, (2**23));
    signal float1 : float_record := ("0", to_signed(0,8), (22 => '1', others => '0'));
    signal float2 : float_record := ("0", to_signed(0,8), (22 => '1', others => '0'));
    signal float_resutl : float_record := normalize(-float1 * (-float2));

------------------------------------------------------------------------

------------------------------------------------------------------------
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


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
