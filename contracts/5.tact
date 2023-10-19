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
    }
  }

  receive(msg: AdminWithdrawalProfit) {
    require(sender() == self.owner, "Insufficient privelegies");
    nativeReserve(ton("0.1"), 0);
    send(SendParameters{
      to: sender(),
      value: 0, 
      mode: SendRemainingBalance, 
      bounce: true, 
      body: AdminFetchProfit {
        queryId: 0
      }.toCell()
    });
  }

  receive(msg: AdminWithdrawalAllNFTs) {
    require(context().value >= (ton("1.0") + self.NFTamount * ton("0.8")), "Insufficent funds");
    require(sender() == self.owner, "Invalid sender");

    let amount: Int = self.NFTamount;
    while (amount != 0) {
      amount = amount - 1;
      send(SendParameters{
        to: self.myNFTs.get(amount)!!,
        value: ton("0.7"), 
        mode: 0, 
        bounce: false, 
        body: Transfer {
          queryId: 0,           
          newOwner: sender(),
          responseDestination: sender(),
          customPayload: null, 
          forwardAmount: 0,
          forwardPayload: emptySlice() 
        }.toCell()
      });
    }
    self.myNFTs = emptyMap();
    self.NFTamount = 0;
  }

  get fun profit(): Int { 
    return myBalance() - ton("0.1");
  }
  
  get fun nfts(): map<Int as uint16, Address> { 
    return self.myNFTs;
  }
}
