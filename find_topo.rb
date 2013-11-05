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

def get_map_bounds(map_num)
  # Uses 8 minutes for default width, even though this is not technically
  # correct. Would be better to use 7.5, but I have no way of knowing 
  # from the map name if the corner is at 0 or 30 seconds.

  y = (map_num[0..3]).to_i
  y2 = y + 8
  x = (map_num[4..8]).to_i
  x2 = x + 8

  [x,x2,y,y2]
end

def contains_point?(lat, long, bounds)
  if bounds[0] < long && long < bounds[1]
    if bounds[2] < lat && lat < bounds[3]
      true
    else
      false
    end
  else
    false
  end
end

def find_map(lat, long, map_names)
  map_names.each do |name|
    map_num = name[/\d*/]
    bounds = get_map_bounds(map_num)
    return name if contains_point?(lat, long, bounds)
  end
end

def main
  map_names = load_names


  map = find_map(4516,12201, map_names)

  puts map

end

main


