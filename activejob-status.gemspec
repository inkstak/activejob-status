# frozen_string_literal: true

$:.push File.expand_path("lib", __dir__)
require "activejob-status/version"

Gem::Specification.new do |spec|
  spec.name = "activejob-status"
  spec.version = ActiveJob::Status::VERSION

  spec.authors = ["Savater Sebastien"]
  spec.email = "github.60k5k@simplelogin.co"

  spec.summary = "Monitor your jobs"
  spec.licenses = ["MIT"]

  spec.homepage = "https://github.com/inkstak/activejob-status"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/releases"

  spec.files = Dir["lib/**/*"] + %w[LICENSE README.md]
  spec.require_paths = ["lib"]

  spec.add_dependency "activejob", ">= 6.0"
  spec.add_dependency "activesupport", ">= 6.0"

  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-rake"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "standard", ">= 1.0"
  spec.add_development_dependency "timecop"
end
