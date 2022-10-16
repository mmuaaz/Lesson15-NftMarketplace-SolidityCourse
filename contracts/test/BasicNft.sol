// SPDX-License-Identifier: MIT

// ------------------There are some changes in this SC versus the last time we wrote used SC in the last lesson

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

pragma solidity ^0.8.7;

contract BasicNft is ERC721 {
    string public constant TOKEN_URI =
        "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";
    uint256 private s_tokenCounter;

    event DogMinted(uint256 indexed tokenId);

    constructor() ERC721("Dogie", "DOG") {
        s_tokenCounter = 0;
    }

    function mintNft() public /*returns (uint256)*/
    {
        _safeMint(msg.sender, s_tokenCounter); //safeMint is the function on the openzappelin SC ERC721 which has 2 parameters; address to and tokenID
        emit DogMinted(s_tokenCounter); // Patrick said that we are emitting tokenId here, I dont know how but tokenCounter somehow is tokenId
        s_tokenCounter = s_tokenCounter + 1;

        // return s_tokenCounter;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return TOKEN_URI;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;

        //what is the ID of the token based off of this address
        //if you have a collection of tokens on the same SC each one of them takes a unique tokenID
    }
}
