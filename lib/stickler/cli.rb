#--
# Copyright (c) 2008 Jeremy Hinegardner
# All rights reserved.  Licensed under the same terms as Ruby.  No warranty is
# provided.  See LICENSE and COPYING for details.
#++

require 'main'
require 'stickler/version'

module Stickler

  # 
  # Convert the Parameters::List that exists as the parameters from Main
  #
  def self.params_to_hash( params )
    h = Hash.new
    params.each do |p|
      h [p.names.first ] = p.value
    end
    return h
  end

  #
  # ::Main.create returns a class that is instantiated with ARGV and ENV as
  # parameters.  The Cli is then used as:
  #
  #   Cli.new( ARGV, ENV ).run
  #
  CLI = ::Main.create {

    author  "Copyright (c) 2008 Jeremy Hinegardner <jeremy@copiousfreetime.org>"
    version Stickler::VERSION

    description <<-txt
      Stickler is a tool to organize and maintain an internal gem 
      distribution server.  It synchronizes locally distriubted gems
      with their upstream version, and locks the local version to a
      particular version.
      
      run 'stickler help modename' for more info.
    txt

    examples <<-txt
      . stickler setup 
      . stickler delete rails
      . stickler add ramaze 
      . stickler add keybox --version 1.2.1
      . stickler check --email 'admin@example.com'
      . stickler list
    txt

    option( :quiet, "q" ) {
      description 'be quiet about logging to stdout'
      default false
      attr
    }
    
    option( :debug ) {
      description 'be verbose about logging in general'
      default false
      attr
    }

    run { help! }

    mode( :setup ) {
      description 'setup a directory as a stickler repository'

      examples <<-txt
        . stickler setup 
        . stickler setup -d /var/stickler
      txt
      
      mixin :option_directory
      mixin :option_force

      run { 
        Stickler::Repository.new( Stickler.params_to_hash( params ) ).setup 
      }
    }

    mode( :info ) {
      description 'report information about the stickler repository'

      examples <<-txt
        . stickler info
      txt

      mixin :option_directory
      
      run { Stickler::Repository.new( Stickler.params_to_hash( params ) ).info }
    }

    mode( :add ) {
      description 'add a gem, or a directory of gems  and all dependencies to the repository'

      examples <<-txt
        . stickler add heel
        . stickler add ramaze -v 0.3.5
      txt

      mixin :option_directory

      run { puts "Add not implemented" }
    }

    mode( :remove ) {
      description 'remove a gem from the repository'
      example <<-txt
        . stickler remove mongrel
        . stickler remove rails --include-dependencies
      txt

      option( 'include-dependencies' ) { 
        desc 'include any dependencies that are not required elsewhere'
        default false
      }
      
      mixin :option_directory
      
      run { 
        puts "Remove not implemented" 
        puts "include_dependencies = #{include_dependencies}"
      }
    }

    mode( :check ) {
      description "check upstream repository for new versions of gems"
      example <<-txt
        . stickler check --email 'admin@example.com'
        . stickler check --email 'admin@example.com' --via 'smtp.example.com'
      txt

      option( :email ) {
        desc "send the check results via email"
        argument( :required )
        attr
      }

      option( :via ) {
        desc "send the email via a particular server"
        argument( :required )
        default "localhost"
        attr
      }

      mixin :option_directory

      run { 
        puts "Check not implemented " 
        puts "directory = #{directory}"
        puts "email     = #{email}"
        puts "via       = #{via}"
      }
    }

    mode( :rebuild ) {
      description "rebuild all gems synced from elsewhere"

      example <<-txt
        . stickler rebuild
      txt
      mixin :option_directory
      
      run { puts "Check not implemented" }
    }

    ##
    # common options used by more than one commands
    #
    mixin :option_directory do 
      option( :directory, "d" ) {
        argument :required
        default Dir.pwd
        attr 
      }
    end

    mixin :option_force do
      option( :force )  {
        default false
        attr
      }
    end
    
  }
end
