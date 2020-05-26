# Changes to the "[Video Transcoding](https://github.com/donmelton/video_transcoding)" project

This single document contains all of the notes created for each [release](https://github.com/donmelton/video_transcoding/releases).

## [0.25.3](https://github.com/donmelton/video_transcoding/releases/tag/0.25.3)

Tuesday, May 26, 2020

* Modify `detect-crop` to show preview commands compatible with newer versions of `mpv`.
* Update all copyright notices to the year 2020.

## [0.25.2](https://github.com/donmelton/video_transcoding/releases/tag/0.25.2)

Wednesday, May 15, 2019

* Fix a crash in `transcode-video` with the `--copy-audio-name` option when the input audio track name does not exist. Via [ #279](https://github.com/donmelton/video_transcoding/issues/279).

## [0.25.1](https://github.com/donmelton/video_transcoding/releases/tag/0.25.1)

Saturday, March 30, 2019

* Fix a heinous multi-part bug in `transcode-video` which could prevent the proper detection of certain input audio formats, normally allowed for pass-through, from being copied unchanged to the output. This could also cause the `--keep-ac3-stereo` option from behaving correctly when used together with the `--ac3-encoder eac3` option and argument. Thanks to [@khaosx](https://github.com/khaosx) for finding the problem!

## [0.25.0](https://github.com/donmelton/video_transcoding/releases/tag/0.25.0)

Saturday, March 9, 2019

* Change the default mixdown for stereo audio output tracks in `transcode-video` from Dolby Pro Logic II format to regular stereo. This matches the behavior of the presets in HandBrake since version 1.2.0. The old behavior is still available in `transcode-video` via the `--mixdown dpl2` option and argument. Via [ #262](https://github.com/donmelton/video_transcoding/issues/262).
* Remove previous addition to the "README" document explaining that stereo tracks can also include surround audio information in matrix-encoded Dolby Pro Logic II format since that's no longer the default behavior, nor is it recommended (which makes me sad).
* In order to avoid a crash on the Windows Subsystem for Linux platform, buffer characters that seem to be part of a multibyte UTF-8 sequence when copying output from `HandBrakeCLI` to the console or the `.log` file in `transcode-video` and from `ffmpeg` to the console in `convert-video`. Thanks to [@joshstaiger](https://github.com/joshstaiger) for the persistent detective work and the patch! Via [ #189](https://github.com/donmelton/video_transcoding/issues/189) and [ #264](https://github.com/donmelton/video_transcoding/pull/264).
* As a convenience to those _not_ using batch scripts, echo the output file name at the completion of transcoding. Thanks to [@JayJay1974](https://github.com/JayJay1974) for the idea! Via [ #260](https://github.com/donmelton/video_transcoding/issues/260).
* Explain the `--fallback-crop` option and its new `minimal` argument in the "Cropping" section of the "README" document. Thanks to [@JMoVS](https://github.com/JMoVS) for the reminder! Via [ #266](https://github.com/donmelton/video_transcoding/issues/266).
* Modify the `--help` output of `transcode-video` to clarify that the `--ac3-bitrate` and `--pass-ac3-bitrate` options only affect surround audio and surround pass-through bitrates.
* Lower the bitrate of stereo and mono Dolby Digital Plus output to sensible levels in `transcode-video` when applying the `--ac3-encoder eac3` option and argument. Previously this was always 768 Kbps for stereo and 384 Kbps for mono, with stereo being higher than the default bitrate for surround audio output in the same format.
* Add a "CHANGELOG.md" document to the project and replace the content of the "History" section of the "README" document with pointers to the GitHub releases page and that new "CHANGELOG.md" document.

## [0.24.0](https://github.com/donmelton/video_transcoding/releases/tag/0.24.0)

Sunday, February 24, 2019

* Add `--audio-format` and `--keep-ac3-stereo` options to `transcode-video`. Thanks to [@samhutchins](https://github.com/samhutchins) for the idea and design! Via [ #254](https://github.com/donmelton/video_transcoding/issues/254).
    * With the `--audio-format` option, you can now specify whether AC-3 or AAC is used when surround or stereo output tracks are created.
    * This allows multichannel 5.1 AAC audio output by adding `--audio-format surround=aac` to your command line. However, you may want to pair that with `--audio-width main=surround` to avoid two AAC tracks of the same input being created.
    * Think of the `--keep-ac3-stereo` option as a kinder, gentler form of the `--prefer-ac3` option.
    * It copies rather than transcodes AC-3 stereo or mono audio tracks even when the current stereo format is AAC, but it doesn't affect surround tracks.
* Deprecate the `--prefer-ac3` option in `transcode-video` and remove its description from the `--help` output. Also via [ #254](https://github.com/donmelton/video_transcoding/issues/254).
    * The option still works for now, but using it issues a warning message.
    * You can get the exact same functionality by adding `--audio-width all=surround --audio-format all=ac3` to your command line.
    * However, you might want to add `--audio-width all=surround --keep-ac3-stereo` instead since you'll get higher quality and slightly smaller output, albeit with some AAC tracks in your output when stereo audio in non-AC-3 format still needs to be transcoded.
* Add a `minimal` argument to the `--fallback-crop` option in `transcode-video` which determines the smallest possible crop values, when using the`--crop detect` option and argument, by combining results from both `HandBrakeCLI` and `ffmpeg`. Thanks to [@dkoenig01](https://github.com/dkoenig01) for the idea! Via [ #255](https://github.com/donmelton/video_transcoding/issues/255).
* Relax validation criteria for HandBrake-generated `.log` files in `query-handbrake-log` as workaround for `HandBrakeCLI` spewing linkage failure warnings on certain Linux platforms. Via [ #257](https://github.com/donmelton/video_transcoding/issues/257).

## [0.23.0](https://github.com/donmelton/video_transcoding/releases/tag/0.23.0)

Sunday, February 10, 2019

* Add a `--avbr` ratecontrol option to `transcode-video` (via [ #248](https://github.com/donmelton/video_transcoding/issues/248)) which:
    * Implements an average variable bitrate (AVBR) ratecontrol system focused on maintaining quality at the risk of final bitrates being as much as 10-15% higher or lower than the target.
    * May emit a few `VBV underflow` warnings at the beginning of a transcode, but nothing like the sustained deluge possible with my special, or default, ratecontrol system.
    * Works only with the `x264` and `x264_10bit` encoders. Sorry, but the settings necessary to implement AVBR are not available with the `x265` family of encoders.
* Add my new AVBR ratecontrol system to the "Explanation" section of the "README" document.
* Add an undocumented `--raw` ratecontrol testing option to `transcode-video` which implements, by default, an unconstrained ABR system, easily modified with `--handbrake-option` and/or `--encoder-option`.
* Add a `--mixdown` option to `transcode-video` which sets the mixdown format for all AAC audio tracks, either Dolby Pro Logic II (the default) or stereo. Thanks to [@samhutchins](https://github.com/samhutchins) for the idea and the patch! Via [ #245](https://github.com/donmelton/video_transcoding/pull/245).
* Fix failure in `detect-crop` on Linux for certain inputs by forcing the text output from `ffmpeg` into UTF-8 binary format to ensure the correct parsing of that data during crop detection. Via [ #247](https://github.com/donmelton/video_transcoding/issues/247).
* List all hardware-based video encoders within the related answer in the "FAQ" section of the "README" document. Thanks to [@vr8hub](https://github.com/vr8hub) for the idea! Via [ #251](https://github.com/donmelton/video_transcoding/issues/251).
* Update all copyright notices to the year 2019.

## [0.22.0](https://github.com/donmelton/video_transcoding/releases/tag/0.22.0)

Saturday, December 15, 2018

* Add an `--encoder` option to `transcode-video` so `--encoder x265` will work the same as the much longer and harder to type `--handbrake-option encoder=x265`.
* Add a `--simple` ratecontrol option to `transcode-video` (via [ #211](https://github.com/donmelton/video_transcoding/issues/211)) which:
    * Works like my special, or default, ratecontrol system but won't emit those annoying `VBV underflow` warnings because it's only constrained by the target bitrate and not also a minimum quality.
    * Signals Hypothetical Reference Decoder (HRD) information in metadata like my average bitrate (ABR) ratecontrol system.
    * Produces output similar in appearance to that from hardware-based encoders but is less prone to color banding.
* Modify `transcode-video` to not pass the target video bitrate to hardware-based encoders when a CRF value is also specified, e.g. via something like `--handbrake-option quality=20`. Currently, this is only applicable to encoders such as `nvenc_h264`, `nvenc_h265`, `vce_h264` and `vce_h265`.
* Revise both the H.265 video and hardware-based video transcoding answers in the "FAQ" section of the "README" document.
* Update and simplify the "Explanation" section of the "README" document.

## [0.21.2](https://github.com/donmelton/video_transcoding/releases/tag/0.21.2)

Tuesday, December 4, 2018

* Modify `transcode-video` to pass the target video bitrate to hardware-based encoders available in HandBrake for Windows and Linux as well as HandBrake nightly builds for macOS:
    * Check the output of `HandBrakeCLI --help` from one of those builds to find out if your platform has any of these video encoders available.
    * The names of these encoders all end with "`_h264`" (for H.264) or "`_h265`" (for HEVC).
    * On macOS, adding `--handbrake-option encoder=vt_h264` is all that's needed to enable hardware-based H.264 transcoding. Use `vt_h265` for HEVC.
    * On Windows and Linux, use `qsv_h264` or `qsv_h265`. Other encoders might be available as well in nightly builds.
    * WARNING: If you request an encoder that is _not_ available, `HandBrakeCLI` may fail or it may just fallback to a software-based encoder. Check your console output while transcoding to be certain.
    * These hardware-based encoders are far faster than the software-based `x264` and `x265` encoders while still delivering _reasonable_ quality. Of course, your mileage (and perception) may vary.

## [0.21.1](https://github.com/donmelton/video_transcoding/releases/tag/0.21.1)

Sunday, December 2, 2018

* Fix a bug in `transcode-video` creating MP3 instead of AAC audio in MKV output on Windows. This was caused by a previous optimization not passing a named AAC audio encoder to `HandBrakeCLI`, i.e. `ca_aac` or `av_aac`. Apparently the default is different on Windows. Go figure. Thanks, [@samhutchins](https://github.com/samhutchins)! Via [ #235](https://github.com/donmelton/video_transcoding/issues/235).
* Add a workaround in `transcode-video` for HandBrake nightly builds not setting the mixdown of multichannel audio track inputs to Dolby Pro Logic II format at 160 Kbps when the output is AAC stereo. Apparently the new default for that type of input is 5.1 channels at 384 Kbps, which wouldn't play on most Roku or Apple TV devices without re-transcoding or non-standard software. Again, go figure.
* Add a workaround in `transcode-video` and `convert-video` for HandBrake nightly builds not copying mono or stereo audio track inputs which are already in AAC format.

## [0.21.0](https://github.com/donmelton/video_transcoding/releases/tag/0.21.0)

Friday, November 9, 2018

* Modify `transcode-video` to create "sparse" `.log` files by removing overwritten progress information, often making those files an order of magnitude (i.e. `10x`) smaller. Via [ #213](https://github.com/donmelton/video_transcoding/issues/213).
* Replace code in `transcode-video` which used `mkvpropedit` or `mp4track` in a post-transcoding step to sanitize audio titles containing commas, with much simpler code leveraging a comma escaping mechanism only available in `HandBrakeCLI` version 1.0.0 or later.
* Fix bug in `transcode-video` where the level was not set when using the `x264_10bit` encoder.
* Remove support the non-existent `x265_16bit` encoder in `transcode-video`. This might have been available last year in some development builds of `HandBrakeCLI`, but it's definitely not in any release.

## [0.20.1](https://github.com/donmelton/video_transcoding/releases/tag/0.20.1)

Sunday, October 21, 2018

* Modify `transcode-video` to no longer validate `--filter` option arguments against a fixed list of names. This will prevent annoying failures whenever the HandBrake team adds a new filter.

## [0.20.0](https://github.com/donmelton/video_transcoding/releases/tag/0.20.0)

Monday, June 18, 2018

* Now require `HandBrakeCLI` version 1.0.0 or later. Not only does this change make for easier testing, but it allows removal of many capability-detection hacks needed to support older versions. My thanks again to all the users who provided positive feedback about this online!
* Relax frame rate control in `transcode-video` so that the options `--rate=30` and `--pfr` are no longer passed to `HandBrakeCLI` for most non-DVD videos. This means that the peak frame rate will no longer be limited to `30` FPS, allowing camera-generated videos to retain their original frame rates. However, the old behavior can be restored for those videos by adding `--limit-rate 30` to your `transcode-video` command line.
* Modify `transcode-video` to no longer pass `--encoder-preset=medium` to `HandBrakeCLI` since that's the default behavior anyway. However, adding `--preset medium` to your `transcode-video` command line still does so.
* Modify `transcode-video` to no longer pass a named audio encoder to `HandBrakeCLI` in order to select AAC, i.e. `ca_aac` or `av_aac`, since AAC is the default audio format anyway. However, adding the `--aac-encoder` option to your `transcode-video` command line still allows an explicit choice.
* Modify `transcode-video` to substitute "analyse" for the x264 option called "partitions" when invoked with the `--quick` or `--veryquick` options. This is done to better match the archaic internal name used by HandBrake. It has no effect on actual transcoding behavior.
* Add `-n` as a shortcut alias for the `--dry-run` option in `transcode-video`. This is the same shortcut alias used in `rsync` and `make`.
* Expand the "Explanation" section of the "README" document to describe both the special, or default, ratecontrol system and the average bitrate (ABR) ratecontrol system, enabled via the `--abr` option.
* Add clarification to the "README" document that stereo AAC tracks can also include surround audio information in matrix-encoded Dolby Pro Logic II format.
* Fix spelling of "suppress" in the `--help` output of `query-handbrake-log`. Thanks, [@chrisridd](https://github.com/chrisridd)! Via [ #205](https://github.com/donmelton/video_transcoding/pull/205).

## [0.19.0](https://github.com/donmelton/video_transcoding/releases/tag/0.19.0)

Saturday, January 27, 2018

* Add support for [Dolby Digital Plus](https://en.wikipedia.org/wiki/Dolby_Digital_Plus) audio format, aka Enhanced AC-3, to `transcode-video` and `convert-video` with a new `--ac3-encoder` option for each tool. Also, extend the `--ac3-bitrate` and `--pass-ac3-bitrate` options in `transcode-video` to support higher bitrates, 768 and 1536 Kbps, available to Enhanced AC-3. Via [ #26](https://github.com/donmelton/video_transcoding/issues/26).
    * WARNING: Dolby Digital Plus output is currently NOT COMPATIBLE with the MP4 file format when using `transcode-video` due to a limitation in `HandBrakeCLI`. This means that adding both `--mp4` and `--ac3-encoder eac3` to your command line will fail with the error "`incompatible encoder 'eac3' for muxer 'av_mp4'`."
    * Oddly enough, `ffmpeg` doesn't have this limitation so you'll be able to use `convert-video --ac3-encoder eac3` to convert your MKV files into MP4 format without any problems. Go figure.
* Remove "Can you add support for Enhanced AC-3 audio?" from the "FAQ" section of the "README" document, for obvious reasons. :)
* Add `--reverse-double-order` option to `transcode-video` to reverse order of double-width audio output tracks. Thanks, [@samhutchins](https://github.com/samhutchins)! Via [ #184](https://github.com/donmelton/video_transcoding/pull/184).
* Fix a bug in `convert-video` where the number of audio channels was wrong when tracks had to be transcoded. This was most noticeable for AAC output and appears due to a change in the behavior of `ffmpeg`.
* Append `.inspect` to all Hash objects used as `Console.debug` arguments. Apparently a change in the way Ruby works was preventing these objects from being printed, although I'm unsure about the specific version of Ruby in which this occurred.
* Remove superfluous quotes in the `--help` output of `transcode-video`.
* Remove the deprecated `--cvbr` and `--vbr` options in `transcode-video` and `--player` option in `detect-crop`.
* Revise my usage in the "FAQ" section of the "README" document since I no longer choose the default settings with `transcode-video`.
* Re-order a few misplaced lines in the "History" section of the "README" document.
* Update all copyright notices to the year 2018.

## [0.18.0](https://github.com/donmelton/video_transcoding/releases/tag/0.18.0)

Saturday, December 2, 2017

* Improve the average bitrate (ABR) ratecontrol system provided by the `--abr` option in `transcode-video`. Via [ #179](https://github.com/donmelton/video_transcoding/issues/179).
    * Implement it with a maximum bitrate constraint to raise its overal quality level and guarantee that it will not generate any `VBV underflow` warnings like the default ratecontrol system.
    * Signal Hypothetical Reference Decoder (HRD) information, meaning that the VBV maximum bitrate value is added as metadata to the output video, something you should _not_ do when using the default ratecontrol system.
    * Move it from the "Advanced" to the "Quality" section in the `--help` output and describe its quality output as "different" rather than "lower" compared to the default ratecontrol system.
    * Also remove the no-longer valid characterization of ABR in the "Explanation" section of the "README" document.
* Deprecate the poorly named `--cvbr` and `--vbr` options in `transcode-video` and remove them from the `--help` output.
    * The ratecontrol system implemented by the `--cvbr` option was always experimental. After much testing, it was found to be noticeably lower in quality compared to the default and to the new ABR implementation.
    * The ratecontrol system implemented by the `--vbr` option was only ever intended for comparison testing. And probably used only by myself.
* Modify `transcode-video` to no longer re-calculate `vbv-bufsize` based on any user input value for `vbv-maxrate`. Instead, always calculate both `vbv-maxrate` and `vbv-bufsize` based on the target video bitrate.
* Deprecate the `--player` option in `detect-crop` and remove it from the `--help` output.
* Fix failure of subtitle detection for HandBrake nightly builds. Language detection for subtitles in disc image directory input and individual closed caption tracks may still be wrong but will not be fixed at this time. Via [ #172](https://github.com/donmelton/video_transcoding/issues/172).
* Mention [Nick Wronski](https://github.com/nwronski)'s nifty batch-processing wrapper for `transcode-video` in the the "README" document. Thanks, [@JMoVS](https://github.com/JMoVS)! Via [ #180](https://github.com/donmelton/video_transcoding/pull/180).

## [0.17.4](https://github.com/donmelton/video_transcoding/releases/tag/0.17.4)

Sunday, September 10, 2017

* Force text output from `mp4track` into UTF-8 binary format to ensure correct parsing of that data. Thanks, [@DavidNielsen](https://github.com/DavidNielsen)! Via [ #152](https://github.com/donmelton/video_transcoding/pull/152).

## [0.17.3](https://github.com/donmelton/video_transcoding/releases/tag/0.17.3)

Sunday, May 14, 2017

* `HandBrakeCLI` versions 1.0 and later changed the default frame rate mode from "constant" to "peak-limited" when a rate is specified. This new behavior in `HandBrakeCLI` requires two significant changes in `transcode-video`:
    * Fix a bug where the `--force-rate` option failed to force a constant frame rate. This bug made it behave essentially the same at the `--limit-rate` option.
    * Fix a bug where a constant frame rate was not forced for inputs containing [MPEG-2 video](https://en.wikipedia.org/wiki/MPEG-2). This bug affected the transcoding of all DVDs but very few Blu-ray Discs. The good news is that this bug probably didn't cause visual problems since the new default peak-limited implementation in `HandBrakeCLI` versions 1.0 and later worked like a constant frame rate most of the time.
* Modify `convert-video` to use binary file mode when reading and writing console and log output from `ffmpeg`. This eliminates redundant information and "console spew" on Windows by suppressing the EOL <-> CRLF conversion. Thanks, [@samhutchins](https://github.com/samhutchins)! Via [ #147](https://github.com/donmelton/video_transcoding/pull/147).
* Also modify `transcode-video` and `convert-video` to use binary file mode when processing console I/O from `mkvpropedit` and `mp4track` to eliminate that same "console spew" on Windows.
* Modify `detect-crop` to escape preview commands for `cmd.exe` and PowerShell on Windows in a manner that's still compatible with Bourne and Z shells. Also mention in the "Using `detect-crop`" section of the "README" document that path names within the sample commands are not escaped properly when using `cmd.exe` or PowerShell on Windows and that `bash.exe` can be used as a workaround. Via [ #146](https://github.com/donmelton/video_transcoding/issues/146).
* Modify `transcode-video` to accept `x264_10bit`, `x265_10bit`, `x265_12bit` and `x265_16bit` as supported encoders while also adjusting the encoder profile for these variants. Via [ #143](https://github.com/donmelton/video_transcoding/issues/143).
* Modify `transcode-video` to no longer set the x264 encoder level if a frame rate has been requested higher than `30` FPS. Via [ #141](https://github.com/donmelton/video_transcoding/issues/141).

## [0.17.2](https://github.com/donmelton/video_transcoding/releases/tag/0.17.2)

Monday, April 3, 2017

* Fix failure of version detection for recent HandBrake nightly builds. Thanks, [@kvanh](https://github.com/kvanh)! Via [ #139](https://github.com/donmelton/video_transcoding/issues/139).
* Modify `detect-crop` to escape preview commands for Z shells. Thanks, [@jjathman](https://github.com/jjathman)! Via [ #138](https://github.com/donmelton/video_transcoding/issues/138).

## [0.17.1](https://github.com/donmelton/video_transcoding/releases/tag/0.17.1)

Wednesday, February 22, 2017

* Modify `transcode-video` to use binary file mode when reading and writing console and log output from `HandBrakeCLI`. This eliminates redundant information and "console spew" on Windows by suppressing the EOL <-> CRLF conversion. Thanks, [@samhutchins](https://github.com/samhutchins)! Via [ #130](https://github.com/donmelton/video_transcoding/issues/130).

## [0.17.0](https://github.com/donmelton/video_transcoding/releases/tag/0.17.0)

Thursday, February 16, 2017

* Remove all dependencies on `mplayer`, via [ #120](https://github.com/donmelton/video_transcoding/issues/120) and [ #123](https://github.com/donmelton/video_transcoding/issues/123):
    * Modify `detect-crop` and `transcode-video` to use `ffmpeg` for crop detection instead of `mplayer`.
    * Modify `detect-crop` to use [`mpv`](https://mpv.io/), a free cross-platform media player, for optional crop preview instead of `mplayer`.
    * Add a `--player` option to `detect-crop` so `mplayer` can still be used for crop preview commands. Warning: this feature will be deprecated soon.
* Update the "README" document to:
    * Remove any mention of `mplayer` and list `mpv` as an optional package.
    * Fix typo in version 0.16.0 release information. Thanks, [@samhutchins](https://github.com/samhutchins)!

## [0.16.0](https://github.com/donmelton/video_transcoding/releases/tag/0.16.0)

Friday, January 20, 2017

* Add a `--cvbr` option to `transcode-video`. This is essentially the same as the experimental option of the same name which was removed on February 25, 2016, but now it doesn't have a bitrate argument. It enables a _simple_ constrained variable bitrate (CVBR) ratecontrol system, less constrained than the default, producing a more predictable output size while avoiding `VBV underflow` warnings. Use it with `--target big` for the best results.
* Modify the `--abr` option in `transcode-video` to no longer use a bitrate argument. Instead, it relies on the `--target` option to control bitrate, just like the default ratecontrol system and the new `--cvbr` option. So, passing a bitrate argument is now an error. But you should consider using `--cvbr` instead of `--abr` anyway since the former is almost always higher quality.
* Remove the deprecated `--no-constrain` option from `detect-crop` and the `--no-constrain-crop` option from `transcode-video`.
* Modify `convert-video` to allow HEVC format video along with H.264.
* Update the "README" document to:
    * Revise and simplify the Windows installation instructions to point users at the fine work by [@samhutchins](https://github.com/samhutchins) and [@JMoVS](https://github.com/JMoVS) on documenting their two methods. Via [ #115](https://github.com/donmelton/video_transcoding/issues/115).
    * Revise the "Using `transcode-video`" section to correct out-of-date performance data about the `--quick` option.
    * Revise the H.265 answer in the "FAQ" section with up-to-date information about the x265 video encoder. Via [ #118](https://github.com/donmelton/video_transcoding/pull/118).

## [0.15.0](https://github.com/donmelton/video_transcoding/releases/tag/0.15.0)

Sunday, January 15, 2017

* Modify `convert-video`, via [ #114](https://github.com/donmelton/video_transcoding/issues/114), to:
    * Add support for text-based and DVD-style image-based subtitles. Please note that Blu-ray Disc-style image-based subtitles are _not_ supported due to MP4 format restrictions. 
    * Add a `--no-double` option which no longer assumes input files might contain two main audio tracks whose order needs to be swapped, or that a "missing" stereo AAC audio track needs to be added to MP4 output.
    * Change the algoritm deciding when a "missing" stereo AAC audio track is added. Previously that only happened when the first track of the input MKV file was in surround format and there were no other audio tracks. Now it won't matter how many audio tracks are in the input.
    * Use `ffmpeg` and `mkvpropedit` for conversion to MKV format instead of just `mkvmerge` which could not convert subtitle formats.
    * Remove the dependency on `mkvmerge` and add a dependency on `mkvpropedit`.
    * No longer pass the `-strict experimental` arguments to `ffmpeg` when using the built-in, native AAC encoder.
* Fix a bug preventing the detection of whether an audio track had the "default" flag set when parsing scan output from `HandBrakeCLI` versions 1.0.0 and later. This was caused by the integration of Libav version 12.0 in HandBrake on December 17, 2016.
* Fix a long-standing bug preventing the detection of all subtitles and disambiguation with chapter information in MP4 files when parsing scan output from `mp4track`.
* Remove support for the Freeware Advanced Audio Coder (FAAC) from the "FFmpeg" module since it's no longer included with `ffmpeg`.
* Remove the "mkvmerge.rb" source file and any references to the "MKVmerge" module since `convert-video` no longer needs it.
* Update the "README" document to:
    * Remove `mkvmerge` from the "Requirements" section.
    * Clarify subtitle support in the "Using `convert-video`" section.

## [0.14.0](https://github.com/donmelton/video_transcoding/releases/tag/0.14.0)

Wednesday, January 4, 2017

* Add a `--prefer-ac3` option to `transcode-video`. This prefers Dolby Digital AC-3 over AAC format when encoding or copying audio, even when the original track channel layout is stereo or mono. It also sets the audio output "width" for all tracks to `surround`. Via [ #112](https://github.com/donmelton/video_transcoding/issues/112).
* Fix a bug in the parsing of audio and subtitle track names that was introduced by the integration of Libav version 12.0 in HandBrake on December 17, 2016, affecting `HandBrakeCLI` versions 1.0.0 and later. This caused `transcode-video` to substitute any commas with underscores in added audio track names when used with those versions of `HandBrakeCLI`.

## [0.13.0](https://github.com/donmelton/video_transcoding/releases/tag/0.13.0)

Monday, January 2, 2017

* Modify the `--quick` option in `transcode-video` to remove the x264 `mixed-refs=0` setting because it's unnecessary when the `ref=1` setting is also applied. Via [ #108](https://github.com/donmelton/video_transcoding/issues/108).
* Add a `--veryquick` option to `transcode-video` for encoding 90-125% faster than the default setting with little easily perceptible loss in video quality. Unlike `--quick`, its output size is larger than the default. Via [ #108](https://github.com/donmelton/video_transcoding/issues/108).
* Remove the deprecated `--small` and `--small-video` options from `transcode-video`.
* Update all copyright notices to the year 2017.
* Update the "README" document to:
    * Revise the installation instructions to reflect that `HandBrakeCLI` has been removed from Homebrew Cask (thanks to [@vitorgalvao](https://github.com/vitorgalvao)) and is now part of Homebrew Core (thanks to [@JMoVS](https://github.com/JMoVS)). Via [ #106](https://github.com/donmelton/video_transcoding/pull/106) from [@vitorgalvao](https://github.com/vitorgalvao).
    * Revise the version of `HandBrakeCLI` required for HEVC transcoding to 1.0.0 or later in the "FAQ" section.
    * Clarify Enhanced AC-3 audio support in the "FAQ" section.

## [0.12.3](https://github.com/donmelton/video_transcoding/releases/tag/0.12.3)

Tuesday, December 6, 2016

* Increase the speed and quality of the `--quick` option. Encoding is now _70-80% faster_ than the default setting with _no easily perceptible loss in video quality_. The improvement is so good that I no longer recommend using x264 presets to speed things up. Via [ #104](https://github.com/donmelton/video_transcoding/issues/104).
* Update the "README" document to:
    * Revise the "Understanding the x264 preset system" section to suggest using `--quick` or `--target big` instead of faster or slower presets.
    * Add Docker virtualization software installation instructions. Via [ #98](https://github.com/donmelton/video_transcoding/issues/98) from [@ntodd](https://github.com/ntodd).

## [0.12.2](https://github.com/donmelton/video_transcoding/releases/tag/0.12.2)

Sunday, November 6, 2016

* Modify `transcode-video` to use HandBrake's new "auto-anamorphic" API, if available, instead of "strict-anamorphic". The HandBrake team removed the "strict-anamorphic" API on October 31, 2016, breaking `transcode-video` when it's used with the latest nightly builds. Via [ #67](https://github.com/donmelton/video_transcoding/issues/96) from [@iokui](https://github.com/iokui).
* Add "auto-anamorphic" and "non-anamorphic" to the list of HandBrake APIs disabled when the `--pixel-aspect` option is used with `transcode-video`.
* Re-enable the x264 video encoder when the `--quick` option is used with `transcode-video`.

## [0.12.1](https://github.com/donmelton/video_transcoding/releases/tag/0.12.1)

Friday, November 4, 2016

* Modify `transcode-video` to enable the `--quick` option only for the x264 video encoder and enable my special ratecontrol system only for the x264 and x265 encoders.
* Update the "README" document to:
    * Revise the H.265 answer in the "FAQ" section to show how you can try _experimental_ HEVC transcoding now.
    * Use new canonical "macOS" name.
    * Add "Explanation" section describing how my special ratecontrol system works.

## [0.12.0](https://github.com/donmelton/video_transcoding/releases/tag/0.12.0)

Friday, October 14, 2016

* Revise the ratecontrol system and default target video bitrates in `transcode-video` so that output is smaller and transcoding is faster. Via [ #90](https://github.com/donmelton/video_transcoding/issues/90).
    * Increase the value of `vbv-bufsize` to be twice that of `vbv-maxrate`, the target. This is much more likely to produce an output video bitrate nearer to that target.
    * Lower the targets to accomodate this new accuracy and avoid wasting bitrate and time on unneeded quality.
* Deprecate the `--small` and `--small-video` options in `transcode-video`.
* Add a variation of the `--target` option with `big` and `small` arguments to `transcode-video`. The `small` macro provides output similar to, but still smaller than, the old `--small-video` option. The `big` macro provides output even larger than the old ratecontrol system and targets.
* Remove unnecessary boundary checking of the target video bitrate in `transcode-video`.
* Modify `transcode-video` so adding `--handbrake-option encoder=x265` is all that is needed to enable _experimental_ HEVC transcoding. Use this _only_ with `HandBrakeCLI` nightly builds from September 29, 2016, or later.
* Update the "README" document to:
    * Revise the default target video bitrates.
    * Remove all references to the `--small` option since it's now deprecated.
    * Add the Windows Subsystem for Linux as a possible installation platform. Via [ #89](https://github.com/donmelton/video_transcoding/pull/89) from [@JMoVS](https://github.com/JMoVS).
    * Replace visible HTML comments with zero-width spaces.
    * Tweak the description of how I use `transcode-video`. Yes, again.

## [0.11.1](https://github.com/donmelton/video_transcoding/releases/tag/0.11.1)

Monday, September 26, 2016

* Add `queue-import-file` and anything starting with `preset` to the list of unsupported `HandBrakeCLI` options.
* Back out a change from version 0.3.1 to optimize setting the encoder level to behave more like past versions. This made no actual difference in the output video, only the `.log` file.
* Update the "README" document to:
    * Clarify tradeoffs when using the x264 preset system.
    * Revise the status of H.265 and Enhanced AC-3 support.
    * Tweak the description of how I use `transcode-video`. Again.

## [0.11.0](https://github.com/donmelton/video_transcoding/releases/tag/0.11.0)

Thursday, September 15, 2016

* Change the behavior of `detect-crop` and the `--crop detect` function of `transcode-video` to no longer constrain the crop by default. Add a `--constrain` option to `detect-crop` and a `--constrain-crop` option to `transcode-video` to restore the old behavior. Also, deprecate the `--no-constrain` option of `detect-crop` and the `--no-constrain-crop` option of `transcode-video` since both are no longer necessary. Via [ #81](https://github.com/donmelton/video_transcoding/issues/81).
* Update the "README" document to:
    * Revise multiple sections about the changes to cropping behavior.
    * Revise the description of the `--small` option in multiple sections.
    * Revise how I use `transcode-video` in the "FAQ" section.
* Add support for the `comb-detect`, `hqdn3d` and `pad` filters to `transcode-video`.
* Fix a bug in `transcode-video` where the `--filter` option failed when `nlmeans-tune` was used as a argument. This was due to a regular expression only allowing lowercase alpha characters and not hyphens.
* Update the default AC-3 audio and pass-through bitrates in the `--help` output of `transcode-video` to 640 Kbps, matching the behavior of the code since version 0.5.0.

## [0.10.0](https://github.com/donmelton/video_transcoding/releases/tag/0.10.0)

Friday, May 6, 2016

* Add resolution-specific qualifiers to the `--target` option in `transcode-video`. This allows different video bitrate targets for inputs with different resolutions. For example, you can use `--target 1080p=6500` alone to change the target for Blu-ray Discs and not DVDs. Or you could combine that with `--target 480p=2500` to affect both resolutions. Via [ #68](https://github.com/donmelton/video_transcoding/pull/68) from [@turley](https://github.com/turley).
* Fix a bug in `transcode-video` where video bitrate targets were not reset when the `--small` or `--small-video` options followed the `--target` option on the command line.
* Fix a bug where `query-handbrake-log` would fail for `time` or `speed` on macOS or Linux when parsing .log files created on Windows. This was due to a regular expression not expecting a carriage return (CR) before a line feed (LF), i.e. a Windows-style line ending (CRLF). Via [ #67](https://github.com/donmelton/video_transcoding/issues/67) from [@lambdan](https://github.com/lambdan).

## [0.9.0](https://github.com/donmelton/video_transcoding/releases/tag/0.9.0)

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

## [0.8.1](https://github.com/donmelton/video_transcoding/releases/tag/0.8.1)

Thursday, April 28, 2016

* Fix a bug where `query-handbrake-log` reported the wrong `time` or `speed` when parsing .log files containing output from HandBrake subtitle scan mode, i.e. when using `--burn-subtitle scan` or `--force-subtitle scan` from `transcode-video`. Via [ #46](https://github.com/donmelton/video_transcoding/issues/46) from [@martinpickett](https://github.com/martinpickett).
* Fix a bug where `query-handbrake-log ratefactor` failed if the number it was searching for was less than 10. This was due to HandBrake unexpectedly inserting a space before that number. Honestly, I doubt this ever happend before the new ratecontrol system debuted in 0.6.0. That's how good the new ratecontrol system is. Via [ #61](https://github.com/donmelton/video_transcoding/issues/61) from [@bmhayward](https://github.com/bmhayward).

## [0.8.0](https://github.com/donmelton/video_transcoding/releases/tag/0.8.0)

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

## [0.7.0](https://github.com/donmelton/video_transcoding/releases/tag/0.7.0)

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

## [0.6.0](https://github.com/donmelton/video_transcoding/releases/tag/0.6.0)

Sunday, April 3, 2016

* Revise the default ratecontrol system and video bitrate targets in `transcode-video`:
    * Raise the quality target by lowering the constant ratefactor (CRF) from `16` to `1`, the lowest lossy CRF value available with the x264 video encoder. This significantly improves video quality but also raises bitrates much closer to the targets, thereby increasing output file sizes for some inputs.
    * Raise the quality limit by setting `qpmax`, the x264 quantizer maximum, to `34`. This prevents x264 from occasionally generating a single, but still noticeable, very low quality frame because the CRF value is set so low.
    * Lower the video bitrate targets for 480p and 720p output to keep bitrates and file sizes closer to that produced by the old ratecontrol system. Note that 1080p and 2160p targets remain unchanged.
    * Add an `--old-behavior` option to restore the old ratecontrol system and video bitrate targets for users not yet wanting to change over. This option is only temporary and will soon be deprecated and then removed.
    * Update the "README" document to reflect changes to the 480p and 720p video bitrate targets.
* Remove an obsolete `brew install caskroom/cask/brew-cask` line from the "README" document. Via [ #54](https://github.com/donmelton/video_transcoding/pull/54) from [@timsutton](https://github.com/timsutton).

## [0.5.1](https://github.com/donmelton/video_transcoding/releases/tag/0.5.1)

Thursday, February 25, 2016

* Don't fail if the `ffmpeg` version string can't be parsed. Via [ #43](https://github.com/donmelton/video_transcoding/issues/43) from [@rementis](https://github.com/rementis), [@Lambdafive](https://github.com/Lambdafive) and [@kford](https://github.com/kford).
* Remove the deprecated `--cvbr` option in `transcode-video`.

## [0.5.0](https://github.com/donmelton/video_transcoding/releases/tag/0.5.0)

Thursday, January 14, 2016

* Raise the default video bitrate targets and AC-3 audio bitrate limits in `transcode-video`:
    * Deprecate the `--big` option since its behavior is now the default. An informal survey via Twitter and Facebook showed that about 90% of users (including myself) responding were always using the `--big` option anyway to get higher quality.
    * Add a `--small` option to restore the old video bitrate targets and AC-3 audio bitrate limits.
    * Add a `--small-video` option to restore only the old video bitrate targets. Via Facebook from [@DaveHamilton](https://github.com/DaveHamilton).
    * Update the "README" document to reflect all these changes.
* Move `--abr` and `--vbr` to the advanced options section in the `--help` output of `transcode-video`.
* Deprecate the experimental `--cvbr` option in `transcode-video`.

## [0.4.0](https://github.com/donmelton/video_transcoding/releases/tag/0.4.0)

Monday, January 11, 2016

* Add a `--cvbr` option to `transcode-video`. This implements a very experimental variation of the default ratecontrol system with a target bitrate as its single argument. Use it for evaluation purposes only.

## [0.3.1](https://github.com/donmelton/video_transcoding/releases/tag/0.3.1)

Friday, January 8, 2016

* Fix compatibility with development/nightly builds of `HandBrakeCL` in `transcode-video`:
    * Always force the x264 `medium` preset to override the new `veryfast` default value. Via [ #36](https://github.com/donmelton/video_transcoding/pull/36) from [@cnrd](https://github.com/cnrd).
    * Explicitly set the encoder profile to `high` to override the new `main` default value.
    * Explicitly (and dynamically) set the encoder level to override the new `4.0` default value. 
* Fix a stupid regression from version 0.2.8 caused by a typo in the patch for the SubRip-format text file offset fix to `transcode-video`. Via [ #37](https://github.com/donmelton/video_transcoding/issues/37) from [@bpharriss](https://github.com/bpharriss).
* Be more lenient about `--encoder-option` arguments in `transcode-video` so `8x8dct` is allowed.
* Always print the `HandBrakeCLI` version string to diagnostic output even if it can't be parsed.

## [0.3.0](https://github.com/donmelton/video_transcoding/releases/tag/0.3.0)

Tuesday, January 5, 2016

* Add a `--abr` option to `transcode-video`. This implements a modified average bitrate (ABR) ratecontrol system with a target bitrate as its single argument. It produces a much more predictable output size but lower quality than the default ratecontrol system. It can sometimes be handy but use it with caution.
* Add a `--vbr` option to `transcode-video`. This implements a true VBR ratecontrol system with a constant ratefactor as its single argument, much like HandBrake's default behavior when using its `--quality` option. It's useful mostly for comparison testing against the default ratecontrol system.
* Update all copyright notices to the year 2016.

## [0.2.8](https://github.com/donmelton/video_transcoding/releases/tag/0.2.8)

Tuesday, January 5, 2016

* Prevent the `--bind-srt-language` option in `transcode-video` from also setting the SubRip-format text file offset to the same value. This was a stupid copy and paste error since the initial project version. Via [ #25](https://github.com/donmelton/video_transcoding/pull/25) from [@arikalish](https://github.com/arikalish).
* Don't fail if the `HandBrakeCLI` version string can't be parsed. Via [ #29](https://github.com/donmelton/video_transcoding/issues/29) from [@paulbailey](https://github.com/paulbailey).
* Don't fail if the `mp4track` version string can't be parsed. Via [ #27](https://github.com/donmelton/video_transcoding/issues/27) from [@dgibbs64](https://github.com/dgibbs64).
* Add a missing preposition to the last bullet point of the "Why MakeMKV?" section in the "README" document. Via [ #32](https://github.com/donmelton/video_transcoding/pull/32) from [@eventualbuddha](https://github.com/eventualbuddha).

## [0.2.7](https://github.com/donmelton/video_transcoding/releases/tag/0.2.7)

Tuesday, July 7, 2015

* Apply the `--subtitle-forced` option when scanning subtitles in `transcode-video`. Via [ #20](https://github.com/donmelton/video_transcoding/issues/20) from [@rhapsodians](https://github.com/rhapsodians).

## [0.2.6](https://github.com/donmelton/video_transcoding/releases/tag/0.2.6)

Wednesday, May 20, 2015

* Prevent the user's file format choice from corrupting the output path in `transcode-video` and `convert-video`. Via [ #5](https://github.com/donmelton/video_transcoding/issues/5) from [@arikalish](https://github.com/arikalish).

## [0.2.5](https://github.com/donmelton/video_transcoding/releases/tag/0.2.5)

Sunday, May 17, 2015

* Simplify the calculation of `vbv-bufsize` in `transcode-video`.

## [0.2.4](https://github.com/donmelton/video_transcoding/releases/tag/0.2.4)

Friday, May 15, 2015

* Prevent an undefined method error if `HandBrakeCLI` removes tracks during scan. Via [ #15](https://github.com/donmelton/video_transcoding/issues/15) from [@blackoctopus](https://github.com/blackoctopus).

## [0.2.3](https://github.com/donmelton/video_transcoding/releases/tag/0.2.3)

Tuesday, May 12, 2015

* No longer fail on invalid audio and subtitle track information when parsing scan output from `HandBrakeCLI`. Via [ #11](https://github.com/donmelton/video_transcoding/issues/11) from [@eltito51](https://github.com/eltito51) and [ #13](https://github.com/donmelton/video_transcoding/issues/13) from [@tchjunky](https://github.com/tchjunky).

## [0.2.2](https://github.com/donmelton/video_transcoding/releases/tag/0.2.2)

Monday, May 11, 2015

* Ensure the AC-3 passthru bitrate in `transcode-video` is never below the AC-3 encoding bitrate.

## [0.2.1](https://github.com/donmelton/video_transcoding/releases/tag/0.2.1)

Sunday, May 10, 2015

* Fix the `--main-audio` option in `transcode-video` by ensuring the `resolve_main_audio` method actually returns a result. Via [ #9](https://github.com/donmelton/video_transcoding/issues/9) from [@JMoVS](https://github.com/JMoVS).

## [0.2.0](https://github.com/donmelton/video_transcoding/releases/tag/0.2.0)

Saturday, May 9, 2015

* Rewrite the automatic frame rate and deinterlace logic in `transcode-video` to match the behavior of the old `transcode-video.sh` script on which the tool is based.
* Clarify in `--help` output that `transcode-video` audio copy policies only apply to main and explicitly added audio tracks.
* Ignore the sometimes missing patch version when checking MPlayer.
* Mention in the "README" document that custom track names and external subtitle file names are allowed to contain commas.

## [0.1.4](https://github.com/donmelton/video_transcoding/releases/tag/0.1.4)

Friday, May 8, 2015

* Fix a stupid regression from version 0.1.2 caused by the line endings fix on Windows. Via [ #7](https://github.com/donmelton/video_transcoding/issues/7) from [@brandonedling](https://github.com/brandonedling).

## [0.1.3](https://github.com/donmelton/video_transcoding/releases/tag/0.1.3)

Friday, May 8, 2015

* Check the extra version number for MPlayer to accept all builds. Via [ #6](https://github.com/donmelton/video_transcoding/issues/6) from [@CallumKerrEdwards](https://github.com/CallumKerrEdwards).

## [0.1.2](https://github.com/donmelton/video_transcoding/releases/tag/0.1.2)

Thursday, May 7, 2015

* Fix handling of DOS-style line endings when parsing scan output from `HandBrakeCLI` on Windows. Via [ #4](https://github.com/donmelton/video_transcoding/issues/4) from [@CallumKerrEdwards](https://github.com/CallumKerrEdwards) and [@commandtab](https://github.com/commandtab).
* Disable automatic subtitle burning in `transcode-video` when input is MP4 format.
* Clarify usage of `--copy-audio` option in the "README" document. Via [ #5](https://github.com/donmelton/video_transcoding/issues/5) from [@arikalish](https://github.com/arikalish).
* Fix some section links in the "README" document. Via [ #3](https://github.com/donmelton/video_transcoding/pull/3) from [@vitorgalvao](https://github.com/vitorgalvao).

## [0.1.1](https://github.com/donmelton/video_transcoding/releases/tag/0.1.1)

Wednesday, May 6, 2015

* Add a workaround in the `Media` class `initialize` method for no required keyword arguments in Ruby 2.0. Via [ #1](https://github.com/donmelton/video_transcoding/pull/1) from [@cadonau](https://github.com/cadonau) and [ #2](https://github.com/donmelton/video_transcoding/issues/2) from [@CallumKerrEdwards](https://github.com/CallumKerrEdwards).

## [0.1.0](https://github.com/donmelton/video_transcoding/releases/tag/0.1.0)

Tuesday, May 5, 2015

* Initial project version.
