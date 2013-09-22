Intelligent Thumbnailer
=======================

Select set of good thumbnails for a video.

A set of good thumbnails can be described as a collection that

* Is evenly spread across the video to be representative about the video
* Are different from each other as much as possible.
* Each thumbnail is a good i.e. satisfies the following criteria
  * Not too dark and not too bright
  * Sharp (without motion blur)
  * Has some content (not plain sky or blank wall) [Hence some entropy]
  * Ideally has a face or prefferably more than 1 but should not be closeup of face.


Current Status
--------------

Supports only entropy and brightness check. i.e. Chooses thumbnails that have high entropy and reasonable brightness. See notes below for details

Dependencies
------------

Needs ffmpeg already installed on system
Needs ruby-ffmpeg and trollop gems


Warning: Work in progress.
--------------------------
Currently supports entropy and brightness only

Coming soon
------------

* Face detection
* Blur detection
* Correlation calculation (So as to not choose frames highly correlated toe each other)

Usage
-----

         --input,  -i <s>:   Input file
           --num,  -n <i>:   Number of thumbnails (default: 5)
          --act-dumb,  -a:   Do not use intelligence,random
            --prefix,  -p:   Output name prefix
        --format,  -f <s>:   Format of output thumbnail (default: jpeg)
    --resolution,  -r <s>:   Resolution of output (default: copy)
    --search-steps:-s <s>:   Search steps (default: 3)
              --help,  -h:   Show this message


Notes
-----

Brightness: If the image is too bright or too dark, it is probably not useful. Hence if brightness where 0 to 1 where 0 is all black and 1 is all white, images between 0.25 to 0.75 are favoured the most and those from 0 to 0.25 and 0.75 to 1.0 are not.

Entropy: The more content the image has the better. So a frame with some people in it is probably better than just a plain blue sky. The plain blue sky will have very little entropy. 

Blur: Frames that have blur in them are not good canidates. They may have high entropy or reasonable brightness or even faces in them. But if they are blurry, they are not good candidates

Face: It is always perferrable to get faces if possible. Our algorithm prefers 2-3 faces over 1 face. But all faces together must not occupy more than 30% of screen space, else its probably a face blow up. 

Correlation: Ideally the thumbnails should not be very similar to each other. This is possible if scenes repeat with very high correlation between them. 


Algorithm
---------

Logically divides the video into 2N chunks where N is the number of thumbnails requested. 
Currently simply randomly chooses searchsteps number of frames within in chunk and calculates the brightness and entropy of each frame.
Selects frames with highest entropy and brightness in each chunk
Selects the top N frames from each chunk.


Changes to algorithm coming soon
Add blur detection and correlation metric. Correlation metric will try to minimize correlation between chosen frames
