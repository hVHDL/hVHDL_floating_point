# vhdl_float
simple floating point library for synthesis in fpga coded in object oriented style. This is a synthesizable version of a floating point filter, which has been tested with most common FPGAs

```vhdl
    floating_point_filter : process(clock)
    begin
        if rising_edge(clock) then
        
            create_float_alu(float_alu);
            create_float_to_integer_converter(float_to_integer_converter);
        ------------------------------------------------------------------------
            filter_is_ready <= false;
            CASE filter_counter is
                WHEN 0 => 
                    subtract(float_alu, u, y);
                    filter_counter <= filter_counter + 1;
                WHEN 1 =>
                    if add_is_ready(float_alu) then
                        multiply(float_alu  , get_add_result(float_alu) , filter_gain);
                        filter_counter <= filter_counter + 1;
                    end if;

                WHEN 2 =>
                    if multiplier_is_ready(float_alu) then
                        add(float_alu, get_multiplier_result(float_alu), y);
                        filter_counter <= filter_counter + 1;
                    end if;
                WHEN 3 => 
                    if add_is_ready(float_alu) then
                        y <= get_add_result(float_alu);
                        filter_counter <= filter_counter + 1;
                        filter_is_ready <= true;
                    end if;
                WHEN others =>  -- wait for start
            end CASE;
        ------------------------------------------------------------------------

            if example_filter_input.filter_is_requested then
                convert_integer_to_float(float_to_integer_converter, example_filter_input.filter_input, 15);
            end if;

            if int_to_float_conversion_is_ready(float_to_integer_converter) then
                request_float_filter(float_filter, get_converted_float(float_to_integer_converter));
            end if;

            convert_float_to_integer(float_to_integer_converter, get_filter_output(float_filter), 14);

        end if; --rising_edge
    end process floating_point_filter;	

```

Also includes float to real and real to float conversion functions for simple constant assignment like

float_number <= to_float(3.14);


run all test benches with vunit+ghdl+gtkwave using

```
python vunit_run_float.py -p 8 --gtkwave-fmt ghw
```

An iir low pass filter has been tested on an example project for the hVHDL project and can be found here
https://hvhdl.readthedocs.io/en/latest/hvhdl_example_project/hvhdl_example_project.html#floating-point-filter-implementation

There is a blog post on the bit level design of the floating point module
https://hardwaredescriptions.com/floating-point-in-vhdl/

The floating point alu is also documented in
https://hardwaredescriptions.com/high-level-floating-point-alu-in-synthesizable-vhdl/
