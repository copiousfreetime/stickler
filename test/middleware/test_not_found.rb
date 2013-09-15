require 'test_stickler'

module Stickler
  class MiddlewareNotFound < Test
    include Rack::Test::Methods
    def app
      ::Stickler::Middleware::NotFound.new
    end

    def setup
      get "/"
    end

    def test_responds_with_404_to_everything
      assert_equal 404, last_response.status
    end

    def test_resturns_html_page
      assert_equal 'text/html', last_response.content_type
    end

    def test_body_says_look_elsewhere 
     assert_match( /Not Found/, last_response.body)
    end
  end
end
