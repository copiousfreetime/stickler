require 'stickler/version'
module Utils
  class << self

    # Try to load the given _library_ using the built-in require, but do not
    # raise a LoadError if unsuccessful. Returns +true+ if the _library_ was
    # successfully loaded; returns +false+ otherwise.
    #
    def try_require( lib ) 
      require lib
      true 
    rescue LoadError 
      false 
    end 

    # partition an rdoc file into sections, and return the text of the section
    # given.  
    def section_of(file, section_name) 
      File.read(file).split(/^(?==)/).each do |section|
        lines = section.split("\n")
        return lines[1..-1].join("\n").strip if lines.first =~ /#{section_name}/i
      end
      nil
    end

    # Get an array of all the changes in the application for a particular
    # release.  This is done by looking in the history file and grabbing the
    # information for the most recent release.  The history file is assumed to
    # be in RDoc format and version release are 2nd tier sections separated by
    # '== Version X.Y.Z'
    #
    # returns:: A hash of notes keyed by version number
    #
    def release_notes_from(history_file)
      releases = {}
      File.read(history_file).split(/^(?==)/).each do |section|
        lines = release.split("\n")
        md = %r{Version ((\w+\.)+\w+)}.match(lines.first)
        next unless md
        releases[md[1]] = lines[1..-1].join("\n").strip
      end
      return releases
    end
  end # << self
end

