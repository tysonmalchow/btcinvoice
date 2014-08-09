'use strict';

var Express = require("express")
var express = Express();
var server = require('http').Server(express);
var bodyParser = require('body-parser');
var logfmt = require("logfmt");
var BTCI = require('./lib/btci');
var SocketIO = require('socket.io');

var socketIO = new SocketIO(server);

console.log("init BTCI services");
BTCI.init();

console.log("init express application");
express.use(logfmt.requestLogger());
express.use(bodyParser.json());

express.get('/invoice/:address', function(req, res) {
    BTCI.getInvoice(req.param('address')).done(function(invoice) {
        res.json(invoice);
    });
});
express.get('/ticker', function(req,res) {
    BTCI.getTicker().done(function(ticker) {
        res.json({ticker: ticker});
    });
});
express.post('/invoice', function(req, res) {
    console.log("amount: ",req.body);
    BTCI.createInvoice(req.param('amount'), req.param('currency')).done(function(invoice) {
        res.json(invoice);
    });
});
express.use(Express.static(__dirname + '/app'));

// tell clients to update their view whenever an interesting update happens
socketIO.on('connection', function(socket) {
    console.log("Realtime socket connected");
    var binding = null;

    socket.on('listen', function(address) {
        console.log("got listen request for ", address);
        if(binding) binding.destroy();
        binding = BTCI.listenToInvoice(address, function(address) {
            socket.emit('update', {address: address})
        });
    });

    socket.on('disconnect', function(){
        if(binding) binding.destroy();
        binding = null;
        console.log("Realtime socket disconnected");
    });
});

console.log("launching server");
var port = Number(process.env.PORT || 5000);
server.listen(port);
//express.listen(port, function() {
//    console.log("Listening on " + port);
//});
