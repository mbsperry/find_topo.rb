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
  
  puts "============="

  directories.shift
  directories.each do |dir|
    url = "http://fsgeodata.fs.fed.us/rastergateway/data/#{dir[0]}/fstopo/"
    http = Curl.get(url)
    http.body_str.scan(/"(.*)\.zip"/) do |match|
      map_names.push match
    end
    break if map_names.length > 100
  end

  map_names
end

