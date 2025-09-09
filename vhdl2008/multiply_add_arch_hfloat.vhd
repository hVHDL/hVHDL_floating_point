architecture hfloat of multiply_add is

    use work.normalizer_generic_pkg.all;
    use work.denormalizer_generic_pkg.all;
    use work.float_adder_pkg.all;
    use work.float_multiplier_pkg.all;

    constant g_exponent_length : natural := g_floatref.exponent'length;
    constant g_mantissa_length : natural := g_floatref.mantissa'length;

    constant float_zero : float_record := (
            sign       => '0'
            , exponent => (g_exponent_length-1 downto 0 => (g_exponent_length-1 downto 0 => '0'))
            , mantissa => (g_mantissa_length-1 downto 0 => (g_mantissa_length-1 downto 0 => '0')));

    constant init_normalizer : normalizer_record := normalizer_typeref(2, floatref => float_zero);
    signal normalizer : init_normalizer'subtype := init_normalizer;

    constant init_adder : float_adder_record := adder_typeref(2, float_zero);
    signal adder : init_adder'subtype := init_adder;

    constant init_multiplier : float_multiplier_record := multiplier_typeref(float_zero);
    signal multiplier : init_multiplier'subtype := init_multiplier;

    constant init_float_array : float_array(2 downto 0) := (2 downto 0 => float_zero);
    signal add_array : init_float_array'subtype := init_float_array;

begin


    mpya_out.is_ready <= '1' when normalizer_is_ready(normalizer) else '0';
    mpya_out.result   <= to_std_logic(get_normalizer_result(normalizer));

    process(clock) is
    begin
        if rising_edge(clock) 
        then
            create_normalizer(normalizer);
            create_adder(adder);
            create_float_multiplier(multiplier);

            add_array <= add_array(add_array'high-1 downto 0) & float_zero;

            if mpya_in.is_requested = '1' then
                request_float_multiplier(multiplier
                ,to_float(mpya_in.mpy_a, float_zero)
                ,to_float(mpya_in.mpy_b, float_zero));
                add_array(0) <= to_float(mpya_in.add_a, float_zero);
            end if;

            if float_multiplier_is_ready(multiplier) then
                request_add(adder
                ,get_multiplier_result(multiplier)
                ,add_array(add_array'high));
            end if;

            if adder_is_ready(adder) 
            then
                request_normalizer(normalizer, get_result(adder));
            end if;

        end if; -- rising edge
    end process;

end hfloat;
