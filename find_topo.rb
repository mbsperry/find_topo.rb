require 'pry'
require 'gpx'
require_relative 'point'

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
  # Uses 8 minutes for default width, even though this is not technically
  # correct. Would be better to use 7.5, but I have no way of knowing 
  # from the map name if the corner is at 0 or 30 seconds.
  
  w = 7.5/60
  offset = 0.5/60

  y_dms = (map_num[0..3]+"00").to_i
  y = to_decimal(y_dms)
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

def contains_point?(lat, long, bounds)
  if bounds[0] < long && long < bounds[1]
    if bounds[2] < lat && lat < bounds[3]
      return true
    end
  end
  false
end

def find_map(lat, long, map_names)
  map_names.each do |name|
    map_num = name[/\d*/]
    bounds = get_map_bounds(map_num)
    return name if contains_point?(lat, long, bounds)
  end
  false
end

def main
  map_names = load_names


  maps = []

  gpx = GPX::GPXFile.new(:gpx_file => 'export.gpx')
  gpx.routes[0].points.each do |pt|
    maps.push find_map(pt.lat, pt.lon.abs, map_names)
  end

  puts maps.uniq

end

main



