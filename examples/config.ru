#-----------------------------------------------------------------------
# Example rackup file for an entire stickler stack
#
# -*- vim: set ft=ruby: -*-
#-----------------------------------------------------------------------
$:.unshift File.expand_path( File.join( File.dirname(__FILE__), "..", "lib" ) )

require 'stickler'

tmp = File.expand_path( File.join( File.dirname( __FILE__ ), "..", "tmp" ) )

run Stickler::Server.new( tmp ).app
