# Fastup

Fastup builds an index from `$LOAD_PATH` and patches `require` to use
that index to significantly speed up booting up large Rails apps with
many dependencies.

```
$ bundle show | wc -l
375

### before fastup

$ time echo 'puts "loaded #{$LOADED_FEATURES.size} features"' | bundle exec rails c
loaded 5095 features

real    0m23.652s
user    0m14.300s
sys     0m9.237s

### with fastup enabled

$ time echo 'puts "loaded #{$LOADED_FEATURES.size} features"' | bundle exec rails c
loaded 5097 features

real    0m15.142s
user    0m11.005s
sys     0m4.058s
```

## Usage

After requiring `bundler/setup`, require `fastup/autoapply`, for
example in `config/boot.rb` of a Rails app:

```
require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
require 'fastup/autoapply'
```

## Production Ready?

This has not been used in production.
