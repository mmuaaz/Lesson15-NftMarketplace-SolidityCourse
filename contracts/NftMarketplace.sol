// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // the security check to avoid Re-entrancy attack
//=== any function we are skeptical that they could be vulnerable then we add this SC's modifier "nonReentrant"

// ERRORS

error NftMarketplace__PriceMustBeAboveZero();
error NftMarketplace__NotApprovedForMarketplace();
error NftMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
error NftMarketplace__NotOwner();
error NftMarketplace__NotListed(address nftAddress, uint256 tokenId);
error NftMarketplace__PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error NftMarketplace__NoProceeds();
error NftMarketplace__TransferFailed();

contract NftMarketplace is ReentrancyGuard {
    struct Listing {
        uint256 price;
        address seller;
    }
    // EVENTS

    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    ); // Challenge: Have this SC accept payment in a subset of tokens as well
    // HInt: Use the ChainLink Price Feeds to convert the price of the token between each other
    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );
    event ItemCanceled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);

    //NFT COntract ADdress -> NFT TOkenID -> Listings
    mapping(address => mapping(uint256 => Listing)) private s_listings;
    // Keeping track of how much people have earned by selling NFTs
    // Seller Address -> Amount earned
    mapping(address => uint256) private s_proceeds;

    // MODIFIERS
    // creating this so that we may check if the listing is not already there
    modifier notListed(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert NftMarketplace__AlreadyListed(nftAddress, tokenId);
        }
        _;
    }
    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NftMarketplace__NotOwner();
        }
        _;
    }
    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert NftMarketplace__NotListed(nftAddress, tokenId);
        }
        _;
    }

    //     Create a decentralized NFT Marketplace

    /**
     * @notice Method for listing your NFT on the marketplace
     * @param nftAddress: Address of the NFT
     * @param tokenId: The token ID of the NFT
     * @param price: sale price of the listed NFT
     * @dev Muhammad Muaaz learning with Solidity course: Patrick Collins
     */
    //         i. `ListItem` function
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external notListed(nftAddress, tokenId, msg.sender) isOwner(nftAddress, tokenId, msg.sender) {
        if (price <= 0) {
            revert NftMarketplace__PriceMustBeAboveZero();
        }
        // -------Listing of the item can be done by 1 of two ways: i. send the NFT to the SC => Requires a transfer, and SC hold the NFT => gas expensive
        //  We can have the owner of the NFT be the marketplace, the issue is that the marketplace will then own the NFT and the user wont be able to
        // ii. Owners can still hold their NFTs, and give the marketplace approval to sell it for them,  // we will use this method
        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NftMarketplace__NotApprovedForMarketplace();
        }
        // ------------- NOw we need to keep track of the listed NFTs for selling and buying purposes; we could do ARRAY or MAPPING
        //  I think we should do mapping
        s_listings[nftAddress][tokenId] = Listing(price, msg.sender); // s_listings of the "nftAddress", at the "tokenId" equal to we are gonna create a listing
        //of the price and the guy who is selling(seller offcourse)
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    //         ii. `BuyItem` function
    function buyItem(address nftAddress, uint256 tokenId)
        external
        payable
        nonReentrant
        isListed(nftAddress, tokenId)
    {
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        if (msg.value < listedItem.price) {
            revert NftMarketplace__PriceNotMet(nftAddress, tokenId, listedItem.price);
        }
        // ----------when they send the money, it needs to belong to the owner of the NFT that is selling it
        //----------- for this reason, we need to keep track of how much these sellers, and buyers: => create another data structure "proceeds"
        s_proceeds[listedItem.seller] = s_proceeds[listedItem.seller] + msg.value; // updating the procees of the seller that he has sold the NFT and earned the money
        //-----in order to buy an item,the SC should be able to delete the listings from the mapping
        delete (s_listings[nftAddress][tokenId]);
        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        // check to make sure the NFT was transferred
        //safeTransferFrom function vs transferFrom: Refer to "NftMarketPlaceGuide"
        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
    }

    //         iii. `cancelItem`: Cancels the listing if you dont want to sell anymore

    function cancelListing(address nftAddress, uint256 tokenId)
        external
        isOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId)
    {
        delete (s_listings[nftAddress][tokenId]);
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }

    //         iv. `updateListing`: Update the price

    function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isListed(nftAddress, tokenId)
        /**nonReentrant*/
        isOwner(nftAddress, tokenId, msg.sender)
    {
        //We should check the value of `newPrice` and revert if it's below zero (like we also check in `listItem()`)
        // if (newPrice <= 0) {
        //     revert PriceMustBeAboveZero();
        // }
        s_listings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
    }

    //         v. `withdrawProceeds`: Withdraw payment for my Sold NFTs

    function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[msg.sender];
        if (proceeds <= 0) {
            revert NftMarketplace__NoProceeds();
        }
        s_proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        // require(success, "Transfer failed");
        if (!success) {
            revert NftMarketplace__TransferFailed();
        }
    }

    /////////////////////

    // Getter Functions //
    /////////////////////

    function getListing(address nftAddress, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return s_listings[nftAddress][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }
}
