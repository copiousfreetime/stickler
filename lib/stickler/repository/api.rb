require 'stickler/repository'
require 'stickler/spec_lite'
module Stickler::Repository
  #
  # The API that all Stickler Repository classes MUST implement.  
  # This file is here to document the API
  #
  module Api
    #
    # :call-seq:
    #   repo.uri -> URI
    #
    # Return the URI of the repo
    #
    def uri
      raise NotImplementedError, not_implemented_msg( :uri )
    end

    #
    # :call-seq:
    #   repo.gems_uri -> URI
    #
    # Return the URI to the location holding all the +.gem+ files
    #
    def gems_uri
      raise NotImplementedError, not_implemented_msg( :gems_uri )
    end

    #
    # :call-seq:
    #   repo.uri_for_gem( spec ) -> URI
    #
    # Given a SpecLite like object, return a URI that can be used
    # to directly access the gem in the repository.
    #
    def uri_for_gem( spec )
      raise NotImplementedError, not_implemented_msg( :uri_for_gem )
    end

    #
    # :call-seq:
    #   repo.specifications_uri -> URI
    #
    # Return the URI to the location holding all the +.gemspec+ files
    #
    def specifications_uri
      raise NotImplementedError, not_implemented_msg( :specifications_uri )
    end

    #
    # :call-seq:
    #   repo.uri_for_specification( spec ) -> URI
    #
    # Given a SpecLite like object, return a URI that can be used
    # to directly retrieve the Gem::Specification of the gem.
    #
    # The URI returned is a URI to a compressed version of the specification
    # and as such will need to be uncompressed with Gem.inflate
    #
    def uri_for_specification( spec )
      raise NotImplementedError, not_implemented_msg( :uri_for_specification )
    end

    #
    # :call-seq:
    #   repo.source_index -> Gem::SourceIndex
    #
    # Return a Gem::SourceIndex object that can be used to query the 
    # repository
    #
    def source_index
      raise NotImplementedError, not_implemented_msg( :source_index )
    end

    # 
    # :call-seq:
    #   repo.search_for( spec ) -> Array 
    # 
    # +match+ MUST be an object that responds to +name+, +version+ and
    # +platform+.
    #
    # The Array that is returned will be +empty?+ if no gems are found that
    # match +match+.  
    #
    # When one or matches is found, the Array will contain contain 
    # Stickler::SpecLite instances.
    #
    def search_for( spec )
      raise NotImplementedError, not_implemented_msg( :search_for )
    end

    #
    # :call-seq:
    #   repo.push( path_to_gem_file ) -> Stickler::SpecLite
    #   repo.put( path_to_gem_file ) -> Stickler::SpecLite
    #
    # Push, in the sense of the gem commandline command <tt>gem push</tt>.
    # +path_to_gem_file+ must be a file system location to a .gem file
    # that is then _pushed_ into the repository.
    #
    # The SpecLite returned can be used to retrieve the gem 
    # from the repo using the #get() method.  A direct URI to the 
    # gem may be obtained using the #uri_for() method.
    #
    # This is also aliased as *put* to provide a reciprocal for 
    # the *get* method.
    #
    def push( path_to_gem_file )
      raise NotImplementedError, not_implemented_msg( :push )
    end
    alias :put :push

    #
    # :call-seq:
    #   repo.delete( spec ) -> true|false
    #
    # Remove the gem matching the spec completely from the respository.
    # Return +true+ if the gem was removed, +false+ otherwise
    #
    def delete( spec )
      raise NotImplementedError, not_implemented_msg( :delete)
    end

    #
    # :call-seq:
    #   repo.yank( spec ) -> Stickler::SpecLite
    #
    # "yank" in the sense of
    # http://update.gemcutter.org/2010/03/05/february-changelog.html.  
    # This means, remove the gem matching +spec+ from the index, so it will not
    # be found when searching, but do not remove the gem physically from the
    # server.  It can still be downloaded directly.
    #
    # The SpecLite instance that is returned will have the information that may
    # be used in the #get() or #uri_for_gem() methods to retrieve the actual
    # gemfile.
    #
    # After a gem has been 'yanked' it MUST not longer be found via the
    # #search_for() method, nor can it's specification be retrieved via the
    # #uri_for_specification() method.
    #
    def yank( spec ) 
      raise NotImplementedError, not_implemented_msg( :yank ) 
    end

    #
    # :call-seq:
    #   repo.get( spec ) -> bytes
    #
    # Retrieve the gem matching the spec from the repository.  The bytes
    # returned MUST be something that would be acceptable to be written
    # directly to disk as a .gem file.
    #
    def get( spec )
      raise NotImplementedError, not_implemented_msg( :get )
    end

    #
    # :call-seq:
    #   repo.add( opts = {} ) -> Stickler::SpecLite
    #
    # A lower level version of #push.  The hash passed in MUST have the
    # following keys:
    #
    # [:name]     The name of the gem ( i.e. 'stickler' )
    # [:version]  The version in dotted notation ( i.e. '1.0.2' )
    # [:body]     An object that responds to +read+ and behaves like IO#read
    #
    # The following option is optional, if it is not given, then the platform
    # of the given gem is assumed to be 'ruby'.
    #
    # [:platform] The Gem::Platform compatible string for use if the gem is
    #             not a pure ruby gem (i.e. 'x86-mswin' or 'java' )
    #
    # The *opts[:body]* object will be iterated over using each to store the
    # object in the repository.
    #
    def add( params = {} )
      raise NotImplementedError, not_implemented_msg( :add )
    end

    #
    # :call-seq:
    #   repo.open( spec ) -> reader
    #   repo.open( spec ) { |reader| block }
    #
    # Open the gem in a readonly manner, similar to that of File.open.
    # the +reader+ object that is returned MUST respond to +read+,  
    # +close+ and +rewind+.   These methods behave like their corresponding
    # IO#read, IO#close and IO#rewind methods.
    #
    def open( spec, &block )
      raise NotImplementedError, not_implemented_msg( :open )
    end

    private
    # :stopdoc:
    def not_implemented_msg( method )
      "Please implement #{self.class.name}##{method}"
    end
    # :startdoc:
  end
end
