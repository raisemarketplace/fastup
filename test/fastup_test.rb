require 'benchmark'
require 'open3'
require 'tmpdir'

require 'test_helper'

module Fastup
  class TestAppBoot < Minitest::Test
    def capture(*args)
      out, status = Open3.capture2e(*args)
      raise "#{args} exited with error:\n#{out}" unless status.success?
      out
    end

    tag :slow
    def test_app_boot
      results = {}

      Bundler.with_original_env do
        Dir.chdir(File.expand_path('../app', __FILE__)) do
          results[:setup] = capture "bundle --quiet"

          filter = ->(line) do
            line =~ /^feature:/ && line !~ %r{/lib/fastup}
          end

          results[:total_fastup] = Benchmark.measure {
            results[:output_fastup] = capture("USE_FASTUP=1 BUNDLE_FROZEN=true bundle exec ruby boot.rb").lines.select(&filter)
          }
          results[:total_nofastup] = Benchmark.measure {
            results[:output_nofastup] = capture("BUNDLE_FROZEN=true bundle exec ruby boot.rb").lines.select(&filter)
          }
        end
      end

      warn("\nfastup: %.2f nofastup: %.2f" % [results[:total_fastup].total, results[:total_nofastup].total])

      assert results[:total_fastup].total < results[:total_nofastup].total,
             "expected fastup (#{results[:total_fastup]}) to be faster than without (#{results[:total_nofastup]})"

      assert_equal results[:output_fastup], results[:output_nofastup]
    end
  end

  class TestSearchPath < Minitest::Test
    def setup
    end

    Scenario = Struct.new(:name, :source, :paths, :links)
    Source = Array
    Paths = Array
    Links = Hash

    Scenarios = [

      Scenario.new(
        'simple_one_binary',
        Source[
          'ls/bin/ls',
        ],
        Paths['ls/bin'],
        Links[
          'ls' => 'ls/bin/ls'
        ]),

      Scenario.new(
        'simple_nested',
        Source[
          'ls/bin/a/b/c/ls',
        ],
        Paths['ls/bin'],
        Links[
          'a' => 'ls/bin/a'
        ]),

      Scenario.new(
        'simple_two_binaries',
        Source[
          'ls/bin/ls',
          'ps/bin/ps'
        ],
        Paths['ls/bin', 'ps/bin'],
        Links[
          'ls' => 'ls/bin/ls',
          'ps' => 'ps/bin/ps'
        ]),

      Scenario.new(
        'simple_overlap',
        Source[
          'gems/rspec/lib/rspec.rb',
          'gems/rspec/lib/rspec/something.rb',

          'gems/rspec-core/lib/rspec/core.rb'
        ],
        Paths['gems/rspec/lib', 'gems/rspec-core/lib'],
        Links[
          'rspec.rb' => 'gems/rspec/lib/rspec.rb',
          'rspec/something.rb' => 'gems/rspec/lib/rspec/something.rb',
          'rspec/core.rb' => 'gems/rspec-core/lib/rspec/core.rb'
        ]),

      Scenario.new(
        'conflict',
        Source[
          'rspec-1.0/lib/rspec.rb',
          'rspec-2.0/lib/rspec.rb'
        ],
        Paths['rspec-1.0/lib', 'rspec-2.0/lib'],
        Links['rspec.rb' => 'rspec-1.0/lib/rspec.rb']),

      Scenario.new(
        'conflict_file_vs_directory',
        Source[
          'a/lib/something',
          'b/lib/something/sub'
        ],
        Paths['a/lib', 'b/lib'],
        Links['something' => 'a/lib/something']),

      Scenario.new(
        'conflict_directory_vs_file',
        Source[
          'a/lib/something/sub',
          'b/lib/something'
        ],
        Paths['a/lib/', 'b/lib'],
        Links['something' => 'a/lib/something']),

    ]

    Scenarios.each do |s|
      define_method("test_scenario_#{s.name}") do
        Dir.mktmpdir do |source|
          s.source.each do |path|
            FileUtils.mkdir_p(File.join(source, File.dirname(path)))
            FileUtils.touch(File.join(source, path))
          end

          paths = s.paths.map{ |p| File.join(source, p) }

          sp = Fastup::SearchPath.new(paths)

          s.links.each do |(key, target)|
            actual_target = sp.lookup(key).slice(source.length+1..-1)
            assert_equal target, actual_target, "expected #{key} -> #{target} but found #{key} -> #{actual_target}"
          end
        end
      end
    end
  end
end
