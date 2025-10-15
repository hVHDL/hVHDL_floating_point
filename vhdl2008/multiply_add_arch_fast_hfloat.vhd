architecture fast_hfloat of multiply_add is

    use work.normalizer_generic_pkg.all;
    use work.denormalizer_generic_pkg.all;
    use work.float_adder_pkg.all;
    use work.float_multiplier_pkg.all;

    constant g_exponent_length : natural := g_floatref.exponent'length;
    constant g_mantissa_length : natural := g_floatref.mantissa'length;

    constant hfloat_zero : hfloat_record := (
            sign       => '0'
            , exponent => (g_exponent_length-1 downto 0 => (g_exponent_length-1 downto 0 => '0'))
            , mantissa => (g_mantissa_length-1 downto 0 => (g_mantissa_length-1 downto 0 => '0')));

    constant init_normalizer : normalizer_record := normalizer_typeref(2, floatref => hfloat_zero);
    signal normalizer : init_normalizer'subtype := init_normalizer;

    constant init_adder : float_adder_record := adder_typeref(2, hfloat_zero);
    signal adder : init_adder'subtype := init_adder;

    constant init_multiplier : float_multiplier_record := multiplier_typeref(hfloat_zero);
    signal multiplier : init_multiplier'subtype := init_multiplier;

    constant init_float_array : float_array(2 downto 0) := (2 downto 0 => hfloat_zero);
    signal add_array : init_float_array'subtype := init_float_array;

    signal a , b       : hfloat_zero.mantissa'subtype                       := (others => '0');
    signal mpy_result  : unsigned(hfloat_zero.mantissa'length*2-1 downto 0) := (others => '0');
    signal mpy_result2 : unsigned(hfloat_zero.mantissa'length*2-1 downto 0) := (others => '0');

    ----------------------
    ----------------------
    function to_hfloat( s : std_logic_vector) return hfloat_record is
    begin
        return to_hfloat(s, hfloat_zero);
    end to_hfloat;
    ----------------------
    ----------------------
    impure function get_shift return unsigned is
        constant shiftwidth : integer := 
                             to_integer(
                             to_hfloat(mpya_in.mpy_a).exponent 
                             + to_hfloat(mpya_in.mpy_b).exponent 
                             - to_hfloat(mpya_in.add_a).exponent);

        constant retval : a'subtype := (0 => '1', others => '0');

    begin

        return shift_left(retval, shiftwidth + hfloat_zero.mantissa'high-2);

    end get_shift;
    ----------------------
    ----------------------
    signal ready_pipeline : std_logic_vector(1 downto 0) := (others => '0');
    ----------------------
    type exp_array is array (natural range <>) of hfloat_zero.exponent'subtype;
    signal exponent_pipeline : exp_array(1 downto 0) := (others => (others => '0'));
    ----------------------
    signal mpy_a, mpy_b : hfloat_zero.mantissa'subtype :=(others => '0');

begin

    mpya_out.is_ready <= ready_pipeline(ready_pipeline'left);
    mpya_out.result   <= to_std_logic((
                         sign      => '0'
                         ,exponent => exponent_pipeline(exponent_pipeline'left)
                         ,mantissa => (mpy_result(hfloat_zero.mantissa'length*2-1 downto hfloat_zero.mantissa'length))
                     ));
    

    process(clock) is
    begin
        if rising_edge(clock) 
        then
            create_normalizer(normalizer);
            create_adder(adder);
            create_float_multiplier(multiplier);

            ready_pipeline    <= ready_pipeline(ready_pipeline'left-1 downto 0) & mpya_in.is_requested;
            exponent_pipeline <= exponent_pipeline(exponent_pipeline'left-1 downto 0) & hfloat_zero.exponent;

            mpy_result2    <= to_hfloat(mpya_in.mpy_a).mantissa * to_hfloat(mpya_in.mpy_b).mantissa;
            mpy_result     <= a * b + mpy_result2;

            if mpya_in.is_requested = '1' then
                a <= get_shift;
                b <= to_hfloat(mpya_in.add_a).mantissa;
                exponent_pipeline(0) <= 
                             to_hfloat(mpya_in.mpy_a).exponent 
                             + to_hfloat(mpya_in.mpy_b).exponent;

            end if;

        end if; -- rising edge
    end process;

end fast_hfloat;
