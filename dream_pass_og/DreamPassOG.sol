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
        "https://cdn.jsdelivr.net/gh/Team-Sleepy/dream_pass_og_metadata@live/";

    string public constant baseExtension = ".json";
    uint256 public constant cost = 0.08 ether;
    uint256 public constant publicCost = 0.1 ether;

    // lock WL at time of contract deployment
    address[] public whitelistedAddresses = [
        0x8694CE0e61cA9ec134b63A79630d329FB8A4e759,
        0xa0Fece1EdB991a49C6F2A50E6a52ed4084d7c333,
        0xb00A15dAD3b051dFBdbFcF3C96Ba82503b839Ba2,
        0x09D7a89f672fD47a17b234Fb3cF87984427b8270,
        0x29c047D56aBf5b8f0e967C0FEAd3635657483273,
        0x7b61A2C92DD964931C0c49C39cE616A81165A3dC,
        0xc9c96Aa20B0AA43cEaE7f7AA5118E6037a9Bd9DE,
        0x5732805E33c7D0d23ccCb776D009FC494A4693e5,
        0x703d1BC5A9f0d5B50B1bf4e36580990FA0f8FE8c,
        0xff8888562676dFbE4FB80Eb5beaA9C6BbDE9A4E4,
        0xFA9E14bAf401253e478Cb2378b911A76A535e697,
        0x611ebe9135Aa43AA46b648A98f4d71c57Ad113ea,
        0xc10aDFEE7ca7349a755E9e9A1D279b0eA06f35Ee,
        0xd076a5dbE634E6855D1d49177d3e35759Fd1F49C,
        0xEe23Cb998aa14874EE25A31Ea3416bF47557126b,
        0x6ECD4aDCfE44E2A4BdEb30b63294DaBA5220B0b1,
        0xeaEf7c7593E2185b6CbBFEf73B07e252340360BA,
        0x58954A8209C5758A0c23D00E5695A900877e38eE,
        0x2313C3f96abB45b48BC43C3B82DB571C920fD8A9,
        0x08957c8e1467ae0b0dE21a15F33038c40a62EbEb,
        0xFc5a92E6E7940E59abE1df9B2B50A2F0C350e549,
        0x3FAb5b1B86B9Ad627742Ab81153B771988572877,
        0x367dF0e660d1DB5df23231a27C6aFD31Fac265Fd,
        0x7E5735d1EfFad50fD1E5F554e17D7aaB4C750282,
        0x5F8B6Cd64AC97dda30B2371683a6a45c0086CEe2,
        0x3942Ae3782FbD658CC19A8Db602D937baF7CB57A,
        0x7e2f447bb8bD3A96a247711e2e0d09777c876e47
    ];

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

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}
