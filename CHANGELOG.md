# Changes to the "[Video Transcoding](https://github.com/lisamelton/video_transcoding)" project

## [2025.01.23](https://github.com/lisamelton/video_transcoding/releases/tag/2025.01.23)

Thursday, January 23, 2025

* Add missing ratecontrol code for the `nvenc-hevc` video mode that was _stupidly_ left out of the original rewrite of `transcode-video.rb`. This also implements the `--no-bframe-refs` option.

## [2025.01.19](https://github.com/lisamelton/video_transcoding/releases/tag/2025.01.19)

Sunday, January 19, 2025

* Add `nvenc-av1` video mode to `transcode-video.rb`.

## [2025.01.10](https://github.com/lisamelton/video_transcoding/releases/tag/2025.01.10)

Friday, January 10, 2025

* Fix bug preventing `encopts` arguments being passed to the `--extra` option of `transcode-video.rb`.
* Clarify that the automatic behavior of `transcode-video.rb` described in the `README.md` file is for a single forced subtitle and does not apply to multiple subtitles.
* Add note to the `README.md` file regarding possible future video modes for `transcode-video.rb`.

## [2025.01.09](https://github.com/lisamelton/video_transcoding/releases/tag/2025.01.09)

Thursday, January 9, 2025

* Deprecate and remove legacy [RubyGems](https://en.wikipedia.org/wiki/RubyGems)-based project files.
* Remove `*.gem` files from the list to ignore.
* Add redesigned and rewritten tools to the project, i.e. the `transcode-video.rb`, `detect-crop.rb` and `convert-video.rb` scripts.
* Completely update the `README.md` file.
* Begin using a date-based version numbering scheme for the project and all the scripts.

> [!NOTE]
> Changes before version 2025.01.09 are no longer relevant and not included in this document.
