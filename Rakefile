begin
  require 'bones'
rescue LoadError
  abort '### Please install the "bones" gem ###'
end

task :default => 'spec:run'
task 'gem:release' => 'spec:run'

Bones {
  name 'stickler'
  authors 'Jeremy Hinegardner'
  email   'jeremy@hinegardner.org'
  url     'http://rubygems.org/gems/stickler'

  ruby_opts      %w[-W0 -rubygems]
  readme_file    'README.rdoc'
  ignore_file    '.gitignore'
  history_file   'HISTORY.rdoc'
  rubyforge.name 'copiousfreetime'

  spec.opts << "--color" << "--format specdoc"

  depend_on 'sinatra', '~> 1.0.0'
  depend_on 'addressable', '~> 2.1.2'
  depend_on 'resourceful', '~> 1.0.1'
  depend_on 'trollop', '~> 1.16.2'

  depend_on 'bones'       , '~> 3.4.6', :development => true
  depend_on 'rack-test'   , '~> 0.5.4', :development => true
  depend_on 'bones-extras', '~> 1.2.4', :development => true
}
