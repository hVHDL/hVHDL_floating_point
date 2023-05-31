library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_type_definitions_pkg.all;
    use work.normalizer_pipeline_pkg.normalizer_pipeline_configuration;

package normalizer_pkg is
------------------------------------------------------------------------
    alias number_of_normalizer_pipeline_stages is normalizer_pipeline_configuration;

    type normalizer_record is record
        normalizer_is_requested : std_logic_vector(number_of_normalizer_pipeline_stages downto 0);
        normalized_data         : float_array(0 to number_of_normalizer_pipeline_stages);
    end record;

    subtype float_normalizer_record is normalizer_record;

    function init_normalizer return normalizer_record;
    function init_float_normalizer return normalizer_record;
------------------------------------------------------------------------
    procedure create_normalizer (
        signal self : inout normalizer_record);
------------------------------------------------------------------------
    procedure request_normalizer (
        signal self : out normalizer_record;
        float_input : in float_record);
------------------------------------------------------------------------
    function normalizer_is_ready (self : normalizer_record)
        return boolean;
------------------------------------------------------------------------
    function get_normalizer_result ( self : normalizer_record)
        return float_record;
------------------------------------------------------------------------
    procedure to_float (
        signal self : out normalizer_record;
        int_input                : in integer;
        radix                    : in integer);
------------------------------------------------------------------------
end package normalizer_pkg;

package body normalizer_pkg is
------------------------------------------------------------------------
    function init_normalizer return normalizer_record
    is
        variable init_normalizer_is_requested : std_logic_vector(number_of_normalizer_pipeline_stages downto 0);
        variable init_normalized_data         : float_array(0 to number_of_normalizer_pipeline_stages);
    begin

        for i in 0 to number_of_normalizer_pipeline_stages loop
            init_normalizer_is_requested(i) := '0';
            init_normalized_data(i) := zero;
        end loop;

        return (normalizer_is_requested => init_normalizer_is_requested,
                normalized_data         => init_normalized_data);
        
    end init_normalizer;
------------------------------------------------------------------------
    function init_float_normalizer return normalizer_record
    is
    begin
        return init_normalizer;
        
    end init_float_normalizer;
------------------------------------------------------------------------
    procedure create_normalizer 
    (
        signal self : inout normalizer_record
    ) 
    is
    begin

        self.normalizer_is_requested(0) <= '0';
        for i in 1 to number_of_normalizer_pipeline_stages loop
            self.normalizer_is_requested(i) <= self.normalizer_is_requested(i-1);
            self.normalized_data(i)      <= normalize(self.normalized_data(i-1), mantissa_high/number_of_normalizer_pipeline_stages);
        end loop;
    end procedure;

------------------------------------------------------------------------
    procedure request_normalizer
    (
        signal self : out normalizer_record;
        float_input              : in float_record
    ) is
    begin
        self.normalizer_is_requested(self.normalizer_is_requested'low) <= '1';
        self.normalized_data(self.normalized_data'low) <= float_input;
        
    end request_normalizer;

    procedure to_float
    (
        signal self : out normalizer_record;
        int_input                : in integer;
        radix                    : in integer
    ) is
        variable float_to_be_scaled : float_record;
        variable float_sign : std_logic;
    begin
        if int_input < 0 then
            float_sign := '1';
        else
            float_sign := '0';
        end if;
        float_to_be_scaled := (sign => float_sign,
            exponent => to_signed(mantissa_length - radix, exponent_length), 
            mantissa => to_unsigned(abs(int_input), mantissa_length));

        self.normalizer_is_requested(self.normalizer_is_requested'low) <= '1';
        self.normalized_data(self.normalized_data'low) <= float_to_be_scaled;
        
    end to_float;

------------------------------------------------------------------------
    function normalizer_is_ready
    (
        self : normalizer_record
    )
    return boolean
    is
    begin
        return self.normalizer_is_requested(self.normalizer_is_requested'high) = '1';
    end normalizer_is_ready;

------------------------------------------------------------------------
    function get_normalizer_result
    (
        self : normalizer_record
    )
    return float_record
    is
    begin
        return self.normalized_data(self.normalized_data'high);
    end get_normalizer_result;
------------------------------------------------------------------------
end package body normalizer_pkg;
