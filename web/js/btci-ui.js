'use strict';

var coreui = angular.module('btciCore', [
    'ngRoute',
    'services',
    'monospaced.qrcode'
]);


coreui.config(['$routeProvider',
    function($routeProvider) {
        //$scope.exchange = 'Test';
        $routeProvider.
            when('/', {
                templateUrl: 'templates/start.html',
                controller: 'Start'
            }).
            when('/invoice/:address', {
                templateUrl: 'templates/invoice.html',
                controller: 'Invoice'
            }).
            otherwise({
                redirectTo: '/'
            });
    }]);

coreui.controller('Start', ['$scope', '$location', 'RPC',
    function($scope, $location, RPC) {

        $scope.check = function() {
            var amount = parseFloat($scope.amount);
            if(isNaN(amount) || amount == 0)
                $scope.buttonClass = 'disabled';
            else
                $scope.buttonClass = 'enabled';
        };

        $scope.setCurrency = function(c) {
            $scope.currentCurrency = c;
        };

        $scope.create = function() {
            RPC.createInvoice($scope.amount, $scope.currentCurrency)
                .success(function(invoice) {
                    $location.path('/invoice/' + invoice.address);
                });
        };

        $scope.currencies = ['SATOSHI','BTC','USD$']
        $scope.currentCurrency = $scope.currencies[0];
        $scope.buttonClass = 'disabled';
    }]);

coreui.controller('Invoice', ['$scope', 'RPC', '$routeParams',
    function($scope, RPC, $routeParams) {
        var listenerBinding = null;

        $scope.address = $routeParams.address;
        socket.emit('listen', $scope.address);

        $scope.progresstext = '';
        $scope.progressvalue = 0;
        $scope.title = 'Loading';

        listenerBinding = RPC.listenForUpdates($scope.address, function() {
            console.log("updating ui from server notification");
            updateInvoice();
        });

        updateInvoice();

        function formatSatoshi(s, u) {
            if(s < 50000000)
                return s + (u?' Satoshi':'');
            return (s / 100000000) + (u?' BTC':'');
        }

        function updateInvoice() {
            RPC.getInvoice($routeParams.address).success(function(invoice) {
                var remaining = (invoice.amount - invoice.balance)/(invoice.amount<50000000?1:100000000); // make it match the formatted value
                $scope.progresstext = '' + remaining + ' remaining';
                $scope.progressvalue = Math.floor(invoice.balance / invoice.amount * 100);

                $scope.title = formatSatoshi(invoice.amount,true);

                if(invoice.balance==0) {
                    $scope.status = "UNPAID";
                    $scope.statusclass = "unpaid";

                } else if(invoice.balance < invoice.amount) {
                    $scope.status = "PARTIALLY PAID";
                    $scope.statusclass = "partiallypaid";

                } else {
                    $scope.status = "FULLY PAID";
                    $scope.statusclass = "fullypaid";
                }
             });
        }

        $scope.$on('$destroy', function() {
            listenerBinding.destroy();
        });
    }]);

coreui.directive('exchangeRate', ['RPC' ,function(RPC) {
    var timer;

    function updateElement(rateElement, updated) {
        RPC.getExchangeRate('USD').success(function(rate) {
            rateElement.text('1 BTC = USD$' + rate.exchangeRate);
            updated.text('Last updated at ' + new Date());
        }).fail;
    }

    return {
        restrict: 'E',
        template: '<div class="desc">Current Exchange Rate:</div><div class="rate"/><div class="updated"/>',
        link: function(scope, element, attrs) {
            updateElement(element.find('.rate'),element.find('.updated'));
            timer = setInterval(function() {updateElement(element.find('.rate'),element.find('.updated')); console.log("Udated exchange rates");}, 10000);
        }
    };
}]);