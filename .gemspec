Gem::Specification.new do |s|
  s.name = 'fastup'
  s.version = '1.0.3pre'
  s.licenses    = ['MIT']
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.md", "COPYING"]
  s.summary = 'index load path to accelerate boot'
  s.description = 'index load path to accelerate boot of bundler-based apps with lots of gem dependencies'
  s.author = 'Patrick Mahoney'
  s.email = 'patrick.mahoney@raise.com'
  s.homepage = 'https://github.com/raisemarketplace/fastup'
  s.files = Dir['lib/**/*.rb', 'test/**/*.rb']

  s.add_development_dependency('minitest')
  s.add_development_dependency('minitest-reporters')
  s.add_development_dependency('minitest-tagz')
  s.add_development_dependency('rake')
  s.add_development_dependency('yard')
end
