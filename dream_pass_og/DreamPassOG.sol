// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DreamPassOG is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // enum SaleStatus { INACTIVE, PRE_SALE, AFTER_PRE_SALE, PUBLIC_SALE, ENDED }

    string public baseURI;
    string public baseExtension = ".json";

    uint256 public cost = 0.08 ether;
    uint256 public maxSupply = 50;
    uint256 public nftPerAddressLimit = 1;

    bool public paused = true;
    bool public onlyWhitelisted = true;

    address[] public whitelistedAddresses;

    mapping(address => uint256) public addressMintedBalance;

    event passMinted(address _to, uint256 _amount, string _remark);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public

    function mintPreSale() public payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        uint256 mintAmount = 1;
        require(supply + mintAmount <= maxSupply, "max NFT limit exceeded");
        require(onlyWhitelisted, "Minting only available during pre-sale");
        require(isWhitelisted(msg.sender), "you must be whitelisted");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(
            ownerMintedCount < 1,
            "Max NFT per address minted during presale is 1!"
        );
        require(msg.value >= cost * mintAmount, "insufficient funds");
        _safeMint(msg.sender, supply + 1);
        addressMintedBalance[msg.sender]++;
        emit passMinted(msg.sender, 1, "pre-sale mint");
    }

    function mintPublicSale(uint256 _mintAmount) public payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        require(
            onlyWhitelisted == false,
            "Public minting only available after pre-sale"
        );

        require(msg.value >= cost * _mintAmount, "insufficient funds");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
        emit passMinted(msg.sender, _mintAmount, "public mint");
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return
            string(
                abi.encodePacked(
                    currentBaseURI,
                    tokenId.toString(),
                    baseExtension
                )
            );
    }

    //only owner

    function startPreSale() public onlyOwner {
        paused = false;
        onlyWhitelisted = true;
        cost = 0.08 ether;
    }

    function endPreSale() public onlyOwner {
        paused = true;
        onlyWhitelisted = false;
        cost = 0.1 ether;
    }

    function startPublicSale() public onlyOwner {
        paused = false;
        onlyWhitelisted = false;
        cost = 0.1 ether;
    }

    function endPublicSale() public onlyOwner {
        paused = true;
    }

    function devMint(uint256 _mintAmount) public onlyOwner {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
        emit passMinted(msg.sender, _mintAmount, "dev mint");
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    // function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    //     maxMintAmount = _newmaxMintAmount;
    // }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    // function pause(bool _state) public onlyOwner {
    //     paused = _state;
    // }

    // function setOnlyWhitelisted(bool _state) public onlyOwner {
    //     onlyWhitelisted = _state;
    // }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}