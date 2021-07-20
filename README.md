
# Sovrython Decentralised-Order-Book #

POC of what a Decentralised Order Book could like, I tried to keep it as simple as possible to later build a robust UI on top of it, minimize surface of attack / bugs on solidity and to make it simple to quickly review and understand.
This is not meant as a production ready descentralized order book.

Initially I had a lot of the logic of matching orders, sorting written in solidity however after review I realized that that logic of matching orders implemenation can also be descentralized as long as you can get all the orders and interact with them.
This led to simplify the solidity code possibly for distributing implemenation of matching logic based on the order list.


## How to use with RSK testnet and truffle ##

Make sure you have SOV and WRBTC in testnet to run all the examples

truffle console --network testnet
in truffle: 

```
migrate

const deployedContractInstance = await OrderBook.deployed()

const SOVTokenERC20Address = "0x6a9A07972D07e58F0daf5122d11E069288A375fb";
const WRBTCERC20Address = "0x69FE5cEC81D5eF92600c1A0dB1F11986AB3758Ab";
const sovrynSwapAddress = "0x61172b53423e205a399640e5283e51fe60ec2256";


const swapNetwork = await deployedContractInstance.LoadSwapNetwork(sovrynSwapAddress);

const path = await deployedContractInstance.getSovrynConversionPath(SOVTokenERC20Address,WRBTCERC20Address);

const sovrynrate = await deployedContractInstance.getRateBetwenTokens(SOVTokenERC20Address,WRBTCERC20Address,50);

sovrynrate.toNumber() //once sovrynrate is defined


let orderId = await deployedContractInstance.makeOffer(1, SOVTokenERC20Address,1, WRBTCERC20Address);

deployedContractInstance.buy(orderId);

deployedContractInstance.cancel(orderId);


const sovrynSwapTokens = await deployedContractInstance.swapTokens(SOVTokenERC20,WRBTCERC20,10, 1);



```
