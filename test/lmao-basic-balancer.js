const LMOptionsWithBal = artifacts.require("LMAsOptionsWithBal");
const LMOptionsTokenWithBal = artifacts.require("LMAsOptionsTokenWithBal");
const IERC20 = artifacts.require("IERC20");

const { BN, time, expectRevert, constants, send } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');
const {resetToBlock, impersonate} = require("./helpers/blockchain-helpers.js");

/*
    Balancer Oracle only works when there's a direct pool.
    USDC - WETH BPT: 0x96646936b91d6b9d7d0c47c496afbf3d6ec7b6f8 exposes getTimeWeithedAverage
*/


function olmBasicTest(description, rewardAddr, rewardWhale, rewardTotalBalance, buyWithAddr, buyWithWhale, buyWithTotalBalance, bptOracleAddr, blockNo) {
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

            lmOptionToken = await LMOptionsTokenWithBal.new(
                reward.address,
                buyWith.address,
                treasury,
                86400 * 30, // 1 month expiry
                10000, // 100% market price
                bptOracleAddr,
                "OLM_DAI_WITH_USDC",
                "OLM_DAI_WITH_USDC",
                {from: admin}
            );

            lmOptionNFT = await LMOptionsWithBal.at(await lmOptionToken.optionContract());
            
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
let weth = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

// 0xe78388b4ce79068e89bf8aa7f218ef6b9ab0e9d0 is being tagged as Avalanche bridge
// on etherscan, it is an EOA so we could use it to obtain dai, usdc, weth, usdt, wbtc, and more.
let daiWhale = "0xe78388b4ce79068e89bf8aa7f218ef6b9ab0e9d0";
let usdcWhale = "0xe78388b4ce79068e89bf8aa7f218ef6b9ab0e9d0";
let wethWhale = "0xe78388b4ce79068e89bf8aa7f218ef6b9ab0e9d0";

let bptOracle_UsdcWETH = "0x96646936b91d6b9d7d0c47c496afbf3d6ec7b6f8"; // USDC-WETH

olmBasicTest(
    "buy WETH with DAI", 
    weth, wethWhale, "2" + "0".repeat(18),
    usdc, usdcWhale, "7001" + "0".repeat(6),
    bptOracle_UsdcWETH,
    13292680
);
