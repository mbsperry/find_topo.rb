#!/usr/bin/env ruby

require 'gpx'
require 'optparse'
require 'ostruct'
require 'open3'
require 'pp'

# This is a simple utility that takes either a GPX track or a single
# point and fingures out which USFS topo maps containt the track/point.
# Outputs a list a map names which can be downloaded from:
# http://fsgeodata.fs.fed.us/rastergateway/states-regions/regions.php
#
# Maintainer: mbsperry at gmail

# All boundary/box datastructures cheat: [xmin,xmax,ymin,ymax] instead of 
# polygon/point structures
#
# UTM coordinates default to easting,northing
# Degree coordinates default to latitude, longitude


def load_names
  names = []

  File.open("map_names.txt", 'r') do |file|
    while line = file.gets
      names.push line
    end
  end

  names
end

def to_decimal(x)
  deg,minsec = x.divmod(10000)
  min,sec = minsec.divmod(100)
  deg + min/60.0 + sec/3600.0
end

def get_map_bounds(map_num)
  # Correctly assigns boundaries based on 7.5 quad width 
  w = 7.5/60
  offset = 0.5/60

  # Make sure to add 00 for the seconds position
  y_dms = (map_num[0..3]+"00").to_i
  y = to_decimal(y_dms)

  # check if corner is evenly divisble by 7.5, if not add offset
  unless y % w == 0
    y += offset
  end
  y2 = y + w

  x_dms = (map_num[4..8]+"00").to_i
  x = to_decimal(x_dms)
  unless x % w == 0
    x += offset
  end
  x2 = x + w

  [x,x2,y,y2]
end

def find_map_by_point(lat, long, map_names)
  map_names.each do |name|
    
    # Extract the latlon number from each name
    map_num = name[/\d*/]
    bounds = get_map_bounds(map_num)

    #contains_point? requires the point to be in x,y format
    return name if contains_point?(bounds, [long.to_f.abs,lat.to_f.abs])
  end
  false
end

def find_map_by_bound(track_bound, map_names)
  maps = []

  map_names.each do |name|
    
    # Extract the latlon number from each name
    map_num = name[/\d*/]
    bounds = get_map_bounds(map_num)
    maps.push name if intersects?(track_bound, bounds)
  end
  maps
end

def assign_smaller(min, x)
  min = if x < min
          x
        else
          min
        end
end

def get_track_bounds(gpx)
  min_x = 180
  max_x = 0
  min_y = 180
  max_y = 0
  gpx.routes[0].points.each do |pt|
    min_x = pt.lon.abs if pt.lon.abs < min_x
    max_x = pt.lon.abs if pt.lon.abs > max_x
    min_y = pt.lat if pt.lat < min_y
    max_y = pt.lat if pt.lat > max_y
  end

  [min_x,max_x,min_y,max_y]
end

def contains_point?(box, point)
  #box should be array [min_x,max_x,min_y,max_y]
  # point is [x,y]

  x = point[0]
  y = point[1]

  if box[0] < x && x < box[1] && box[2] < y && y < box[3]
    true
  else
    false
  end
end

# Rewritten for no particular reason
#def contains_point?(lat, long, bounds)
  #if bounds[0] < long && long < bounds[1]
    #if bounds[2] < lat && lat < bounds[3]
      #return true
    #end
  #end
  #false
#end

def intersects?(box1, box2)
  # first check to see if poly2 contains poly1's points
  # next check to see if poly1 contains poly2's points

  (0..1).each do |x|
    (2..3).each do |y|
      return true if contains_point?(box1, [box2[x],box2[y]])
    end
  end

  (0..1).each do |x|
    (2..3).each do |y|
      return true if contains_point?(box2, [box1[x],box1[y]])
    end
  end
  false
end

def utm_to_latlong(point)
  # Format for UTM is easting, northing
  # Uses gdal command line utility, which oddly requires the coordinates
  # to be supplied on stdin -- I can't seem to figure out how to give them
  # on the command line.
  
  src = "EPSG:3717"
  dst = "EPSG:4269"

  cmd = "gdaltransform -s_srs #{src} -t_srs #{dst}"

  ll_string = ""

  Open3.popen2e(cmd) do |i,o|
    i.print "#{point[0]} #{point[1]}"
    i.close
    ll_string = o.gets
  end

  #gdaltransform returns string "long lat elevation"
  latlong = ll_string.split

  [latlong[1],latlong[0]]

end

def main(options)
  map_names = load_names

  if options.use_file == true
    file_name = options.file_name

    # Error if file does not exist
    unless File.exists?(file_name)
      puts "File does not exist"
      return false
    end

    gpx = GPX::GPXFile.new(:gpx_file => file_name)
    track_bound = get_track_bounds(gpx)
    maps = find_map_by_bound(track_bound, map_names)
    puts maps
  elsif options.use_point == true
    if options.proj == "latlong"
      point = options.point
    else
      point = utm_to_latlong(options.point)
    end

    map = find_map_by_point(point[0],point[1], map_names)
    puts map
  end

end

def parse(args)
  options = OpenStruct.new
  options.use_point = false
  options.use_file = true
  options.proj = "utm"

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: find_topo.rb [options] [track_file]"
    opts.separator "Maintainer: mbsperry at gmail"

    opts.separator ""
    opts.separator "Finds the USFS topo that contains the given GPX track or point"
    opts.separator "If run with no commands: reads track from 'export.gpx' file in the working directory."

    opts.separator ""
    opts.separator "Specific options:"

    opts.on("-c [PROJECTION]", "--projection [PROJECTION]", "Either 'latlong' or 'utm'. Defaults to 'utm'.") do |proj|
      options.proj = proj || "utm"
    end

    opts.on("-p X,Y", "--point X,Y", Array, "Find topo which contains the specified point") do |point|
      options.use_point = true
      options.use_file = false
      options.point = point
    end

    opts.on("-f", "--file [FILE]", "Use specified gpx file, defaults to 'export.gpx'") do |file|
      options.use_file = true
      options.file_name = file || 'export.gpx'
    end


  end

  opt_parser.parse!(args)
  options.file_name = args.pop || 'export.gpx'

  options
end

options = parse(ARGV)

# Debugging
# pp options

main(options)

