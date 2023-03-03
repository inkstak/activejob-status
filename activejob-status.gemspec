# frozen_string_literal: true

$:.push File.expand_path("lib", __dir__)
require "activejob-status/version"

Gem::Specification.new do |s|
  s.name = "activejob-status"
  s.version = ActiveJob::Status::VERSION

  s.authors = ["Savater Sebastien"]
  s.email = "github.60k5k@simplelogin.co"

  s.homepage = "https://github.com/inkstak/activejob-status"
  s.licenses = ["MIT"]
  s.summary = "Monitor your jobs"

  s.files = Dir["lib/**/*"] + %w[LICENSE README.md]
  s.require_paths = ["lib"]

  s.add_dependency "activejob", ">= 6.0"
  s.add_dependency "activesupport", ">= 6.0"

  s.add_development_dependency "appraisal"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rubocop"
  s.add_development_dependency "rubocop-rake"
  s.add_development_dependency "rubocop-rspec"
  s.add_development_dependency "rubocop-performance"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "standard"
  s.add_development_dependency "timecop"
end
