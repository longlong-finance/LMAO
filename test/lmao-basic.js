const LMOptions = artifacts.require("LMAsOptions");
const LMOptionsToken = artifacts.require("LMAsOptionsToken");
const IERC20 = artifacts.require("IERC20");

const { BN, time, expectRevert, constants, send } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');
const {resetToBlock, impersonate} = require("./helpers/blockchain-helpers.js");

function olmBasicTest(description, rewardAddr, rewardWhale, rewardTotalBalance, buyWithAddr, buyWithWhale, buyWithTotalBalance, blockNo) {
    describe("LMAO basic: " + description, function(){

        let accounts;
        let admin;
        let reward, buyWith;
        let lmOptionToken;
        let lmOptionNFT;

        before(async function() {
            await resetToBlock(blockNo);
            await impersonate([buyWithWhale]);
            await impersonate([rewardWhale]);
            accounts = await web3.eth.getAccounts();
            admin = accounts[1];
            user = accounts[2];
            treasury = accounts[3];

            reward = await IERC20.at(rewardAddr);
            buyWith = await IERC20.at(buyWithAddr);

            lmOptionToken = await LMOptionsToken.new(
                reward.address,
                buyWith.address,
                treasury,
                86400 * 30, // 1 month expiry
                10000, // 100% market price
                "OLM_DAI_WITH_USDC",
                "OLM_DAI_WITH_USDC",
                {from: admin}
            );

            lmOptionNFT = await LMOptions.at(await lmOptionToken.optionContract());
            
            console.log("option token: ", lmOptionToken.address);
            console.log("option NFT: ", lmOptionNFT.address);

            await reward.transfer(admin, rewardTotalBalance, {from: rewardWhale});
            await buyWith.transfer(user, buyWithTotalBalance, {from: buyWithWhale});
        });

        
        describe("Options Liquidity Mining", function() {
            it("Happy path", async function() {
                console.log("Admin mints option ERC20");
                assert.equal(await lmOptionToken.balanceOf(admin), "0");
                await reward.approve(lmOptionToken.address, rewardTotalBalance, {from: admin});
                await lmOptionToken.mintOptionToken(rewardTotalBalance, {from: admin});                
                assert.equal(await lmOptionToken.balanceOf(admin), rewardTotalBalance);

                console.log("Admin transfers option ERC20 to user");
                await lmOptionToken.transfer(user, rewardTotalBalance, {from: admin});


                console.log("User burns option ERC20 to create an option NFT");
                // await lmOptionToken.approve(lmOptionNFT.address, rewardTotalBalance, {from: user});
                await lmOptionToken.mintOption(rewardTotalBalance, {from: user});

                console.log("User executes the option NFT");
                await buyWith.approve(lmOptionNFT.address, buyWithTotalBalance, {from: user}); // we assume the amount we approve is enough to redeem the option
                await lmOptionNFT.redeem(0, {from: user}); // this is the very first one, so the id is 0. 
            });
        });
    });
}

let usdc = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
let dai = "0x6B175474E89094C44Da98b954EedeAC495271d0F";

// 0xe78388b4ce79068e89bf8aa7f218ef6b9ab0e9d0 is being tagged as Avalanche bridge
// on etherscan, it is an EOA so we could use it to obtain dai, usdc, weth, usdt, wbtc, and more.
let daiWhale = "0xe78388b4ce79068e89bf8aa7f218ef6b9ab0e9d0";
let usdcWhale = "0xe78388b4ce79068e89bf8aa7f218ef6b9ab0e9d0";

olmBasicTest(
    "buy USDC with DAI", 
    usdc, usdcWhale, "1000" + "0".repeat(6),
    dai, daiWhale, "1100" + "0".repeat(18),
    13292680
);
