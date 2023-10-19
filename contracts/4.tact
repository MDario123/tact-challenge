import "@stdlib/deploy";

message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining; 
}

message(0x5fcc3d14) Transfer { 
    queryId: Int as uint64;            
    newOwner: Address; 
    responseDestination: Address; 
    customPayload: Cell?; 
    forwardAmount: Int as coins;
    forwardPayload: Slice as remaining; 
}

message NftWithdrawal {
  queryId: Int as uint64;
  nftAddress: Address;
}

contract Task4 with Deployable {
  //seed: Int as uint128;
  timeEnd: Int as uint32;
  nftAddress: Address?;
  ownerAddress: Address?;
  rem: Slice as remaining;
  
  init(seed: Int) {
    //self.seed = seed; // needed to deploy multiple smart contracts copies from one admin address
    self.timeEnd = 0;
    self.nftAddress = null;
    self.ownerAddress = null;
    self.rem = emptySlice();
  }

  receive(msg: OwnershipAssigned) {
    if (self.timeEnd != 0) {
      send(SendParameters{
        to: sender(),
        value: 0, 
        mode: SendRemainingValue + SendIgnoreErrors, 
        bounce: true, 
        body: Transfer {
          queryId: msg.queryId,           
          newOwner: msg.prevOwner,
          responseDestination: msg.prevOwner,
          customPayload: null, 
          forwardAmount: 0,
          forwardPayload: emptySlice() 
        }.toCell()
      });
    } else {
      self.timeEnd = msg.forwardPayload.loadUint(32) + now();
      self.nftAddress = sender();
      self.ownerAddress = msg.prevOwner;
    }
  }

  receive(msg: NftWithdrawal) {
    require(sender() == self.ownerAddress, "Invalid sender");

    if (now() < self.timeEnd) {
      self.reply("NFT is still locked".asComment());
    } else {
      
      send(SendParameters{
        to: msg.nftAddress,
        value: 0, 
        mode: SendRemainingValue + SendIgnoreErrors, 
        bounce: true, 
        body: Transfer {
          queryId: msg.queryId,           
          newOwner: sender(),
          responseDestination: sender(),
          customPayload: null, 
          forwardAmount: 0,
          forwardPayload: emptySlice() 
        }.toCell()
      });
      
      self.timeEnd = 0;
      self.nftAddress = null;
      self.ownerAddress = null;

    }
  }

  get fun time(): Int {
    return max(self.timeEnd - now(), 0);
  }

  get fun nft(): Address? {
    return self.nftAddress;
  }

  get fun owner(): Address? {
    return self.ownerAddress;
  }
}
