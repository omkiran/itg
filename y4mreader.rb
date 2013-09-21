class Y4Mreader
  attr_reader :w, :h
  def initialize file_name
    @f = File.open(file_name, "rb")
  end
  def read_header
    @f.read(10)
    @w = read_until(0x20)[1..-1].to_i
    @h = read_until(0x20)[1..-1].to_i
    rest = read_until(0x0a)
  end

  def read bytes
    @f.read(bytes)
  end

  def read_until(char)
      s = []
      cnt = 0
      loop{
        l =  @f.read(1)
        break if l.ord == char
        s << l         
      }
      s.join("")
  end
end
