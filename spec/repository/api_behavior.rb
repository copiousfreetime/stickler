require 'stickler/repository/api'

shared_examples_for "includes Repository::Api" do
  describe "responds to all the api methods" do
    Stickler::Repository::Api.api_methods.each do |method|
      it "responds to ##{method}" do
        @repo.respond_to?( method ).should == true
      end
    end
  end
end

require 'digest/sha1'
shared_examples_for "implements Repository::Api" do
  before( :each ) do
    @foo_gem_local_path = File.join( @gems_dir, "foo-1.0.0.gem" )
    @foo_spec           = Stickler::SpecLite.new( 'foo', '1.0.0' )
    @foo_digest         = Digest::SHA1.hexdigest( IO.read( @foo_gem_local_path ) )
    @missing_spec       = Stickler::SpecLite.new( "does_not_exist", "0.1.0" )
  end

  # removed specifications_uri
  %w[ uri gems_uri ].each do |method|
    it "returns a URI like object from #{method}" do
      result = @repo.send( method )
      [ ::URI, ::Addressable::URI ].include?( result.class ).should == true
    end
  end

  # removed specification
  %w[ gem ].each do |thing|
    describe "#uri_for_#{thing}" do
      before( :each ) do
        @repo.push( @foo_gem_local_path )
        @method = "uri_for_#{thing}"
      end

      it "returns URI for a #{thing} that exists" do
        uri = @repo.send( @method, @foo_spec )
        [ ::URI, ::Addressable::URI ].include?( uri.class ).should == true
      end

      it "returns nil for a #{thing} that does not exist" do
        @repo.send( @method, @missing_spec ).should be_nil
      end
    end
  end

  describe "#push" do
    it "pushes a gem from a .gem file" do
      @repo.push( @foo_gem_local_path )
      @repo.search_for( Stickler::SpecLite.new( "foo", "1.0.0" ) )
    end

    it "raises an error when pushing a gem if the gem already exists" do
      @repo.push( @foo_gem_local_path )
      lambda { @repo.push( @foo_gem_local_path ) }.should raise_error( Stickler::Repository::Error, /gem foo-1.0.0 already exists/ )
    end
  end

  describe "#delete" do
    it "deletes a gem from the repo" do
      @repo.search_for( @foo_spec ).should be_empty
      @repo.push( @foo_gem_local_path )
      @repo.search_for( @foo_spec ).size.should == 1
      @repo.delete( @foo_spec ).should == true
      @repo.search_for( @foo_spec ).should be_empty
    end

    it "returns false if it is unable to delete a gem from the repo" do
      @repo.search_for( @foo_spec ).should be_empty
      @repo.delete( @foo_spec ).should == false
    end
  end

  describe "#yank" do
    before( :each ) do
      @repo.search_for( @foo_spec ).should be_empty
      @repo.push( @foo_gem_local_path )
      @response_uri = @repo.yank( @foo_spec )
    end

    it "returns the uri in which to get the gem" do
      [ ::URI, ::Addressable::URI ].include?( @response_uri.class ).should == true
    end

    it "returns nil if the gem to yank does not exist or is already yanked" do
      @repo.yank( @missing_spec ).should == nil
    end

    it "does not find the gem in a search" do
      @repo.search_for( @foo_spec ).should be_empty
    end

    it "does have the #uri_for_gem" do
      @repo.uri_for_gem( @foo_spec ).should == @response_uri
    end

    it "can still return the gem" do
      data = @repo.get( @foo_spec )
      sha1 = Digest::SHA1.hexdigest( data )
      sha1.should == @foo_digest
    end

  end

  describe "#unyank" do
    before( :each ) do
      @repo.search_for( @foo_spec ).should be_empty
      @repo.push( @foo_gem_local_path )
    end

    it "returns nil if the gem to unyank does not exist" do
      non_existing_gem = @missing_spec
      @repo.unyank( non_existing_gem ).should be_nil
    end

    #Do we even care about this?
    xit "returns nil if the gem to unyank has not been yanked" do
      @repo.unyank( @foo_spec ).should be_nil
    end

    context " when file has been yanked" do
      before :each do
        @repo.yank( @foo_spec )
      end

      it "return true if the gem is successfully unyanked" do
        @repo.unyank( @foo_spec ).should be_true
      end

      it "finds the gem in a search" do
        @repo.unyank( @foo_spec )
        @repo.search_for( @foo_spec ).should_not be_empty
      end
    end
  end

  describe "#search_for" do
    it "returns specs for items that are found" do
      @repo.push( @foo_gem_local_path )
      @repo.search_for( @foo_spec ).should_not be_empty
    end

    it "returns an empty array when nothing is found" do
      @repo.search_for( @missing_spec ).should be_empty
    end
  end

  describe "#get" do
    it "returns the bytes of the gem for a gem that exists" do
      @repo.push( @foo_gem_local_path )
      data = @repo.get( @foo_spec )
      sha1 = Digest::SHA1.hexdigest( data )
      sha1.should == @foo_digest
    end

    it "returns nil if the gem does not exist" do
      @repo.get( @missing_spec ).should be_nil
    end
  end

  describe "#open" do
    before( :each ) do
      @repo.push( @foo_gem_local_path )
    end
    it "reads a gem via a returned output stream" do
      io = @repo.open( @foo_spec )
      sha1 = Digest::SHA1.hexdigest( io.read )
      sha1.should == @foo_digest
    end

    it "can be called with a block" do
      sha1 = Digest::SHA1.new
      @repo.open( @foo_spec ) do |io|
        sha1 << io.read
      end
      sha1.hexdigest.should == @foo_digest
    end

    it "returns nil if the gem does not exist" do
      @repo.open( @missing_spec ).should == nil
    end

    it "does not call the block if the gem does not exist" do
      called = false
      @repo.open( @missing_spec ) do |io|
        called = true
      end
      called.should == false
    end
  end

end
