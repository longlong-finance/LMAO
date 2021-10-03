# Liquidity Mining As Options with ERC20 token

The Liquidity Mining V2 contract that is mentioned in Andre's post (which credit also goes to podsfinance and JosephDelong) provides an interesting alternative for protocols to use. However, the PoC provided by Andre requires protocols to use a new staking contract and only designed for options liquidity mining. Naturally, this requires users to migrate to this new pool. 

Thus we built upon Andre's PoC, wrapping the option's reward amount in an ERC20. This allows protocols to drip the options token via the regular staking pools, be it the regular synthetix, masterChef, or other infrastructure that they already have (maybe Merkle tree?!). If the protocol has a modified staking pool that allows multiple reward tokens to be dripped, then their users would not need to migrate at all!

1. Protocol mints option ERC20 tokens with its reward token.
1. Protocol sends the option ERC20 token into the staking pool and start the distribution. Users start to accumulate.
1. User claims the option ERC20 token from the staking pool. 
1. User burns the option ERC20 token and mints an ERC721 token that represents the option.
1. User execute within expiry or let it expire.

Building is fun. LMAO.