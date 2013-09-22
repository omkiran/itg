require 'trollop'
require 'ruby-ffmpeg'
require_relative './y4mreader'


# Stubs
def calc_blur( imageY )
    return 0;
end

def face_metric( thumb )
    return 1;
end

# 
def pixel_metrics thumbnail
    entropy    = 0.0
    brightness = 0.0
    y4m = Y4Mreader.new thumbnail[:file]
    y4m.read_header
    size = y4m.w * y4m.h
    imageY = y4m.read(size).each_char.to_a
    # Get brighness between 0 to 1
    brightness = ( imageY.map{ |x| x.ord }.reduce(:+)  / size.to_f ) / 255.0
    if brightness > 0.75 # too bright is also bad.. so we are pushing the extreme bright to low scores
        brightness = 1.0 - brightness;
    elsif brightness > 0.25 || brightness < 0.75
        brightness = 2*brightness; # Middle range is pushed to higher scores
    end
    # Get histogram of image and calulate entropy as sum(for all p)[p*log2(p)] * -1
    image_hist = imageY.group_by{ |x| x.ord }
    image_hist.each{ | k, v | image_hist[k] = v.size}
    entropy = image_hist.values.collect{ |x| (x/size.to_f) * Math.log(x/size.to_f) }.reduce(:+) * -1.0/8.0
    # Divide by 8.0 because we have 256 bins and we are not log to the base 2 but to base 10.
    {:brightness => brightness, :entropy => entropy}
end


def get_metrics( thumbs, ts, i, opts)
    thumbs.each_with_index.collect{ |t, j|
            pixel_metrics( t ).merge( { :face => 0, :blur => 0, :ts => ts[j], :chunk => i} )
    }
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
    # Now optimize for distance, correlation and face simultaneously
    # 
    best.sort[0..best.size/2].map{ |k,v| values << v }
    values
end

def intelligent_thumbs(movie, opts)
    # Divide the movie into L = 2*N parts
    ts     = []
    thumbs = []
    metrics = []
    # We start with 2x the number of chunks as required
    chunk_length = movie.duration / (2 * opts[:num] )
    # Select random timestamps for each chunk
    ts = Array.new(2*opts[:num]){ |i| Array.new(opts[:search_steps]){ |j| rand(i*chunk_length..(i+1)*chunk_length) } }
    # Now get thumbnails for each chunk
    thumbs = Array.new(ts.size){ |i| movie.thumbnails(ts[i]) }
    # Now get the metrics
    metrics = Array.new(ts.size){ |i| get_metrics( thumbs[i], ts[i], i, opts) }
    # Once metrics are available choose the best 2 from each chunk and then optimize
    final_set = optimize(metrics, opts)
end

def dumb_thumbs(movie, opts)
    chunk_length = movie.duration / opts[:num]
    (0...l).collect{ |i| rand(i*chunk_length..(i+1)*chunk_length) }
end


# Handle the input parameters
opts = Trollop::options do
    banner "Intelligent thumbnails. Omkiran Sharma (c) 2013"
    opt :input,       "Input file", :required => true,            :type => :string
    opt :num,         "Number of thumbnails",                     :type => :integer, :default => 5
    opt :act_dumb,    "Do not use intelligence,random selection", :type => :boolean, :default => false
    opt :prefix,      "Output name prefix",                       :type => :boolean
    opt :format,      "Format of output thumbnail",               :type => :string,  :default => "jpeg"
    opt :resolution,  "Resolution of output",                     :type => :string,  :default => "320x240"
    opt :search_steps,"Number of intermediate files",             :type => :integer, :default => 3
end

# For the input given, if we are to act dumb, sample randomly and be done
movie    = FFMPEG::Movie.new( opts[:input] )
duration = movie.duration
final_set = opts[:act_dumb] ? dumb_thumbs( movie, opts ) : intelligent_thumbs( movie, opts )
system("rm *.y4m")
thumbs = movie.thumbnails(final_set, { :format => opts[:format], :prefix => opts[:prefix], :resolution => opts[:resolution] } )
