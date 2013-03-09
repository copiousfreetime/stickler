# vim: syntax=ruby
load 'tasks/this.rb'

This.name     = "stickler"
This.author   = "Jeremy Hinegardner"
This.email    = "jeremy@copiousfreetime.org"
This.homepage = "http://github.com/copiousfreetime/#{ This.name }"


This.ruby_gemspec do |spec|
  spec.add_runtime_dependency( 'sinatra'    , '~> 1.3.2'  )
  spec.add_runtime_dependency( 'addressable', '~> 2.2.6'  )
  spec.add_runtime_dependency( 'excon'      , '~> 0.13.4'  )
  spec.add_runtime_dependency( 'trollop'    , '~> 1.16.2' )
  spec.add_runtime_dependency( 'logging'    , '~> 1.6.2'  )

  # The Development Dependencies
  spec.add_development_dependency( 'rake'        , '~> 10.0.3' )
  spec.add_development_dependency( 'rack-test'   , '~> 0.6.1'   )
  spec.add_development_dependency( 'builder'     , '~> 3.0.0'   )
  spec.add_development_dependency( 'rspec'       , '~> 2.9.0'   )
  spec.add_development_dependency( 'rdoc'        , '~> 3.12'    )

end

load 'tasks/default.rake'
