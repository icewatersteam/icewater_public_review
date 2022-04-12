# Setup

   npm install

# To compile

    truffle compile

# To deploy in the dev environment

    truffle develop
    migrate --reset --compile-all

# To deploy in a new network

Edit the `truffle-config.js` file and add a new entry under `networks`. Then run:

    truffle migrate --reset --compile-all --network YOUR_NETWORK


