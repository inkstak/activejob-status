# frozen_string_literal: true

$:.push File.expand_path("lib", __dir__)
require "activejob-status/version"

Gem::Specification.new do |s|
  s.name = "activejob-status"
  s.version = ActiveJob::Status::VERSION
  s.authors = ["Savater Sebastien"]
  s.email = ["savater.sebastien@gmail.com"]
  s.homepage = "https://github.com/inkstak/activejob-status"
  s.licenses = ["MIT"]
  s.summary = "Monitor your jobs"

  s.files = Dir["lib/**/*"]
  s.require_paths = ["lib"]

  s.add_dependency "activejob", ">= 4.2"
  s.add_dependency "activesupport", ">= 4.2"
end
