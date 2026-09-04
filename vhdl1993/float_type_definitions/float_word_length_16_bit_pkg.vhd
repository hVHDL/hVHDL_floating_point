library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    -- configure word lengths to 8 bit exponent with 16 bit mantissa

package float_word_length_pkg is

    constant mantissa_bits : integer := 16;
    constant exponent_bits : integer := 8;

end package float_word_length_pkg;

