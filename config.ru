require "bundler/setup"
require "rack/jekyll"
require "yaml"

run Rack::Jekyll.new
