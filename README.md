# ruby-bspwm-bar-script
An extension of the bspwm / lemonboy bar example script with added functionality. Ported to Ruby for speed, efficiency, and readability.

This panel script supports multiple monitors and prints volume, battery, network throughput, and time information.

## Using
1. To use this panel, add `bar_functions.rb` and `bar_parser.rb` to a directory in `$PATH` with `+x` permissions. Be sure to have Ruby installed.
2. Move `colours.yaml` to a directory you like and edit `$colour_file` in `bar_functions.rb` and `bar_parser.rb` to point to it.
3. Call `bar_functions.rb &` at startup.

