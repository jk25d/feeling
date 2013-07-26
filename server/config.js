exports.Config = {
    ip:'70.7.105.129',
    port:8080,
    policyPort: 843, // flash policy if you use flash sockets

    common:{


        /**
         * redis hashring
         */
        redis:{
            '127.0.0.1:6379':1
        },

        maxClients:100000,
        maxClientsPerChannel:60000,
        maxMessageLength: 180,

        maxMessagesInHistory: 100,
        historyBlockLength: 300000, // ms
        historyBlockCount: 36 // stored history blocks
    }
};
