require File.expand_path("../lib/gruis/pineapple/version", __FILE__)
require "rubygems"
::Gem::Specification.new do |s|
  s.name                      = "gruis-pineapple"
  s.version                   = Gruis::Pineapple::VERSION
  s.platform                  = ::Gem::Platform::RUBY
  s.authors                   = ['Caleb Crane']
  s.email                     = ['pineapple@gru.is']
  s.homepage                  = "http://github.com/gruis/pineapple"
  s.summary                   = 'Wanikani writing study builder'
  s.description               = ''
  s.files                     = Dir["lib/**/*.rb", "bin/*", "*.md"]
  s.require_paths             = ['lib']
  s.executables               = Dir["bin/*"].map{|f| f.split("/")[-1] }
  s.license                   = 'MIT'

  s.add_dependency "faraday"
  s.add_dependency "dotenv"
  s.add_dependency "vcr"
end