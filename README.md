# Video Transcoding

Tools to transcode, inspect and convert videos.

## About

> [!NOTE]
> *This decade-old project was redesigned and rewritten for the modern era of video transcoding, and then re-released in early 2025 with different behavior and incompatible APIs. Some old conveniences were removed but new features and flexibility were added. Please manage your expectations accordingly if you came here looking for the older tools.*

Hi, I'm [Lisa Melton](http://lisamelton.net/). I created these tools to transcode my collection of Blu-ray Discs and DVDs into a smaller, more portable format while remaining high enough quality to be mistaken for the originals.

Most of the tools in this package are essentially intelligent wrappers around Open Source software like [HandBrake](https://handbrake.fr/) and [FFmpeg](http://ffmpeg.org/). And they're all designed to be executed from the command line shell:

* `transcode-video.rb`
Transcode essential media tracks into a smaller, more portable format while remaining high enough quality to be mistaken for the original.

* `detect-crop.rb`
Detect the unused outside area of video tracks and print TOP:BOTTOM:LEFT:RIGHT crop values to standard output.

* `convert-video.rb`
Convert a media file from Matroska `.mkv` format to MP4 format or other media to Matroksa format without transcoding.

## Installation

> [!WARNING]
> *Older versions of this project were packaged via [RubyGems](https://en.wikipedia.org/wiki/RubyGems) and installed via the `gem` command. If you had it installed that way, it's a good idea to uninstall that version via this command: `gem uninstall video_transcoding`*

These tools work on Windows, Linux and macOS. They're standalone Ruby scripts which must be installed and updated manually. You can retrieve them via the command line by cloning the entire repository like this:

    git clone https://github.com/lisamelton/video_transcoding.git

Or download it directly from the GitHub website here:

https://github.com/lisamelton/video_transcoding

On Linux and macOS, make sure each script is executable by setting their permissions like this:

    chmod +x transcode-video.rb
    chmod +x detect-crop.rb
    chmod +x convert-video.rb

And then move or copy them to a directory listed in your `$env:PATH` environment variable on Windows or `$PATH` environment variable on Linux and macOS.

Because they're written in Ruby, each script requires that language's runtime and interpreter. See "[Installing Ruby](https://www.ruby-lang.org/en/documentation/installation/)" if you don't have it on your platform.

Additional software is required for all the scripts to function properly, specifically these command line programs:

* `HandBrakeCLI`
* `ffprobe`
* `ffmpeg`

See "[HandBrake Downloads (Command Line)](https://handbrake.fr/downloads2.php)" and "[Download FFmpeg](https://ffmpeg.org/download.html) to find versions for your platform.

On macOS, all of these programs can be easily installed via [Homebrew](http://brew.sh/), an optional package manager:

    brew install handbrake
    brew install ffmpeg

The `ffprobe` program is included within the `ffmpeg` package.

On Windows, it's best to follow one of the two methods described here, manually installing binaries or installing into the [Windows Subsystem for Linux](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux):

https://github.com/JMoVS/installing_video_transcoding_on_windows

## Usage

For each tool in this package, use `--help` to list the options available for that tool along with brief instructions on their usage. For example:

    transcode-video.rb --help

And since all of the tools take one or more media files as arguments, using them can be as simple as this on Windows:

    transcode-video.rb C:\Rips\Movie.mkv

Or this on Linux and macOS:

    transcode-video.rb /Rips/Movie.mkv

## Default `transcode-video.rb` behavior

The `transcode-video.rb` tool creates a Matroska `.mkv` format file in the current working directory with video in 8-bit H.264 format and audio in multichannel AAC format.

4K inputs are automatically scaled to 1080p and HDR is automatically converted to SDR color space.

Video is automatically cropped.

The first audio track in the input, if available, is automatically selected.

Any forced subtitle is automatically burned into the video track or included as a separate text-only track depending on its original format.

The venerable `x264` software-based encoder is used with two-pass ratecontrol to produce a constant bitrate. Using two passes _is_ a bit slower than other methods but the output quality is worth the wait, as is the output size. This Is The Way™.

**Video:**

Resolution | H.264 bitrate
--- | ---
1080p (Blu-ray) | 5000 Kbps
720p | 2500 Kbps
480p (DVD) | 1250 Kbps

**Audio:**

Channels | AAC bitrate
--- | ---
Surround | 384 Kbps
Stereo | 128 Kbps
Mono | 80 Kbps

All this behavior can easily be changed by selecting different video and audio modes via the `--mode` and `--audio-mode` options, using other options like `--add-audio` or by passing arguments directly to the `HandBrakeCLI` API via the `--extra` option. It's very, very flexible.

## Other video modes

While the default behavior of `transcode-video.rb` is focused on creating high-quality 1080p and smaller-resolution SDR videos, other modes are available.

### `--mode hevc`

Designed for 4K HDR content, this mode uses the `x265_10bit` software-based encoder with a constant quality (instead of a constant bitrate) ratecontrol system. But it's reeeeeally slow. I mean, really slow. However, it does produce high-quality output. You just have to decide whether it's worth it.

One big selling point is that the `x265_10bit` encoder can produce output compatible with both the [HDR10](https://en.wikipedia.org/wiki/HDR10) and [HDR10+](https://en.wikipedia.org/wiki/HDR10%2B) standards as well as [Dolby Vision](https://en.wikipedia.org/wiki/Dolby_Vision).

### `--mode nvenc-hevc`

Also designed for 4K HDR content, this mode uses the `nvenc_h265_10bit` Nvidia hardware-based encoder, also with a constant quality ratecontrol system, because you can't always afford to wait on `x265_10bit`. The output will be slightly larger and somewhat lesser in quality but you'll get it a LOT faster. A lot.

But be aware that the `nvenc_h265_10bit` encoder can only produce HDR10-compatible output.

### `--mode av1`

This Is The Future. Unfortunately, the [AV1 video format](https://en.wikipedia.org/wiki/AV1) is currently the Star Trek Future. Other than desktop PCs, most devices can't play it yet. This mode uses the `svt_av1_10bit` software-based encoder with a constant quality ratecontrol system. Although the encoder is already quite good, it's still a work in progress. But it's faster than `x265_10bit` and usually produces smaller output. So it's certainly worth a try. Especially on 4K HDR content.

The `svt_av1_10bit` encoder can produce output compatible with the HDR10 and HDR10+ standards and pass through Dolby Vision metadata.

When using this mode, audio output is in Opus format at slightly lower bitrates. Why Opus? Because it's higher quality than AAC and if you can play AV1 format video then you can certainly play Opus format audio.

> [!NOTE]
> *Additional `--mode` arguments leveraging the `vt_h265_10bit` and `nvenc_av1_10bit` video encoders, likely to be named `vt-hevc` and `nvenc-av1`, are under consideration pending ratecontrol tuning. And tuning of any `vt-hevc` mode implementation will be delayed until I actually have an Apple Silicon Mac. But I'm working on the `nvenc-av1` mode implementation now since I already have the necessary Nvidia hardware.*

## Calling `HandBrakeCLI` from `transcode-video.rb`

The `transcode-video.rb` tool has less than 20 options. But the `HandBrakeCLI` API has over 100. It's YUUUUUGE! And you can pass arguments directly to that API via the `--extra` option.

But use the `-x` shortcut because who wants to do all that work typing `--extra`.

Even though the `convert-video.rb` tool is included in this project, you can output to MP4 format from `transcode-video.rb` itself like this:

    transcode-video.rb -x format=av_mp4 C:\Rips\Movie.mkv

What if you want to tweak a crop instead of relying on `HandBrakeCLI`'s new and improved algorithm? It's as simple as:

    transcode-video.rb -x crop=140:140:0:0 C:\Rips\Movie.mkv

If you want to get faster results and are willing to live dangerously when using `x264`, you can disable two-pass transcoding like this:

    transcode-video.rb -x no-multi-pass C:\Rips\Movie.mkv

What about filters? Easy peasy. You can apply any of `HandBrakeCLI`'s built-in filters this way:

    transcode-video.rb -x detelecine C:\Rips\Movie.mkv

Want to waste space? Then keep your original audio track in your output by changing the audio encoder:

    transcode-video.rb -x aencoder=copy C:\Rips\Movie.mkv

And if you just want an excerpt of your input, you can specify a chapter range for your output:

    transcode-video.rb -x chapters=3-5 C:\Rips\Movie.mkv

## Feedback

Please report bugs or ask questions by [creating a new issue](https://github.com/lisamelton/video_transcoding/issues) on GitHub. I always try to respond quickly but sometimes it may take as long as 24 hours.

## Acknowledgements

This project would not be possible without my collaborators on the [Video Transcoding Slack](https://videotranscoding.slack.com/) who spend countless hours reviewing, testing, documenting and supporting this software.

## License

Video Transcoding is copyright [Lisa Melton](http://lisamelton.net/) and available under an [MIT license](https://github.com/lisamelton/video_transcoding/blob/master/LICENSE).
