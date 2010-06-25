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
    # Return the URI to the location holding all the +.gem+ files.
    #
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
    #
    # Push, in the sense of the gem commandline command <tt>gem push</tt>.
    # +path_to_gem_file+ must be a file system location to a .gem file
    # that is then _pushed_ into the repository.
    #
    # The SpecLite returned can be used to retrieve the gem
    # from the repo using the #get() method.  A direct URI to the
    # gem may be obtained using the #uri_for() method.
    #
    # If the gem pushed already exists, then a Stickler::Repository::Error is
    # raised.
    #
    def push( path_to_gem_file )
      raise NotImplementedError, not_implemented_msg( :push )
    end

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
    # If the gem described by spec does not exist, nil is returned.
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
    # If the gem described by spec does not exist, nil is returned.
    #
    def get( spec )
      raise NotImplementedError, not_implemented_msg( :get )
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
    # If the gem described by spec does not exist, nil is returned.
    # If the gem described by spec does not exist, the block is not called.
    #
    def open( spec, &block )
      raise NotImplementedError, not_implemented_msg( :open )
    end

    # :stopdoc:
    def self.api_methods
      %w[
          delete
          gems_uri
          get
          open
          push
          search_for
          source_index
          uri
          uri_for_gem
          yank
        ]
    end
    # :startdoc:

    private
    # :stopdoc:
    def not_implemented_msg( method )
      "Please implement #{self.class.name}##{method}"
    end
    # :startdoc:
  end
end
