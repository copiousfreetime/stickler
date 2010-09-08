#-----------------------------------------------------------------------
#-*- vim: set ft=ruby: -*-
#
# Serve up the not found page for everything
#-----------------------------------------------------------------------
$:.unshift File.expand_path( File.join( File.dirname(__FILE__), "..", "lib" ) )

require 'stickler/middleware/not_found'

run ::Stickler::Middleware::NotFound.new
