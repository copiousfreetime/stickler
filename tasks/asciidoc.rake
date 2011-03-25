namespace :asciidoc do

  rule '.html' => '.asciidoc' do |t|
    sh "a2x --no-xmllint --format xhtml #{t.source}"
  end

  src  = FileList["*.asciidoc", "man/*.asciidoc"]
  html = src.collect{ |f| f.ext( "html" ) }

  desc "Create html pages"
  task :create => html

  task :clobber_asciidoc do
    rm_f FileList["man/*.{html,xml}", "*.{html,xml}"]
  end
end

desc "Alias to asciidoc:create"
task :asciidoc => "asciidoc:create"
task :clobber => %w[ asciidoc:clobber_asciidoc]
