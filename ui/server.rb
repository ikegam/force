#!/usr/bin/ruby

require 'webrick'

FORCE_CONF = "../force.conf"

s = WEBrick::HTTPServer.new(
  :BindAddress => '127.0.0.1',
  :Port => 10800
)

s.mount_proc("/") { |req, res|

  form = '
    <div>MAC : <input type="text" name="MAC"></div>
    <div>Network Name : <input type="text" name="Network Name"></div>
    <input type="submit" value="send">
    <input type="reset" value="reset">
  '

  res.body = "
  <html>
    <head>
    <title>Force Web UI</title>
    <link rel=\"stylesheet\" type=\"text/css\" media=\"screen\" href=\"style.css\">
    </head>
  <body>
  <center>
  <h1 id=\"project_title\">Force Web UI</h1>
  </center>
  <div id=\"main_content_wrap\" class=\"outer\">
  <section id=\"main_content\" class=\"inner\">
  <h2>Networks and MAC addresses</h2>
  <table>
  #{
    lines=[]
    File.open(FORCE_CONF){|x| x.readlines.each{|e|
      next if e =~ /^.*\#/
      columns = e.split(/\s+/)
      next if columns.size != 2
      lines.push("<form method=\"POST\" action=\"delete\"><tr><td>#{columns[0]}</td><td>#{columns[1]}</td><td><input type=\"hidden\" name=\"mac\" value=\"#{columns[0]}\"><input type=\"submit\" name=\"delete\" value=\"delete\"></td></tr></form>")
  
    }}
    lines.join("\n")
  }
  </table>
  <h2>Add new entry</h2>
  <form method=\"POST\" action=\"register\">
  #{form}
  </form>
  </section></div>
  </body>
  </html>
  "
}

s.mount_proc("/delete") { |req, res|
  ret = []
  File.open(FORCE_CONF){|x| x.readlines.each{|e|
    next if e =~ /^.*\#/
    columns = e.split(/\s+/)
    next if columns.size != 2
    next if columns[0] == req.query['mac']
    ret.push(columns.join(" "))
  }
  }
  File.open(FORCE_CONF, 'w'){|x|
    x.write(ret.join("\n"))
  }
  res.body="
  <html><head></head>
    <body>
    <p>Successfull</p>
    </body>
  </html>
  "
}

s.mount_proc("/register") { |req, res|
  result = req.query.map{|x| x[1]}.join(" ")
  p result

  File.open(FORCE_CONF, 'a'){|x|
    x.write("\n#{result}\n")
  }

  res.body="
  <html><head></head>
    <body>
    <p>Successfull</p>
    </body>
  </html>
  "
}

s.mount_proc("/style.css") {|req, res|
  File.open('style.css'){|x| res.body = x.readlines.join("\n")}
}

trap("INT"){ s.shutdown }
s.start

