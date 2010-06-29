require 'stickler/repository'

module Stickler::Repository
  #
  # A null repository.  It is in most respecs like a Repository::Local that has
  # nothing in it.
  #
  # The response to +root_dir+ is set by default to be the class name, or
  # whatever is passed to the initializer.
  #
  class Null
    # the root directory of the repository, this is set in the constructor
    attr_reader :root_dir

    def initialize( root_dir = self.class.name )
      @root_dir = root_dir
    end

    def empty_string( junk = "" )
      ""
    end
    alias :uri :empty_string
    alias :gems_uri :empty_string

    def nilish( junk = nil, &block )
      nil
    end
    alias :push :nilish
    alias :delete :nilish
    alias :yank :nilish
    alias :get :nilish
    alias :open :nilish
    alias :uri_for_gem :nilish
    alias :full_path_to_gem :nilish

    def last_modified_time
      Time.now
    end

    def empty_array( junk = nil )
      []
    end
    alias :specs :empty_array
    alias :latest_specs :empty_array
    alias :search_for :empty_array

    def

    def specs
      Array.new
    end

    def latest_specs
      Array.new
    end

  end
end
