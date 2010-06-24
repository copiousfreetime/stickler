
shared_examples_for "includes Repository::Api" do
  describe "responds to all the api methods" do
    Stickler::Repository::Api.api_methods.each do |method|
      it "responds to ##{method}" do
        @repo.respond_to?( method ).should == true
      end
    end
  end
end

shared_examples_for "implements Repository::Api" do
  before( :each ) do
    @foo_gem_local_path = File.join( @gems_dir, "foo-1.0.0.gem" )
    @foo_spec = Stickler::SpecLite.new( 'foo', '1.0.0' )
  end

   [ [ 'uri' ],
     [ 'gems_uri' ],
     [ 'specifications_uri' ],
     [ 'uri_for_specification', Stickler::SpecLite.new( 'foo', '1.0.0' ) ] ,
     [ 'uri_for_gem', Stickler::SpecLite.new( 'foo', '1.0.0' ) ], 
   ].each do |send_args|
    it "returns a URI like object from #{send_args.first}" do
      result = @repo.send( *send_args )
      [ ::URI, ::Addressable::URI ].include?( result.class ).should == true
    end
  end

  it "returns a Gem::SourceIndex for #source_index" do
    idx = @repo.source_index
    idx.should be_kind_of( Gem::SourceIndex )
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

  it "can find a gem in the repo" 
  it "does not find a gem that has been yanked"

end
