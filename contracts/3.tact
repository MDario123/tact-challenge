import "@stdlib/deploy";

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

// To simplify the testing process and the specificity of the messages being sent, we decided to add clear default values in this transaction
message(0xf8a7ea5) TokenTransfer {
     queryId: Int as uint64; // should be 0
     amount: Int as coins; // should be amount of jettons to send
     destination: Address; // should be user address / TokenNotification.from
     responseDestination: Address?; // should be myAddress()
     customPayload: Cell?; // should be null
     forwardTonAmount: Int as coins; // should be ton("0.01")
     forwardPayload: Slice as remaining; // should be emptySlice()
}

contract Task3 with Deployable {
  owner: Address;
  aAmount: Int;
  bAmount: Int;
  jettonAddressA: Address;
  jettonAddressB: Address;
  decimal: Int;

  init(admin: Address, newJettonAddressA: Address, newJettonAddressB: Address) {
    self.owner = admin;
    self.jettonAddressA = newJettonAddressA;
    self.jettonAddressB = newJettonAddressB;
    self.aAmount = 0;
    self.bAmount = 0;
    self.decimal = 1000000000;
  }

  receive(msg: TokenNotification) {
    require((sender() == self.jettonAddressA) || (sender() == self.jettonAddressB), "unknown sender address");

    if (msg.from == self.owner) {
      if (sender() == self.jettonAddressA) {
        self.aAmount = self.aAmount + msg.amount;
      } else {
        self.bAmount = self.bAmount + msg.amount;
      }
    } else {
      if (sender() == self.jettonAddressA) {
        let want: Int = (self.bAmount * self.decimal / self.aAmount) * msg.amount / self.decimal;
        if (self.bAmount < want) {
          send(SendParameters{
            to: sender(),
            value: 0, 
            mode: 64, 
            bounce: true, 
            body: TokenTransfer {
              queryId: 0,
              amount: msg.amount,
              destination: msg.from,
              responseDestination: myAddress(),
              customPayload: null,
              forwardTonAmount: ton("0.01"),
              forwardPayload: emptySlice()
            }.toCell()
          });
        } else {
          self.aAmount = self.aAmount + msg.amount;
          self.bAmount = self.bAmount - want;

          send(SendParameters{
            to: self.jettonAddressB,
            value: 0, 
            mode: 64, 
            bounce: true, 
            body: TokenTransfer {
              queryId: 0,
              amount: want,
              destination: msg.from,
              responseDestination: myAddress(),
              customPayload: null,
              forwardTonAmount: ton("0.01"),
              forwardPayload: emptySlice()
            }.toCell()
          });
        }
      } else {
        let want: Int = (self.aAmount * self.decimal / self.bAmount) * msg.amount / self.decimal;
        if (self.aAmount < want) {
          send(SendParameters{
            to: sender(),
            value: 0, 
            mode: 64, 
            bounce: true, 
            body: TokenTransfer {
              queryId: 0,
              amount: msg.amount,
              destination: msg.from,
              responseDestination: myAddress(),
              customPayload: null,
              forwardTonAmount: ton("0.01"),
              forwardPayload: emptySlice()
            }.toCell()
          });
        } else {
          self.bAmount = self.bAmount + msg.amount;
          self.aAmount = self.aAmount - want;

          send(SendParameters{
            to: self.jettonAddressA,
            value: 0, 
            mode: 64, 
            bounce: true, 
            body: TokenTransfer {
              queryId: 0,
              amount: want,
              destination: msg.from,
              responseDestination: myAddress(),
              customPayload: null,
              forwardTonAmount: ton("0.01"),
              forwardPayload: emptySlice()
            }.toCell()
          });
        }
      }
    }
  } 
  
  get fun price(jetton: Address): Int { 
    if (jetton != self.jettonAddressA) {
      return (self.aAmount * self.decimal / self.bAmount);
    }
    return (self.bAmount * self.decimal / self.aAmount);
  }
  
  get fun balance(jetton: Address): Int { 
    if (jetton == self.jettonAddressA) {
      return self.aAmount;
    } 
    return self.bAmount;
  }
}
