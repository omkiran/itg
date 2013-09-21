require 'trollop'
require 'ruby-ffmpeg'
require_relative './y4mreader'

def calc_blur( imageY )
    return 0;
end
def face_metric( thumb )
    return 1;
end

def pixel_metrics( t )
    entropy    = 0.0
    brightness = 0.0
    y4m = Y4Mreader.new t[:file]
    y4m.read_header
    size = y4m.w * y4m.h
    imageY = y4m.read(size).each_char.to_a
    brightness = ( imageY.map{ |x| x.ord }.reduce(:+)  / size.to_f ) / 255.0
    if brightness > 0.75 # too bright is also bad.. so we are pushing the extreme bright to low scores
    elsif brightness > 0.25 || brightness < 0.75
        brightness = 2*brightness; # Middle range is pushed to higher scores
    end
    image_hist     = imageY.group_by{ |x| x.ord }
    image_hist.each do | k, v | image_hist[k] =  v.size end
    entropy = image_hist.values.collect{ |x| (x/size.to_f) * Math.log(x/size.to_f) }.reduce(:+) * -1.0/8.0
    [brightness, entropy]
end


def get_metrics( thumbs, opts , ts, i)
    metrics = []
    thumbs.each_with_index do | t, j |
        brightness, entropy = pixel_metrics( t )
        blur = 0
        face = face_metric( t )
        metrics << { :brightness => brightness, :blur => blur, :entropy => entropy, :face => face , :ts => ts[i][j], :chunk => i}
    end
    metrics
end

def optimize(metrics, opts)
# From each one choose such that the distance is maximized.
# We really have small number of them and therefore we can simply check on all..
# Select top two from each chunk
    best = {}
    # For each chunk get the best
    (opts[:num]*2).times do | i |
        m =  metrics[i].collect{ |x| x[:brightness] + x[:entropy] }
        best[m.max] = metrics[i][m.rindex(m.max)][:ts]
    end
    values = []
    puts best.size/2 
    # Now optimize for distance, correlation and face
    best.sort[0..best.size/2].map{ |k,v| values << v }
    values
end

def intelligent_thumbs(movie, opts)
    # Divide the movie into L = 2*N parts
    l = 2*opts[:num]
    ts     = []
    thumbs = []
    metrics = []
    # Select x random snapshots in each part 
    chunk_length = movie.duration / l
    (0...l).each do | i |
        ts[i] ||= []
        thumbs[i] ||= []
        thumbnails ||= []
        opts[:search_steps].times{ |j| ts[i] << rand(i*chunk_length..(i+1)*(chunk_length)) }
    end
    ts.size.times{ |i| thumbs[i] = movie.thumbnails(ts[i]) }
    # Now do a metrics check on each of the snapshots and gather them
    thumbs.size.times{ |i| metrics[i] = get_metrics( thumbs[i], opts, ts, i ) }
    # Once metrics are available choose the best 2 from each chunk and then optimize
    final_set = optimize(metrics, opts)
end

opts = Trollop::options do
    banner "Intelligent thumbnails. Omkiran Sharma (c) 2013"
    opt :input,      "Input file", :required => true,  :type => :string
    opt :num,        "Number of thumbnails",           :type => :integer, :default => 5
    opt :act_dumb,   "Do not use intelligence,random", :type => :boolean, :default => false
    opt :prefix,     "Output name prefix",             :type => :boolean
    opt :format,     "Format of output thumbnail",     :type => :string,  :default => "jpeg"
    opt :resolution, "Resolution of output",           :type => :string,  :default => "copy"
    opt :search_steps,"Search steps",                  :type => :integer, :default => 3
end

# For the input given, if we are to act dumb, sample randomly and be done
movie = FFMPEG::Movie.new( opts[:input] )
duration = movie.duration
final_set = []
if opts[:act_dumb]
    opts[:num].times do final_set << rand(0..duration) end
else
    final_set = intelligent_thumbs(movie, opts)
end
system("rm *.y4m")
thumbs = movie.thumbnails(final_set)
