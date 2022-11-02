require("dotenv").config();

const Web3 = require('web3')
const { Token } = require("@uniswap/sdk")
const IUniswapV3Router02 = require('@uniswap/v3-periphery/artifacts/contracts/interfaces/ISwapRouter.sol/ISwapRouter.json')
const IUniswapV3Factory = require("@uniswap/v3-core/artifacts/contracts/interfaces/IUniswapV3Factory.sol/IUniswapV3Factory.json")
const IUniswapV2Router02 = require('@uniswap/v2-periphery/build/IUniswapV2Router02.json')
const IUniswapV2Factory = require("@uniswap/v2-core/build/IUniswapV2Factory.json")
const IERC20 = require('@openzeppelin/contracts/build/contracts/ERC20.json')

// -- SETUP NETWORK & WEB3 -- //

const chainId = 1
const web3 = new Web3('http://127.0.0.1:7545')

// -- IMPORT HELPER FUNCTIONS -- //

const { getUPairContract, getSPairContract, calculateUPrice, calculateSPrice, getPoolImmutables, getPoolState } = require('../helpers/helpers')

// -- IMPORT & SETUP UNISWAP/SUSHISWAP CONTRACTS -- //

const config = require('../config.json')
const uFactory = new web3.eth.Contract(IUniswapV3Factory.abi, config.UNISWAP.FACTORY_ADDRESS) // UNISWAP FACTORY CONTRACT
const sFactory = new web3.eth.Contract(IUniswapV2Factory.abi, config.SUSHISWAP.FACTORY_ADDRESS) // SUSHISWAP FACTORY CONTRACT
const uRouter = new web3.eth.Contract(IUniswapV3Router02.abi, config.UNISWAP.V3_ROUTER_02_ADDRESS) // UNISWAP ROUTER CONTRACT
const sRouter = new web3.eth.Contract(IUniswapV2Router02.abi, config.SUSHISWAP.V2_ROUTER_02_ADDRESS) // UNISWAP ROUTER CONTRACT

// -- CONFIGURE VALUES HERE -- //
let exchange = 'Uniswap'
    console.log(exchange)

const V3_FACTORY_TO_USE = uFactory
    console.log("uFactory:", V3_FACTORY_TO_USE._address)
const V3_ROUTER_TO_USE = uRouter
    console.log("uRouter:", V3_ROUTER_TO_USE._address)
const V2_FACTORY_TO_USE = sFactory
    console.log("sFactory:", V2_FACTORY_TO_USE._address)
const V2_ROUTER_TO_USE = sRouter
    console.log("sRouter:", V2_ROUTER_TO_USE._address)

const UNLOCKED_ACCOUNT = '0x218b95be3ed99141b0144dba6ce88807c4ad7c09' // SHIB Unlocked Account
    console.log("Account holding ERC20:", UNLOCKED_ACCOUNT)
const ERC20_ADDRESS = process.env.ARB_AGAINST
const WETH_ADDRESS = process.env.ARB_FOR
const AMOUNT = '10' // 40,500,000,000,000 SHIB -- Tokens will automatically be converted to wei
const GAS = 450000

// -- SETUP ERC20 CONTRACT & TOKEN -- //

const ERC20_CONTRACT = new web3.eth.Contract(IERC20.abi, ERC20_ADDRESS)
    console.log("ERC20:", ERC20_CONTRACT._address, ERC20_ADDRESS)
const WETH_CONTRACT = new web3.eth.Contract(IERC20.abi, WETH_ADDRESS)
    console.log("WETH:", WETH_CONTRACT._address, WETH_ADDRESS)

// -- MAIN SCRIPT -- //

const main = async () => {
    const accounts = await web3.eth.getAccounts()
    const account = accounts[1] // This will be the account to recieve WETH after we perform the swap to manipulate price
        console.log("WETH receiver:", account)
    const uPairContract = await getUPairContract(V3_FACTORY_TO_USE, ERC20_ADDRESS, WETH_ADDRESS, 3000)
    //ERRORING
        console.log('uPairContract:', uPairContract._address)
    const sPairContract = await getSPairContract(V2_FACTORY_TO_USE, ERC20_ADDRESS, WETH_ADDRESS)
        console.log('sPairContract:', sPairContract._address)
    
    const ERC20_TOKEN = new Token(
        chainId,
        ERC20_ADDRESS,
        18,
        await ERC20_CONTRACT.methods.symbol().call(),
        await ERC20_CONTRACT.methods.name().call()
    )
    
        console.log("ERC20:", ERC20_TOKEN.symbol)
        
    const WETH_TOKEN = new Token(
        chainId,
        WETH_ADDRESS,
        18,
        await WETH_CONTRACT.methods.symbol().call(),
        await WETH_CONTRACT.methods.name().call()
    )
    
        console.log("WETH:", WETH_TOKEN.symbol)

    // Fetch price of SHIB/WETH before we execute the swap
    const uPriceBefore = await calculateUPrice(V3_FACTORY_TO_USE, ERC20_ADDRESS, WETH_ADDRESS, 3000)
        console.log("Uniswap Price Before", uPriceBefore)
    const sPriceBefore = await calculateSPrice(sPairContract)
        console.log("SushiSwap Price Before", sPriceBefore)

    console.log("Dumping token")
    await manipulatePrice([ERC20_TOKEN, WETH_TOKEN], account)

    // Fetch price of SHIB/WETH after the swap
    const uPriceAfter = await calculateUPrice(V3_FACTORY_TO_USE, ERC20_ADDRESS, WETH_ADDRESS, 3000)
    console.log("Uniswap Price After", uPriceAfter)
    const sPriceAfter = await calculateSPrice(sPairContract)
    console.log("SushiSwap Price After", sPriceAfter)


    const data = {
        'Uniswap':'V3',
        'uPrice Before': `1 ${WETH_TOKEN.symbol} = ${Number(uPriceBefore).toFixed(2)} ${ERC20_TOKEN.symbol}`,
        'uPrice After': `1 ${WETH_TOKEN.symbol} = ${Number(uPriceAfter).toFixed(2)} ${ERC20_TOKEN.symbol}`,
        'Sushiswap':'V2',
        'sPrice Before': `1 ${WETH_TOKEN.symbol} = ${Number(sPriceBefore).toFixed(2)} ${ERC20_TOKEN.symbol}`,
        'sPrice After': `1 ${WETH_TOKEN.symbol} = ${Number(sPriceAfter).toFixed(2)} ${ERC20_TOKEN.symbol}`,
    }

    console.table(data)

    let WETHbalance = await WETH_CONTRACT.methods.balanceOf(account).call()
    WETHbalance = web3.utils.fromWei(WETHbalance.toString(), 'ether')

    let ERC20balance = await ERC20_CONTRACT.methods.balanceOf(UNLOCKED_ACCOUNT).call()
    ERC20balance = web3.utils.fromWei(ERC20balance.toString(), 'ether')

    console.log(`\nBalance in reciever account: ${WETHbalance} WETH\n`)
    console.log(`\nBalance in unlocked account: ${ERC20balance} ERC20\n`)
}

main()

// 

async function manipulatePrice(tokens, account) {
    console.log(`\nBeginning Swap...\n`)

    console.log(`Input Token: ${tokens[0].symbol}`)
    console.log(`Output Token: ${tokens[1].symbol}\n`)

    const amountIn = web3.utils.toWei(AMOUNT, 'gwei')
    console.log("Amount In:", amountIn)

    console.log("Swapping", web3.utils.toWei(AMOUNT, 'ether'), tokens[0].symbol, "using", exchange)

    if (exchange == 'Sushiswap') {
        const path = [tokens[0].address, tokens[1].address]
        console.log("Path:", path)
        const deadline = Math.floor((Date.now() / 1000) + 60 * 20) // 20 minutes
        
        const allowance = await ERC20_CONTRACT.methods.allowance(UNLOCKED_ACCOUNT, V2_ROUTER_TO_USE._address).call()
        console.log("Allowance:", allowance)
      
        if (allowance < amountIn) {
            console.log("Approving Router", V2_ROUTER_TO_USE._address, "to use", amountIn, "token.")
            const approval = await ERC20_CONTRACT.methods.approve(V2_ROUTER_TO_USE._address, web3.utils.toWei(AMOUNT, 'ether')).send({from: UNLOCKED_ACCOUNT, gas: GAS })
            console.log("Approved")
        }
        
        console.log("Swapping....", amountIn, 0, path, UNLOCKED_ACCOUNT, deadline)
        console.log(V2_ROUTER_TO_USE.methods)
        const nonce = await web3.eth.getTransactionCount(UNLOCKED_ACCOUNT)
        console.log(nonce)
        const tx = await V2_ROUTER_TO_USE.methods.swapExactTokensForTokens(allowance, 0, path, UNLOCKED_ACCOUNT, deadline)
        receipt = await tx.send({ 
            from: UNLOCKED_ACCOUNT,
            to: V2_ROUTER_TO_USE._address,
            nonce: nonce,
            gas: GAS,
            gasPrice: 50000000000,
            value: 0,
            chainId: 1,
            type: '0x1'
        })
        .on('error', function(error) { // If the transaction was rejected by the network with a receipt, the second parameter will be the receipt.
            console.log(error)
            console.log("SWAP FAILED!!!")
        });
        
        console.log(`Swap Complete!\n`)

        //return receipt
    } else {
        const ethBalance = await web3.eth.getBalance(UNLOCKED_ACCOUNT)
        console.log("Account has", web3.utils.fromWei(ethBalance, 'ether'), "ETH")
        const uPairContract = await getUPairContract(V3_FACTORY_TO_USE, ERC20_ADDRESS, WETH_ADDRESS, 3000)
        console.log("Pool address:", uPairContract._address)
        const immutables = await getPoolImmutables(uPairContract)
        console.log("Pool Immutables:", immutables)
   
        
        const state = await getPoolState(uPairContract)
        console.log("Pool State:", state)

       
        const params = {
            tokenIn: immutables.token0,
            tokenOut: immutables.token1,
            fee: immutables.fee.toString(),
            recipient: UNLOCKED_ACCOUNT,
            deadline: Math.floor(Date.now() / 1000) + (60 * 10).toString(),
            amountIn: amountIn.toString(),
            amountOutMinimum: '0',
            sqrtPriceLimitX96: '0'
          }

        console.log("Tx Params:", params)

        
        
        const allowance = await ERC20_CONTRACT.methods.allowance(UNLOCKED_ACCOUNT, V3_ROUTER_TO_USE._address).call()
        console.log("Allowance:", allowance)
      
        if (allowance < amountIn) {
            console.log("Approving Router to use token.")
            const approval = await ERC20_CONTRACT.methods.approve(V3_ROUTER_TO_USE._address, web3.utils.toWei(AMOUNT, 'ether')).send({from: UNLOCKED_ACCOUNT, gas: GAS })
            console.log("Approved")
        }
        
        try {
            console.log("Initiating swap...")
            const receipt = await V3_ROUTER_TO_USE.methods.exactInput(params).send({from: UNLOCKED_ACCOUNT, gas: GAS})
            
            console.log(`Swap Complete!\n`)
            console.log(receipt)
       
        } catch (error) {
        
            console.log(`Swap Failed!\n`)
            console.log(error)
        }
        

        
    }
}
