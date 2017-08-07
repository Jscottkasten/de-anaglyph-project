#!/usr/bin/ruby1.8

class ImageMono
    attr_reader :data, :width, :height, :stride

    def initialize(x, y, data = "")
        @width  = x
        @height = y
        @stride = x
    
        size = y * @stride

        if data.length == 0
            @data = "\0" * size
        elsif data.length != size
            puts "data length #{data.length}, size #{size}"
            raise ArgumentError "Wrong size for initialization data."
        else
            @data = data
        end
    end

    def set(x, y, c)
        @data[(y * @stride) + x] = (c & 0x000000FF)
    end

    def get(x, y)
        return @data[(y * @stride) + x]
    end

    def blit(x_here, y_here, x_there, y_there, width, height, img)
        unless img.instance_of?(ImageMono)
            raise ArgumentError "Incompatible blit source."
        end

        if ((x_there + width)  > img.width)  or
           ((y_there + height) > img.height) or
           ((x_here  + width)  > @width)     or
           ((y_here  + height) > @height)
            raise ArgumentError "Bad intersection rectangle."
        end

        nbytes  = width
        p_here  = x_here  + (y_here  * @stride)
        p_there = x_there + (y_there * img.stride)

        height.times do
            @data[p_here, nbytes] = img.data[p_there, nbytes]

            p_here  += @stride
            p_there += img.stride
        end
    end
end

class ImageRGB
    attr_reader :data, :width, :height, :stride

    def initialize(x, y, data = "")
        @width  = x
        @height = y
        @stride = x * 3
    
        size = y * @stride

        if data.length == 0
            @data = "\0" * size
        elsif data.length != size
            raise ArgumentError "Wrong size for initialization data."
        else
            @data = data
        end
    end

    def set(x, y, c)
        pos = (y * @stride) + (x * 3)

        # R, G, B
        @data[pos    ] = (c & 0x00FF0000) >> 16
        @data[pos + 1] = (c & 0x0000FF00) >>  8
        @data[pos + 2] = (c & 0x000000FF)
    end

    def get(x, y)
        pos = (y * @stride) + (x * 3)

        # R, G, B
        return ((@data[pos] << 16) | (@data[pos + 1] << 8) | (@data[pos + 2]))
    end

    def ycbcr
        data = "\0" * (@stride * @height)
        pos  = 0

        r    = 0
        g    = 0
        b    = 0

        y    = 0
        cb   = 0
        cr   = 0

        while pos < @data.length
            r = @data[pos    ]
            g = @data[pos + 1]
            b = @data[pos + 2] 

            y  =   0.0 + (0.299000 * r) + (0.587000 * g) + (0.114000 * b)
            cb = 128.0 - (0.168736 * r) - (0.331264 * g) + (0.500000 * b)
            cr = 128.0 + (0.500000 * r) - (0.418688 * g) - (0.081312 * b)

            data[pos    ] = [[ y.to_i, 0].max, 255].min
            data[pos + 1] = [[cb.to_i, 0].max, 255].min
            data[pos + 2] = [[cr.to_i, 0].max, 255].min

            pos += 3
        end

        return ImageYCbCr.new(@width, @height, data)
    end

    def plane(n)
        unless (n >= 0) and (n <= 2)
            raise ArgumentError "Bad plane index."
        end

        data = "\0" * (@width * @height)
        pos  = n
        
        while pos < @data.length
            data[pos / 3] = @data[pos]

            pos += 3
        end

        return ImageMono.new(@width, @height, data)
    end

    def blit_to_plane(n, x_here, y_here, x_there, y_there, width, height, img)
        unless (n >= 0) and (n <= 2)
            raise ArgumentError "Bad plane index."
        end

        unless img.instance_of?(ImageMono)
            raise ArgumentError "Incompatible blit source."
        end

        if ((x_there + width)  > img.width)  or
           ((y_there + height) > img.height) or
           ((x_here  + width)  > @width)     or
           ((y_here  + height) > @height)
            raise ArgumentError "Bad intersection rectangle."
        end

        nbytes   = width
        p_here   = (x_here * 3) + (y_here  * @stride) + n
        p_there  = x_there + (y_there * img.stride)
        pp_here  = 0
        pp_there = 0

        height.times do
            pp_here  = p_here
            pp_there = p_there
            nbytes.times do
                @data[pp_here] = img.data[pp_there]

                pp_here  += 3
                pp_there += 1
            end

            p_here  += @stride
            p_there += img.stride
        end
    end

    def blit(x_here, y_here, x_there, y_there, width, height, img)
        unless img.instance_of?(ImageRGB)
            raise ArgumentError "Incompatible blit source."
        end

        if ((x_there + width)  > img.width)  or
           ((y_there + height) > img.height) or
           ((x_here  + width)  > @width)     or
           ((y_here  + height) > @height)
            raise ArgumentError "Bad intersection rectangle."
        end

        nbytes   = width * 3
        p_here   = (x_here  * 3) + (y_here  * @stride)
        p_there  = (x_there * 3) + (y_there * img.stride)
        pp_here  = 0
        pp_there = 0

        height.times do
            pp_here  = p_here
            pp_there = p_there
            nbytes.times do
                @data[pp_here] = img.data[pp_there]

                pp_here  += 1
                pp_there += 1
            end

            p_here  += @stride
            p_there += img.stride
        end
    end
end

class ImageYCbCr
    attr_reader :data, :width, :height, :stride

    def initialize(x, y, data = "")
        @width  = x
        @height = y
        @stride = x * 3
    
        size = y * @stride

        if data.length == 0
            @data = "\0" * size
        elsif data.length != size
            raise ArgumentError "Wrong size for initialization data."
        else
            @data = data
        end
    end

    def set(x, y, c)
        pos = (y * @stride) + (x * 3)

        # Y, Cb, Cr
        @data[pos    ] = (c & 0x00FF0000) >> 16
        @data[pos + 1] = (c & 0x0000FF00) >>  8
        @data[pos + 2] = (c & 0x000000FF)
    end

    def get(x, y)
        pos = (y * @stride) + (x * 3)

        # Y, Cb, Cr
        return ((@data[pos] << 16) | (@data[pos + 1] << 8) | (@data[pos + 2]))
    end

    def rgb
        data = "\0" * (@stride * @height)
        pos  = 0

        r    = 0
        g    = 0
        b    = 0

        y    = 0
        cb   = 0
        cr   = 0

        while pos < @data.length
            y  = @data[pos    ]
            cb = @data[pos + 1] - 128
            cr = @data[pos + 2] - 128

            r = y.to_f                   + (1.402000 * cr)
            g = y.to_f - (0.344140 * cb) - (0.714140 * cr)
            b = y.to_f + (1.772000 * cb)

            data[pos    ] = [[r.to_i, 0].max, 255].min
            data[pos + 1] = [[g.to_i, 0].max, 255].min
            data[pos + 2] = [[b.to_i, 0].max, 255].min

            pos += 3
        end

        return ImageRGB.new(@width, @height, data)
    end

    def plane(n)
        unless (n >= 0) and (n <= 2)
            raise ArgumentError "Bad plane index."
        end

        data = "\0" * (@width * @height)
        pos  = n
        
        while pos < @data.length
            data[pos / 3] = @data[pos]

            pos += 3
        end

        return ImageMono.new(@width, @height, data)
    end

    def blit_to_plane(n, x_here, y_here, x_there, y_there, width, height, img)
        unless (n >= 0) and (n <= 2)
            raise ArgumentError "Bad plane index."
        end

        unless img.instance_of?(ImageMono)
            raise ArgumentError "Incompatible blit source."
        end

        if ((x_there + width)  > img.width)  or
           ((y_there + height) > img.height) or
           ((x_here  + width)  > @width)     or
           ((y_here  + height) > @height)
            raise ArgumentError "Bad intersection rectangle."
        end

        nbytes   = width
        p_here   = (x_here * 3) + (y_here  * @stride) + n
        p_there  = x_there + (y_there * img.stride)
        pp_here  = 0
        pp_there = 0

        height.times do
            pp_here  = p_here
            pp_there = p_there
            nbytes.times do
                @data[pp_here] = img.data[pp_there]

                pp_here  += 3
                pp_there += 1
            end

            p_here  += @stride
            p_there += img.stride
        end
    end
end

class Anaglyph < ImageRGB
    def left
        data   = "\0" * (@width * @height)
        pos    = 0

        cross  = -0.05
	l_corr = (0.587 + 0.114) * 0.642
        r_corr = 0.750

        g      = 0
        b      = 0

        y      = 0

        while pos < @data.length
            r = @data[pos    ]
            g = @data[pos + 1]
            b = @data[pos + 2] 

            data[pos / 3] = [[((((0.587 * g) + (0.114 * b)) / l_corr) + (cross * r_corr * r)).to_i, 255].min, 0].max

            pos += 3
        end

        return ImageMono.new(@width, @height, data)
    end

    def right
        data   = "\0" * (@width * @height)
        pos    = 0

        cross  = -0.05
	l_corr = (0.587 + 0.114) * 0.642
        r_corr = 0.750

        while pos < @data.length
            r = @data[pos    ]
            g = @data[pos + 1]
            b = @data[pos + 2] 

            data[pos / 3] = [[((cross * ((0.587 * g) + (0.114 * b)) / l_corr) + (r_corr * r)).to_i, 255].min, 0].max

            pos += 3
        end

        return ImageMono.new(@width, @height, data)
    end

    def side_by_side
        img_sbs   = ImageMono.new(@width * 2, @height)
        img_sbs.blit(0, 0, 0, 0, @width, @height, self.left)
        img_sbs.blit(@width, 0, 0, 0, @width, @height, self.right)

        return (img_sbs)
    end
end

#####
# Process command line.
def runme
    if ARGV.length != 2 and ARGV.length != 3
        puts "de-anaglyph <anaglyph-file> [<color-file>] <out-file>"
        exit 1
    end

    if ARGV.length == 2
        x = 1280
        y = 720
        byte = 0

        pos = 0
        anadata = "\0" * (x * y * 3)
        IO.popen("convert #{ARGV[0]} -depth 8 rgb:-").each_byte do |byte|
            anadata[pos] = byte
            pos += 1
        end

        anaglyph = Anaglyph.new(x, y, anadata)
#        IO.popen("convert -size #{x}x#{y} -depth 8 gray:- left.bmp", "w+") do |f|
#            f.write(anaglyph.left.data)
#        end
#        IO.popen("convert -size #{x}x#{y} -depth 8 gray:- right.bmp", "w+") do |f|
#            f.write(anaglyph.right.data)
#        end

        IO.popen("convert -size #{2*x}x#{y} -depth 8 gray:- -scale 50%x100% #{ARGV[1]}", "w+") do |f|
            f.write(anaglyph.side_by_side.data)
        end
    else
        x = 2048
        y = 1536
        byte = 0

        pos = 0
        anadata = "\0" * (x * y * 3)
        IO.popen("convert #{ARGV[0]} -depth 8 rgb:-").each_byte do |byte|
            anadata[pos] = byte
            pos += 1
        end

        anaglyph = Anaglyph.new(x, y, anadata)
        y_left   = anaglyph.left
        y_right  = anaglyph.right

#        IO.popen("convert -size #{x}x#{y} -depth 8 gray:- left.bmp", "w+") do |f|
#            f.write(y_left.data)
#        end
#        IO.popen("convert -size #{x}x#{y} -depth 8 gray:- right.bmp", "w+") do |f|
#            f.write(y_right.data)
#        end


        pos = 0
        colordata = "\0" * (x * y * 3)
        IO.popen("convert #{ARGV[1]} -depth 8 rgb:-").each_byte do |byte|
            colordata[pos] = byte
            pos += 1
        end

        color    = ImageRGB.new(x, y, colordata).ycbcr
        cb       = color.plane(1)
        cr       = color.plane(2)

#        IO.popen("convert -size #{x}x#{y} -depth 8 gray:- y.bmp", "w+") do |f|
#            f.write(color.plane(0).data)
#        end
#        IO.popen("convert -size #{x}x#{y} -depth 8 gray:- cb.bmp", "w+") do |f|
#            f.write(color.plane(1).data)
#        end
#        IO.popen("convert -size #{x}x#{y} -depth 8 gray:- cr.bmp", "w+") do |f|
#            f.write(color.plane(2).data)
#        end

        # Far
#        left_common   = [ 933, 1024]
#        right_common  = [ 817, 1008]
#        color_common  = [1120, 1172]
        left_common    = [ 888,  596]
        right_common   = [ 770,  577]
        color_common   = [1071,  736]

        upper_offset  = [[left_common[0], right_common[0], color_common[0]].min, [left_common[1], right_common[1], color_common[1]].min]

        left_offset   = [ left_common[0] - upper_offset[0],  left_common[1] - upper_offset[1]]
        right_offset  = [right_common[0] - upper_offset[0], right_common[1] - upper_offset[1]]
        color_offset  = [color_common[0] - upper_offset[0], color_common[1] - upper_offset[1]]


        new_width     = x - [left_offset[0], right_offset[0], color_offset[0]].max
        new_height    = y - [left_offset[1], right_offset[1], color_offset[1]].max

        compos_yuv = ImageYCbCr.new(new_width * 2, new_height)
        compos_yuv.blit_to_plane(0,         0, 0,  left_offset[0],  left_offset[1], new_width, new_height, y_left)
        compos_yuv.blit_to_plane(0, new_width, 0, right_offset[0], right_offset[1], new_width, new_height, y_right)
        compos_yuv.blit_to_plane(1,         0, 0, color_offset[0], color_offset[1], new_width, new_height, cb)
        compos_yuv.blit_to_plane(1, new_width, 0, color_offset[0], color_offset[1], new_width, new_height, cb)
        compos_yuv.blit_to_plane(2,         0, 0, color_offset[0], color_offset[1], new_width, new_height, cr)
        compos_yuv.blit_to_plane(2, new_width, 0, color_offset[0], color_offset[1], new_width, new_height, cr)

#        IO.popen("convert -size #{new_width*2}x#{new_height} -depth 8 gray:- cb.bmp", "w+") do |f|
#            f.write(compos_yuv.plane(1).data)
#        end
#        IO.popen("convert -size #{new_width*2}x#{new_height} -depth 8 gray:- cr.bmp", "w+") do |f|
#            f.write(compos_yuv.plane(2).data)
#        end

        sbs_color = compos_yuv.rgb

        # Now we need to crop and re-aspect.
        asp_width  = new_width * 2
        asp_height = (new_width / 1.77778).to_i
        asp_offset = (new_height - asp_height) / 2

        crop_x_off = 1920 - (asp_width / 2)
        crop_y_off = (1080 - asp_height) / 2

        final = ImageRGB.new(1920*2, 1080)
        final.blit(crop_x_off, crop_y_off, 0, asp_offset, asp_width, asp_height, sbs_color)

        IO.popen("convert -size #{1920*2}x#{1080} -depth 8 rgb:- -scale 50%x100% #{ARGV[2]}", "w+") do |f|
            f.write(final.data)
        end
    end
end

#####
# Run

runme
