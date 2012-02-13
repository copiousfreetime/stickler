begin
  USING_BONES_VERSION = '3.7.3'
  require 'bones'
rescue LoadError
  load 'tasks/contribute.rake'
  Rake.application.invoke_task( :help )
end

task :default => 'spec:run'
task 'gem:release' => 'spec:run'

$: << "lib"
require 'stickler/version'

Bones {
  name 'stickler'
  authors 'Jeremy Hinegardner'
  email   'jeremy@hinegardner.org'
  url     'http://www.copiousfreetime.org/projects/stickler'
  version Stickler::VERSION

  ruby_opts      %w[-w -rubygems]
  readme_file    'README.asciidoc'
  ignore_file    '.bnsignore'
  history_file   'HISTORY.asciidoc'

  spec.opts << "--color" << "--format documentation"

  summary 'Stickler is a tool to organize and maintain an internal gem repository.'
  description <<_
Stickler is a tool to organize and maintain an internal gem repository.
Primarily, you would want to use Stickler if:

1. You have proprietary gems that you want to have available via a gem server so 
   you may +gem install+ them.
2. You would like to have a local mirror of third party gems from either 
   http://rubygems.org or some other gem server.
3. You want both (1) and (2) in the same server.
_

  # I'm explicitly controlling the version of bones.


  depend_on 'sinatra'    , '~> 1.3.2'
  depend_on 'addressable', '~> 2.2.6'
  depend_on 'excon'      , '~> 0.9.5'
  depend_on 'trollop'    , '~> 1.16.2'
  depend_on 'logging'    , '~> 1.6.2'

  depend_on 'rake'        , '~> 0.9.2.2', :development => true
  depend_on 'bones'       , "~> #{USING_BONES_VERSION}", :development => true
  depend_on 'rack-test'   , '~> 0.6.1', :development => true
  depend_on 'bones-extras', '~> 1.3.0', :development => true
  depend_on 'builder'     , '~> 3.0.0', :development => true
  depend_on 'rspec'       , '~> 2.8.0', :development => true
}

# Sorry Tim, I need to manage my own bones version
::Bones.config.gem._spec.dependencies.delete_if do |d|
  d.name == 'bones' and d.requirement.to_s =~ /^>=/
end
