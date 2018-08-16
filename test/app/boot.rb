require 'bundler/setup'
require 'fastup/autoapply' if ENV['USE_FASTUP']
Bundler.require

puts $LOADED_FEATURES.join("\n")
