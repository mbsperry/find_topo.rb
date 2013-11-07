require 'pry'
require 'gpx'
require_relative 'point'


# All boundary/box datastructures cheat: [xmin,xmax,ymin,ymax] instead of 
# polygon/point structures


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

# Rewritten 
#def contains_point?(lat, long, bounds)
  #if bounds[0] < long && long < bounds[1]
    #if bounds[2] < lat && lat < bounds[3]
      #return true
    #end
  #end
  #false
#end

def find_map_by_point(lat, long, map_names)
  map_names.each do |name|
    
    # Extract the latlon number from each name
    map_num = name[/\d*/]
    bounds = get_map_bounds(map_num)
    return name if contains_point?(lat, long, bounds)
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


def load_gpx(file_name)
  gpx = GPX::GPXFile.new(:gpx_file => file_name)
end

def main
  map_names = load_names

  file_name = 'export.gpx'
  gpx = GPX::GPXFile.new(:gpx_file => file_name)
  track_bound = get_track_bounds(gpx)
  maps = find_map_by_bound(track_bound, map_names)
  #gpx.routes[0].points.each do |pt|
    #maps.push find_map(pt.lat, pt.lon.abs, map_names)
  #end

  puts maps.uniq

end

main


