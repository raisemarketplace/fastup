require 'benchmark'

require 'bundler/setup'
require 'fastup/autoapply' if ENV['USE_FASTUP']

total = Benchmark.measure{ Bundler.require }.total

puts ['gems_count', 'load_path_size', 'loaded_features_size', 'time'].join("\t") if ENV['PRINT_HEADER']

puts "%d\t%d\t%d\t%.5f" % [
       ENV['GEMS_COUNT'].to_i,
       $LOAD_PATH.size,
       $LOADED_FEATURES.size,
       total,
     ]
