
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

  it "pushes a gem from a .gem file" do
    @repo.push( @foo_path )
    @repo.search_for( Stickler::SpecLite.new( "foo", "1.0.0" ) )
  end

  it "raises an error when pushing a gem if the gem already exists" do
    @repo.push( @foo_path )
    lambda { @repo.push( @foo_path ) }.should raise_error( Stickler::Repository::Error, /gem foo-1.0.0 already exists/ )
  end

  it "deletes a gem from the repo"
  it "can find a gem in the repo" 
  it "does not find a gem that has been yanked"

end
