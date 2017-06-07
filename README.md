# ruby-bspwm-bar-script
A complete and easily extendable bspwm / lemonboy bar panel script. Written in Ruby for speed, efficiency, and readability. 

This panel script supports multiple monitors and prints volume, battery, network throughput, and time information.

Originally based on an example bspwm panel shell script.

## Dependencies
* [Ruby](https://www.ruby-lang.org/en/)
* [Lemonboy bar](https://github.com/LemonBoy/bar) or [krypt-n fork](https://github.com/krypt-n/bar) if you want xft fonts
* [Bspwm](https://github.com/baskerville/bspwm)
* [xdo](https://github.com/baskerville/xdo) for panel positioning and layering 
* [xtitle](https://github.com/baskerville/xtitle) for getting window titles

## Using
1. To use this panel, add `bar_functions.rb` and `bar_parser.rb` to a directory in `$PATH` with `+x` permissions. Be sure to have Ruby installed.
2. Move `colours.yaml` to a directory you like and edit `$colour_file` in `bar_functions.rb` and `bar_parser.rb` to point to it.
3. Call `bar_functions.rb &` at startup.

## Screenshot
Visit the wiki to see a simple screenshot of what you can expect with a default configuration

