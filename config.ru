require 'rubygems'
require 'bundler'

Bundler.require
require 'rack-flash'
require 'sass/plugin/rack'
require './feedmn'

# Use scss for stylesheets
Sass::Plugin.options[:style] = :compressed
Sass::Plugin.options[:template_location] = 'assets/stylesheets'
use Sass::Plugin::Rack
# Use coffeescript for javascript
use Rack::Coffee, root: 'assets', urls: '/javascripts'

run Feedmn