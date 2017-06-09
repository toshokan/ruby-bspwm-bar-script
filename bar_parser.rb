#!/usr/bin/env ruby

require 'yaml'

# ---- Config Variables ----
# Path to yaml formatted colour list ( #{Dir.home} represents ~ )
$colour_file = "#{Dir.home}/.Xresources.d/bar-colours.yaml"

# ---- File Preparation ----
$c = File.open($colour_file, "r+")
$colours = YAML.load($c.read)
$c.close
# Flush stdout immediately
STDOUT.sync = true

# ---- Functions ----
def colourWrapper(fg, bg, data, params={})
	# Wrap data in lemonbar markup, with optional clickable element
	if !params[:click]
		"%{F#{fg}}%{B#{bg}} #{data} %{B-}%{F-}"
	else
		"%{F#{fg}}%{B#{bg}}%{A:#{params[:click]}:} #{data} %{A}%{B-}%{F-}"
	end
end


# ---- Main ----
# Get number of monitors and initialize an array to hold their properties
$numMonitors = `bspc query -M`.lines.count
$wm_array = Array.new($numMonitors)

# Loop over STDIN
while line = gets
	data = line[1..-1].chomp
	case line
		when /^N/
			# Network information
			net = colourWrapper($colours[:SYS_FG], $colours[:SYS_BG], data)
		when /^B/
			# Battery Information
			batt = colourWrapper($colours[:SYS_FG], $colours[:SYS_BG], data)
		when /^V/
			# Volume Information
			vol = colourWrapper($colours[:SYS_FG], $colours[:SYS_BG], data)
		when /^S/
			# Clock Information
			sys = colourWrapper($colours[:SYS_FG], $colours[:SYS_BG], data, click:"notify-send \"\`cal\`\"")
		when /^T/
			# Window Title Information
			title = colourWrapper($colours[:SYS_FG], $colours[:SYS_BG], data)
		when /^W/
			# Bspwm State Information
			wm=""
			cur_mon=-1
			desktop_num=0
			data.split(":").each do |item|
				name = item[1..-1].chomp
				case item
					when /^[mM]/
						if $numMonitors < 2
							next
						end
						case item
							when /^m/
								# Inactive monitor
								cur_mon+=1
								wm=""
								fg=$colours[:MONITOR_FG]
								bg=$colours[:MONITOR_BG]
							when /^M/
								# Active monitor
								cur_mon+=1
								wm=""
								fg=$colours[:FOCUSED_MONITOR_FG]
								bg=$colours[:FOCUSED_MONITOR_BG]
						end
						wm = wm << colourWrapper(fg,bg,name,click:"bspc monitor -f #{name}")
					when /^[fFoOuU]/
						case item
							when /^f/
								# Free desktop
								fg=$colours['FREE_FG']
								bg=$colours['FREE_BG']
								desktop_num+=1
							when /^F/
								# Focused free desktop
								fg=$colours[:FOCUSED_FREE_FG]
								bg=$colours[:FOCUSED_FREE_BG]
								desktop_num+=1
							when /^o/
								# occupied desktop
								fg=$colours[:OCCUPIED_FG]
								bg=$colours[:OCCUPIED_BG]
								desktop_num+=1
							when /^O/
								# Focused occupied desktop
								fg=$colours[:FOCUSED_OCCUPIED_FG]
								bg=$colours[:FOCUSED_OCCUPIED_BG]
								desktop_num+=1
							when /^u/
								# urgent desktop
								fg=$colours[:URGENT_FG]
								bg=$colours[:URGENT_BG]
								desktop_num+=1
							when /^U/
								# Focused urgent desktop
								fg=$colours[:FOCUSED_URGENT_FG]
								bg=$colours[:FOCUSED_URGENT_BG]
								desktop_num+=1
						end
						wm = wm << colourWrapper(fg,bg,name,click:"bspc desktop -f ^#{desktop_num}")
					when /^[LTG]/
						# Layout, State, and Flags
						wm = wm << colourWrapper($colours[:STATE_FG],$colours[:STATE_BG],name)
				end
				$wm_array[cur_mon]=wm
			end	
	end

	if $numMonitors > 1
		print "%{l}#{$wm_array[0]}%{c}#{title}%{r}#{net} | #{batt} | #{vol} | #{sys}"
		print "%{S+}%{l}#{$wm_array[1]}%{c}#{title}%{r}#{net} | #{batt} | #{vol} |  #{sys}\n"
	else
		print "%{l}#{$wm_array[0]}%{c}#{title}%{r}#{net} | #{batt} | #{vol} | #{sys}\n"
	end

end
	
