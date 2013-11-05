class Point
  attr_accessor :lat
  attr_accessor :long

  def initialize(x,y)
    @lat = x
    @long = y
  end

  def to_h_m_s(x)
    h = x.floor
    m = (x % h) * 60
    s = (m % m.floor) * 60
    [h,m.floor,s.floor]
  end

end

