namespace :asciidoc do

  rule '.html' => '.asciidoc' do |t|
    sh "a2x --no-xmllint --format xhtml #{t.source}"
  end

  src  = FileList["*.asciidoc", "man/*.asciidoc"]
  html = src.collect{ |f| f.ext( "html" ) }

  desc "Create html pages"
  task :create => html

  task :clobber_asciidoc do
    rm_f FileList["man/*.{html,xml,css}", "*.{html,xml,css}"]
    rm_rf FileList["asciidoc-output"]
  end

  desc "Deploy the asciidoc"
  task :deploy => html do
    FileUtils.cp "README.html", "index.html"
    %w[ . man ].each do |d|
      dest_d = File.expand_path( "asciidoc-output/#{d}" )
      FileUtils.mkdir dest_d unless File.directory?( dest_d )
      FileUtils.cp FileList["#{d}/*.{css,html}"], dest_d
    end
    sh "rsync -ravz asciidoc-output/* #{ENV['DEST_DIR']}" if ENV['DEST_DIR']
  end
end

desc "Alias to asciidoc:create"
task :asciidoc => "asciidoc:create"
task :clobber => %w[ asciidoc:clobber_asciidoc]
