truffle console --network testnet


migrate --reset


const deployedContractInstance = await OrderBook.deployed()


await deployedContractInstance.LoadSwapNetwork("0x61172b53423e205a399640e5283e51fe60ec2256")


const path = await deployedContractInstance.getSovrynConversionPath("0x849D38abD3962cb40d4887E4279ad0e4E5958e34","0x69FE5cEC81D5eF92600c1A0dB1F11986AB3758Ab")


const sovrynrate = await deployedContractInstance.getRateBetwenTokens("0x849D38abD3962cb40d4887E4279ad0e4E5958e34","0x69FE5cEC81D5eF92600c1A0dB1F11986AB3758Ab",5000000000)


const tokensGot = await deployedContractInstance.swapTokens("0x849D38abD3962cb40d4887E4279ad0e4E5958e34","0x69FE5cEC81D5eF92600c1A0dB1F11986AB3758Ab",5000000000, 1)



sovrynrate.toNumber()

int(rate, 16)


deployedContractInstance.dc


DoC (Dollar on Chain)
Token Contract Address: 0xCb46C0DdC60d18eFEB0e586c17AF6Ea36452DaE0
Token Symbol: DOC
Decimals: 18

WRBTC
Token Contract Address: 0x69fE5cEc81D5eF92600c1a0dB1f11986aB3758ab
Token Symbol: WRBTC
Decimals: 18



    ERC20(0x849D38abD3962cb40d4887E4279ad0e4E5958e34), //https://explorer.testnet.rsk.co/address/0x849d38abd3962cb40d4887e4279ad0e4e5958e34

            ERC20(0x69FE5cEC81D5eF92600c1A0dB1F11986AB3758Ab)); //https://explorer.testnet.rsk.co/address/0x69fe5cec81d5ef92600c1a0db1f11986ab3758ab

    }


undefined
truffle(testnet)> undefined
truffle(testnet)> deployedContractInstance.getA()
[ '0xCB46c0ddc60D18eFEB0E586C17Af6ea36452Dae0',
  '0x3A6239854FF3e4Ebf9a0AAD7E2FadEc8dCC33aa9',
  '0x69FE5cEC81D5eF92600c1A0dB1F11986AB3758Ab' ]
truffle(testnet)> 
