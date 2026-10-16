library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use work.multiply_add_pkg.all;

-- quarter wave lookup table sine in IEEE binary32, the floating point
-- counterpart of hVHDL_fixed_point's lut_sine_pkg : the same quarter wave
-- symmetry and the same linear interpolation between table points, done as
-- a single multiply-add, here in floating point on a multiply_add entity
-- whose operands are IEEE binary32 (the agilex architecture, the native
-- floating point DSP block).
--
-- the interpolation point + slope * fraction needs the fraction as a float.
-- instead of normalizing it, the fraction bits are placed in the mantissa of
-- a float with the exponent of 1.0, which gives 1.0 + fraction exactly, and
-- the table holds point - slope in place of the point :
--
--     sine = slope * (1.0 + fraction) + (point - slope)
--
-- the sign of the negative half wave is put on the table values before the
-- multiply-add, so the result needs nothing done to it afterwards.
package float_lut_sine_pkg is

    -- angle is a 32 bit unsigned fraction of a full turn : 0 => 0 rad, 2**32 => 2*pi rad
    constant angle_word_length : natural := 32;
    constant address_width     : natural := 8;
    constant fraction_width    : natural := angle_word_length - 2 - address_width;
    constant number_of_entries : natural := 2**address_width;

    subtype float32_slv is std_logic_vector(31 downto 0);
    type float_sine_table_array is array (natural range <>) of float32_slv;

    -- the multiply-add's operands : mpy_a * mpy_b + add_a
    type sine_operands_record is record
        slope             : float32_slv;
        one_plus_fraction : float32_slv;
        offset            : float32_slv;
    end record;

------------------------------------------------------------------------
    -- real <-> binary32 bits, for the tables and for testbenches ; normal
    -- numbers only (no subnormals, infinities or NaNs)
    function to_float32_slv ( number : real)
        return float32_slv;
------------------------------------------------------------------------
    function to_real ( float32 : float32_slv)
        return real;
------------------------------------------------------------------------
    function calculate_offset_lut ( number_of_entries : natural)
        return float_sine_table_array;
------------------------------------------------------------------------
    function calculate_slope_lut ( number_of_entries : natural)
        return float_sine_table_array;
------------------------------------------------------------------------
    -- quarter wave symmetry : the index used to read both luts for a given
    -- angle (the angle is mirrored first when its quadrant is odd)
    function get_quarter_index ( angle : unsigned(angle_word_length-1 downto 0))
        return natural;
------------------------------------------------------------------------
    -- the multiply-add's operands for the sine of angle
    function get_sine_operands ( angle : unsigned(angle_word_length-1 downto 0))
        return sine_operands_record;
------------------------------------------------------------------------
    -- starts the sine of angle on a multiply_add entity ; the sine is its
    -- result (get_mpya_result) once mpya_is_ready
    procedure request_sine (
        signal self_in : out multiply_add_in_record;
        angle : unsigned(angle_word_length-1 downto 0));
------------------------------------------------------------------------
    -- what the multiply-add computes from the operands, in real arithmetic :
    -- a model for testbenches
    function get_sine_from_quarter_wave_lut ( angle : unsigned(angle_word_length-1 downto 0))
        return real;
------------------------------------------------------------------------

    -- deferred constants : values are given in the package body, once the
    -- generator functions above have been elaborated
    constant offset_lut : float_sine_table_array(0 to number_of_entries-1);
    constant slope_lut  : float_sine_table_array(0 to number_of_entries-1);

------------------------------------------------------------------------
end package float_lut_sine_pkg;

package body float_lut_sine_pkg is
------------------------------------------------------------------------
    function to_float32_slv
    (
        number : real
    )
    return float32_slv
    is
        constant magnitude : real := abs(number);
        variable exponent  : integer;
        variable mantissa  : integer;
        variable result    : float32_slv := (others => '0');
    begin
        if magnitude = 0.0 then
            return result;
        end if;

        -- log2 may land one off at exact powers of two
        exponent := integer(floor(log2(magnitude)));
        if 2.0**exponent > magnitude then
            exponent := exponent - 1;
        end if;
        if 2.0**(exponent+1) <= magnitude then
            exponent := exponent + 1;
        end if;

        -- 24 bits with the hidden one, rounded to nearest
        mantissa := integer(round(magnitude / 2.0**exponent * 2.0**23));
        if mantissa = 2**24 then
            mantissa := 2**23;
            exponent := exponent + 1;
        end if;
        assert exponent >= -126 and exponent <= 127
            report "to_float32_slv : " & real'image(number) & " is out of the normal range"
            severity failure;

        if number < 0.0 then
            result(31) := '1';
        end if;
        result(30 downto 23) := std_logic_vector(to_unsigned(exponent + 127, 8));
        result(22 downto 0)  := std_logic_vector(to_unsigned(mantissa - 2**23, 23));
        return result;

    end to_float32_slv;
------------------------------------------------------------------------
    function to_real
    (
        float32 : float32_slv
    )
    return real
    is
        constant exponent : integer := to_integer(unsigned(float32(30 downto 23)));
        constant mantissa : real    := real(to_integer(unsigned(float32(22 downto 0)))) / 2.0**23;
        variable result   : real;
    begin
        if exponent = 0 then
            return 0.0;
        end if;
        result := (1.0 + mantissa) * 2.0**(exponent - 127);
        if float32(31) = '1' then
            return -result;
        else
            return result;
        end if;

    end to_real;
------------------------------------------------------------------------
    function quarter_wave_point
    (
        i : natural;
        number_of_entries : natural
    )
    return real
    is
    begin
        return sin(math_pi/2.0 * real(i)/real(number_of_entries));
    end quarter_wave_point;
------------------------------------------------------------------------
    function calculate_offset_lut
    (
        number_of_entries : natural
    )
    return float_sine_table_array
    is
        variable result : float_sine_table_array(0 to number_of_entries-1);
        variable this_point, next_point : real;
    begin
        for i in 0 to number_of_entries-1 loop
            this_point := quarter_wave_point(i, number_of_entries);
            next_point := quarter_wave_point(i+1, number_of_entries);
            result(i) := to_float32_slv(this_point - (next_point - this_point));
        end loop;
        return result;

    end calculate_offset_lut;
------------------------------------------------------------------------
    function calculate_slope_lut
    (
        number_of_entries : natural
    )
    return float_sine_table_array
    is
        variable result : float_sine_table_array(0 to number_of_entries-1);
    begin
        for i in 0 to number_of_entries-1 loop
            result(i) := to_float32_slv(quarter_wave_point(i+1, number_of_entries) - quarter_wave_point(i, number_of_entries));
        end loop;
        return result;

    end calculate_slope_lut;
------------------------------------------------------------------------
    -- the next-to-top bit tells whether the quadrant is odd, in which case
    -- the quarter wave lut must be traversed backwards (quarter wave symmetry) ;
    -- not exported, used to build the quarter index and the fraction
    function get_phase_in_quadrant
    (
        angle : unsigned(angle_word_length-1 downto 0)
    )
    return unsigned
    is
    begin
        if angle(angle_word_length-2) = '1' then
            return not angle(angle_word_length-3 downto 0);
        else
            return angle(angle_word_length-3 downto 0);
        end if;

    end get_phase_in_quadrant;
------------------------------------------------------------------------
    function get_quarter_index
    (
        angle : unsigned(angle_word_length-1 downto 0)
    )
    return natural
    is
    begin
        return to_integer(get_phase_in_quadrant(angle)(angle_word_length-3 downto fraction_width));

    end get_quarter_index;
------------------------------------------------------------------------
    function get_sine_operands
    (
        angle : unsigned(angle_word_length-1 downto 0)
    )
    return sine_operands_record
    is
        -- top bit tells whether the sine is in the negative half of the wave
        constant is_negative   : std_logic := angle(angle_word_length-1);
        constant quarter_index : natural range 0 to number_of_entries-1 := get_quarter_index(angle);
        constant fraction      : unsigned(fraction_width-1 downto 0) := get_phase_in_quadrant(angle)(fraction_width-1 downto 0);
        variable result        : sine_operands_record;
    begin
        -- 1.0 + fraction : the exponent of 1.0, the fraction as the mantissa's top bits
        result.one_plus_fraction := (others => '0');
        result.one_plus_fraction(30 downto 23) := "01111111";
        result.one_plus_fraction(22 downto 23-fraction_width) := std_logic_vector(fraction);

        result.slope  := slope_lut(quarter_index);
        result.offset := offset_lut(quarter_index);
        -- the negative half wave : both negated, so the result is
        result.slope(31)  := result.slope(31) xor is_negative;
        result.offset(31) := result.offset(31) xor is_negative;
        return result;

    end get_sine_operands;
------------------------------------------------------------------------
    procedure request_sine
    (
        signal self_in : out multiply_add_in_record;
        angle : unsigned(angle_word_length-1 downto 0)
    ) is
        constant operands : sine_operands_record := get_sine_operands(angle);
    begin
        multiply_add(self_in, operands.slope, operands.one_plus_fraction, operands.offset);
    end request_sine;
------------------------------------------------------------------------
    function get_sine_from_quarter_wave_lut
    (
        angle : unsigned(angle_word_length-1 downto 0)
    )
    return real
    is
        constant operands : sine_operands_record := get_sine_operands(angle);
    begin
        return to_real(operands.slope) * to_real(operands.one_plus_fraction) + to_real(operands.offset);
    end get_sine_from_quarter_wave_lut;
------------------------------------------------------------------------
    constant offset_lut : float_sine_table_array(0 to number_of_entries-1) := calculate_offset_lut(number_of_entries);
    constant slope_lut  : float_sine_table_array(0 to number_of_entries-1) := calculate_slope_lut(number_of_entries);
------------------------------------------------------------------------
end package body float_lut_sine_pkg;
