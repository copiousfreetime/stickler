namespace :man do

  rule '.1' => '.asciidoc' do |t|
    sh "a2x --format manpage #{t.source}"
  end

  src = FileList["man/*.asciidoc"]
  man = src.collect{ |f| f.ext( "1" ) }

  desc "Create man pages"
  task :create => man 

  task :clobber_man do
    rm_f FileList["man/*.1", "man/*.html", "man/*.xml"]
  end
end

task :clobber => %w[ man:clobber_man ]
task 'gem:prereqs' => 'man:create'
