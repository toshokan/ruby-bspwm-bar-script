#!/usr/bin/env ruby

require 'json'
require 'open3'

# ---- Config Variables ----
# Path to the unix pipe used for communication
$panel_fifo = "/tmp/panel-fifo"
# Path to JSON formatted colour list ( #{Dir.home} represents ~ )
$colour_file = "#{Dir.home}/.Xresources.d/bar-colours.json"
# Options passed to bar 
$panel_height = 16
$panel_font = "Kochi Gothic,東風ゴシック:style=Regular:size=9"
$panel_wm_name = "bspwm_panel"

# ---- File and Environment Preparation ----
if File.exist?($panel_fifo)
	File.delete($panel_fifo)
end
system("mkfifo #{$panel_fifo}")
$f = File.open($panel_fifo, "a+")
$f.sync = true
$c = File.open($colour_file, "r+")
$colours = JSON.parse($c.read, symbolize_names: true)
$c.close

$pids = Array.new
Process.setproctitle("bar_functions")

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
	loop do
		$f.puts 'S' << Time.now.strftime("%d %b %H:%M")
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
	# Get the window title
	marker = 'T'
  Open3.popen2("xtitle -sf \"#{marker}%s\n\" -t 150") do |stdin, stdout, status|
    $pids.push status.pid
    stdout.each_line do |line|
      $f.puts line
    end
  end
end

def bspcSubscribe()
	# Get bspwm info
  Open3.popen2("bspc subscribe report") do |stdin, stdout, status|
    $pids.push status.pid
    stdout.each_line do |line|
      $f.puts line
    end
  end
end

def startBar()
  # Use pipes on bar_parser.rb and lemonbar to print parsed information to bar 
  lemonbarCmd = "lemonbar -a 32 -n #{$panel_wm_name} -g x#{$panel_height} -f \"#{$panel_font}\" -F \"#{$colours[:DEFAULT_FG]}\" -B \"#{$colours[:DEFAULT_BG]}\""
  parsepipe = IO.popen("bar_parser.rb", "r+")
  lemonpipe = IO.popen(lemonbarCmd, "r+")
  shpipe = IO.popen("sh", "w")

  fpid = fork do
    while line = lemonpipe.gets do
      shpipe.puts line
    end
  end

  $pids.push fpid

  while line = $f.readline do
    parsepipe.puts line
    lemonpipe.puts parsepipe.gets
  end
end

def barLayer()
	# Make sure bar is clickable but does not draw itself over fullscreen windows
	panel_ids = `xdo id -a bspwm_panel`
	root_ids = `xdo id -n root`
	panel_ids.each_line do |pid|
		root_ids.each_line do |rid|
			system("xdo below -t #{rid.chomp} #{pid.chomp}")
		end
	end
	panel_ids.each_line do |pid|
		root_ids.each_line do |rid|
			system("xdo above -t #{rid.chomp} #{pid.chomp}")
		end
	end
end

def cleanup()
  # Kill child processes and exit cleanly
  $pids.each do |pid|
    Process.kill("TERM", pid)
  end
  exit 0
end

# ---- Main ----
# Register signal handler
Signal.trap("TERM") { cleanup() }
Signal.trap("INT") { cleanup() }

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
