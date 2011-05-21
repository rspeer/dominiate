var http = require("http");
var url = require("url");
var querystring = require("querystring");
var golem = require("./golem");

/* Here's where I invent a JSON API from scratch. Either because I don't know
   any better, or because it seems Node actually has that kind of
   do-it-yourself vibe to it. */

// An object that handles requests based on the URL. Could be an entire module.
router = golem;

// The main HTTP request handler. Its job is to delegate to a function, passing
// it an object with 'succeed' and 'fail' members it can call to return a
// response.
function onRequest(request, response) {
    var pathname = url.parse(request.url).pathname;
    var query = querystring.parse(url.parse(request.url).query);

    console.log("Request for " + pathname + " received with query "+JSON.stringify(query));

    // The function to delegate to is specified by the URL.
    var handler = router[pathname.substring(1)];
    
    function succeed(data) {
        respondHTTP(response, 200, data)
    }

    function fail(data) {
        respondHTTP(response, 404, data)
    }
    responder = {"succeed": succeed, "fail": fail}

    // Call the handler, and clean up the mess if it doesn't work.
    if (handler === undefined) {
        responder.fail("Unknown method");
    } else {
        try {
            handler(request, responder, query);
        }
        catch (e) {
            respondHTTP(response, 500, e);
        }
    }
}

// The content of every HTTP response will be a JSON object.
function respondHTTP(response, code, data) {
    response.writeHead(code, {"Content-Type": "text/json"});
    response.write(JSON.stringify(data)+"\n");
    response.end();
}

// Great, now start the server.
http.createServer(onRequest).listen(8888);
console.log("Server has started.");

