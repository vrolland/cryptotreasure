# CryptoTreasures

## Features

- Add a cryptoTreasure type [ADMIN]
- Add several cryptoTreasure types [ADMIN]

- Mint a cryptotreasure from an id
- Mint a cryptotreasure from a type
- Mint several cryptotreasures from a type [ADMIN]
- Store tokens into a cryptotreasure
- Withdraw tokens from a cryptotreasure
- Transfer tokens from a cryptotreasure to another
- Destroy a cryptotreasure
- Restrict Store to the owner and approved
- Lock a cryptotreasure for a time

### Erc721 related features

- Approve another user to perform any action on a cryptoTreasure
- Approve another user to perform any action on all user's cryptoTreasures
- Transfer a cryptoTreasure
- Update TokenURI [ADMIN]

### AccessControl related features

- Add an admin [ADMIN]
- revoke an admin [ADMIN]
- renounce to be admin [ADMIN]

## Detailed features

### Add a cryptoTreasure type

Type: - type `id` - `from`: first tokenId allowed - `to`: last tokenid allowed - `_lockedDestructionDuration`: destroy not allowed for a time after mint - `_mintStartTimestamp`: mint not allowed before a specific date (except for admins) - `numberToReserved`: number of token reserved for admins - `ERC20ToLock address`: erc20 token to lock to mint a box - `ERC20ToLock amount`: erc20 amount to lock to mint a box

Conditions: - only admins

Caveats: - overlap possible between types

### Add several cryptoTreasure types

same.

### Mint a cryptotreasure from an id

Mint a cryptotreasure `to` an address from a `tokenId` - `typeId`: the type id - `_storeRestrictedToOwnerAndApproval`: store is allowed to other or not - lock erc20 token if required by the type of the box

Conditions: - type exists - tokenId match the type range (from <= tokenId <= to) - token not minted yet - mint allowed already started (or admin) - token not reserved (or admin) - allowance of erc20 token to lock

### Mint a cryptotreasure from a type

Mint a cryptotreasure `to` an address from a `typeId` - `_storeRestrictedToOwnerAndApproval`: store is allowed to other or not - lock erc20 token if required by the type

Conditions: - type exists - mint allowed already started (or admin) - not reserved token still available (or admin) - allowance of erc20 token to lock

### Mint several cryptotreasures from a type [ADMIN]

same.

### Store tokens into a cryptotreasure

Store an unlimited number of ETH, ERC20s, ERC721s, ERC1155s into a cryptotreasure

Conditions: - cryptoTreasure exists - cryptoTreasure not destroyed - cryptoTreasure not locked - store allowed (restriction?) - tokens allowance

### Withdraw tokens from a cryptotreasure

Withdraw tokens (ETH, ERC20s, ERC721s, ERC1155s) previously stored into a cryptotreasure to an address

Conditions: - cryptoTreasure exists - cryptoTreasure not locked - withdraw allowed for user (owner or approved) - Tokens owned by the cryptoTreasure

### Transfer tokens from a cryptotreasure to another

Transfer tokens (ETH, ERC20s, ERC721s, ERC1155s) previously stored into a cryptotreasure to another box

Conditions: - Both cryptoTreasures exist - Both cryptoTreasures not locked - withdraw allowed for user (owner or approved) - destination cryptoTreasure not destroyed - store allowed (restriction?) - Tokens owned by the source cryptoTreasure

### Destroy a cryptotreasure

Destroy (optionally withdraw to an address in the same time) a cryptotreasure - Send to the owner the token locked during the minting

Conditions: - cryptoTreasure exists - cryptoTreasure not locked - cryptoTreasure not destroyed - destroy allowed for user (owner or approved) - Destruction lock period over - withdraw allowed for user (owner or approved) - withdraw tokens owned by the cryptoTreasure

### Restrict Store to the owner and approved

Change restriction of the storing (owner and approved OR everyone)

Conditions: - cryptoTreasure exists - cryptoTreasure not locked - allowed user (owner or approved)

### Lock a cryptotreasure for a time

Prevent any "box actions" on a cryptotreasure for a time. (TransferFrom still possible)

Conditions: - cryptoTreasure exists - cryptoTreasure not locked - allowed user (owner or approved)
