module Stickler::Middleware
  #
  # Idea completely taken from rack-contrib, it can function as a middleware
  # also, and in that case, completely swallows all requests and returns the
  # 4040 page.
  #
  class NotFound
    def initialize( app = nil )
      @body = <<-_
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
    <style type="text/css" media="screen">
      * { margin: 0; padding: 0; border: 0; outline: 0; }
      div.clear { clear: both; }
      body { background: #eeeeee; margin: 0; padding: 0; }
      #wrap { width: 1000px; margin: 0 auto; padding: 30px 50px 20px 50px;
              background: #fff; border-left: 1px solid #DDD;
              border-right: 1px solid #DDD; }
      #header { margin: 0 auto 25px auto; }
      h1 { margin: 0; font-size: 36px; color: #981919; text-align: center; }
      h2 { margin: 0; font-size: 22px; color: #333333; }
      table.gem { width: 980px; text-align: left; font-size: 12px;
                  color: #666666; padding: 0; border-spacing: 0;
                  border: 1px solid #EEEEEE; border-bottom: 0;
                  border-left: 0;
                  clear:both;}
      table.gem tr th { padding: 2px 10px; font-weight: bold;
        font-size: 22px; background: #f7f7f7; text-align: center;
        border-left: 1px solid #eeeeee;
        border-bottom: 1px solid #eeeeee; }
      table.gem tr td { padding: 2px 20px 2px 10px;
                        border-bottom: 1px solid #eeeeee;
                        border-left: 1px solid #eeeeee; }

    </style>
    <title>Stickler - Not Found</title>
  </head>
  <body>
    <div id="wrap">
      <div id="header">
        <h1>Nothing Found</h1>
      </div>
      <h2>Try <a href="/">Over Here</a></h2>
    </div>
  </body>
</html>
      _
      @size = @body.size.to_s
    end

    def call( env )
      [ 404, 
        { 'Content-Type' => 'text/html', 'Content-Length' => @size },
        [ @body ]
      ]
    end
  end
end
