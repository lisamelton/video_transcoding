#
# crop.rb
#
# Copyright (c) 2013-2024 Lisa Melton
#

module VideoTranscoding
  module Crop
    extend self

    def detect(path, duration, width, height)
      Console.info "Detecting crop with ffmpeg..."
      fail "media duration too short: #{duration} second(s)" if duration < 2
      steps = 10
      interval = duration / (steps + 1)
      target_interval = 5 * 60

      if interval == 0
        steps = 1
        interval = 1
      elsif interval > target_interval
        steps = (duration / target_interval) - 1
        interval = duration / (steps + 1)
      end

      crop_width, crop_height, crop_x, crop_y = 0, 0, width, height
      last_seconds = Time.now.tv_sec

      (1..steps).each do |step|
        begin
          IO.popen([
            FFmpeg.command_name,
            '-hide_banner',
            '-nostdin',
            '-noaccurate_seek',
            '-ss', (interval * step).to_s,
            '-i', path,
            '-frames:v', '10',
            '-filter:v', 'cropdetect=24:2',
            '-an',
            '-sn',
            '-ignore_unknown',
            '-f', 'null',
            '-'
          ], :err=>[:child, :out]) do |io|
            io.each do |line|
              seconds = Time.now.tv_sec

              if seconds - last_seconds >= 3
                Console.warn '...'
                last_seconds = seconds
              end

              line.encode! 'UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ''

              if line =~ / crop=([0-9]+):([0-9]+):([0-9]+):([0-9]+)$/
                d_width, d_height, d_x, d_y = $1.to_i, $2.to_i, $3.to_i, $4.to_i
                crop_width  = d_width   if crop_width   < d_width
                crop_height = d_height  if crop_height  < d_height
                crop_x      = d_x       if crop_x       > d_x
                crop_y      = d_y       if crop_y       > d_y
                Console.debug line
              end
            end
          end
        rescue SystemCallError => e
          raise "crop detection failed: #{e}"
        end

        fail "crop detection failed" unless $CHILD_STATUS.exitstatus == 0
      end

      {
        :top    => crop_y,
        :bottom => height - (crop_y + crop_height),
        :left   => crop_x,
        :right  => width - (crop_x + crop_width)
      }
    end

    def constrain(raw_crop, width, height)
      crop = raw_crop.dup
      delta_x = crop[:left] + crop[:right]
      delta_y = crop[:top] + crop[:bottom]
      min_delta = (width / 64)
      min_delta += 1 if min_delta.odd?

      if delta_x > delta_y
        crop[:top], crop[:bottom] = 0, 0

        if delta_x < min_delta or delta_x >= width
            crop[:left], crop[:right] = 0, 0
        end
      else
        crop[:left], crop[:right] = 0, 0

        if delta_y < min_delta or delta_y >= height
            crop[:top], crop[:bottom] = 0, 0
        end
      end

      crop
    end

    def handbrake_string(crop)
      "#{crop[:top]}:#{crop[:bottom]}:#{crop[:left]}:#{crop[:right]}"
    end

    def player_string(crop, width, height)
      "#{width - (crop[:left] + crop[:right])}:" +
      "#{height - (crop[:top] + crop[:bottom])}:" +
      "#{crop[:left]}:" +
      "#{crop[:top]}"
    end

    def drawbox_string(crop, width, height)
      "#{crop[:left]}:" +
      "#{crop[:top]}:" +
      "#{width - (crop[:left] + crop[:right])}:" +
      "#{height - (crop[:top] + crop[:bottom])}"
    end
  end
end
