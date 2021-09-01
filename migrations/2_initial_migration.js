const root = require("path").join.bind(this, __dirname, "../")
require("dotenv").config({ path: root(".env") });

const SisyphusGamble = artifacts.require("SisyphusGamble");
const ERC20_ADDRESS = process.env.ERC20_ADDRESS;

module.exports = function (deployer) {
  deployer.deploy(SisyphusGamble, ERC20_ADDRESS, 1, 1, 1, ERC20_ADDRESS, ERC20_ADDRESS);
};
