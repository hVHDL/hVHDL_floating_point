# vhdl_float
simple floating point library for synthesis in fpga coded in object oriented style. This is a synthesizable version of a floating point filter, which has been tested with fpga

```vhdl
  floating_point_filter : process(clock)

  begin
    if rising_edge(clock) then
          create_float_alu(float_alu);
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

      end if; -- rising_edge
  end process stimulus;	
```

Also includes float to real and real to float conversion functions for simple constant assignment like

float_number <= to_float(3.14);


run all test benches with vunit+ghdl+gtkwave using

python vunit_run_float.py -p 8 --gtkwave-fmt ghw

An iir low pass filter which uses the Multiplier and adder has been tested successfully on efinix trion fpga

A blog post on the library design can be found at
https://hardwaredescriptions.com/floating-point-in-vhdl/
