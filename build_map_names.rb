require 'curb'

def build_topo_names
  #  topo_regex = "(.*)\.zip"
  #  dir_regex = "(\d*)."

  directories = []
  map_names = []

  http = Curl.get("http://fsgeodata.fs.fed.us/rastergateway/data/")
  http.body_str.scan(/"(\d*)."/) do |match|
    directories.push match
  end
  
  directories.shift
  directories.each do |dir|
    url = "http://fsgeodata.fs.fed.us/rastergateway/data/#{dir[0]}/fstopo/"
    puts url
    http = Curl.get(url)
    http.body_str.scan(/"(.*)\.zip"/) do |match|
      map_names.push match
    end
  end

  map_names
end

def write_to_file
  map_names = build_topo_names

  File.open('map_names.txt', 'w') do |file|
    map_names.each do |name|
      file.puts name
    end
  end
end

write_to_file
