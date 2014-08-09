'use strict';

var SATOSHI_UNIT = 100000000;
var Bitcoin = require('bitcoinjs-lib');
var Q = require('q');
var MongoDB = require('mongodb');
var crypto = require('crypto');
var WebSocket = require('ws');
var http = require('https');

var assert = require('assert');
var mongoUri =
    process.env.MONGOLAB_URI ||
    process.env.MONGOHQ_URL ||
    'mongodb://localhost/btci';

/**
 * database access
 */
var DAO = {
    /**
     * iterate all invoices in the database applying a callback
     */
    forEachInvoice: function(callback) {
        MongoDB.Db.connect(mongoUri, function (err, db) {
            db.collection('invoice', function(err, collection) {
                collection.find({closed: false}).toArray(function(err, invoices) {
                    invoices.forEach(callback);
                    db.close();
                });
            });
        });
    },

    /**
     * get an invoice from the database using an address
     * @param address public address
     */
    getInvoiceFromAddress: function(address) {
        var deferred = Q.defer();
        MongoDB.Db.connect(mongoUri, function (err, db) {
            db.collection('invoice', function(er, collection) {
                collection.findOne({
                    address: address
                }, {w: 0}, function(err, invoice) {
                    // assert.equal(err, null, "");

                    if(err)
                        deferred.reject(err);
                    else
                        deferred.resolve(invoice);

                    db.close();
                });
            });
        });
        return deferred.promise;
    },

    /**
     * saves  an invoice to the database
     * @param invoice the raw invoice
     * @returns {promise} promise of the id'd invoice
     */
    insertInvoice: function(invoice) {
        var deferred = Q.defer();
        MongoDB.Db.connect(mongoUri, function (err, db) {
            db.collection('invoice', function(er, collection) {
                collection.insert(invoice, {w: 0}, function(err, invoices) {
                    assert.equal(err, null, "");
                    deferred.resolve(invoices[0]);
                    db.close();
                });
            });
        });
        return deferred.promise;
    },

    /**
     * add unspent transaction outputs
     * @param utxos
     */
    addUnspentTxOutputs: function(utxos) {

        // add to mongo object
        MongoDB.Db.connect(mongoUri, function (err, db) {
            db.collection('invoice', function(er, collection) {
                utxos.forEach(function(utxo) {
                    collection.update(
                        {address: utxo.address},
                        {
                            $push: {
                                utxos: utxo
                            }
                        },
                        function(err, r) {
                            if(err) {
                                console.log('failed to add utxo to the db', err);
                            } else {
                                console.log('added utxo to the db: ', utxo);
                            }
                            db.close();
                        }
                    );
                });
            });
        });
    }
};

/**
 *
 * @param currency example: USD
 * @returns numeric exchange rate
 */
function getExchangeRate(currency) {
    var deferred = Q.defer();
    var lastOne = {};

    http.get("https://blockchain.info/ticker", function(res) {
        var resultBody = "";

        res.on('data', function(chunk) {
            resultBody+=chunk;
        });

        res.on('end', function() {
            try {
                deferred.resolve(lastOne = JSON.parse(resultBody));
            } catch (e) {
                deferred.resolve(lastOne);
            }
        });

    }).on('error', function(e) {
        console.error("Failed to parse ticker data", e.message);
        deferred.reject(e);
    });

    return deferred.promise.then(function(ticker) {
        if(!(currency in ticker)) return 1;
        return ticker[currency.toUpperCase()].last;
    });
}

/**
 * connection to the blockchain.info API
 *
 * @constructor
 */
function BlockchainAPIConnection() {
    var websocket = new WebSocket('ws://ws.blockchain.info/inv');
    var wallets = [];
    var walletListeners = {};
    var connected = false;

    websocket.on('open', function() {
        console.log("Connection to Blockchain opened.");
        connected = true;

        wallets.forEach(function(wallet) {
            subscribeAddresses(wallet.addresses);
        });
    });

    websocket.on('error', function(error) {
        console.log("blockchain.info api: received error: ", error);
    })

    websocket.on('message', function(data, flags) {
        try {
            var dataObject = JSON.parse(data);
            // console.log("blockchain.info api: received message: ", dataObject);

            switch(dataObject.op) {
                case 'utx': handleTx(dataObject.x); break;
                default:
            }
        } catch (e) {
            console.error('Failed to understand message from blockchain api: ', e);
        }
    });

    /** handle an incoming transaction from blockchain.info */
    function handleTx(tx) {
        console.log('blockchain.info api: processing transaction ', tx.hash);

        // find a matching wallet
        for(var i=0; i<wallets.length; i++) {
            var wallet = wallets[i];
            var address = wallet.addresses[0];
            var utxos = [];

            // locate matching tx
            tx.out.forEach(function(out, i) {
                if(out.addr != address)
                    return;

                utxos.push({
                    hash: tx.hash,
                    outputIndex: i,
                    address: out.addr,
                    value: out.value
                });
            });

            if(utxos.length > 0) {
                console.log("Balance before: " + wallet.getBalance());
                //wallet.setUnspentOutputs(utxos);

                // build locally parseable transactions
                var btTx = new Bitcoin.Transaction();
                utxos.forEach(function(utxo) {
                    btTx.addInput(tx.hash, utxo.outputIndex);
                    btTx.addOutput(wallet.addresses[0], utxo.value);
                });

                // process in the wallet
                wallet.processConfirmedTx(btTx);
                console.log("Balance after: " + wallet.getBalance());

                // save the transactions to the database for future processing
                DAO.addUnspentTxOutputs(utxos);

                // notify any currently watching UIs
                notifyUpdate(address);

                break;
            }
        }
    }

    function notifyUpdate(address) {
        if(!(address in walletListeners))
            return;

        walletListeners[address].forEach(function(listener) {
            console.log("firing callback listener");
            listener(address);
        });
    }

    function subscribeAddresses(addresses) {
        addresses.forEach(function(address) {
            websocket.send('{"op":"addr_sub", "addr":"' + address + '"}');
        });
        console.log("blockchain.info api: subscribed to ", addresses);
    }

    return {
        /**
         * subscribes a new wallet to the blockchain connection, ensuring it hears all future
         * transactions it's interested in
         */
        subscribe: function(wallet) {
            wallets.push(wallet);

            if(!connected)
                return;

            subscribeAddresses(wallet.addresses);
        },

        registerListener: function(address, callback) {
            if(!(address in walletListeners))
                walletListeners[address] = [];
            walletListeners[address].push(callback);
            return {
                destroy: function() {
                    var listeners = walletListeners[address];
                    var i = listeners.indexOf(callback);
                    if(i < 0) return;
                    listeners.splice(i,1);
                    console.log("registered listener destroyed");
                }};
        },

        /**
         * determines the balance of the wallet behind the given address
         * @param address public address
         * @returns the balance, or 0
         */
        getBalance: function(address) {
            return wallets.reduce(function(p, wallet) {
                if(wallet.addresses.indexOf(address) < 0)
                    return p;
                console.log("wallet balance: " + wallet.getBalance());
                return p + wallet.getBalance();
            }, 0);
        }
    };
}

// replace with an implementation that used a local bitcoind to skip blockchain.info api dependency if needed
var blockchainConnection = new BlockchainAPIConnection();

/**
 * generate a client-side view of the invoice with its balance populated via the blockchain wallet state
 *
 * @param invoice invoice from the database
 * @returns
 */
function toDTO(invoice) {
    if(!invoice) return {};
    return {
        address: invoice.address,
        amount: invoice.amount,
        currency: invoice.currency,
        balance: blockchainConnection.getBalance(invoice.address) || 0,
        token: invoice.accesstoken,
        refunded: invoice.refunded
    };
}

module.exports = {
    /**
     * load up existing invoices (wallets) from the database and register them with our
     * blockchain for updates
     */
    init: function() {
        DAO.forEachInvoice(function(invoice) {
            if(!invoice.walletSeed) return;
            var seed = new Buffer(invoice.walletSeed, 'base64');
            var wallet = new Bitcoin.Wallet(seed);
            wallet.generateAddress();

            // update balance from existing data
            wallet.setUnspentOutputs(invoice.utxos);

            console.log("from " + invoice.utxos.length + "utxos, got balance: " + wallet.getBalance());

            // subscribe to new transactions bound for this wallet
            blockchainConnection.subscribe(wallet);
        });
        console.log("Database connected and existing invoices have been loaded");
    },

    getExchangeRate: getExchangeRate,

        /**
         * registers a listener callback for invoice changes
         */

    listenToInvoice: function(address, callback) {
        return blockchainConnection.registerListener(address, callback);
    },

    /**
     * creates a new invoice
     * @param amount total amount to bill
     * @param currency currency to bill in
     * @returns {promise} the invoice
     */
    createInvoice: function(amount, currency) {
        var deferred = Q.defer();

        amount = parseFloat(amount);
        if(isNaN(amount))
            throw "Invoice amount must be numeric";
        console.log("Creating invoice for amount: " + amount + " in " + currency);

        switch(currency) {
            case 'USD$':
                getExchangeRate('USD').then(function(rate) {
                    console.log('using exchange rate ', rate);
                    amount = parseInt(amount/rate*SATOSHI_UNIT);
                    buildInvoice(amount);
                });
                break;

            case 'BTC':
                amount = amount*SATOSHI_UNIT;

            default:
            case 'SATOSHI':
                buildInvoice(amount);
        }

        function buildInvoice(amount) {
            // create lots of shit
            var seed = crypto.randomBytes(32);
            var wallet = new Bitcoin.Wallet(seed);
            var address = wallet.generateAddress();
            var accesstoken = "" + Math.random();

            console.log("Generated new address for " + amount + "invoice wallet: " + address);

            // listen to shit and update other shit
            blockchainConnection.subscribe(wallet);

            // database ..n shit
            var invoice;
            DAO.insertInvoice(invoice={
                amount: amount,
                walletSeed: seed.toString('base64'), // this is sooper dooper insecure, should encrypt !
                address: address,
                accesstoken: accesstoken,
                currency: currency,
                closed: false,
                refunded: false,
                utxos: []
            });

            deferred.resolve(toDTO(invoice));
        }

        return deferred.promise;
    },

    /**
     * gets a client-view of an invoice
     * @param {string} address address to retrieve
     * @returns {promise}
     */
    getInvoice: function(address) {
        var deferred = Q.defer();

        return DAO.getInvoiceFromAddress(address).then(function(invoice) {
            return toDTO(invoice);
        });

        return deferred.promise;
    }
};
