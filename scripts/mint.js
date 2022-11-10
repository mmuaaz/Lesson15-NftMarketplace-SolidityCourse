const { network } = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")

async function mint() {
    basicNft = await ethers.getContract("BasicNft")
    console.log("Minting NFT...")
    const mintTx = await basicNft.mintNft()
    const mintTxReceipt = await mintTx.wait(1)
    const tokenId = mintTxReceipt.events[0].args.tokenId
    console.log(`Got TokenID: ${tokenId}`)
    console.log(`Nft Address: ${basicNft.address}`)

    if (network.config.chainId == "31337") {
        await moveBlocks(2, (sleepAmount = 1000)) // await 1 second or 1000 miliseconds between each blocks
    }
}
mint()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
