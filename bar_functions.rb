#!/usr/bin/env ruby

require 'yaml'

# ---- Config Variables ----
# Path to the unix pipe used for communication
$panel_fifo = "/tmp/panel-fifo"
# Path to yaml formatted colour list ( #{Dir.home} represents ~ )
$colour_file = "#{Dir.home}/.Xresources.d/bar-colours.yaml"
# Options passed to bar 
$panel_height = 16
$panel_font = "Kochi Gothic,東風ゴシック:style=Regular:size=9"
$panel_wm_name = "bspwm_panel"

# ---- File Preparation ----
if File.exist?($panel_fifo)
	File.delete($panel_fifo)
end
system("mkfifo #{$panel_fifo}")
$f = File.open($panel_fifo, "a+")
$f.sync = true
$c = File.open($colour_file, "r+")
$colours = YAML.load($c.read)
$c.close

# ---- Functions ----
def volume()
	# Get volume
	loop do
		amixerstr = `amixer get Master`
		volume = /[0-9]+%/.match(amixerstr)[0].chomp('%')
		if(amixerstr.include? "[on]")
			volume << '%'
		else
			volume << 'M'
		end
		$f.puts 'V' << volume
		sleep 1
	end
end

def clock()
	# Get the time
	time = Time.new
	loop do
		$f.puts 'S' << time.strftime("%d %b %H:%M")
		sleep 1
	end
end

def net()
	# Get network traffic on wired and wireless interfaces
	ethernet="enp0s25"
	wireless="wlp3s0"
	loop do
		if `ip link show "#{ethernet}"`.include?("state DOWN") and `ip link show "#{wireless}"`.include?("state DOWN") 
			net = ""
			sleep 30
		elsif `ip link show "#{ethernet}"`.include?("state UP")
			net = netHelper(ethernet)
		elsif `ip link show "#{wireless}"`.include?("state UP")
			net = netHelper(wireless)
		end
		$f.puts 'N' << net
	end
end

def netHelper(iface)
	# Calculate network traffic from sysfs stats
	rxFile = "/sys/class/net/#{iface}/statistics/rx_bytes"
	txFile = "/sys/class/net/#{iface}/statistics/tx_bytes"
	rx1 = File.read(rxFile).to_i
	tx1 = File.read(txFile).to_i
	sleep 1
	rx2 = File.read(rxFile).to_i
	tx2 = File.read(txFile).to_i
	rxNet = (rx2 - rx1)/1024
	txNet = (tx2 - tx1)/1024
	return "#{rxNet}↓↑#{txNet}"
end

def battery()
	# Get battery information
	loop do
		batt = /[0-9]+%/.match(`acpi -b`)[0].chomp('%')
		battstatus = File.read("/sys/class/power_supply/BAT0/status")
		if battstatus.include?("Discharging")
			batt << '-'
		elsif battstatus.include?("Charging")
			batt << '+'
		end
		$f.puts 'B' << batt
		sleep 10
	end
end

def windowTitle()
	# Get the window title (piped directly to $panel_fifo via a subshell)
	marker = 'T'
	system("xtitle -sf '#{marker}%s\n' -t 150 > #{$panel_fifo}")
end

def bspcSubscribe()
	# Get bspwm info (piped directly to $panel_fifo via a subshell)
	system("bspc subscribe report > #{$panel_fifo}")
end

def startBar()
	# Start bar in a subshell, receiving information formatted by bar_parser.rb
	system("bar_parser.rb < #{$panel_fifo} | lemonbar -a 32 -n #{$panel_wm_name} -g x#{$panel_height} -f \"#{$panel_font}\" -F \"#{$colours['DEFAULT_FG']}\" -B \"#{$colours['DEFAULT_BG']}\" | sh")
end

def barLayer()
	# Make sure bar is clickable but does not draw itself over fullscreen windows
	panel_ids = `xdo id -a bspwm_panel`
	root_ids = `xdo id -n root`
	panel_ids.each_line do |pid|
		root_ids.each_line do |rid|
				system("xdo above -t #{rid.chomp} #{pid.chomp}")
		end
	end
end

# ---- Main ----
# Start threads for each function
Thread.new { volume() }
Thread.new { clock() }
Thread.new { net() }
Thread.new { battery() }
Thread.new { windowTitle() }
Thread.new { bspcSubscribe() }

# For debugging, this script can write to the fifo without spawning a bar
if ARGV[0] != "n"
	# Check if the panel is already running
	if system("xdo id -a #{$panel_wm_name} >/dev/null")
		puts "The panel is already running"
		exit(1)
	end
	Thread.new { startBar() }
	sleep 1
	barLayer()
end

# Sleep forever, keeping threads active
sleep


