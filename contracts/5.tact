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
    } else {
      if (context().value < ton("2.1")) {
        if (context().value >= context().readForwardFee()) {
          send( SendParameters{
            to: sender(),
            value: 0,
            mode: 66,
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
        }
      } else {
        nativeReserve(ton("2.0"), 4);
        let nft: Address = sender();
        if (self.NFTamount != 0) {
          let x: Int = random(0, self.NFTamount - 1);
          nft = self.myNFTs.get(x)!!;
          self.myNFTs.set(x, sender());
        }
        send( SendParameters{
          to: nft,
          value: 0,
          mode: 130,
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
      }
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

    send(SendParameters{
      to: myAddress(),
      value: 0,
      mode: 66,
      bounce: true,
      body: KeepWithdrawing {
        queryId: msg.queryId
      }.toCell()
    });
  }

  receive(msg: KeepWithdrawing) {
    require(sender() == myAddress(), "Invalid sender");

    let amount: Int = max(0, self.NFTamount - 253);
    repeat (self.NFTamount - amount) {
      send( SendParameters{
        to: self.myNFTs.get(amount),
        value: ton("0.07"),
        mode: 0,
        bounce: true,
        body: Transfer {
          queryId: msg.queryId,
          newOwner: self.owner,
          responseDestination: self.owner,
          customPayload: null,
          forwardAmount: 0,
          forwardPayload: emptySlice() 
        }.toCell()
      });
      self.myNFTs.set(amount, null);
      amount = amount + 1;
    }
    self.NFTamount = max(0, self.NFTamount - 253);
    if (self.NFTamount != 0) {
      send(SendParameters{
        to: myAddress(),
        value: 0,
        mode: 66,
        bounce: true,
        body: KeepWithdrawing {
          queryId: msg.queryId
        }.toCell()
      });
    }
  }

  get fun profit(): Int { 
    return myBalance() - ton("0.1");
  }
  
  get fun nfts(): map<Int as uint16, Address> { 
    return self.myNFTs;
  }
}
