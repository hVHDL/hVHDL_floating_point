library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

package float_multiplier_pkg is

    type float_record is record
        exponent : signed(7 downto 0);
        mantissa : signed(23 downto 0);
    end record;

------------------------------------------------------------------------
    function float ( real_number : real)
        return float_record;
------------------------------------------------------------------------

end package float_multiplier_pkg;

package body float_multiplier_pkg is

------------------------------------------------------------------------
        function get_data
        (
            int_number : integer;
            real_number : real
        )
        return signed 
        is
            variable returned_signed : signed(7 downto 0);
        begin
            if real_number >= 0.0 then 
                returned_signed := to_signed(int_number, 8);
            else
                returned_signed := -to_signed(int_number, 8);
            end if;

            return returned_signed;

        end get_data;
------------------------------------------------------------------------
    function float
    (
        real_number : real
    )
    return float_record
    is
        variable returned_float : float_record := ((others => '0'), (others => '0'));
        constant exp_width : integer := returned_float.exponent'high + 1;

    begin

        if abs(real_number) > 2.0 then
            returned_float.exponent := get_data(1, real_number);
        end if;

        return returned_float;
        
    end float;
------------------------------------------------------------------------

------------------------------------------------------------------------
end package body float_multiplier_pkg;
