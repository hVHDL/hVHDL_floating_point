
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    
library vunit_lib;
    use vunit_lib.run_pkg.all;

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

    type float_array is array (natural range <>) of float32;

    function to_float32 (a : real) return float32 is
    begin
        return to_float(a, float32'high);
    end to_float32;

    function get_biased_exponent(a : float32) return integer is
        constant slv_a : std_logic_vector(a'high-1 downto 0) := to_slv(a(a'high-1 downto 0));
    begin
        return to_integer(signed(slv_a(a'high-1 downto 0)));
    end get_biased_exponent;

    function get_exponent(a : float32) return integer is
    begin
        return get_biased_exponent(a) + 128;
    end get_exponent;

    function get_mantissa(a : float32) return unsigned is
        constant retval : unsigned(23 downto 0) := unsigned('1' & to_slv(a(-1 downto -23)));
    begin
        return retval;
    end get_mantissa;


    constant ctesti       : float32 := to_float32(16.0);
    signal stesti         : float32 := ctesti;
    signal test_exponent  : integer := get_biased_exponent(ctesti);
    signal test_exponent1 : integer := get_exponent(ctesti);
    signal test_mantissa  : unsigned(23 downto 0) := get_mantissa(ctesti);
    signal slv_testi      : std_logic_vector(7 downto 0) := to_slv(ctesti(7 downto 0));

    function to_float32 (a : integer; radix : integer ; bitwidth : natural; maxshift : natural) return float32 is
        constant uint_a : unsigned(bitwidth-1 downto 0) := to_unsigned(abs(a), bitwidth);
        variable exponent : signed(7 downto 0) := to_signed(radix,8);
        variable zerocount : natural := 0;
        variable retval : float32 := (others => '0');
    begin
        for i in uint_a'low to uint_a'high loop
            if uint_a(i) = '1'
            then 
                zerocount := 0;
            else
                zerocount := zerocount + 1;
            end if;
        end loop;
        exponent := exponent + zerocount + 128;


        for i in float32'range loop
            if i >=0 then
                if i < 7 then
                    retval(i) := exponent(i);
                else
                    retval(i) := '0';
                end if;
            end if;
        end loop;


        return retval;
    end to_float32;

    signal should_be_0_3 : float32 := to_float32(8e3, 16,16,0);
    signal ref : float32 := to_float32(8.0e3/2.0**16);

    use work.float_typedefs_generic_pkg.all;
    use work.normalizer_generic_pkg.all;

    constant float_zero : float_record :=(sign => '0', exponent => (7 downto 0 => x"00"), mantissa => (23 downto 0 => x"000000"));

    constant init_normalizer : normalizer_record := (
        normalizer_is_requested => "00"
        ,normalized_data => (1 downto 0 => float_zero));

    signal normalizer : init_normalizer'subtype := init_normalizer;
    signal conv_result : float_zero'subtype := float_zero;
    signal float32_conv_result : float32 := to_float32(0.0);

    function to_ieee_float32(a : float_record) return float32 is
        variable retval : float32;
        variable dingdong : a'subtype;
    begin
        dingdong :=(
        a.sign
        ,a.exponent+126
        ,shift_left(a.mantissa,1));

        retval(retval'left) := a.sign;
        for i in 0 to 7 loop
            retval(i) := dingdong.exponent(i);
        end loop;

        for i in a.mantissa'range loop
            if i-a.mantissa'high - 1 >= retval'low then
                retval(i-dingdong.mantissa'high - 1) := dingdong.mantissa(i);
            end if;
        end loop;

        return retval;
    end to_ieee_float32;

    signal convref : float32 := to_float32(4.0);

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

            create_normalizer(normalizer);

            if simulation_counter = 0 then
                to_float(normalizer, 4, 0, float_zero);
            end if;
            if normalizer_is_ready(normalizer) then
                conv_result <= get_normalizer_result(normalizer);
                float32_conv_result <= to_ieee_float32(get_normalizer_result(normalizer));
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
