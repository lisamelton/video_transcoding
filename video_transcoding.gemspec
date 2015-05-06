$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/lib')

require 'video_transcoding'

Gem::Specification.new do |s|
  s.name                  = 'video_transcoding'
  s.version               = VideoTranscoding::VERSION
  s.required_ruby_version = '>= 2.0'
  s.summary               = 'Tools to transcode, inspect and convert videos.'
  s.description           = <<-HERE
    Video Transcoding is a package of tools to transcode, inspect
    and convert videos.
  HERE
  s.license               = 'MIT'
  s.author                = 'Don Melton'
  s.email                 = 'don@blivet.com'
  s.homepage              = 'https://github.com/donmelton/video_transcoding'
  s.files                 = Dir['{bin,lib}/**/*'] + Dir['[A-Z]*'] + ['video_transcoding.gemspec']
  s.executables           = ['convert-video', 'detect-crop', 'query-handbrake-log', 'transcode-video']
  s.extra_rdoc_files      = ['LICENSE', 'README.md']
  s.require_paths         = ['lib']
end
