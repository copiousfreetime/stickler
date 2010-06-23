require File.expand_path( File.join( File.dirname(__FILE__), "spec_helper.rb" ) )

require 'stickler/mirror'
require 'fileutils'

describe 'Sticker::Mirror' do
  before do
    @mm_root  = File.expand_path( File.join( File.dirname(__FILE__), "mm-tmp" ) )
    @upstream = 'rubygems.org'
    @m        = Stickler::Mirror.new( @mm_root, @upstream )
  end

  after do 
    FileUtils.rm_rf( @mm_root )
  end

  it 'has a root_dir' do
    @m.root_dir.should == File.join( @mm_root, @upstream )
    File.directory?( @m.root_dir ).should == true
  end

  it 'has a gems_dir' do
    @m.gems_dir.should == File.join( @mm_root, @upstream, 'gems' )
    File.directory?( @m.gems_dir ).should == true
  end

  it 'has a specifications_dir' do
    @m.specifications_dir.should == File.join( @mm_root, @upstream, 'specifications' )
    File.directory?( @m.specifications_dir ).should == true
  end

  it 'has an upstream uri' do
    @m.upstream_uri.to_s.should == 'http://rubygems.org'
  end

  it 'can add a new gem' do
    spec = @m.add_gem( { :name => 'foo', :version => '1.0.0' } )
    gemfile = File.join( @m.gems_dir,spec.file_name )
    File.exist?( gemfile ).should == true
    specfile = File.join( @m.specifications_dir, spec.full_name + ".gemspec")
  end
  
end
