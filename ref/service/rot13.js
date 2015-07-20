/*

run me with:
    node rot13.js

post data to me with:
    curl -v -d @post.txt localhost:30710/rot13/submit

 */


var http = require("http");
var querystring = require("querystring");


var ENDPOINT = "/rot13/";
var SUBMIT = "/rot13/submit";
var MANIFEST = {
	"name": "translate",
	"description": "rot13's a message",
	"requires": [ "body" ],
	"requests": [ ],
	"modifies": [ "body" ],
	"endpoint": ENDPOINT
};


function rot13(str) {
	var map = [];
	var i = 0;
	var c = null;
	var s = "abcdefghijklmnopqrstuvwxyz";
	for(i = 0; i < s.length; i++) {
		map[s.charAt(i)] = s.charAt( (i + 13) % 26);
	}
	for(i = 0; i < s.length; i++) {
		map[s.charAt(i).toUpperCase()] = (
			s.charAt( (i + 13) % 26).toUpperCase());
	}
	ret = "";
	for(i = 0; i < str.length; i++) {
		c = str.charAt(i);
		ret += (c >= 'A' && c <= 'Z' ||
				c >= 'a' && c <= 'z' ? map[c] : c);
    }
	return ret;
}

http.createServer(function (req, res) {
	//console.log(req.url, req.method);
	if(req.url === "/") {
		res.writeHead(200, {
			"Content-Type": "application/json"
		});
		res.end(JSON.stringify(MANIFEST, null, "    "));
	} else if(req.url === MANIFEST.endpoint) {
		res.writeHead(201, {
			"Content-Type": "application/json",
			"Location": SUBMIT
		});
		res.end();
	} else if(req.url === SUBMIT) {
		var data = [];
		if(req.method === "POST") {
			req.on("data", function(chunk) {
				//console.log("chunk:", chunk.toString());
				data.push(chunk.toString());
			});
			req.on("end", function() {
				if(!data.length) {
					res.writeHead(400, {
						"Content-Type": "text/plain"
					});
					res.end("400 Bad Request");
					return;
				}
				var msg = JSON.parse(data.join(""));
				if(msg.body) {
					msg.body = rot13(msg.body);
				}
				res.writeHead(200, {
					"Content-Type": "application/json"
				});
				res.write(JSON.stringify(msg, null, "    "));
				res.end()
			});
		} else {
			res.writeHead(405, {
				"Content-Type": "text/plain"
			});
			res.end("405 Method Not Allowed");
		}
	}
}).listen(30710, "127.0.0.1");
console.log("motion server 'rot13' running at http://127.0.0.1:30710");
