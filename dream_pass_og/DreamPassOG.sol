// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DreamPassOG is ERC721Enumerable, Ownable {
    using Strings for uint256;

    enum SaleStatus {
        INACTIVE,
        PRE_SALE,
        PUBLIC_SALE
    }

    SaleStatus public currentStatus = SaleStatus.INACTIVE;

    string public baseURI =
        "https://cdn.jsdelivr.net/gh/Team-Sleepy/dream_pass_og_metadata@public/";

    string public constant baseExtension = ".json";
    uint256 public constant cost = 0.08 ether;
    uint256 public constant publicCost = 0.1 ether;

    address[] public whitelistedAddresses;

    mapping(address => uint256) public addressMintedBalance;

    event passMinted(address _to, uint256 _amount, string _remark);

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public

    function mintPreSale() public payable {
        require(currentStatus == SaleStatus.PRE_SALE, "Presale inactive");

        uint256 supply = totalSupply();
        uint256 mintAmount = 1;

        require(supply + mintAmount <= 50, "maxed");
        require(isWhitelisted(msg.sender), "no WL");

        uint256 ownerMintedCount = addressMintedBalance[msg.sender];

        require(ownerMintedCount < 1, "minted");
        require(msg.value >= cost * mintAmount, "not enuf eth");

        _safeMint(msg.sender, supply + 1);
        addressMintedBalance[msg.sender]++;
        emit passMinted(msg.sender, 1, "presale mint");
    }

    function mintPublicSale(uint256 _mintAmount) public payable {
        require(currentStatus == SaleStatus.PUBLIC_SALE, "Public INACTIVE");

        uint256 supply = totalSupply();

        require(_mintAmount > 0, "min=1");
        require(supply + _mintAmount <= 50, "maxed");
        require(msg.value >= publicCost * _mintAmount, "not enuf eth");

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

    function setStatus(SaleStatus newStatus) external onlyOwner {
        currentStatus = newStatus;
    }

    function devMint(uint256 _mintAmount) public onlyOwner {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(supply + _mintAmount <= 50, "max NFT limit exceeded");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
        emit passMinted(msg.sender, _mintAmount, "dev mint");
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function whitelistUsers(address[] calldata _users) external onlyOwner {
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
