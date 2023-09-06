library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    -- configure word lengths to 5 bit exponent with 15 bit mantissa

package float_word_length_pkg is

    constant mantissa_bits : integer := 15;
    constant exponent_bits : integer := 5;

end package float_word_length_pkg;

