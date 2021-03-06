## find_topo: The easy way to find USFS Topo maps
### Version: 1.00

It's kind of silly, but I find the USFS topo gateway really hard to
use. I always end up having to download several maps and manually go
through each one to figure out if it contains my area of interest.

find_topo is a simple utility to speed up that process.

- Can use either GPX track or a single point
- Outputs a list of USFS topo names that contain that track/point
- At http://caltopo.com/ you can mark out a trail and download the gpx
  track

#### Requirements

- [GPX gem](http://gpx.rubyforge.org/)
- [GDAL library](http://www.gdal.org) if using UTM coordinates

#### Use

- By default will open a file named 'export.gpx' in the working
  directory and output all maps that contain points in that track.
- `find_topo.rb --help` 

```
Specific options:
    -c, --projection [PROJECTION]    Either 'latlong' or 'utm'. Defaults to 'utm'.
    -p, --point X,Y                  Find topo which contains the specified point
    -f, --file [FILE]                Use specified gpx file, defaults to 'export.gpx'
```

That's it!
