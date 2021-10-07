# Liquidity Mining As Options with ERC20 token

The Liquidity Mining V2 contract that is mentioned in [Andre's post](https://andrecronje.medium.com/liquidity-mining-rewards-v2-50896e44f259) (which credit goes to [podsfinance](https://www.pods.finance) and Joseph Delong) provides an interesting alternative for protocols to use. However, the PoC provided by Andre requires protocols to use a new staking contract and only designed for options liquidity mining. Naturally, this requires users to migrate to this new pool if protocols already have such pools. 

Thus we built upon Andre's PoC, wrapping the option's reward amount in an ERC20. This allows protocols to drip the options token via the regular staking pools, be it the regular synthetix, masterChef, or other infrastructure that they already have (maybe Merkle tree?!). If the protocol has a modified staking pool that allows multiple reward tokens to be dripped, then their users would not need to migrate at all!

1. Protocol mints option ERC20 tokens with its reward token.
1. Protocol sends the option ERC20 token into the staking pool and start the distribution. Users start to accumulate.
1. User claims the option ERC20 token from the staking pool. 
1. User burns the option ERC20 token and mints an ERC721 token that represents the option.
1. User execute within expiry or let it expire.

Another thing we added, is a special support with Balancer's Oracle. Balancer's Oracle is not as generalized, it would restrict the buyToken and reward to be in the same pool. However, this is very suitable for protocols that are doing liquidity mining with BalancerV2! The supports comes with a separate set of contracts, both ends with `WithBal`. Please refer to the balancer tests for its usage. 

Feel free to reach out and chat for clarifications. Happy to discuss with fellow developers!

Building is fun. LMAO.

[LongLong.finance](https://longlong.finance)
