'use strict';

var services = angular.module('services', []);

var updateCallback;
var socket = io.connect('http://localhost:5000');
socket.on('update', function (data) {
    console.log("Got invoice update notification for address: ", data.address);

    if(updateCallback) updateCallback();
});

services.factory('RPC', ['$http', function($http) {

    function post(url, entity) {
        loader(true);
        return $http({method: 'POST', url: url, data: entity})
            .success(function() {
                loader(false);
            })
            .error(function(data, status, headers, config) {
                loader(false);
                console.log("RPC Failure: ",data);
            });
    }

    function get(url) {
        loader(true);
        return $http({method: 'GET', url: url })
            .success(function() {
                loader(false);
            })
            .error(function(data, status, headers, config) {
                loader(false);
                console.log("RPC Failure: ", data);
            });
    }

    function loader(display) {
        $('loader-animation').css('display', display ? '' : 'none');
    }

    return {
        createInvoice: function(amount, currency) {
            return post('/invoice', { amount: amount, currency: currency });
        },

        getInvoice: function(address, token) {
            return get('/invoice/' + address + "?token=" + encodeURIComponent(token));
        },

        getTicker: function() {
            return get('/ticker');
        },

        listenForUpdates: function(address, callback) {
            socket.emit('listen', address);
            updateCallback = callback;
        }
    };

}])

