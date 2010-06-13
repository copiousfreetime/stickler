begin
  require 'bones'
rescue LoadError
  abort '### Please install the "bones" gem ###'n
end

task :default => 'spec:run'
task 'gem:release' => 'spec:run'

Bones {
  name 'stickler'
  authors 'Jeremy Hinegardner'
  email   'jeremy(at)hinegardner.org'
  url     'http://rubygems.org/gems/stickler'

  ignore_file '.gitignore'
}
