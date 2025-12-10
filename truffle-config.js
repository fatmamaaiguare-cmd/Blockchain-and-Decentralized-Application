module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,     // Port Ganache GUI
      network_id: "*"
    }
  },

  contracts_build_directory: "./src/artifacts/",

  mocha: {
    // timeout: 100000
  },

  compilers: {
    solc: {
      version: "0.5.9"  // Garde cette version si tes contrats sont modernes
    }
  }

  // db: {
  //   enabled: false
  // }
};
