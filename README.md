# Video Transcoding

Tools to transcode, inspect and convert videos.

## About

Hi, I'm [Don Melton](http://donmelton.com/). I created these tools to transcode my collection of Blu-ray Discs and DVDs into a smaller, more portable format while remaining high enough quality to be mistaken for the originals.

What makes these tools unique is the special rate control system which achieves those goals.

This package is based on my original collection of [Video Transcoding Scripts](https://github.com/donmelton/video-transcoding-scripts) written in Bash. While still available online, those scripts are no longer in active development. Users are encouraged to install this Ruby Gem instead.

Most of the tools in this package are essentially intelligent wrappers around Open Source software like [HandBrake](https://handbrake.fr/), [MKVToolNix](https://www.bunkus.org/videotools/mkvtoolnix/), [MPlayer](http://mplayerhq.hu/), [FFmpeg](http://ffmpeg.org/), and [MP4v2](https://code.google.com/p/mp4v2/). And they're all designed to be executed from the command line shell:

* [`transcode-video`](#why-transcode-video)
Transcode video file or disc image directory into format and size similar to popular online downloads.

* [`detect-crop`](#why-detect-crop)
Detect optimal crop values for video file or disc image directory.

* [`convert-video`](#why-convert-video)
Convert video file from Matroska to MP4 format or from MP4 to Matroksa format without transcoding video.

* [`query-handbrake-log`](#why-query-handbrake-log)
Report information from HandBrake-generated `.log` files.

Even if you don't try any of my tools, you may find this "README" document helpful:

* [About](#about)
* [Installation](#installation)
* [Rationale](#rationale) ([Why `transcode-video`?](#why-transcode-video), [Why `detect-crop`?](#why-detect-crop), [Why `convert-video`?](#why-convert-video), [Why `query-handbrake-log`?](#why-query-handbrake-log))
* [Usage](#usage)
    * [Using `transcode-video`](#using-transcode-video) ([Changing output format](#changing-output-format), [Improving quality](#improving-quality), [Improving performance](#improving-performance), [Cropping](#cropping),  [Understanding audio](#understanding-audio), [Understanding subtitles](#understanding-subtitles))
    * [Using `detect crop`](#using-detect-crop)
    * [Using `convert-video`](#using-convert-video)
    * [Using `query-handbrake-log`](#using-query-handbrake-log)
* [Guide](#guide) ([Preparing your media](#preparing-your-media-for-transcoding), [Why MakeMKV](#why-makemkv), [Why a single `.mkv`file?](#why-a-single-mkv-file), [Forced subtitles?](#why-bother-with-forced-subtitles), [Why convert lossless audio?](#why-convert-lossless-audio), [Understanding the x264 preset system](#understanding-the-x264-preset-system))
* [Feedback](#feedback)
* [Acknowledgements](#acknowledgements)
* [License](#license)

## Installation

My Video Transcoding tools are designed to work on OS X, Linux and Windows. They're packaged as a Gem and require Ruby version 2.0 or later. See "[Installing Ruby](https://www.ruby-lang.org/en/documentation/installation/)" if don't have the proper version on your platform.

Use this command to install the package: 

    gem install video_transcoding

You may need to prefix that command with `sudo` in some environments: 

    sudo gem install video_transcoding

### Requirements

Most of the tools in this package require other software to function properly, specifically these command line programs:

* `HandBrakeCLI`
* `ffmpeg`
* `mkvmerge`
* `mkvpropedit`
* `mp4track`
* `mplayer`

You can download the command line version of HandBrake, called `HandBrakeCLI`, here:

<https://handbrake.fr/downloads2.php>

On OS X, the other dependencies can be easily installed via [Homebrew](http://brew.sh/), an add-on package manager:

    brew install ffmpeg
    brew install mkvtoolnix
    brew install mp4v2
    brew install mplayer

`HandBrakeCLI` is also available via [Homebrew Cask](http://caskroom.io/), an extension to Homebrew:

    brew install caskroom/cask/brew-cask
    brew cask install handbrakecli

On Linux, package management systems vary so it's best consult the indexes for those systems.

On Windows, it's best to search the Web for the appropriate binary or add-on package manager. The [VideoHelp](http://www.videohelp.com) and [Cygwin](https://cygwin.com/) sites are a good place to start.

When installing `HandBrakeCLI` or other downloaded programs, make sure the executable binary is in a directory listed in your `PATH` environment variable. On Unix-style systems like OS X and Linux, that directory might be `/usr/local/bin`.

## Rationale

### Why `transcode-video`?

Videos from the [iTunes Store](https://en.wikipedia.org/wiki/ITunes_Store) are my template for a portable format while remaining high enough quality to be mistaken for the originals. Their files are very good quality, only about 20% the size of the same video on a Blu-ray Disc, and play on a wide variety of devices.

HandBrake is a powerful video transcoding tool but it's complicated to configure. It has several presets but they aren't smart enough to automatically change bitrate targets and other encoding options based on different inputs. More importantly, HandBrake's default presets don't produce a predictable output size with sufficient quality.

HandBrake's "AppleTV 3" preset is closest to what I want but transcoding "[Planet Terror (2007)](http://www.blu-ray.com/movies/Planet-Terror-Blu-ray/1248/)" with it results in a huge video bitrate of 19.9 Mbps, very near the original of 22.9 Mbps. And transcoding "[The Girl with the Dragon Tattoo (2011)](http://www.blu-ray.com/movies/The-Girl-with-the-Dragon-Tattoo-Blu-ray/35744/)," while much smaller in output size, lacks detail compared to the original.

So, to follow the iTunes Store template, the `transcode-video` tool configures the [x264 video encoder](http://www.videolan.org/developers/x264.html) within HandBrake to use a [constrained variable bitrate (CVBR)](https://en.wikipedia.org/wiki/Variable_bitrate) mode, and to automatically target bitrates appropriate for different input resolutions.

Input resolution | Target video bitrate
--- | ---
1080p or Blu-ray video | 5 Mbps
720p | 4 Mbps
480i, 576p or DVD video | 2 Mbps

When audio transcoding is required, it's done in [AAC format](https://en.wikipedia.org/wiki/Advanced_Audio_Coding) and, if the original is [multi-channel surround sound](https://en.wikipedia.org/wiki/Surround_sound), in [Dolby Digital AC-3 format](https://en.wikipedia.org/wiki/Dolby_Digital). Meaning the output can contain two tracks from the same source in different formats. And mono, stereo and surround inputs are all handled differently.

Input channels | Pass through | AAC track | AC-3 track
--- | --- | --- | ---
Mono | AAC only | 80 Kbps | none
Stereo | AAC only | 160 Kbps | none
Surround | AC-3 only, up to 448 Kbps | 160 Kbps | 384 Kbps with 5.1 channels

Which makes the output of `transcode-video` very near the same size, quality and configuration as videos from the iTunes Store, including their audio tracks.

But if the iTunes-style configuration is not suitable, most of these default settings and automatic behaviors can be easily overridden or augmented with additional command line options.

### Why `detect-crop`?

Removing the black, non-content borders of a video during transcoding is not about making the edges of the output look pretty. Those edges are usually not visible anyway when viewed full screen.

Cropping is about faster transcoding and higher quality. Fewer pixels to read and write almost always leads to a speed improvement. Fewer pixels also means the x264 encoder within HandBrake doesn't waste bitrate on non-content.

HandBrake applies automatic crop detection by default. While it's usually correct, it does guess wrong often enough not to be trusted without review. For example, HandBrake's default behavior removes the top and bottom 140 pixels from "[The Dark Knight (2008)](http://www.blu-ray.com/movies/The-Dark-Knight-Blu-ray/743/)" and "[The Hunger Games: Catching Fire (2013)](http://www.blu-ray.com/movies/The-Hunger-Games-Catching-Fire-Blu-ray/67923/)," losing significant portions of their full-frame content.

And sometimes HandBrake only crops a few pixels from one or more edges, which is too small of a difference in size to improve performance or quality.

This is why `transcode-video` doesn't allow HandBrake to apply cropping by default.

Instead, the `detect-crop` tool leverages both HandBrake and MPlayer, with additional measurements and constraints, to find the optimal video cropping bounds. It then indicates whether those two programs agree. To aid in review, this tool prints commands to the terminal console allowing the recommended (or disputed) crop to be displayed, as well as a sample command line for `transcode-video` itself.

### Why `convert-video`?

All videos from the iTunes Store are in [MP4 format](https://en.wikipedia.org/wiki/MPEG-4_Part_14) format. However, the `transcode-video` tool generates output in the more flexible [Matroska format](https://en.wikipedia.org/wiki/Matroska) by default.

While you can easily change the behavior of `transcode-video` to generate MP4 format with a command line option, it's sometimes handy to convert between formats quickly without re-transcoding. The `convert-video` tool is designed for exactly that convenience.

### Why `query-handbrake-log`?

The `transcode-video` tool creates both video files and `.log` files. While not nearly as entertaining, the cryptic `.log` file still contains useful information. And the `query-handbrake-log` can extract performance metrics, video bitrate and relative quality from those `.log` files into easily readable reports.

## Usage

Each of my Video Transcoding tools has several command line options. The `transcode-video` tool is the most complex with over 40 of its own. Not all of those options are detailed here. Use `--help` to list the full set of options available for a specific tool, along with brief instructions on their usage:

    transcode-video --help

This built-in help works even if a tool's software dependencies are not yet installed.

All of the tools can accept multiple inputs, but batch processing for `transcode-video` is still best handled by a separate script.

The `transcode-video` and `detect-crop` tools work best with video files:

    transcode-video "/path/to/Movie.mkv"

However, both tools also accept disc image directories as input:

    transcode-video "/path/to/Movie disc image directory/"

Disc image directories contain unencrypted backups of Blu-ray Discs or DVDs. Typically these formats include more than one video title. These additional titles can be bonus features, alternate versions of a movie, multiple TV show episodes, etc.

By default, `transcode-video` and `detect-crop` will automatically select the main feature in a disc image directory. Or they will select the first title, if the main feature can't be determined.

Both tools allow you to scan disc image directories, listing titles and tracks:

    transcode-video --scan "/path/to/Movie disc image directory/"

So you can then select a specific title by number:

    transcode-video --title 5 "/path/to/Movie disc image directory/"

### Using `transcode-video`

The `transcode-video` tool automatically determines target video bitrate, number of audio tracks, etc. without any command line options, so using it can be as simple as:

    transcode-video "/path/to/Movie.mkv"

That command creates, after a reasonable amount of time, two files in the current working directory:

    Movie.mkv
    Movie.mkv.log

The `.log` file can be used as input to the `query-handbrake-log` tool.

#### Changing output format

By default, the `transcode-video` tool generates output in Matroska format. To generate output in MP4 format, use the `--mp4` option:

    transcode-video --mp4 "/path/to/Movie.mkv"

Which will instead create:

    Movie.mp4
    Movie.mp4.log

To create MP4 output with the `.m4v` file extension instead of `.mp4`, use the `--m4v` option:

    transcode-video --m4v "/path/to/Movie.mkv"

The `.m4v` file extension is more "iTunes-friendly," but the file content itself is exactly the same as a file with the `.mp4` extension.

#### Improving quality

If quality is more important to you than output size, use the `--big` option:

    transcode-video --big "/path/to/Movie.mkv"

Video bitrate targets are raised 50-60% depending upon the video resolution of your input.

Input resolution | Target video bitrate with `--big`
--- | ---
1080p or Blu-ray video | 8 Mbps
720p | 6 Mbps
480i, 576p or DVD video | 3 Mbps

Dolby Digital AC-3 audio bitrate limits are raised 66% to their maximum allowed value. However, there's no impact on the bitrate of mono and stereo AAC audio tracks.

Input channels | Pass through<br />with `--big` | AAC track<br />with `--big` | AC-3 track<br />with `--big`
--- | --- | --- | ---
Mono | AAC only | 80 Kbps | none
Stereo | AAC only | 160 Kbps | none
Surround | AC-3 only, up to 640 Kbps | 160 Kbps | 640 Kbps with 5.1 channels

With `--big`, noisy video and complex surround audio have the most potential for perceptible quality improvements.

Be aware that performance degrades 6-10% using the `--big` option due to more calculations being made and more bits being written to disk.

#### Improving performance

If you're willing to trade some precision for a 45-50% increase in video encoding speed, use the `--quick` option:

    transcode-video --quick "/path/to/Movie.mkv"

The precision loss is minor and, when combined with the `--big` option, may not even be perceptible:

    transcode-video --big --quick "/path/to/Movie.mkv"

The `--quick` option is also more than 15% speedier than the x264 video encoder's "fast" preset and it avoids the occasional quality loss problems of the "faster" and "veryfast" presets.

Be aware that output files are slightly larger when using the `--quick` option since the loss of precision is also a loss of efficiency.

#### Cropping

No cropping is applied by default. Use the `--crop TOP:BOTTOM:LEFT:RIGHT` option and arguments to indicate the amount of black, non-content border to remove from the edges of your video.

This command removes the top and bottom 144 pixels, typical of a 2.40:1 widescreen movie embedded within 16:9 Blu-ray Disc video:

    transcode-video --crop 144:144:0:0 "/path/to/Movie.mkv"

This command removes the left and right 240 pixels, typical of a 4:3 classic TV show embedded within 16:9 Blu-ray Disc video:

    transcode-video --crop 0:0:240:240 "/path/to/Movie.mkv"

Use the `detect-crop` tool to determine the optimal cropping bounds.

You can also call the `detect-crop` logic from `transcode-video` with the single `detect` argument:

    transcode-video --crop detect "/path/to/Movie.mkv"

However, be aware that `detect` can fail if HandBrake and MPlayer disagree about the cropping values.

#### Understanding audio

By default, the `transcode-video` tool selects the first audio track in the input as the main audio track. This is the first track in the output and the default track for playback.

But you can select any audio track as the main track. In this case, track number 3:

    transcode-video --main-audio 3 "/path/to/Movie.mkv"

You can also give the main audio track a custom name:

    transcode-video --main-audio 3="Original Stereo" "/path/to/Movie.mkv"

Unlike `HandBrakeCLI`, custom track names are allowed to contain commas.

By default, only one audio track is selected. But you can add additional tracks, also with custom names:

    transcode-video --add-audio 4 --add-audio 5="Director Commentary" "/path/to/Movie.mkv"

Or you can add all audio tracks with a single option and argument:

    transcode-video --add-audio all "/path/to/Movie.mkv"

You can even add audio tracks selected by their three-letter language code. This command adds all French and Spanish language tracks:

    transcode-video --add-audio language=fre,spa "/path/to/Movie.mkv"

If no main audio track has been selected before adding tracks by language code, the first track added becomes the main audio track.

By default, the main audio track is transcoded in AAC format and, if the original is multi-channel surround sound, in Dolby Digital AC-3 format. Meaning the output can contain two tracks from the same source in different formats. So, main audio output is "wide" enough for "double" tracks.

Also by default, any added audio tracks are only transcoded in AAC format. Meaning the output only contains a single track in one format. So, additional audio output is only "wide" enough for "stereo" tracks.

However, you can change the "width" of main audio or additional audio output using the `--audio-width` option. There are three possible widths: `double`, `surround` and `stereo`.

Use this command to treat any additional audio tracks just like the main audio track:

    transcode-video --audio-width all=double "/path/to/Movie.mkv"

Or use this command to make main audio output as a single track but still allow it in surround format:

    transcode-video --audio-width 1=surround "/path/to/Movie.mkv"

If possible, audio is first passed through in its original format, providing that format is either AC-3 or AAC. This hardly ever works for Blu-ray Discs but it often will for DVDs and other random videos.

However, you can copy the original audio track, provided HandBrake and your selected file format support it:

    transcode-video --copy-audio 1 "/path/to/Movie.mkv"

The `--copy-audio` option doesn't implicitly add the audio track to be copied. The previous command works because `1` identifies the main audio track and it's included by default. To copy a different track, you must first add it:

    transcode-video --add-audio 4 --copy-audio 4 "/path/to/Movie.mkv"

Be aware that copying audio tracks in their original format will likely defeat two very important goals of transcoding: portability and compression.

#### Understanding subtitles

By default, the `transcode-video` tool automatically burns any forced subtitle track it detects into the output video track. "Burning" means that the subtitle becomes part of the video itself and isn't retained as a separate track. A "forced" subtitle track is detected by a special flag on that track in the input.

But you can select any subtitle track for burning. In this case, track number 3:

    transcode-video --burn-subtitle 3 "/path/to/Movie.mkv"

You can also use a special "scan" mode of HandBrake to find any embedded forced subtitle track that's in the same language as the main audio track:

    transcode-video --burn-subtitle scan "/path/to/Movie.mkv"
    
Be aware that using this special "scan" mode does not always work. Sometimes it won't find any track or, worse, it will find the wrong track. And you won't know whether it worked until the transcoding is complete.

Burning subtitles into the output video works best for "forced" rather than optional subtitles. But it's still a much better idea than adding subtitle tracks in their original format to the output file.

Blu-ray Disc and DVD subtitles are bitmap formats. They're not text. They're large, unwieldy and may not appear correctly if you crop your video. Blu-ray Disc-format subtitles aren't even allowed in MP4 output. And DVD-format subtitles, while allowed, often won't display at all in many MP4 players.

However, you can leverage programs like [SUBtools](http://www.emmgunn.com/subtools/subtoolshome.html) or [Subtitle Edit](http://www.nikse.dk/SubtitleEdit/) to extract Blu-ray Disc and DVD subtitles and convert them into text format. Be aware that while both of these programs can perform automatic character recognition of the subtitle bitmaps, you'll still need to edit the output text by hand. Even the best automatic character recognition is still wrong far too often.

You can also find text-based subtitles for your movies and TV shows at sites like [OpenSubtitles](http://www.opensubtitles.org/), where someone else has already done the tedious work of conversion and editing.

If and when you do have a subtitle in text format, specifically [SubRip](https://en.wikipedia.org/wiki/SubRip) `.srt` format, you can easily add it to your output video from an external file:

    transcode-video --add-srt "/path/to/Subtitle.srt" "/path/to/Movie.mkv"

Unlike `HandBrakeCLI`, external subtitle file names are allowed to contain commas.

### Using `detect-crop`

The command to find the optimal video cropping bounds is as simple as:

    detect-crop "/path/to/Movie.mkv"

Which prints out something like this:

    mplayer -really-quiet -nosound -vf rectangle=1920:816:0:132 '/path/to/Movie.mkv'
    mplayer -really-quiet -nosound -vf crop=1920:816:0:132 '/path/to/Movie.mkv'

    transcode-video --crop 132:132:0:0 '/path/to/Movie.mkv'

Just copy and paste the sample commands to preview or transcode.

When input is a disc image directory instead of a single file, the `detect-crop` tool doesn't use MPlayer, nor does it print out commands to preview the crop.

Be aware that the algorithm to determine optimal shape always crops from the top and bottom or from the left and right, never from both axes.

### Using `convert-video`

The `convert-video` tool repackages video files, converting them from Matroska to MP4 format or from MP4 to Matroksa format without transcoding the video. It's as simple as:

    convert-video "Movie.mkv"

Which creates this MP4 file in the current working directory:

    Movie.mp4

Or...

    convert-video "Movie.mp4"

Which creates this Matroska file in the current working directory:

    Movie.mkv

If necessary, the `convert-video` tool may transcode audio tracks to AAC or Dolby Digital AC-3 format when converting to MP4 format.

Chapter markers and metadata such as track titles are preserved. However, be aware that subtitle tracks are not converted.

### Using `query-handbrake-log`

The `query-handbrake-log` tool reports information from HandBrake-generated `.log` files. While it can certainly work with a single `.log` file, it really shines with multiple files.

There are four types of information that `query-handbrake-log` can report on:

* `time`
The time spent during transcoding, sorted from short to long. This even works for two-pass transcodings.

* `speed`
The speed of transcoding in frames per second, sorted from fast to slow. Since most video is `23.976` FPS, you can easily see trends when you're faster or slower than real time.

* `bitrate`
The final video bitrate of the transcoded output, sorted from low to high. Very useful since most media query tools only provide approximate bitrates for Matroska files, if at all.

* `ratefactor`
Technically this is the average P-frame quantizer for transcoding, sorted from low to high. But you should consider it a relative quality assessment by the x264 video encoder. 

One of these information types is required as an argument:

    query-handbrake-log time "/path/to/Logs directory/"

Which prints out something like this, time spent transcoding followed by video file name:

    01:20:25 Movie.mkv
    01:45:10 Another Movie.mkv
    02:15:35 Yet Another Movie.mkv

## Guide

### Preparing your media for transcoding

I have four rules when preparing my own media for transcoding:

1. Use [MakeMKV](http://www.makemkv.com/) to rip Blu-ray Discs and DVDs.
2. Rip each selected video as a single Matroska format `.mkv` file.
3. Look for forced subtitles and isolate them in their own track.
4. Convert lossless audio tracks to [FLAC format](https://en.wikipedia.org/wiki/FLAC).

#### Why MakeMKV?

* It runs on most desktop computer platforms like OS X, Windows and Linux. There's even a free version available to try before you buy.

* It was designed to decrypt and extract a video track, usually the main feature of a disc and convert it into a single Matroska format `.mkv` file. And it does this really, really well.

* It can also make an unencrypted backup of your entire Blu-ray or DVD to a disc image directory.

* It's not pretty and it's not particularly easy use. But once you figure out how it works, you can rip your video exactly the way you want.

#### Why a single `.mkv` file?

* Many automatic behaviors and other features in both `transcode-video` and `detect-crop` are not available when input is a disc image directory. This is because that format limits the ability of `HandBrakeCLI` and `mplayer` to detect or manipulate certain information about the video.

* Both forced subtitle extraction and lossless audio conversion, detailed below, are not possible when input is a disc image directory.

#### Why bother with forced subtitles?

* Remember "[The Hunt for Red October (1990)](http://www.blu-ray.com/movies/The-Hunt-For-Red-October-Blu-ray/920/)" when Sean Connery and Sam Neill are speaking actual Russian at the beginning of the movie instead of just using cheesy accents like they did the rest of the time? The Blu-ray Disc version provides English subtitles just for those few scenes. They're "forced" on screen for you. Which is actually very convenient.

* Forced subtitles are often embedded within a full subtitle track. And a special flag is set on the portion of that track which is supposed to be forced. MakeMKV can recognize that flag when it converts the video into a single `.mkv` file. It can even extract just the forced portion of that subtitle into a another separate subtitle track. And it can set a different "forced" flag in the output `.mkv` file on that separate track so other software can tell what it's for.

* Not all discs with forced subtitles have those subtitles embedded within other tracks. Sometimes they really are separate. But enough discs are designed with the embedded technique that you should avoid using a disc image directory as input for transcoding.

#### Why convert lossless audio?

* [DTS-HD Master Audio](https://en.wikipedia.org/wiki/DTS-HD_Master_Audio) is the most popular high definition, lossless audio format. It's used on more than 80% of all Blu-ray Discs.

* HandBrake, FFmpeg, MPlayer and other Open Source software can't decode the lossless portion of a DTS-HD audio track. They're only able to extract the non-HD, lossy core which is in [DTS format](https://en.wikipedia.org/wiki/DTS_(sound_system)).

* But MakeMKV can [decode DTS-HD with some help from additional software](http://www.makemkv.com/dtshd/) and convert it into FLAC format which can then be decoded by HandBrake and most other software. Once again, MakeMKV can only do this when it converts the video into a single `.mkv` file.

### Understanding the x264 preset system

The `--preset` option in `transcode-video` controls the x264 video encoder, not the other preset system built into HandBrake. It takes a preset name as its single argument:

    transcode-video --preset fast "/path/to/Movie.mkv"

The x264 presets are supposed to trade encoding speed for compression efficiency, and their names attempt to reflect this. However, that's not quite how they always work.

Preset name | Note
--- | --- | ---
`ultrafast` | not recommended
`superfast` | not recommended
`veryfast` | use with caution
`faster` | use with caution
`fast` | good but you might want to use `--quick` instead
`medium` | default
`slow` | use with caution
`slower` | use with caution
`veryslow` | use with caution
`placebo` | not recommended

Presets faster than `medium` trade precision for more speed. That tradeoff is acceptable for the `fast` preset. But you may notice occasional quality loss problems when using the `faster` or `veryfast` presets.

Presets slower than `medium` trade encoding speed for more compression efficiency. Any quality improvement using these presets may not be perceptible for most input. And on rare occasions, these presets lower quality noticeably.

### Recommended `transcode-video` usage

Use the default settings whenever possible.

Use the `--mp4` or `--m4v` options if your target player can't handle Matroska format.

Use the `--big` option if you can't retain your original source rip or you just have plenty of storage space.

Use the `--quick` option if you're in a hurry or you have a huge number of files to transcode.

Apply unambiguous crop values from `detect-crop` after review.

Don't add audio tracks in their original format that aren't AAC or Dolby Digital AC-3.

Don't add subtitles in their original Blu-ray Disc or DVD format.

Save your `.log` files so you can mine the data later.

### Batch control for `transcode-video`

Although the `transcode-video` tool can accept multiple inputs, batch processing is still best handled by a separate script because options can be changed for each input.

A `batch.sh` script can simply be a list of commands:

    #!/usr/bin/env bash

    transcode-video --crop 132:132:0:0 "/path/to/Movie.mkv"
    transcode-video "/path/to/Another Movie.mkv"
    transcode-video --crop 0:0:240:240 "/path/to/Yet Another Movie.mkv"

But a better solution is to write the script once and supply the list of movies and their crop values separately:

    #!/usr/bin/env bash

    readonly work="$(cd "$(dirname "$0")" && pwd)"
    readonly queue="$work/queue.txt"
    readonly crops="$work/Crops"

    input="$(sed -n 1p "$queue")"

    while [ "$input" ]; do
        title_name="$(basename "$input" | sed 's/\.[^.]*$//')"
        crop_file="$crops/${title_name}.txt"

        if [ -f "$crop_file" ]; then
            crop_option="--crop $(cat "$crop_file")"
        else
            crop_option=''
        fi

        sed -i '' 1d "$queue" || exit 1

        transcode-video $crop_option "$input"

        input="$(sed -n 1p "$queue")"
    done

This requires a `work` directory on disk with three items, one of which is a directory itself:

    batch.sh
    Crops/
        Movie.txt
        Yet Another Movie.txt
    queue.txt

The contents of `Crops/Movie.txt` is simply the crop value for `/path/to/Movie.mkv`:

    132:132:0:0

And the contents of `queue.txt` is just the list of movies, full paths without quotes, delimited by carriage returns:

    /path/to/Movie.mkv
    /path/to/Another Movie.mkv
    /path/to/Yet Another Movie.mkv

Notice that there's no crop file for `/path/to/Another Movie.mkv`. This is because it doesn't require cropping.

For other options that won't change from input to input, e.g. `--mp4`, simply augment the line in the script calling `transcode-video`:

        transcode-video --mp4 $crop_option "$input"

The transcoding process is started by executing the script:

    ./batch.sh

The path is first deleted from the `queue.txt` file and then passed as an argument to the `transcode-video.` tool. To pause after `transcode-video` returns, simply insert a blank line at the top of the `queue.txt` file.

These examples are written in Bash and only supply crop values. But almost any scripting language can be used and any option can be changed on a per input basis.

## Feedback

The best way to send feedback is mentioning me, [@donmelton](https://twitter.com/donmelton), on Twitter. You can also file bugs or ask questions in a longer form by [creating a new issue](https://github.com/donmelton/video_transcoding/issues) on GitHub. I always try to respond quickly but sometimes it may take as long as 24 hours.

## Acknowledgements

A big "thank you" to the developers of HandBrake and the other tools used by this package. So much wow.

Thanks to [Rene Ritchie](https://twitter.com/reneritchie) for letting me continue to babble on about transcoding in his podcasts.

Thanks to [Joyce Melton](https://twitter.com/erinhalfelven), my sister, for help editing this "README" document.

Many thanks to [Jordan Breeding](https://twitter.com/jorbsd) and numerous others online for their positive feedback, bug reports and useful suggestions.

## License

Video Transcoding is copyright [Don Melton](http://donmelton.com/) and available under a [MIT license](https://github.com/donmelton/video_transcoding/blob/master/LICENSE).
