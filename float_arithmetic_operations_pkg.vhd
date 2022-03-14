library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_multiplier_pkg.all;

package float_arithmetic_operations_pkg is

end package float_arithmetic_operations_pkg;


package body float_arithmetic_operations_pkg is

    function ">"
    (
        left, right : float_record
    )
    return float_record
    is
        variable returned_float : float_record;
    begin
        if left.sign > right.sign then
            returned_float := left;
        else
            -- add additional functions here
            returned_float := right;
        end if;

        return returned_float;
        
    end ">";

end package body float_arithmetic_operations_pkg;

