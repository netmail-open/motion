#!/usr/bin/env python

# run me with:
#     ./knights.pl
#
# configure me by creating a config:
#    curl -v -d "" localhost:30710/knights/
# and visiting the returned Location in a web browser
#
# post data to me through that same Location:
#    curl -v -d @knights-post.json localhost:30710/knights/...


import json
import BaseHTTPServer, cgi


PORT = 30710
ENDPOINT = "/knights/"
CONFIGPATH = "/knights/config/"
CONFIGSAVE = "/knights/config/save/"
MANIFEST = {
	"name": "python knights",
	"description": "allows messages with 'shrubbery' property to pass",
	"requires": [ "subject" ],
	"requests": [ "shrubbery" ],
	"modifies": [ "subject" ],
	"endpoint": ENDPOINT
}
CONFIG = {
    "word": "ni"
}


try:
    CONFIG = json.loads(open("knights-config.json").read())
except:
    pass

class MyHandler(BaseHTTPServer.BaseHTTPRequestHandler):
    def do_HEAD(s):
        s.send_response(200)
        s.send_header("Content-type", "application/json")
        s.end_headers()
    def do_POST(s):
        if s.path == ENDPOINT:
            s.send_response(301)
            s.send_header("Location", CONFIGPATH)
            s.end_headers()
        elif s.path == CONFIGPATH:
            try:
                content_len = int(s.headers.getheader('Content-length', 0))
                req = json.loads(s.rfile.read(content_len))
                sub = req["subject"]
            except:
                s.send_response(400)
                s.send_header("Content-type", "text/plain")
                s.wfile.write("400 Bad Request")
                return
            s.send_response(200)
            s.send_header("Content-type", "application/json")
            s.end_headers()
            res = {}
            if sub.split().count("it"):
                raise Exception("AAAUGH!")
            elif req.keys().count("shrubbery"):
                res["subject"] = sub
            else:
                res["subject"] = CONFIG["word"] + "!!!"
            s.wfile.write(json.dumps(res))
        elif s.path == CONFIGSAVE:
            content_len = int(s.headers.getheader('Content-length', 0))
            query_string = s.rfile.read(content_len)
            args = dict(cgi.parse_qsl(query_string))
            if args["word"]:
                CONFIG["word"] = args["word"]
            fd = open("knights-config.json", "w")
            fd.write(json.dumps(CONFIG))
            fd.close()
            s.send_response(301)
            s.send_header("Location", CONFIGPATH)
            s.end_headers()
    def do_GET(s):
        if s.path == "/":
            s.send_response(200)
            s.send_header("Content-type", "application/json")
            s.end_headers()
            s.wfile.write(json.dumps(MANIFEST))
        elif s.path == CONFIGPATH:
            s.send_response(200)
            s.send_header("Content-type", "text/html")
            s.end_headers()
            fd = open("knights-config.html")
            html = fd.read()
            html = html.replace("@WORD_VALUE@", CONFIG["word"])
            s.wfile.write(html)
            fd.close()

if __name__ == '__main__':
    server_class = BaseHTTPServer.HTTPServer
    httpd = server_class(("localhost", PORT), MyHandler)
    print "motion service 'knights' running at http://localhost:%s" % (PORT);
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()
    print "motion service 'knights' stopped.";
