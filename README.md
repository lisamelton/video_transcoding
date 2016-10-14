# Video Transcoding

Tools to transcode, inspect and convert videos.

## About

Hi, I'm [Don Melton](http://donmelton.com/). I created these tools to transcode my collection of Blu-ray Discs and DVDs into a smaller, more portable format while remaining high enough quality to be mistaken for the originals.

What makes these tools unique is the special ratecontrol system which achieves those goals.

This package is based on my original collection of [Video Transcoding Scripts](https://github.com/donmelton/video-transcoding-scripts) written in Bash. While still available online, those scripts are no longer in active development. Users are encouraged to install this Ruby Gem instead.

Most of the tools in this package are essentially intelligent wrappers around Open Source software like [HandBrake](https://handbrake.fr/), [MKVToolNix](https://www.bunkus.org/videotools/mkvtoolnix/), [MPlayer](http://mplayerhq.hu/), [FFmpeg](http://ffmpeg.org/), and [MP4v2](https://code.google.com/p/mp4v2/). And they're all designed to be executed from the command line shell:

* [`transcode-video`](#why-transcode-video)
Transcode video file or disc image directory into format and size similar to popular online downloads.

* [`detect-crop`](#why-detect-crop)
Detect crop values for video file or disc image directory.

* [`convert-video`](#why-convert-video)
Convert video file from Matroska to MP4 format or from MP4 to Matroksa format without transcoding video.

* [`query-handbrake-log`](#why-query-handbrake-log)
Report information from HandBrake-generated `.log` files.

Even if you don't try any of my tools, you may find this "README" document helpful:

* [About](#about)
* [Installation](#installation)
* [Rationale](#rationale)
* [Usage](#usage)
* [Guide](#guide)
* [FAQ](#faq)
* [History](#history)
* [Feedback](#feedback)
* [Acknowledgements](#acknowledgements)
* [License](#license)

## Installation

My Video Transcoding tools are designed to work on OS X, Linux and Windows. They're packaged as a Gem and require Ruby version 2.0 or later. See "[Installing Ruby](https://www.ruby-lang.org/en/documentation/installation/)" if you don't have the proper version on your platform.

Use this command to install the package: 

    gem install video_transcoding

You may need to prefix that command with `sudo` in some environments: 

    sudo gem install video_transcoding

### Updating

Use this command, or the variation prefixed with `sudo`, to update the package:

    gem update video_transcoding

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

    brew cask install handbrakecli

On Linux, package management systems vary so it's best consult the indexes for those systems. But there's a Homebrew port available called [Linuxbrew](http://linuxbrew.sh/) and it doesn't require root access.

On Windows, it's best to search the Web for the appropriate binary or add-on package manager. The [VideoHelp](http://www.videohelp.com) and [Cygwin](https://cygwin.com/) sites are a good place to start. Or you could try installing into the [Windows Subsystem for Linux](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux) as described here:

<https://gist.github.com/JMoVS/75f3c6b344648deef59bc761e5e5a0e6>

When installing `HandBrakeCLI` or other downloaded programs, make sure the executable binary is in a directory listed in your `PATH` environment variable. On Unix-style systems like OS X and Linux, that directory might be `/usr/local/bin`.

## Rationale

### Why `transcode-video`?

Videos from the [iTunes Store](https://en.wikipedia.org/wiki/ITunes_Store) are my template for a portable format while remaining high enough quality to be mistaken for the originals. Their files are very good quality, much smaller than the same video on a Blu-ray Disc, and play on a wide variety of devices.

HandBrake is a powerful video transcoding tool but it's complicated to configure. It has several presets but they aren't smart enough to automatically change bitrate targets and other encoding options based on different inputs. More importantly, HandBrake's default presets don't produce a predictable output size with sufficient quality.

HandBrake's "AppleTV 3" preset is closest to what I want but transcoding "[Planet Terror (2007)](http://www.blu-ray.com/movies/Planet-Terror-Blu-ray/1248/)" with it results in a huge video bitrate of 19.9 Mbps, very near the original of 22.9 Mbps. And transcoding "[The Girl with the Dragon Tattoo (2011)](http://www.blu-ray.com/movies/The-Girl-with-the-Dragon-Tattoo-Blu-ray/35744/)," while much smaller in output size, lacks detail compared to the original.

So, the `transcode-video` tool configures the [x264 video encoder](http://www.videolan.org/developers/x264.html) within HandBrake to use a modified [constrained variable bitrate (CVBR)](https://en.wikipedia.org/wiki/Variable_bitrate) mode, and to automatically target bitrates appropriate for different input resolutions.

Input resolution | Target video bitrate
--- | ---
1080p or Blu-ray video | 8000 Kbps
720p | 4000 Kbps
480i, 576p or DVD video | 2000 Kbps

When audio transcoding is required, it's done in [AAC format](https://en.wikipedia.org/wiki/Advanced_Audio_Coding) and, if the original is [multi-channel surround sound](https://en.wikipedia.org/wiki/Surround_sound), in [Dolby Digital AC-3 format](https://en.wikipedia.org/wiki/Dolby_Digital). Meaning the output can contain two tracks from the same source in different formats. And mono, stereo and surround inputs are all handled differently.

Input channels | AAC track | AC-3 track
--- | --- | ---
Mono | 80 Kbps | none
Stereo | 160 Kbps | none
Surround | 160 Kbps | 640 Kbps with 5.1 channels

But most of these default settings and automatic behaviors can be easily overridden or augmented with additional command line options.

### Why `detect-crop`?

HandBrake applies automatic crop detection by default. While it's usually correct, it does guess wrong often enough not to be trusted without review. For example, HandBrake's default behavior removes the top and bottom 140 pixels from "[The Dark Knight (2008)](http://www.blu-ray.com/movies/The-Dark-Knight-Blu-ray/743/)" and "[The Hunger Games: Catching Fire (2013)](http://www.blu-ray.com/movies/The-Hunger-Games-Catching-Fire-Blu-ray/67923/)," losing significant portions of their full-frame content.

This is why `transcode-video` doesn't allow HandBrake to apply cropping by default.

Instead, the `detect-crop` tool leverages both HandBrake and MPlayer to find the video cropping bounds. It then indicates whether those two programs agree. To aid in review, this tool prints commands to the terminal console allowing the recommended (or disputed) crop to be displayed, as well as a sample command line for `transcode-video` itself.

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

#### Reducing output size

If reducing output size is more important to you than a possible loss in quality, use the `--small` option:

    transcode-video --small "/path/to/Movie.mkv"

Video bitrate targets are lowered 33-37% depending upon the video resolution of your input.

Input resolution | Target video bitrate with `--small`
--- | ---
1080p or Blu-ray video | 5000 Kbps
720p | 3000 Kbps
480i, 576p or DVD video | 1600 Kbps

Dolby Digital AC-3 audio bitrate limits are lowered 40%. However, there's no impact on the bitrate of mono and stereo AAC audio tracks.

Input channels | Pass through<br />with `--small` | AAC track<br />with `--small` | AC-3 track<br />with `--small`
--- | --- | --- | ---
Mono | AAC only | 80 Kbps | none
Stereo | AAC only | 160 Kbps | none
Surround | AC-3 only, up to 448 Kbps | 160 Kbps | 384 Kbps with 5.1 channels

With `--small`, noisy video and complex surround audio have the most potential for perceptible quality loss.

#### Improving performance

If you're willing to trade some precision for a 45-50% increase in video encoding speed, use the `--quick` option:

    transcode-video --quick "/path/to/Movie.mkv"

The `--quick` option is also more than 15% speedier than the x264 video encoder's "fast" preset and it avoids the occasional quality loss problems of the "faster" and "veryfast" presets.

Be aware that output files are slightly larger when using the `--quick` option since the loss of precision is also a loss of efficiency.

Performance also improves using the `--small` option due to fewer calculations being made and fewer bits being written to disk.

#### Cropping

No cropping is applied by default. Use the `--crop TOP:BOTTOM:LEFT:RIGHT` option and arguments to indicate the amount of black, non-content border to remove from the edges of your video.

This command removes the top and bottom 144 pixels, typical of a 2.40:1 widescreen movie embedded within 16:9 Blu-ray Disc video:

    transcode-video --crop 144:144:0:0 "/path/to/Movie.mkv"

This command removes the left and right 240 pixels, typical of a 4:3 classic TV show embedded within 16:9 Blu-ray Disc video:

    transcode-video --crop 0:0:240:240 "/path/to/Movie.mkv"

Use the `detect-crop` tool to determine the cropping bounds before transcoding.

You can also call the `detect-crop` logic from `transcode-video` with the single `detect` argument:

    transcode-video --crop detect "/path/to/Movie.mkv"

However, be aware that `detect` can fail if HandBrake and MPlayer disagree about the cropping values.

#### Understanding audio

By default, the `transcode-video` tool selects the first audio track in the input as the main audio track. This is the first track in the output and the default track for playback.

But you can select any input audio track as the main track. In this case, track number 3:

    transcode-video --main-audio 3 "/path/to/Movie.mkv"

Or you can select the first input audio track in a specific language using a three-letter code instead of a track index number. This command selects the first Spanish language track:

    transcode-video --main-audio spa "/path/to/Movie.mkv"

If no track in the target language is found, then selection defaults to the first audio track in the input.

You can also give the main audio track a custom name:

    transcode-video --main-audio 3="Original Stereo" "/path/to/Movie.mkv"

Unlike `HandBrakeCLI`, custom track names are allowed to contain commas.

By default, only one track is selected as the main audio or default track. But you can add additional tracks, also with custom names:

    transcode-video --add-audio 4 --add-audio 5="Director Commentary" "/path/to/Movie.mkv"

Or you can add all audio tracks with a single option and argument:

    transcode-video --add-audio all "/path/to/Movie.mkv"

You can also add audio tracks selected by their three-letter language code. This command adds all French and Spanish language tracks in the same order they're found in the input:

    transcode-video --add-audio fra,spa "/path/to/Movie.mkv"

By default, the main audio track is transcoded in AAC format and, if the original is multi-channel surround sound, in Dolby Digital AC-3 format. Meaning the output can contain two tracks from the same source in different formats. So, main audio output is "wide" enough for "double" tracks.

Also by default, any added audio tracks are only transcoded in AAC format. Meaning the output only contains a single track in one format. So, additional audio output is only "wide" enough for "stereo" tracks.

However, you can change the "width" of main audio or additional audio output using the `--audio-width` option. There are three possible widths: `double`, `surround` and `stereo`.

Use this command to treat any other additional audio tracks just like the main audio track:

    transcode-video --audio-width other=double "/path/to/Movie.mkv"

Or use this command to make main audio output as a single track but still allow it in surround format:

    transcode-video --audio-width main=surround "/path/to/Movie.mkv"

If possible, audio is first passed through in its original format, providing that format is either AC-3 or AAC. This hardly ever works for Blu-ray Discs but it often will for DVDs and other random videos.

However, you can still copy audio tracks and maintain their original format, provided HandBrake and your selected file format support it:

    transcode-video --copy-audio all "/path/to/Movie.mkv"

The `--copy-audio` option doesn't implicitly add audio tracks to be copied. Since only the main audio track is included by default, the previous command only tries to copy that track. To also copy another track, you must first add it:

    transcode-video --add-audio 4 --copy-audio all "/path/to/Movie.mkv"

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

The command to find the video cropping bounds is as simple as:

    detect-crop "/path/to/Movie.mkv"

Which prints out something like this:

    mplayer -really-quiet -nosound -vf rectangle=1920:816:0:132 '/path/to/Movie.mkv'
    mplayer -really-quiet -nosound -vf crop=1920:816:0:132 '/path/to/Movie.mkv'

    transcode-video --crop 132:132:0:0 '/path/to/Movie.mkv'

Just copy and paste the sample commands to preview or transcode.

If HandBrake and MPlayer disagree about the cropping values, then `detect-crop` prints out something like this:

    Results differ...

    # From HandBrakeCLI:

    mplayer -really-quiet -nosound -vf rectangle=1920:816:0:132 '/path/to/Movie.mkv'
    mplayer -really-quiet -nosound -vf crop=1920:816:0:132 '/path/to/Movie.mkv'

    transcode-video --crop 132:132:0:0 '/path/to/Movie.mkv'

    # From mplayer:

    mplayer -really-quiet -nosound -vf rectangle=1920:820:0:130 '/path/to/Movie.mkv'
    mplayer -really-quiet -nosound -vf crop=1920:820:0:130 '/path/to/Movie.mkv'

    transcode-video --crop 130:130:0:0 '/path/to/Movie.mkv'

You'll then need to preview both and decide which to use.

When input is a disc image directory instead of a single file, the `detect-crop` tool doesn't use MPlayer, nor does it print out commands to preview the crop.

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

* It's not pretty and it's not particularly easy to use. But once you figure out how it works, you can rip your video exactly the way you want.

#### Why a single `.mkv` file?

* Many automatic behaviors and other features in both `transcode-video` and `detect-crop` are not available when input is a disc image directory. This is because that format limits the ability of `HandBrakeCLI` and `mplayer` to detect or manipulate certain information about the video.

* Both forced subtitle extraction and lossless audio conversion, detailed below, are not possible when input is a disc image directory.

#### Why bother with forced subtitles?

* Remember "[The Hunt for Red October (1990)](http://www.blu-ray.com/movies/The-Hunt-For-Red-October-Blu-ray/920/)" when Sean Connery and Sam Neill are speaking actual Russian at the beginning of the movie instead of just using cheesy accents like they did the rest of the time? The Blu-ray Disc version provides English subtitles just for those few scenes. They're "forced" on screen for you. Which is actually very convenient.

* Forced subtitles are often embedded within a full subtitle track. And a special flag is set on the portion of that track which is supposed to be forced. MakeMKV can recognize that flag when it converts the video into a single `.mkv` file. It can even extract just the forced portion of that subtitle into a another separate subtitle track. And it can set a different "forced" flag in the output `.mkv` file on that separate track so other software can tell what it's for.

* Not all discs with forced subtitles have those subtitles embedded within other tracks. Sometimes they really are separate. But enough discs are designed with the embedded technique that you should avoid using a disc image directory as input for transcoding.

#### Why convert lossless audio?

* [DTS-HD Master Audio](https://en.wikipedia.org/wiki/DTS-HD_Master_Audio) is the most popular high definition, lossless audio format. It's used on more than 80% of all Blu-ray Discs.

* Currently, HandBrake can't decode the lossless portion of a DTS-HD audio track. It's only able to extract the non-HD, lossy core which is in [DTS format](https://en.wikipedia.org/wiki/DTS_(sound_system)).

* But MakeMKV can decode DTS-HD and convert it into FLAC format which can then be decoded by HandBrake and most other software. Once again, MakeMKV can only do this when it converts the video into a single `.mkv` file.

### Understanding the x264 preset system

The `--preset` option in `transcode-video` controls the x264 video encoder, not the other preset system built into HandBrake. It takes a preset name as its single argument:

    transcode-video --preset fast "/path/to/Movie.mkv"

The x264 preset names (mostly) reflect their relative speed compared to the default, `medium`.

Preset name | Note
--- | --- | ---
`ultrafast` | not recommended
`superfast` | not recommended
`veryfast` | use with caution
`faster` | use with caution
`fast` | good but you might want to use `--quick` instead
`medium` | default
`slow` | &#8203;
`slower` | &#8203;
`veryslow` | &#8203;
`placebo` | not recommended

Presets faster than `medium` trade precision and compression efficiency for more speed. That tradeoff is acceptable for the `fast` preset. But you may notice occasional quality loss problems when using the `faster` or `veryfast` presets.

Presets slower than `medium` trade encoding speed for more precision and compression efficiency. Any quality improvement using these presets may not be perceptible for most input.

### Recommended `transcode-video` usage

Use the default settings whenever possible.

Use the `--mp4` or `--m4v` options if your target player can't handle Matroska format.

Use the `--small` option if you want more space savings.

Use the `--quick` option if you're in a hurry.

Use `detect-crop` before transcoding to manually review and apply the best crop values.

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

## FAQ

### Should I worry about all these `VBV underflow` warnings?

No, these warnings are simply a side effect of my special ratecontrol system. The x264 video encoder within HandBrake is just being overly chatty. Ignore it. Nothing is wrong with the output from `transcode-video`.

### Can you make a GUI version of your tools?

My command line tools have the same behavior and scriptable interface across multiple platforms. Developing a GUI application with those requirements is not an investment that I want to make.

Plus, I wouldn't use a GUI for these tasks. And it's a bad idea to develop software that you won't use yourself.

### When will you add support for H.265 video?

[High Efficiency Video Coding](https://en.wikipedia.org/wiki/High_Efficiency_Video_Coding) or H.265  is the likely successor to [H.264](https://en.wikipedia.org/wiki/H.264/MPEG-4_AVC), which is the format currently output by `transcode-video`. HandBrake has supported H.265 ever since it included the [x265 video encoder](http://x265.org/).

My ratecontrol system can't be applied with the current version of the x265 encoder in HandBrake because it doesn't allow access to `qpmax`, critical for maintaining quality in certain situations. I'll consider adding support once the [fix for `qpmax` support in x265](https://bitbucket.org/multicoreware/x265/issues/232/add-option-to-specify-qpmax) is available in an official HandBrake release.

But support also requires equivalent quality at a smaller size when using my rate control system. And performance is an issue. While speed continues to improve, the x265 encoder is still considerably slower than the current H.264 system.

In the meantime, I recommend using the `--small` option to reduce output size. As a bonus, it's also faster.

### What about hardware-based video transcoding?

Using hardware with [Intel Quick Sync Video](https://en.wikipedia.org/wiki/Intel_Quick_Sync_Video) instead of software like x264 is certainly faster. HandBrake even supports that hardware on some platforms. However, my default ratecontrol system can't be applied to existing hardware encoders because they lack API to change the necessary settings.

Also, keep in mind that hardware encoders are typically designed for realtime video chat or other similar duties. To maintain that performance, they often take shortcuts with video quality like reducing reference frames, lowering subpixel motion estimation, etc. Such an approach is the equivalent of using the `veryfast` preset with a software encoder. That's fine for video chat but I wouldn't recommend it for transcoding your disc collection.

### Can you add support for Enhanced AC-3 audio?

[Dolby Digital Plus](https://en.wikipedia.org/wiki/Dolby_Digital_Plus) or Enhanced AC-3 is a successor to the Dolby Digital AC-3 audio format. AC-3 is the format currently output by `transcode-video` when surround audio is used as input. As of this writing, HandBrake only supports Enhanced AC-3 in development builds.

The original AC-3 format is limited to 5.1 audio channels. This means that any 7.1 channel audio track, typically available on Blu-ray Discs, needs to be downmixed during transcoding. The advantage to Enhanced AC-3 is that it can support up to 13.1 audio channels, so no downmixing is necessary.

Unfortunately, Enhanced AC-3 output is currently limited to 5.1 audio channels in HandBrake development builds. I'll consider adding support once an Enhanced AC-3 feature without that limitation is available in an official HandBrake release.

### How do you assess video transcoding quality?

I compare by visual inspection. Always with the video in motion, never frame by frame. It's tedious but after years of practice I know which portions of which videos are problematic and difficult to transcode. And I look at those first.

In addition, I use the `query-handbrake-log` tool to report on `ratefactor`, the average P-frame quantizer, to get a relative quality assessment from the x264 encoder.

What I don't use are [peak signal-to-noise ratios](https://en.wikipedia.org/wiki/Peak_signal-to-noise_ratio) or a [structural similarity index](https://en.wikipedia.org/wiki/Structural_similarity) in an attempt to objectively compare quality. Although both metrics are available to the x264 encoder, enabling either of them ironically disables key psychovisual optimizations that improve quality.

### What options do you use with `transcode-video`?

I use the default settings. That's why they're the defaults.

I never use the `--crop detect` function of `transcode-video` because I don't trust either `HandBrakeCLI` or `mplayer` to always get it right without supervision. Instead, I use the separate `detect-crop` tool before transcoding to manually review and apply the best crop values.

I let `transcode-video` automatically burn any forced subtitles into the output video track when the "forced" flag is enabled in the original.

I never include separate subtitle tracks, but I do add audio commentary tracks.

For a few problematic videos, I have to apply options like `--force-rate 23.976 --filter detelecine`. But that's rare.

## History

### [0.11.1](https://github.com/donmelton/video_transcoding/releases/tag/0.11.1)

Monday, September 26, 2016

* Add `queue-import-file` and anything starting with `preset` to the list of unsupported `HandBrakeCLI` options.
* Back out a change from version 0.3.1 to optimize setting the encoder level to behave more like past versions. This made no actual difference in the output video, only the `.log` file.
* Update the "README" document to:
    * Clarify tradeoffs when using the x264 preset system.
    * Revise the status of H.265 and Enhanced AC-3 support.
    * Tweak the description of how I use `transcode-video`. Again.

### [0.11.0](https://github.com/donmelton/video_transcoding/releases/tag/0.11.0)

Thursday, September 15, 2016

* Change the behavior of `detect-crop` and the `--crop detect` function of `transcode-video` to no longer constrain the crop by default. Add a `--constrain` option to `detect-crop` and a `--constrain-crop` option to `transcode-video` to restore the old behavior. Also, deprecate the `--no-constrain` option of `detect-crop` and the `--no-constrain-crop` option of `transcode-video` since both are no longer necessary. Via [ #81](https://github.com/donmelton/video_transcoding/issues/81).
* Update the "README" document to:
    * Revise multiple sections about the changes to cropping behavior.
    * Revise the description of the `--small` option in multiple sections.
    * Revise how I use `transcode-video` in the "FAQ" section.
* Add support for the `comb-detect`, `hqdn3d` and `pad` filters to `transcode-video`.
* Fix a bug in `transcode-video` where the `--filter` option failed when `nlmeans-tune` was used as a argument. This was due to a regular expression only allowing lowercase alpha characters and not hyphens.
* Update the default AC-3 audio and pass-through bitrates in the `--help` output of `transcode-video` to 640 Kbps, matching the behavior of the code since version 0.5.0.

### [0.10.0](https://github.com/donmelton/video_transcoding/releases/tag/0.10.0)

Friday, May 6, 2016

* Add resolution-specific qualifiers to the `--target` option in `transcode-video`. This allows different video bitrate targets for inputs with different resolutions. For example, you can use `--target 1080p=6500` alone to change the target for Blu-ray Discs and not DVDs. Or you could combine that with `--target 480p=2500` to affect both resolutions. Via [ #68](https://github.com/donmelton/video_transcoding/pull/68) from [@turley](https://github.com/turley).
* Fix a bug in `transcode-video` where video bitrate targets were not reset when the `--small` or `--small-video` options followed the `--target` option on the command line.
* Fix a bug where `query-handbrake-log` would fail for `time` or `speed` on OS X or Linux when parsing .log files created on Windows. This was due to a regular expression not expecting a carriage return (CR) before a line feed (LF), i.e. a Windows-style line ending (CRLF). Via [ #67](https://github.com/donmelton/video_transcoding/issues/67) from [@lambdan](https://github.com/lambdan).

### [0.9.0](https://github.com/donmelton/video_transcoding/releases/tag/0.9.0)

Monday, May 2, 2016

* Revise the syntax and behavior of the `--main-audio`, `--add-audio` and `--audio-width` options in `transcode-video`:
    * Allow selecting the main audio output track by finding the first input track in a specific language. For example, `--main-audio spa` can now use a language code to select the first Spanish track. Previously, only track numbers were allowed as main audio selection arguments. Via [ #8](https://github.com/donmelton/video_transcoding/issues/8) from [@JMoVS](https://github.com/JMoVS).
    * Allow assignment of an optional name to the main audio track when using a language code. For example, `--main-audio spa="Other Dialogue"` sets the track name in the same manner as using a track number.
    * Restrict the default main audio track to the first track, i.e. track number `1`, if the `--main-audio` option is not used. Previously, the default main audio track could be the first track selected by the `--add-audio` option when a language code argument was used. This was a hack because, at that time, the `--main-audio` option itself couldn't select by language.
    * No longer require or even allow `language=` to prefix a language code argument when using the `--add-audio` option. For example, use `--add-audio fra` to add all the French language tracks. This is much easier to type.
    * Add argument shortcuts to select the `main` track or `other` non-main tracks when using the `--audio-width` option. Previously, tracks were selected only by track number or `all` at once. The `main` shortcut is useful when the main audio track number is unknown because it was selected using a language code. The `other` shortcut is useful when `all` would also modify the main audio track.
* Revise the syntax of the `--add-subtitle` option in `transcode-video` to match the change to the `--add-audio` option which no longer requires or even allows `language=` to prefix a language code argument.
* Add a `--tabular` option to `query-handbrake-log` in order to better format its output report for later import into a spreadsheet application. This uses a tab character instead of a single space as the field delimiter and suppresses the `fps` and `kbps` labels. Via [ #64](https://github.com/donmelton/video_transcoding/issues/64).
* Fix a bug where `query-handbrake-log time` reported the wrong result when parsing .log files from output using a forced frame rate. It's possible this was a regression due to a change in HandBrake.
* Remove a stray "TODO" comment line in `query-handbrake-log`.
* Update the "README" document to:
    * Revise the "Understanding audio" section to reflect new syntax and behavior in `transcode-video`.
    * Add links to the "History" section for release numbers, pull requests, issues and contributors.
    * Correct the release date for version 0.4.0 in the "History" section.
    * Insert a missing "Via" and period in the 0.8.1 release information.

### [0.8.1](https://github.com/donmelton/video_transcoding/releases/tag/0.8.1)

Thursday, April 28, 2016

* Fix a bug where `query-handbrake-log` reported the wrong `time` or `speed` when parsing .log files containing output from HandBrake subtitle scan mode, i.e. when using `--burn-subtitle scan` or `--force-subtitle scan` from `transcode-video`. Via [ #46](https://github.com/donmelton/video_transcoding/issues/46) from [@martinpickett](https://github.com/martinpickett).
* Fix a bug where `query-handbrake-log ratefactor` failed if the number it was searching for was less than 10. This was due to HandBrake unexpectedly inserting a space before that number. Honestly, I doubt this ever happend before the new ratecontrol system debuted in 0.6.0. That's how good the new ratecontrol system is. Via [ #61](https://github.com/donmelton/video_transcoding/issues/61) from [@bmhayward](https://github.com/bmhayward).

### [0.8.0](https://github.com/donmelton/video_transcoding/releases/tag/0.8.0)

Sunday, April 24, 2016

* Add a `--no-constrain-crop` option to `transcode-video`. This changes the behavior of `--crop detect` to mimic the `--no-constrain` option in the `detect-crop` tool.
* Add a `--fallback-crop` option to `transcode-video`. This selects fallback crop values, from HandBrake, MPlayer or no crop at all, if `--crop detect` fails. This makes the new `--no-constrain-crop` option more useful since failure is more likely without constraints. Via [ #56](https://github.com/donmelton/video_transcoding/issues/56) from [@cameronks](https://github.com/cameronks).
* Add a `--aac-encoder` option to `transcode-video`. This gives Windows and Linux users access to the Fraunhofer FDK AAC encoder if it's compiled into their version of `HandBrakeCLI`. Via [ #35](https://github.com/donmelton/video_transcoding/pull/35) from [@cnrd](https://github.com/cnrd).
* Allow a colon (":") instead of a just period (".") to separate the two numerical components of a stream identifier when parsing scan output from `HandBrakeCLI`. This ensures compatibility with different versions of libavcodec and should fix several mysterious bugs on some Linux configurations. Via [ #30](https://github.com/donmelton/video_transcoding/issues/30) and [ #41](https://github.com/donmelton/video_transcoding/issues/41) from [@dgibbs64](https://github.com/dgibbs64).
* Maintain 480p video bitrate targets in `transcode-video` when scaling down to 480p using `--max-width 854 --max-height 480`. Via #58 from @mschout.
* Remove the deprecated `--old-behavior` option in `transcode-video`.
* Clarify the purpose of `--abr` and `--vbr` in the `--help` output of `transcode-video`.
* Update the "README" document to:
    * Add "FAQ" section. Via [ #26](https://github.com/donmelton/video_transcoding/issues/26) from [@reiesu](https://github.com/reiesu) and [ #59](https://github.com/donmelton/video_transcoding/issues/59) from [@dgibbs64](https://github.com/dgibbs64).
    * Add this "History" section.
    * Spell "rate control" as one word, like a real transcoding geek.
    * Insert a missing "you" in the first paragraph of the "Installation" section.
    * Mention and link to Linuxbrew in the "Requirements" section.
    * Describe the default ratecontrol system as a "modified constrained variable bitrate (CVBR) mode."
    * Add example output when HandBrake and MPlayer disagree to the "Using `detect-crop`" section. Via [ #18](https://github.com/donmelton/video_transcoding/issues/18) from [@alanwsmith](https://github.com/alanwsmith).
    * Update the status of DTS-HD decoding for HandBrake and MakeMKV in the "Why convert lossless audio?" section.

### [0.7.0](https://github.com/donmelton/video_transcoding/releases/tag/0.7.0)

Thursday, April 7, 2016

* Once again, lower the video bitrate targets for 480p and 720p output in `transcode-video`. Note that 1080p and 2160p targets still remain unchanged. Via [ #55](https://github.com/donmelton/video_transcoding/issues/55).
* Update the "README" document to:
    * Reflect changes to the 480p and 720p video bitrate targets.
    * Revise description of and recommendation for the `--quick` option.
    * Revise warnings about using slower x264 presets.
* Add a `--target` option to `transcode-video` allowing explicit control of the video bitrate target.
* Deprecate the `--old-behavior` option in `transcode-video`.
* Remove the deprecated `--big` option in `transcode-video`.
* Separate `--small` and `--small-video` in the `--help` output of `transcode-video`.

### [0.6.0](https://github.com/donmelton/video_transcoding/releases/tag/0.6.0)

Sunday, April 3, 2016

* Revise the default ratecontrol system and video bitrate targets in `transcode-video`:
    * Raise the quality target by lowering the constant ratefactor (CRF) from `16` to `1`, the lowest lossy CRF value available with the x264 video encoder. This significantly improves video quality but also raises bitrates much closer to the targets, thereby increasing output file sizes for some inputs.
    * Raise the quality limit by setting `qpmax`, the x264 quantizer maximum, to `34`. This prevents x264 from occasionally generating a single, but still noticeable, very low quality frame because the CRF value is set so low.
    * Lower the video bitrate targets for 480p and 720p output to keep bitrates and file sizes closer to that produced by the old ratecontrol system. Note that 1080p and 2160p targets remain unchanged.
    * Add an `--old-behavior` option to restore the old ratecontrol system and video bitrate targets for users not yet wanting to change over. This option is only temporary and will soon be deprecated and then removed.
    * Update the "README" document to reflect changes to the 480p and 720p video bitrate targets.
* Remove an obsolete `brew install caskroom/cask/brew-cask` line from the "README" document. Via [ #54](https://github.com/donmelton/video_transcoding/pull/54) from [@timsutton](https://github.com/timsutton).

### [0.5.1](https://github.com/donmelton/video_transcoding/releases/tag/0.5.1)

Thursday, February 25, 2016

* Don't fail if the `ffmpeg` version string can't be parsed. Via [ #43](https://github.com/donmelton/video_transcoding/issues/43) from [@rementis](https://github.com/rementis), [@Lambdafive](https://github.com/Lambdafive) and [@kford](https://github.com/kford).
* Remove the deprecated `--cvbr` option in `transcode-video`.

### [0.5.0](https://github.com/donmelton/video_transcoding/releases/tag/0.5.0)

Thursday, January 14, 2016

* Raise the default video bitrate targets and AC-3 audio bitrate limits in `transcode-video`:
    * Deprecate the `--big` option since its behavior is now the default. An informal survey via Twitter and Facebook showed that about 90% of users (including myself) responding were always using the `--big` option anyway to get higher quality.
    * Add a `--small` option to restore the old video bitrate targets and AC-3 audio bitrate limits.
    * Add a `--small-video` option to restore only the old video bitrate targets. Via Facebook from [@DaveHamilton](https://github.com/DaveHamilton).
    * Update the "README" document to reflect all these changes.
* Move `--abr` and `--vbr` to the advanced options section in the `--help` output of `transcode-video`.
* Deprecate the experimental `--cvbr` option in `transcode-video`.

### [0.4.0](https://github.com/donmelton/video_transcoding/releases/tag/0.4.0)

Monday, January 11, 2016

* Add a `--cvbr` option to `transcode-video`. This implements a very experimental variation of the default ratecontrol system with a target bitrate as its single argument. Use it for evaluation purposes only.

### [0.3.1](https://github.com/donmelton/video_transcoding/releases/tag/0.3.1)

Friday, January 8, 2016

* Fix compatibility with development/nightly builds of `HandBrakeCL` in `transcode-video`:
    * Always force the x264 `medium` preset to override the new `veryfast` default value. Via [ #36](https://github.com/donmelton/video_transcoding/pull/36) from [@cnrd](https://github.com/cnrd).
    * Explicitly set the encoder profile to `high` to override the new `main` default value.
    * Explicitly (and dynamically) set the encoder level to override the new `4.0` default value. 
* Fix a stupid regression from version 0.2.8 caused by a typo in the patch for the SubRip-format text file offset fix to `transcode-video`. Via [ #37](https://github.com/donmelton/video_transcoding/issues/37) from [@bpharriss](https://github.com/bpharriss).
* Be more lenient about `--encoder-option` arguments in `transcode-video` so `8x8dct` is allowed.
* Always print the `HandBrakeCLI` version string to diagnostic output even if it can't be parsed.

### [0.3.0](https://github.com/donmelton/video_transcoding/releases/tag/0.3.0)

Tuesday, January 5, 2016

* Add a `--abr` option to `transcode-video`. This implements a modified average bitrate (ABR) ratecontrol system with a target bitrate as its single argument. It produces a much more predictable output size but lower quality than the default ratecontrol system. It can sometimes be handy but use it with caution.
* Add a `--vbr` option to `transcode-video`. This implements a true VBR ratecontrol system with a constant ratefactor as its single argument, much like HandBrake's default behavior when using its `--quality` option. It's useful mostly for comparison testing against the default ratecontrol system.
* Update all copyright notices to the year 2016.

### [0.2.8](https://github.com/donmelton/video_transcoding/releases/tag/0.2.8)

Tuesday, January 5, 2016

* Prevent the `--bind-srt-language` option in `transcode-video` from also setting the SubRip-format text file offset to the same value. This was a stupid copy and paste error since the initial project version. Via [ #25](https://github.com/donmelton/video_transcoding/pull/25) from [@arikalish](https://github.com/arikalish).
* Don't fail if the `HandBrakeCLI` version string can't be parsed. Via [ #29](https://github.com/donmelton/video_transcoding/issues/29) from [@paulbailey](https://github.com/paulbailey).
* Don't fail if the `mp4track` version string can't be parsed. Via [ #27](https://github.com/donmelton/video_transcoding/issues/27) from [@dgibbs64](https://github.com/dgibbs64).
* Add a missing preposition to the last bullet point of the "Why MakeMKV?" section in the "README" document. Via [ #32](https://github.com/donmelton/video_transcoding/pull/32) from [@eventualbuddha](https://github.com/eventualbuddha).

### [0.2.7](https://github.com/donmelton/video_transcoding/releases/tag/0.2.7)

Tuesday, July 7, 2015

* Apply the `--subtitle-forced` option when scanning subtitles in `transcode-video`. Via [ #20](https://github.com/donmelton/video_transcoding/issues/20) from [@rhapsodians](https://github.com/rhapsodians).

### [0.2.6](https://github.com/donmelton/video_transcoding/releases/tag/0.2.6)

Wednesday, May 20, 2015

* Prevent the user's file format choice from corrupting the output path in `transcode-video` and `convert-video`. Via [ #5](https://github.com/donmelton/video_transcoding/issues/5) from [@arikalish](https://github.com/arikalish).

### [0.2.5](https://github.com/donmelton/video_transcoding/releases/tag/0.2.5)

Sunday, May 17, 2015

* Simplify the calculation of `vbv-bufsize` in `transcode-video`.

### [0.2.4](https://github.com/donmelton/video_transcoding/releases/tag/0.2.4)

Friday, May 15, 2015

* Prevent an undefined method error if `HandBrakeCLI` removes tracks during scan. Via [ #15](https://github.com/donmelton/video_transcoding/issues/15) from [@blackoctopus](https://github.com/blackoctopus).

### [0.2.3](https://github.com/donmelton/video_transcoding/releases/tag/0.2.3)

Tuesday, May 12, 2015

* No longer fail on invalid audio and subtitle track information when parsing scan output from `HandBrakeCLI`. Via [ #11](https://github.com/donmelton/video_transcoding/issues/11) from [@eltito51](https://github.com/eltito51) and [ #13](https://github.com/donmelton/video_transcoding/issues/13) from [@tchjunky](https://github.com/tchjunky).

### [0.2.2](https://github.com/donmelton/video_transcoding/releases/tag/0.2.2)

Monday, May 11, 2015

* Ensure the AC-3 passthru bitrate in `transcode-video` is never below the AC-3 encoding bitrate.

### [0.2.1](https://github.com/donmelton/video_transcoding/releases/tag/0.2.1)

Sunday, May 10, 2015

* Fix the `--main-audio` option in `transcode-video` by ensuring the `resolve_main_audio` method actually returns a result. Via [ #9](https://github.com/donmelton/video_transcoding/issues/9) from [@JMoVS](https://github.com/JMoVS).

### [0.2.0](https://github.com/donmelton/video_transcoding/releases/tag/0.2.0)

Saturday, May 9, 2015

* Rewrite the automatic frame rate and deinterlace logic in `transcode-video` to match the behavior of the old `transcode-video.sh` script on which the tool is based.
* Clarify in `--help` output that `transcode-video` audio copy policies only apply to main and explicitly added audio tracks.
* Ignore the sometimes missing patch version when checking MPlayer.
* Mention in the "README" document that custom track names and external subtitle file names are allowed to contain commas.

### [0.1.4](https://github.com/donmelton/video_transcoding/releases/tag/0.1.4)

Friday, May 8, 2015

* Fix a stupid regression from version 0.1.2 caused by the line endings fix on Windows. Via [ #7](https://github.com/donmelton/video_transcoding/issues/7) from [@brandonedling](https://github.com/brandonedling).

### [0.1.3](https://github.com/donmelton/video_transcoding/releases/tag/0.1.3)

Friday, May 8, 2015

* Check the extra version number for MPlayer to accept all builds. Via [ #6](https://github.com/donmelton/video_transcoding/issues/6) from [@CallumKerrEdwards](https://github.com/CallumKerrEdwards).

### [0.1.2](https://github.com/donmelton/video_transcoding/releases/tag/0.1.2)

Thursday, May 7, 2015

* Fix handling of DOS-style line endings when parsing scan output from `HandBrakeCLI` on Windows. Via [ #4](https://github.com/donmelton/video_transcoding/issues/4) from [@CallumKerrEdwards](https://github.com/CallumKerrEdwards) and [@commandtab](https://github.com/commandtab).
* Disable automatic subtitle burning in `transcode-video` when input is MP4 format.
* Clarify usage of `--copy-audio` option in the "README" document. Via [ #5](https://github.com/donmelton/video_transcoding/issues/5) from [@arikalish](https://github.com/arikalish).
* Fix some section links in the "README" document. Via [ #3](https://github.com/donmelton/video_transcoding/pull/3) from [@vitorgalvao](https://github.com/vitorgalvao).

### [0.1.1](https://github.com/donmelton/video_transcoding/releases/tag/0.1.1)

Wednesday, May 6, 2015

* Add a workaround in the `Media` class `initialize` method for no required keyword arguments in Ruby 2.0. Via [ #1](https://github.com/donmelton/video_transcoding/pull/1) from [@cadonau](https://github.com/cadonau) and [ #2](https://github.com/donmelton/video_transcoding/issues/2) from [@CallumKerrEdwards](https://github.com/CallumKerrEdwards).

### [0.1.0](https://github.com/donmelton/video_transcoding/releases/tag/0.1.0)

Tuesday, May 5, 2015

* Initial project version.

## Feedback

The best way to send feedback is mentioning me, [@donmelton](https://twitter.com/donmelton), on Twitter. You can also file bugs or ask questions in a longer form by [creating a new issue](https://github.com/donmelton/video_transcoding/issues) on GitHub. I always try to respond quickly but sometimes it may take as long as 24 hours.

## Acknowledgements

A big "thank you" to the developers of HandBrake and the other tools used by this package. So much wow.

Thanks to [Rene Ritchie](https://twitter.com/reneritchie) for letting me continue to babble on about transcoding in his podcasts.

Thanks to [Joyce Melton](https://twitter.com/erinhalfelven), my sister, for help editing this "README" document.

Many thanks to [Jordan Breeding](https://twitter.com/jorbsd) and numerous others online for their positive feedback, bug reports and useful suggestions.

## License

Video Transcoding is copyright [Don Melton](http://donmelton.com/) and available under a [MIT license](https://github.com/donmelton/video_transcoding/blob/master/LICENSE).
