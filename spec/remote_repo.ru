$:.unshift File.expand_path( File.join( File.dirname(__FILE__), "..", "lib" ) )

require 'stickler/gem_server'
require 'stickler/gemcutter_api_server'
require 'stickler/gem_server_deflater'

gem_dir = File.join( File.expand_path( File.dirname( __FILE__ ) ), "tmp" )
use ::Stickler::GemServerDeflater
use ::Stickler::GemCutterApiServer, :repo_root => gem_dir
use ::Stickler::GemServer, :gem_path => gem_dir
run ::Sinatra::Base

