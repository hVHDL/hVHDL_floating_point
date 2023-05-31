library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use work.float_type_definitions_pkg.all;
    use work.float_to_real_conversions_pkg.all;
    use work.float_alu_pkg.all;

package float_first_order_filter_pkg is

------------------------------------------------------------------------
    type first_order_filter_record is record
        filter_counter   : integer range 0 to 7 ;
        u                : float_record;
        y                : float_record;
        filter_is_ready : boolean;
    end record;

    constant init_first_order_filter : first_order_filter_record := (
        7, to_float(0.0), to_float(0.0), false);

------------------------------------------------------------------------
    procedure create_first_order_filter (
        signal self : inout first_order_filter_record;
        signal alu_object                : inout float_alu_record;
        filter_gain                      : in float_record);

------------------------------------------------------------------------
    procedure request_float_filter (
        signal self : inout first_order_filter_record;
        filter_data : in float_record);

------------------------------------------------------------------------
    function float_filter_is_ready ( self : first_order_filter_record)
        return boolean;
------------------------------------------------------------------------
    function get_filter_output ( self : first_order_filter_record)
        return float_record;
------------------------------------------------------------------------
end package float_first_order_filter_pkg;

package body float_first_order_filter_pkg is

------------------------------------------------------------------------
    procedure create_first_order_filter
    (
        signal self : inout first_order_filter_record;
        signal alu_object                : inout float_alu_record;
        filter_gain                      : in float_record
        
    ) is
    begin

        CASE self.filter_counter is
            WHEN 0 => 
                subtract(alu_object, self.u, self.y);
                self.filter_counter <= self.filter_counter + 1;
                self.filter_is_ready <= false;
            WHEN 1 =>
                self.filter_is_ready <= false;
                if add_is_ready(alu_object) then
                    multiply(alu_object  , get_add_result(alu_object) , filter_gain);
                    self.filter_counter <= self.filter_counter + 1;
                end if;

            WHEN 2 =>
                self.filter_is_ready <= false;
                if multiplier_is_ready(alu_object) then
                    add(alu_object, get_multiplier_result(alu_object), self.y);
                    self.filter_counter <= self.filter_counter + 1;
                end if;
            WHEN 3 => 
                if add_is_ready(alu_object) then
                    self.filter_is_ready <= true;
                    self.y <= get_add_result(alu_object);
                    self.filter_counter <= self.filter_counter + 1;
                else
                    self.filter_is_ready <= false;
                end if;
            WHEN others =>  -- filter is ready
        end CASE;
    end create_first_order_filter;
------------------------------------------------------------------------
    procedure request_float_filter
    (
        signal self : inout first_order_filter_record;
        filter_data : in float_record
    ) is
    begin

        self.u <= filter_data;
        self.filter_counter <= 0;
        
    end request_float_filter;
------------------------------------------------------------------------
    function float_filter_is_ready
    (
        self : first_order_filter_record
    )
    return boolean
    is
    begin
        return self.filter_is_ready;
    end float_filter_is_ready;
------------------------------------------------------------------------
    function get_filter_output
    (
        self : first_order_filter_record
    )
    return float_record
    is
    begin
        return self.y;
    end get_filter_output;

end package body float_first_order_filter_pkg;
