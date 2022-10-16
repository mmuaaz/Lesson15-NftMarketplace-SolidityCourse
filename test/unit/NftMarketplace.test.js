const { network, deployments, ethers, getNamedAccounts } = require("hardhat")
const { developmentChains } = require("../../helper-hardhat-config")
const { assert, expect } = require("chai")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Nft Marketplace Tests", () => {
          let nftMarketplace, basicNft, deployer, player
          const PRICE = ethers.utils.parseEther("0.1")
          const TOKEN_ID = 0
          beforeEach(async () => {
              deployer = (await getNamedAccounts()).deployer
              //   player = (await getNamedAccounts()).player
              const accounts = await ethers.getSigners()
              player = accounts[1] // after importing the player like that we now have to use "player.address" whenever we want to use player account
              await deployments.fixture(["all"])
              nftMarketplace = await ethers.getContract("NftMarketplace") // by default any SC is connected to deployer as it is at the zero index and
              //it defaults to connecting account zero; if we want to connect to "player" account then we do the following
              //   nftMarketplace = await ethers.connect("NftMarketplace", player)    or
              // nftMarketplace = await ethers.getContract("NftMarketplace", player) but Patrick said we should be explicit everytime so the above method is better
              basicNft = await ethers.getContract("BasicNft")
              await basicNft.mintNft() // deployer calling the mint function here because remember its by default connected to whatever account is at zero index
              await basicNft.approve(nftMarketplace.address, TOKEN_ID) // deployer calling the approve function
          })
          it("lists and can be bought", async () => {
              await nftMarketplace.listItem(basicNft.address, TOKEN_ID, PRICE) // listing NFT that has been minted by the deployer
              const playerConnectNftMarketplace = nftMarketplace.connect(player) //connecting player with the SC
              await playerConnectNftMarketplace.buyItem(basicNft.address, TOKEN_ID, {
                  value: PRICE,
              }) // buying
              const newOwner = await basicNft.ownerOf(TOKEN_ID) // "ownerOF" is a function on ERC721 SC, that is imported in BasicNft.sol, and it inherits ERC721
              const deployerProceeds = await nftMarketplace.getProceeds(deployer)
              assert(newOwner.toString() == player.address) // player.address is the address of the player, we now need to explicitly do it like this
              assert(deployerProceeds.toString() == PRICE.toString())
          })
      })
