# A reference implementation for secure content NFT development.

Core Developers| Blockchain Infrastructure
:-------------------------:|:-------------------------:
<img src="https://github.com/sanpo-blockchain/logo/blob/main/sanpo-square-logo.png" height="30"> Technical Committee | <img src="https://github.com/sanpo-blockchain/logo/blob/main/sanpo-logo.png" height="30">

- Smart contract for content distribution that supports copyright protection
  - Based on the ERC721, with drastic enhancements
  - In addition to the media identifier saved in ERC721, contract information and product information are saved in text format.
  - Implemented the concept of specification. Specifications mean copyright information.
  - Mint multiple NFTs with serial numbers based on specifications

___

## Overview
Major smart contracts used for NFT distribution are described below.

<img src="https://github.com/Japan-Contents-Blockchain-Initiative/content-nft-ethereum/blob/main/outline.png" height="300">

| contract name | discription |
----|----
| DigitalContentSpec | Specification of NFT |
| DigitalContentObject | NFT based on Specifications  |
| ERC20Token | Utility Token to trade NFT |

### DigitalContentSpec
#### struct and strage
    string name;                 // content name
    string symbol;               // content symbol
    uint256 contentType;         // content type
    string mediaId;              // media file id
    uint256 totalSupplyLimit;    // object's total supply (0 = no limit)
    string info;                 // additional information by content
    uint256[] originalSpecIds;   // when this spec is based on the other spec(copy right)
    string[] contractDocuments;  // contract documents: URI or text
    uint256[] copyrightFeeRatio; // copyright fee ratio of each spec
    bool allowSecondaryMerket;   // permission of secondary market sale

    mapping (uint256 => address) private _specOwner;              // Mapping from specId to Onwer
    mapping (address => mapping(uint256 => uint256)) _ownedSpecs; // Owner's all specification
    mapping (address => uint256) private _ownedSpecsCount;        // Number of specification of each owners
    mapping (address => uint256) private _ownedSpecsAccumulation; // Considering copyRighttransfer
    mapping (uint256 => address[]) private _pastSpecOwners;       // Past owners of each specification

#### functions
| major function | discription |
----|----
| design | Create a new specification |
| updateSecondaryMarketPermission | ALLOW or NOT ALLOW to sell NFT in seconary markets |
| copyrightTransfer | Change the specification owner |
| getDigitalContentSpec | Get infomation of a specification |
| totalSupplyLimitOf | Maximam number of allowable nft minting |
| specOwnerOf| Owner of a specification |

### DigitalContentObject
#### struct and strage
    uint256 specId; // content spec id
    string mediaId; // media file id
    string info;    // content's additional information

    DigitalContentObject[] private digitalContentObjects;   // All object list (this index is objectId)
    mapping (uint256 => address) private _objectOwner;      // Mapping from object ID to owner
    mapping (uint256 => address) private _objectApprovals;  // Mapping from object ID to approved address
    mapping(address => uint256[]) private _ownedObjects;    // Mapping from owner to list of owned object IDs
    mapping (address => uint256) private _ownedObjectsCount;// Mapping from owner to number of owned objec
    mapping(uint256 => uint256[]) private mintedObjects;    // Mapping from spec ID to index of the minted objects list
    mapping(uint256 => uint256) private mintedObjectsIndex; // Mapping from object id to position in the minted objects array
    uint256[] private _allObjects;                          // Array with all object ids, used for enumeration

#### functions
| major function | discription |
----|----
| mint | Create a new NFT |
| setMediaId | Update a Media information like URI |
| setInfo | Update information of a NFT |
| getDigitalContentObject | Get infomation of a NFT |
| specIdOf | Get the speficication ID of a NFT |
| objectMediaIdOf | Get the media ID of a NFT  |
| totalSupplyOf | Total supply number of the specification that a NFT belongs to |
| transfer | Change the owner of a NFT |
| transferFrom | Change the owner by allowed account |
| approve | Allow a account to change owner |
| ownedObjectsOf | Gets list of the owned object ID |
| getNumberOfObjects | Get the number of objects |


### ERC20Token
Same smart contract as popular ERC20 Token.

___

## License
Content NFT Ethereum is released under the MIT License.
