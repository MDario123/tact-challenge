import "@stdlib/deploy";

message AdminWithdrawalProfit {
  queryId: Int as uint64;
}

message AdminWithdrawalAllNFTs {
  queryId: Int as uint64;
}

message AdminFetchProfit {
  queryId: Int as uint64;
}

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

message(0x3fcc3e14) KeepWithdrawing {  
  queryId: Int as uint64;
}

contract Task5 with Deployable {
  seed: Int as uint128;
  owner: Address;
  myNFTs: map<Int as uint16, Address>;
  NFTamount: Int as uint16;
  
  init(seed: Int, owner: Address) {
    self.owner = owner;
    self.seed = seed; // needed to deploy multiple smart contracts copies from one admin address
    self.myNFTs = emptyMap();
    self.NFTamount = 0;
  }

  receive(msg: OwnershipAssigned) {
    if( msg.prevOwner == self.owner ) {
      self.myNFTs.set(self.NFTamount, sender());
      self.NFTamount = self.NFTamount + 1;
      send(SendParameters{
        to: msg.prevOwner,
        value: 0, 
        mode: 64, 
        bounce: true
      });
    } else {
    }
  }

  receive(msg: AdminWithdrawalProfit) {
    require(sender() == self.owner, "Insufficient privelegies");
    nativeReserve(ton("0.1"), 0);
    
    send(SendParameters{
      to: sender(),
      value: 0, 
      mode: 128, 
      bounce: true, 
      body: AdminFetchProfit {
        queryId: msg.queryId
      }.toCell()
    });
  }

  receive(msg: AdminWithdrawalAllNFTs) {
    require(context().value >= (ton("1.0") + self.NFTamount * ton("0.08")), "Insufficent funds");
    require(sender() == self.owner, "Invalid sender");
  }

  receive(msg: KeepWithdrawing) {
    require(sender() == myAddress(), "Invalid sender");
  }

  get fun profit(): Int { 
    return myBalance() - ton("0.1");
  }
  
  get fun nfts(): map<Int as uint16, Address> { 
    return self.myNFTs;
  }
}
