require File.expand_path( File.join( File.dirname(__FILE__), "spec_helper.rb" ) )

require 'stickler/mirror_manager'
require 'fileutils'
describe 'Sticker::MirrorManager' do
  before do
    @mm_root = File.expand_path( File.join( File.dirname(__FILE__), "mm-tmp" ) )
    @mm = Stickler::MirrorManager.new( @mm_root )
  end

  after do 
    FileUtils.rm_rf( @mm_root )
  end

  it 'has a root directory' do
    @mm.root_dir.should == @mm_root
  end
  
  it 'creates a new mirror when needed' do
    m = @mm.for( 'rubygems.org' )
    m.root_dir.should == File.join( @mm_root, 'rubygems.org' )
  end
end
