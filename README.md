# Video Transcoding

Tools to transcode, inspect and convert videos.

## About

Hi, I'm [Lisa Melton](https://lisamelton.net/). I created these tools to transcode my collection of Blu-ray Discs and DVDs into a smaller, more portable format while remaining high enough quality to be mistaken for the originals.

What makes these tools unique are the [ratecontrol systems](#explanation) which achieve those goals.

This package is based on my original collection of [Video Transcoding Scripts](https://github.com/donmelton/video-transcoding-scripts) written in Bash. While still available online, those scripts are no longer in active development. Users are encouraged to install this Ruby Gem instead.

Most of the tools in this package are essentially intelligent wrappers around Open Source software like [HandBrake](https://handbrake.fr/), [FFmpeg](http://ffmpeg.org/), [MKVToolNix](https://www.bunkus.org/videotools/mkvtoolnix/), and [MP4v2](https://code.google.com/p/mp4v2/). And they're all designed to be executed from the command line shell:

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
* [Explanation](#explanation)
* [FAQ](#faq)
* [History](#history)
* [Feedback](#feedback)
* [Acknowledgements](#acknowledgements)
* [License](#license)

## Installation

My Video Transcoding tools are designed to work on macOS, Linux and Windows. They're packaged as a Gem and require Ruby version 2.0 or later. See "[Installing Ruby](https://www.ruby-lang.org/en/documentation/installation/)" if you don't have the proper version on your platform.

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
* `mkvpropedit`
* `mp4track`

Previewing the output of `detect-crop` is optional, but doing so uses [`mpv`](https://mpv.io/), a free, Open Source, and cross-platform media player.

You can download the command line version of HandBrake, called `HandBrakeCLI`, here:

<https://handbrake.fr/downloads2.php>

On macOS, `HandBrakeCLI` and all its other dependencies can be easily installed via [Homebrew](http://brew.sh/), an add-on package manager:

    brew install handbrake
    brew install ffmpeg
    brew install mkvtoolnix
    brew install mp4v2

The optional crop previewing package can also be installed via Homebrew:

    brew install mpv

On Linux, package management systems vary so it's best consult the indexes for those systems. But there's a Homebrew port available called [Linuxbrew](http://linuxbrew.sh/) and it doesn't require root access.

On Windows, it's best to follow one of the two methods, manually installing binaries or installing into the [Windows Subsystem for Linux](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux), as described here:

<https://github.com/JMoVS/installing_video_transcoding_on_windows>

When installing `HandBrakeCLI` or other downloaded programs, make sure the executable binary is in a directory listed in your `PATH` environment variable. On Unix-style systems like macOS and Linux, that directory might be `/usr/local/bin`.

If you're comfortable using [Docker virtualization software](https://en.wikipedia.org/wiki/Docker_(software)), a pre-built container with everything you need, plus installation instructions, is available here:

<https://hub.docker.com/r/ntodd/video-transcoding/>

## Rationale

### Why `transcode-video`?

Videos from the [iTunes Store](https://en.wikipedia.org/wiki/ITunes_Store) are my template for a portable format while remaining high enough quality to be mistaken for the originals. Their files are very good quality, much smaller than the same video on a Blu-ray Disc, and play on a wide variety of devices.

HandBrake is a powerful video transcoding tool but it's complicated to configure. It has several presets but they aren't smart enough to automatically change bitrate targets and other encoding options based on different inputs. More importantly, HandBrake's default presets don't produce a predictable output size with sufficient quality.

HandBrake's "AppleTV 3" preset is closest to what I want but transcoding "[Planet Terror (2007)](http://www.blu-ray.com/movies/Planet-Terror-Blu-ray/1248/)" with it results in a huge video bitrate of 19.9 Mbps, very near the original of 22.9 Mbps. And transcoding "[The Girl with the Dragon Tattoo (2011)](http://www.blu-ray.com/movies/The-Girl-with-the-Dragon-Tattoo-Blu-ray/35744/)," while much smaller in output size, lacks detail compared to the original.

So, the `transcode-video` tool configures the [x264 video encoder](http://www.videolan.org/developers/x264.html) within HandBrake to use a modified [constrained variable bitrate (CVBR)](https://en.wikipedia.org/wiki/Variable_bitrate) mode, and to automatically target bitrates appropriate for different input resolutions.

Input resolution | Target video bitrate
--- | ---
1080p or Blu-ray video | 6000 Kbps
720p | 3000 Kbps
480i, 576p or DVD video | 1500 Kbps

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

Instead, the `detect-crop` tool leverages both HandBrake and FFmpeg to find the video cropping bounds. It then indicates whether those two programs agree. To aid in review, this tool prints commands to the terminal console allowing the recommended (or disputed) crop to be displayed, as well as a sample command line for `transcode-video` itself.

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

#### Improving performance

You can increase encoding speed by 70-80% with no easily perceptible loss in video quality by using the `--quick` option:

    transcode-video --quick "/path/to/Movie.mkv"

The `--quick` option avoids the typical quality problems associated with the x264 video encoder's speed-based presets, especially as that speed increases.

#### Cropping

No cropping is applied by default. Use the `--crop TOP:BOTTOM:LEFT:RIGHT` option and arguments to indicate the amount of black, non-content border to remove from the edges of your video.

This command removes the top and bottom 144 pixels, typical of a 2.40:1 widescreen movie embedded within 16:9 Blu-ray Disc video:

    transcode-video --crop 144:144:0:0 "/path/to/Movie.mkv"

This command removes the left and right 240 pixels, typical of a 4:3 classic TV show embedded within 16:9 Blu-ray Disc video:

    transcode-video --crop 0:0:240:240 "/path/to/Movie.mkv"

Use the `detect-crop` tool to determine the cropping bounds before transcoding.

You can also call the `detect-crop` logic from `transcode-video` with the single `detect` argument:

    transcode-video --crop detect "/path/to/Movie.mkv"

However, be aware that `detect` can fail if HandBrake and FFmpeg disagree about the cropping values.

Which is why you can select a fallback behavior using the `--fallback-crop` option when that happens, choosing `handbrake`, `ffmpeg`, `minimal` or `none` as its argument:

    transcode-video --crop detect --fallback-crop minimal "/path/to/Movie.mkv"

The `minimal` argument is perhaps the most useful behavior since it determines the smallest possible crop values by combining results from both `HandBrakeCLI` and `ffmpeg`.

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

    mpv --no-audio --vf lavfi=[drawbox=0:132:1920:816:invert:1] '/path/to/Movie.mkv'
    mpv --no-audio --vf crop=1920:816:0:132 '/path/to/Movie.mkv'

    transcode-video --crop 132:132:0:0 '/path/to/Movie.mkv'

Just copy and paste the sample commands to preview or transcode.

Please note that path names within the sample commands are not escaped properly when using `cmd.exe` or PowerShell on Windows. If you have [Git for Windows](https://git-for-windows.github.io/) or another Unix-like environment installed, you can use the [Bash shell](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) (usually named `bash.exe`) to work around this issue.

If HandBrake and FFmpeg disagree about the cropping values, then `detect-crop` prints out something like this:

    Results differ...

    # From HandBrakeCLI:

    mpv --no-audio --vf lavfi=[drawbox=0:132:1920:816:invert:1] '/path/to/Movie.mkv'
    mpv --no-audio --vf crop=1920:816:0:132 '/path/to/Movie.mkv'

    transcode-video --crop 132:132:0:0 '/path/to/Movie.mkv'

    # From ffmpeg:

    mpv --no-audio --vf lavfi=[drawbox=0:130:1920:820:invert:1] '/path/to/Movie.mkv'
    mpv --no-audio --vf crop=1920:820:0:130 '/path/to/Movie.mkv'

    transcode-video --crop 130:130:0:0 '/path/to/Movie.mkv'

You'll then need to preview both and decide which to use.

When input is a disc image directory instead of a single file, the `detect-crop` tool doesn't use FFmpeg, nor does it print out commands to preview the crop.

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

Chapter markers, metadata such as track titles and most subtitles are converted. However, be aware that any Blu-ray Disc-format subtitles are ignored.

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

* It runs on most desktop computer platforms like macOS, Windows and Linux. There's even a free version available to try before you buy.

* It was designed to decrypt and extract a video track, usually the main feature of a disc and convert it into a single Matroska format `.mkv` file. And it does this really, really well.

* It can also make an unencrypted backup of your entire Blu-ray or DVD to a disc image directory.

* It's not pretty and it's not particularly easy to use. But once you figure out how it works, you can rip your video exactly the way you want.

#### Why a single `.mkv` file?

* Many automatic behaviors and other features in both `transcode-video` and `detect-crop` are not available when input is a disc image directory. This is because that format limits the ability of `HandBrakeCLI` and `ffmpeg` to detect or manipulate certain information about the video.

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

    transcode-video --preset slow "/path/to/Movie.mkv"

The x264 preset names (mostly) reflect their relative speed compared to the default, `medium`.

Presets faster than `medium` trade precision and compression efficiency for more speed. You may notice quality loss problems when using these presets, especially as speed increases.

However, you can increase encoding speed by 70-80% with no easily perceptible loss in video quality by using the `--quick` option instead:

    transcode-video --quick "/path/to/Movie.mkv"

Presets slower than `medium` trade encoding speed for more precision and compression efficiency. Any quality improvement using these presets may not be perceptible for most input.

A faster and more perceptible way to improve quality is to simply raise the target video bitrate 50% by using the `--target big` option and argument macro:

    transcode-video --target big "/path/to/Movie.mkv"

### Recommended `transcode-video` usage

Use the default settings whenever possible.

Use the `--mp4` or `--m4v` options if your target player can't handle Matroska format.

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

These examples are written in Bash and only supply crop values. But almost any scripting language can be used and any option can be changed on a per input basis. [Nick Wronski](https://github.com/nwronski) has written a batch-processing wrapper for `transcode-video` in [Node.js](https://nodejs.org/), available here:

<https://github.com/nwronski/batch-transcode-video>

## Explanation

### Ratecontrol systems

What is a ratecontrol system? It's how a video encoder decides on the amount of bits to allocate for a specific frame.

My `transcode-video` tool has four different ratecontrol systems which manipulate x264 and three which manipulate x265, both software-based video encoders built into `HandBrakeCLI`.

Additionally, `transcode-video` allows access to hardware-based video encoders which have their own ratecontrol systems.

All of these ratecontrol systems, mine and those built into hardware, target a specific video bitrate.

The target video bitrate for all of these systems is automatically determined by `transcode-video` using the resolution of the input. For example, the default target for 1080p output is `6000` Kbps, which is about one-fifth the video bitrate found on a typical Blu-ray Disc.

### How my simple and special ratecontrol systems work

My simple and special ratecontrol systems attempt to produce the highest possible video quality near a target bitrate using a constant ratefactor (CRF) to specify quality. A CRF is represented by a number from `0` to `51` with lower values indicating higher quality. The special value of `0` is for lossless output.

Unfortunately, the output bitrate is extremely unpredictable when using the default CRF-based system in x264 or x265. Typically, people pick a middle-level CRF value as their quality target and just hope for the best. This is what most of the presets built into HandBrake do, choosing a CRF of `20` or `22`.

But such a strategy can result in output larger than its input or, worse, output too low in quality to be mistaken for that input.

So I set the target CRF value to `1`, the best possible "lossy" quality. Normally this would produce a huge output bitrate but I also reduce the encoder's maximum bitrate to my target, e.g. `6000` Kbps for 1080p output, by manipulating an option called `vbv-maxrate`.

With this approach, the encoder chooses the lowest CRF value, and therefore the highest quality, which fits below that maximum bitrate ceiling, even if that's usually not a a CRF value of `1`.

And this fully describes the behavior of `transcode-video` when using the `--simple` option.

However, my special, or default, ratecontrol system also sets a maximum CRF (`crf-max`) value of `25`, raising the minimum quality. This allows `vbv-maxrate` to become a "soft" ceiling so that the output bitrate can exceed the target when necessary to maintain that quality.

Unfortunately, this internal tug of war can cause the encoder to sometimes generate a few very low quality frames. 

As part of the encoding process, a quantizer value (QP) is calculated for each macroblock within a frame of video. A QP is represented by a number from `0` to `69` with lower values indicating higher quality.

So I set a maximum quantizer (`qpmax`) value of `34`, again raising the minimum quality. The occasional bad frame is still there, but it's no longer noticeable because it's now of sufficient quality to blend in with the others.

### How my average bitrate (ABR) ratecontrol system works

My average bitrate (ABR) ratecontrol system, selected via the `--abr` option, is based on the ABR algorithm already within x264 and x265 which targets a specific bitrate. 

But I constrain the maximum bitrate (`vbv-maxrate`) to only 1.5 times that of the target, i.e. to just `9000` Kbps when the target bitrate is `6000` Kbps for 1080p output.

It seems counterintuitive, but constraining the maximum bitrate prevents too much bitrate being wasted on complex or difficult to encode passages at the expense of quality elsewhere. This is because with an average bitrate algorithm, when the peaks get too high then the valleys get too low.

And this manipulation is exactly the same strategy used by streaming services such as Netflix.

### How my average variable bitrate (AVBR) ratecontrol system works

My average variable bitrate (AVBR) ratecontrol system, selected via the `--avbr` option, is also based on the ABR algorithm already within x264 which targets a specific bitrate.

But the maximum bitrate is not constrained like my ABR system.

Instead, the tolerance of missing the average bitrate is raised to the maximum amount, disabling overflow detection completely. This makes the ABR algorithm behave much more like a CRF-based encode, so final bitrates can be 10-15% higher or lower than the target.

And to prevent bitrates from getting too low, the Macroblock-tree ratecontrol system built into x264 is disabled. While this does lower compression efficiency somewhat, it significantly reduces blockiness, color banding and other artifacts.

Unfortunately, these modifications to implement AVBR are not possible when using x265.

## FAQ

### Should I worry about all these `VBV underflow` warnings?

No, these warnings are simply a side effect of my special ratecontrol system. The x264 video encoder within HandBrake is just being overly chatty. Ignore it. Nothing is wrong with the output from `transcode-video`.

### Can you make a GUI version of your tools?

My command line tools have the same behavior and scriptable interface across multiple platforms. Developing a GUI application with those requirements is not an investment that I want to make.

Plus, I wouldn't use a GUI for these tasks. And it's a bad idea to develop software that you won't use yourself.

### When will you add support for H.265 video?

HandBrake has supported [High Efficiency Video Coding](https://en.wikipedia.org/wiki/High_Efficiency_Video_Coding) or H.265 ever since it included the [x265 video encoder](http://x265.org/).

You can try HEVC transcoding now using the `--encoder` option:

    transcode-video --encoder x265 "/path/to/Movie.mkv"

While speed continues to improve, x265 is still considerably slower than the default x264 encoder.

### What about hardware-based video transcoding?

Hardware-based encoders, like those in [Intel Quick Sync Video](https://en.wikipedia.org/wiki/Intel_Quick_Sync_Video), are often considerably faster than x264 or x265. Some are available in recent versions of HandBrake.

Check the `Video Options` section from the output of `HandBrakeCLI --help` to find out if your platform has any of these video encoders available:

Platform | H.264 encoder | HEVC encoder
--- | --- | ---
Intel Quick Sync Video | `qsv_h264` | `qsv_h265` and `qsv_h265_10bit`
AMD Video Coding Engine | `vce_h264` | `vce_h265`
Nvidia NVENC | `nvenc_h264` | `nvenc_h265`
Apple VideoToolbox | `vt_h264` | `vt_h265`

You can try hardware-based transcoding now using the `--encoder` option. On macOS, select the Apple VideoToolbox H.264 encoder this way:

    transcode-video --encoder vt_h264 "/path/to/Movie.mkv"

You can also use the `--target` option with these encoders.

### How do you assess video transcoding quality?

I compare by visual inspection. Always with the video in motion, never frame by frame. It's tedious but after years of practice I know which portions of which videos are problematic and difficult to transcode. And I look at those first.

In addition, I use the `query-handbrake-log` tool to report on `ratefactor`, the average P-frame quantizer, to get a relative quality assessment from the x264 encoder.

What I don't use are [peak signal-to-noise ratios](https://en.wikipedia.org/wiki/Peak_signal-to-noise_ratio) or a [structural similarity index](https://en.wikipedia.org/wiki/Structural_similarity) in an attempt to objectively compare quality. Although both metrics are available to the x264 encoder, enabling either of them ironically disables key psychovisual optimizations that improve quality.

### What options do you use with `transcode-video`?

I never use the `--crop detect` function of `transcode-video` because I don't trust either `HandBrakeCLI` or `ffmpeg` to always get it right without supervision. Instead, I use the separate `detect-crop` tool before transcoding to manually review and apply the best crop values.

I let `transcode-video` automatically burn any forced subtitles into the output video track when the "forced" flag is enabled in the original.

I never include separate subtitle tracks, but I do add audio commentary tracks.

For a few problematic videos, I have to apply options like `--force-rate 23.976 --filter detelecine`. But that's rare.

## History

All of the notes for each [release](https://github.com/lisamelton/video_transcoding/releases) are now available in the "[CHANGELOG](https://github.com/lisamelton/video_transcoding/blob/master/CHANGELOG.md)" document.

## Feedback

The best way to send feedback is mentioning me, [@lisamelton@mastodon.social](https://mastodon.social/@lisamelton), on Mastodon. You can also file bugs or ask questions in a longer form by [creating a new issue](https://github.com/lisamelton/video_transcoding/issues) on GitHub. I always try to respond quickly but sometimes it may take as long as 24 hours.

## Acknowledgements

A big "thank you" to the developers of HandBrake and the other tools used by this package. So much wow.

Thanks to [Rene Ritchie](https://twitter.com/reneritchie) for letting me continue to babble on about transcoding in his podcasts.

Thanks to [Joyce Melton](https://twitter.com/erinhalfelven), my sister, for help editing this "README" document.

Many thanks to [Jordan Breeding](https://twitter.com/jorbsd) and numerous others online for their positive feedback, bug reports and useful suggestions.

## License

Video Transcoding is copyright [Lisa Melton](https://lisamelton.net/) and available under a [MIT license](https://github.com/lisamelton/video_transcoding/blob/master/LICENSE).
