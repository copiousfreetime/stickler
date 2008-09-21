#--
# Copyright (c) 2008 Jeremy Hinegardner
# All rights reserved.  Licensed under the same terms as Ruby.  No warranty is
# provided.  See LICENSE and COPYING for details.
#++

require 'main'
require 'stickler'

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
    }
    
    option( :debug ) {
      description 'be verbose about logging in general'
      default false
    }

    run { help! }

    mode( :setup ) {
      description 'setup a directory as a stickler repository'
      argument( 'directory' ) { 
        description "the stickler repository directory"
        default Stickler::Repository.default_directory
      }

      examples <<-txt
        . stickler setup 
        . stickler setup /tmp/stickler
      txt
      
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

    mode( :add ) do
      description <<-desc
        Add a gem and all dependencies or a source to the repository.  
      desc

      examples <<-txt
        . stickler add gem heel 
        . stickler add gem ramaze -v 0.3.5
        . stickler add source http://gems.github.com/
      txt

      mode( :gem ) do
        description <<-desc
        Add a gem and all its dependencies to the repository.  Run from
        within the stickler repository or use the --directory option
        desc

        examples <<-txt
          . stickler add gem heel
          . stickler add gem ramaze -v 2008.06 --directory /var/stickler
        txt

        argument( 'gem_name' ) { description "The gem to add" }
        mixin :option_directory
        mixin :option_version

        option( :requirements ) {
          desc <<-desc
          Satisfy dependency requirements using minimum or the maximum version 
          that satisfies the dependency.  For instance if you had a gem that 
          dependend on rake >= 0.8.1, if you used --requirements minimum then
          stickler will download rake-0.8.1.  If you used --requrements maximum
          then stickler will download the latest version of rake.
          desc
          
          argument( :required )
          validate { |r| %w[ maximum minimum ].include?( r.downcase ) }
          default 'maximum'
        }

        run {
          p = Stickler.params_to_hash( params )
          repo = Stickler::Repository.new( p )
          repo.add_gem( p['gem_name'] )
        }
      end

      mode( :source ) do
        description <<-desc
          Add a source the repository.  This makes that source available 
          for use within the repository.  Run from within the stickler 
          repository or use the --directory option.
        desc

        examples <<-txt
          . stickler add source http://gems.github.com/
        txt

        argument( 'source_uri' ) { description "the source uri to add" }

        mixin :option_directory
        
        run {
          p = Stickler.params_to_hash( params )
          repo = Stickler::Repository.new( p )
          repo.add_source( p['source_uri'] )
        }
      end
    end

    mode( :remove ) do
      description 'remove a gem or source from the repository'
      example <<-txt
        . stickler remove gem mongrel 
        . stickler remove gem rails 
        . stickler remove source htp://gems.github.com/
      txt

      mode( :gem ) do
        description <<-desc
          Remove a gem and all other gems that depend on it from the repository.
          Run from within the stickler repository or use the --directory option
        desc

        example <<-txt
          . stickler remove gem mongrel 
          . stickler remove gem rails 
        txt

        mixin :option_directory
        argument( 'gem_name' ) { description "The gem to remove" }
      end

      mode( :source ) do
        description <<-desc
          Remove a source and all is gems from the repository.
          Run from within the stickler repository or use the --directory option
        desc

        example <<-txt
          . stickler remove source htp://gems.github.com/
        txt

        mixin :option_directory
        argument( 'source_uri' ) { description "The source to remove" }
      
        run {
          p = Stickler.params_to_hash( params )
          repo = Stickler::Repository.new( p )
          repo.remove_source( p['source_uri'] )
        }
      end
      
    end

    mode( 'check-update' ) do
      description <<-desc
      check upstream sources for new versions of gems
      Run from within the stickler repository or use the --directory option
      desc

      example <<-txt
        . stickler check-update --email 'admin@example.com'
        . stickler check-update --email 'admin@example.com' --via 'smtp.example.com'
      txt

      option( :email ) {
        desc "send the check results via email"
        argument( :required )
      }

      option( :via ) {
        desc "send the email via a particular server"
        argument( :required )
        default "localhost"
      }

      mixin :option_directory

      run { 
        puts "Check not implemented " 
        puts "directory = #{directory}"
        puts "email     = #{email}"
        puts "via       = #{via}"
      }
    end

    mode( 'check-consistency' ) do
      description <<-desc
      check all gems in the repository and make sure that all is well
      Run from within the stickler repository or use the --directory option
      desc

      example <<-txt
        . stickler check-consistency 
      txt
      mixin :option_directory
      
      run { puts "Check consistency not implemented" }
    end

    ##
    # common options used by more than one commands
    #
    mixin :option_directory do 
      option( :directory, "d" ) {
        argument :required
        default Dir.pwd
      }
    end

    mixin :option_force do
      option( :force )  { default false }
    end

    mixin :option_version do
      option( :version, "v" ) { argument :required }
    end
    
  }
end
