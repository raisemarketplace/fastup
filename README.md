# Fastup

Fastup builds an index from `$LOAD_PATH` and patches `require` to use
that index to significantly speed up booting up large Rails apps with
many dependencies.

When `require 'code'` is called, Ruby searches each element of
`$LOAD_PATH`, attempting to load `code.rb` from each directory in
`$LOAD_PATH`. Watching the output of `strace` while starting a Ruby
program reveals a large number of failed attempts to open non-existent
files, until the correct path is found. The index built by `fastup`
allows skipping many of these failed attempts.

The speedup is most noticeable in applications with many
dependencies. With few dependencies, the overhead of `fastup` will
cause a small slowdown. Test the speedup first, to see if `fastup` is
worth it or not for any particular application.

![plot](plot.png)

## Usage

`fastup/autoapply` should be required after `bundler/setup` and before
`Bundler.require`, or more generally, after `$LOAD_PATH` has been
populated with all dependencies and before most of them have been
`require`'d.

For example in `config/boot.rb` of a Rails app:

```ruby
require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
require 'fastup/autoapply'
```

## Production Ready?

This has not been used in production.
