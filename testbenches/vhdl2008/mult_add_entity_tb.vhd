
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 

package multiply_add_pkg is

    type multiply_add_in_record is record
        mpy_a : std_logic_vector;
        mpy_b : std_logic_vector;
        add_a : std_logic_vector;
        is_requested : std_logic;
    end record;

    type multiply_add_out_record is record
        result : std_logic_vector;
        is_ready : std_logic;
    end record;

    procedure init_multiply_add(signal self_in : out multiply_add_in_record);

    procedure multiply_add(signal self_in : out multiply_add_in_record
        ;a : std_logic_vector
        ;b : std_logic_vector
        ;c : std_logic_vector);

end package multiply_add_pkg;

package body multiply_add_pkg is

    procedure init_multiply_add(signal self_in : out multiply_add_in_record) 
    is
    begin
        self_in.mpy_a <= (self_in.mpy_a'range => '0');
        self_in.mpy_b <= (self_in.mpy_b'range => '0');
        self_in.add_a <= (self_in.add_a'range => '0');
        self_in.is_requested <= '0';
    end procedure;

    procedure multiply_add(signal self_in : out multiply_add_in_record
        ;a : std_logic_vector
        ;b : std_logic_vector
        ;c : std_logic_vector
    ) 
    is
    begin
        self_in.mpy_a <= a;
        self_in.mpy_b <= b;
        self_in.add_a <= c;
        self_in.is_requested <= '1';
    end procedure;

    procedure multiply(signal self_in : out multiply_add_in_record
        ;a : std_logic_vector
        ;b : std_logic_vector
    ) 
    is
    begin
        self_in.mpy_a <= a;
        self_in.mpy_b <= b;
        self_in.add_a <= (self_in.add_a'range => '0');
        self_in.is_requested <= '1';
    end procedure;

    procedure add(signal self_in : out multiply_add_in_record
        ;a : std_logic_vector
        ;b : std_logic_vector
    ) 
    is
    begin
        self_in.mpy_a <= a;
        self_in.mpy_b <= a;  -- should be 1.0
        self_in.add_a <= b;
        self_in.is_requested <= '0';
    end procedure;

    procedure sub(signal self_in : out multiply_add_in_record
        ;a : std_logic_vector
        ;b : std_logic_vector
    ) 
    is
    begin
        self_in.mpy_a <= a;
        self_in.mpy_b <= a;  -- should be 1.0
        self_in.add_a <= b; -- should be inverted
        self_in.is_requested <= '0';
    end procedure;

end package body multiply_add_pkg;

LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 

    use work.multiply_add_pkg.all;
    use work.float_typedefs_generic_pkg.all;

entity multiply_add is
    generic(
        g_exponent_length  : natural := 8
        ;g_mantissa_length : natural := 24
    );
    port(clock : in std_logic
        ;mpya_in   : in multiply_add_in_record
        ;mpya_out  : out multiply_add_out_record
    );
end multiply_add;

architecture testi of multiply_add is

    use work.normalizer_generic_pkg.all;
    use work.denormalizer_generic_pkg.all;
    use work.float_adder_pkg.all;
    use work.float_multiplier_pkg.all;

    constant float_zero : float_record := (
            sign => '0'
            , exponent => (g_exponent_length-1 downto 0 => (g_exponent_length-1 downto 0 => '0'))
            , mantissa => (g_mantissa_length-1 downto 0 => (g_mantissa_length-1 downto 0 => '0')));

    constant init_normalizer : normalizer_record := normalizer_typeref(2, floatref => float_zero);
    signal normalizer : init_normalizer'subtype := init_normalizer;

    constant init_adder : float_adder_record := adder_typeref(2, float_zero);
    signal adder : init_adder'subtype := init_adder;

    constant init_multiplier : float_multiplier_record := multiplier_typeref(float_zero);
    signal multiplier : init_multiplier'subtype := init_multiplier;

begin


    mpya_out.is_ready <= '1' when normalizer_is_ready(normalizer) else '0';

    process(clock) is
    begin
        if rising_edge(clock) 
        then
            create_normalizer(normalizer);
            create_adder(adder);
            create_float_multiplier(multiplier);

            if mpya_in.is_requested = '1' then
                -- request_float_multiplier(multiplier
                -- ,to_float(mpya_in.mpy_a)
                -- ,to_float(mpya_in.mpy_b));
            end if;

            if float_multiplier_is_ready(multiplier) then
                -- request_add(adder
                -- ,get_multiplier_result(multiplier)
                -- ,to_float(mpya_in.add_a));
            end if;

            if adder_is_ready(adder) 
            then
                request_normalizer(normalizer, get_result(adder));
            end if;

        end if; -- rising edge
    end process;

end testi;


LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    
library vunit_lib;
    context vunit_lib.vunit_context;

entity mult_add_entity_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of mult_add_entity_tb is

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

    constant check_value : real := -84.5;

    use work.float_typedefs_generic_pkg.all;
    use work.normalizer_generic_pkg.all;
    use work.denormalizer_generic_pkg.all;

    constant float_zero : float_record :=(sign => '0', exponent => (7 downto 0 => x"00"), mantissa => (23 downto 0 => x"000000"));

    signal float32_conv_result : float32 := to_float32(0.0);
    signal convref : float32 := to_float32(check_value);
    signal conv_result : float_zero'subtype := float_zero;

    constant init_normalizer : normalizer_record := normalizer_typeref(2, floatref => float_zero);
    signal normalizer : init_normalizer'subtype := init_normalizer;

    constant init_denormalizer : denormalizer_record := denormalizer_typeref(2, floatref => float_zero);
    signal denormalizer : init_denormalizer'subtype := init_denormalizer;

    use work.float_adder_pkg.all;
    constant init_adder : float_adder_record := adder_typeref(2, float_zero);
    signal adder : init_adder'subtype := init_adder;

    use work.float_to_real_conversions_pkg.all;

    constant float1 : float_zero'subtype := to_float(-84.5);
    constant float2 : float_zero'subtype := to_float(1.5);
    constant float3 : float_zero'subtype := to_float(84.5/2.0);

    use work.float_multiplier_pkg.all;
    constant init_multiplier : float_multiplier_record := multiplier_typeref(float_zero);
    signal multiplier : init_multiplier'subtype := init_multiplier;


begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        check(convref = float32_conv_result);
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
            create_adder(adder);
            create_float_multiplier(multiplier);

            if simulation_counter = 0 then
                request_float_multiplier(multiplier, float1, float2);
            end if;
            
            if float_multiplier_is_ready(multiplier) then
                request_add(adder,get_multiplier_result(multiplier), float3);
            end if;

            if adder_is_ready(adder) 
            then
                request_normalizer(normalizer, get_result(adder));
            end if;

            if normalizer_is_ready(normalizer) then
                request_denormalizer(denormalizer, get_normalizer_result(normalizer), 20);
                conv_result         <= get_normalizer_result(normalizer);
                float32_conv_result <= to_ieee_float32(get_normalizer_result(normalizer));
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
