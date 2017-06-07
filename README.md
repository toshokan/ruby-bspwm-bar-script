# ruby-bspwm-bar-script
A complete and easily extendable bspwm / lemonboy bar panel script. Written in Ruby for speed, efficiency, and readability. 

This panel script supports multiple monitors and prints volume, battery, network throughput, and time information.

Originally based on a the example bspwm panel shell script.

## Using
1. To use this panel, add `bar_functions.rb` and `bar_parser.rb` to a directory in `$PATH` with `+x` permissions. Be sure to have Ruby installed.
2. Move `colours.yaml` to a directory you like and edit `$colour_file` in `bar_functions.rb` and `bar_parser.rb` to point to it.
3. Call `bar_functions.rb &` at startup.

