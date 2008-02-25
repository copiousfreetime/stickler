require 'configuration'

require 'rake'
require 'stickler/configuration'
require 'stickler/version'

require 'tasks/utils'

#-----------------------------------------------------------------------
# General project configuration
#-----------------------------------------------------------------------
Configuration.for('project') {
  name          Stickler.to_s.downcase
  version       Stickler::VERSION
  author        "Jeremy Hinegardner"
  email         "jeremy at hinegardner dot org"
  homepage      "http://copiousfreetime.rubyforge.org/stickler/"
  description   Utils.section_of("README", "description")
  summary       description.split(".").first
  history       "HISTORY"
  license       "LICENSE"
  readme        "README"
}

#-----------------------------------------------------------------------
# Packaging 
#-----------------------------------------------------------------------
Configuration.for('packaging') {
  # files in the project 
  proj_conf = Configuration.for('project')
  files {
    bin       FileList["bin/*"]
    lib       FileList["lib/**/*.rb"]
    test      FileList["spec/**/*.rb"]
    data      FileList["data/**/*"]
    tasks     FileList["tasks/**/*.r{ake,b}"]
    rdoc      FileList[proj_conf.history, "COPYING", proj_conf.readme, 
                       proj_conf.license] + lib
    all       bin + lib + test + data + rdoc + tasks 
  }

  # ways to package the results
  formats {
    tgz true
    zip true
    gem Configuration.exist?('gem')
  }
}

#-----------------------------------------------------------------------
# Gem packaging
#-----------------------------------------------------------------------
Configuration.for("gem") {
  spec "gemspec.rb"
  Configuration.for('packaging').files.all << spec
}

#-----------------------------------------------------------------------
# Testing
#-----------------------------------------------------------------------
Configuration.for('test') {
  mode      "spec"
  files     Configuration.for("packaging").files.test
  options   %w[ --format specdoc --color ]
  ruby_opts %w[ ]
}

#-----------------------------------------------------------------------
# Rcov 
#-----------------------------------------------------------------------
Configuration.for('rcov') {
  output_dir  "coverage"
  libs        %w[ lib ]
  rcov_opts   %w[ --html ]
  ruby_opts   %w[ ]
  test_files  Configuration.for('packaging').files.test

  # hmm... how to configure remote publishing
}

#-----------------------------------------------------------------------
# Rdoc 
#-----------------------------------------------------------------------
Configuration.for('rdoc') {
  files       Configuration.for('packaging').files.rdoc
  main        files.first
  title       Configuration.for('project').name
  options     %w[ --line-numbers --inline-source ]
  output_dir  "doc"

  # hmm... how to configure remote publishing ...
}

#-----------------------------------------------------------------------
# Rubyforge 
#-----------------------------------------------------------------------
Configuration.for('rubyforge') {
  project   "copiousfreetime"
  user      "jjh"
}

#-----------------------------------------------------------------------
# dump the configuration
#-----------------------------------------------------------------------
if $0 == __FILE__ then
  $: << "../lib"

  def dump_config(config, prefix = "")
    (config.methods - Object.methods - ['method_missing']).each do |method|
      r = config.send(method)
      r = r.to_ary if r.respond_to?(:to_ary)
      case r
      when Configuration
        puts "#{prefix}<#{method.to_s.center(12)}>" 
        dump_config(r,prefix + "    ")
      when Array
        puts "#{prefix}#{method.to_s.rjust(12)} :"
        r.each do |x|
          puts "#{prefix}#{"-".rjust(12)} #{x}"
        end
      else
        puts "#{prefix}#{method.to_s.rjust(12)} : #{r.inspect}"
      end
    end
  end

  Configuration::Table.keys.sort.each do |config_key|
    puts "[#{config_key.center(12)}]" 
    dump_config(Configuration.for(config_key), "    ")
  end
end
