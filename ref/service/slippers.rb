#!/usr/bin/env ruby

# run me with:
#     ./slippers.rb
#
# post data to me with:
#     curl -v -d @rot13-post.json localhost:30710/rot13/submit


require "socket"
require "json"


ENDPOINT = "/slippers/"
SUBMIT = "/slippers/submit"
MANIFEST = {
	"name" => "slippers",
	"description" => "determines whether a message is in kansas anymore",
	"requires" => [ "latitude", "longitude" ],
	"requests" => [ ],
	"modifies" => [ "in-kansas-anymore" ],
	"endpoint" => ENDPOINT
};


server = TCPServer.new(30710)
puts("motion service 'slippers' running at http://localhost:30710/")
loop {
  socket = server.accept()
  reqline = socket.gets()
  verb = reqline.split()[0]
  path = reqline.split()[1]
  puts reqline
  headers = ""
  response = ""

  if path == "/"
    resp = JSON.pretty_generate(MANIFEST)
    headers = ["HTTP/1.1 200 OK",
               "Content-Type: application/json",
               "Content-Length: #{resp.bytesize + 1}",
               "",
               ""
              ].join("\r\n")
    socket.puts(headers)
    if verb != "HEAD"
      socket.puts(resp)
    end
    socket.close()
  elsif path == ENDPOINT
    headers = ["HTTP/1.1 201 Created",
               "Location: #{SUBMIT}",
               "Connection: close",
               "",
               ""
              ].join("\r\n")
    socket.puts(headers)
    socket.close()
  elsif path == SUBMIT
    res = {
      "in-kansas-anymore" => false
    }
    begin
      if verb != "POST"
        raise "bad request"
      end
      reqline = socket.gets()
      size = 0
      while reqline.strip().length() > 0
        if reqline.split()[0] == "Content-Length:"
          size = reqline.split()[1].to_i()
        end
        reqline = socket.gets()
      end

      json = socket.read(size)
      req = JSON.parse(json)
      lat = req["latitude"].to_f()
      lon = req["longitude"].to_f()
      if 37 <= lat and lat <= 40 and -94.5833333 >= lon and lon >= -102.05
        res["in-kansas-anymore"] = true
      end

      resp = JSON.pretty_generate(res)
      headers = ["HTTP/1.1 200 OK",
                 "Content-Type: application/json",
                 "Content-Length: #{resp.bytesize + 1}",
                 "",
                 ""
                ].join("\r\n")
    rescue
      resp = "400 Bad Request"
      headers = ["HTTP/1.1 400 Bad Request",
                 "Content-Type: text/plain",
                 "Content-Length: #{resp.bytesize + 1}",
                 "",
                 ""
                ].join("\r\n")
    ensure
      socket.puts(headers)
      if verb != "HEAD"
        socket.puts(resp)
      end
      socket.close()
    end
  else
    resp = "404 Not Found"
    headers = ["HTTP/1.1 404 Not Found",
               "Content-Type: text/plain",
               "Content-Length: #{resp.bytesize + 1}",
               "",
               ""
              ].join("\r\n")
    socket.puts(headers)
    if verb != "HEAD"
      socket.puts(resp)
    end
    socket.close()
  end
}
