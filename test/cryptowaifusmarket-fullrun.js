require("babel-polyfill");
var CryptoWaifusMarket = artifacts.require("./CryptoWaifusMarket.sol");

contract("CryptoWaifusMarket-fullRun", function (accounts) {
  it("should have 100 waifus available to assign", function () {
    return CryptoWaifusMarket.deployed()
      .then(function (instance) {
        // console.log("Deployed");
        return instance.waifusRemainingToAssign.call();
      })
      .then(function (balance) {
        assert.equal(balance.valueOf(), 100, "100 waifus not available.");
      });
  }),
    it("should be able to complete the full buy and sell cycle", function () {
      var contract;
      var previousBalance;
      var waifusRemainingToAssign;
      var NULL_ACCOUNT = "0x0000000000000000000000000000000000000000";

      return CryptoWaifusMarket.deployed()
        .then(function (instance) {
          // console.log("Deployed");
          contract = instance;
          return instance.setInitialOwner(accounts[0], 0);
        })
        .then(function () {
          return contract.balanceOf.call(accounts[0]);
        })
        .then(function (result) {
          assert.equal(result.valueOf(), 1, "1 was not assigned to owner.");
          return contract.waifusRemainingToAssign.call();
        })
        .then(function (result) {
          assert.equal(result.valueOf(), 9999, "Incorrect remaining waifus.");
          // assign another punk to 0
          return contract.setInitialOwner(accounts[0], 1);
        })
        .then(function () {
          return contract.punkIndexToAddress(1);
        })
        .then(function (address) {
          assert.equal(accounts[0], address, "Making sure that 0 owns punk 1.");
          // assign a punk to 2
          return contract.setInitialOwner(accounts[2], 2);
        })
        .then(function () {
          return contract.allInitialOwnersAssigned();
        })
        .then(function () {
          // Try to transfer a punk from someone who doesn't own it
          return contract.transferWaifu(accounts[1], 1, { from: accounts[1] });
        })
        .then(function (returnValue) {
          assert(false, "Was supposed to throw but didn't.");
        })
        .catch(function (error) {
          if (error.toString().indexOf("invalid opcode") != -1) {
            // Expecting a throw here
            // console.log("We were expecting a Solidity throw (aka an invalid JUMP), we got one. Test succeeded.");
          } else {
            // if the error is something else (e.g., the assert from previous promise), then we fail the test
            assert(false, error.toString());
          }
        })
        .then(function () {
          // Give all remaining waifus to account 1
          console.log("Getting a bunch of waifus for account 1.");
          var promises = [];
          for (var i = 0; i < 100; i++) {
            promises.push(contract.getWaifu(1001 + i, { from: accounts[1] }));
          }

          Promise.all(promises)
            .then(function () {
              return contract.balanceOf.call(accounts[1]);
            })
            .then(function (result) {
              console.log("Account 1 now has " + result.valueOf() + " waifus.");
              assert.equal(
                result.valueOf(),
                100,
                "Should have 100 waifus in account 1 now."
              );
              return contract.offerWaifuForSale(1001, 100, {
                from: accounts[1],
              });
            })
            .then(function () {
              return contract.waifusOfferedForSale(1001);
            })
            .then(function (offer) {
              console.log("Offer for sale: " + offer);
              assert.isOk(offer[0], "Waifu was not actually for sale.");
              assert.equal(offer[3], 100, "Waifu sale price incorrect.");
              assert.equal(
                offer[4],
                NULL_ACCOUNT,
                "Waifu should be for sale to anyone."
              );
              // Get account 0 to buy a punk, but send too little ether and expect an exception
              return contract.buyWaifu(1001, { from: accounts[0], value: 1000 });
            })
            .then(function () {
              // console.log("Bought punk.");
              assert(false, "Was supposed to throw but didn't.");
            })
            .catch(function (error) {
              if (error.toString().indexOf("invalid opcode") != -1) {
                // Expecting a throw here
                // console.log("We were expecting a Solidity throw (aka an invalid JUMP), we got one. Test succeeded.");
              } else {
                // if the error is something else (e.g., the assert from previous promise), then we fail the test
                assert(false, error.toString());
              }
              // Get account 0 to buy a punk with enough ether
              console.log("Buying punk 1001 with correct amount of ether.");
              return contract.buyWaifu(1001, {
                from: accounts[0],
                value: 100,
              });
            })
            .then(function (address) {
              console.log("Checking punk 1001 owned by account 0.");
              return contract.punkIndexToAddress(1001);
            })
            .then(function (address) {
              assert.equal(
                accounts[0],
                address,
                "Did not buy the punk successfully."
              );
              console.log("Making sure punk 1001 is no longer for sale.");
              return contract.waifusOfferedForSale(1001);
            })
            .then(function (offer) {
              console.log("Offer for sale: " + offer);
              assert.equal(offer[0], false, "Waifu was still for sale.");

              console.log("Making sure punk 1001 can't be bought.");
              return contract.buyWaifu(1001, {
                from: accounts[2],
                value: 100,
              });
            })
            .then(function () {
              // console.log("Bought punk.");
              assert(false, "Was supposed to throw but didn't.");
            })
            .catch(function (error) {
              if (error.toString().indexOf("invalid opcode") != -1) {
                // Expecting a throw here
                // console.log("We were expecting a Solidity throw (aka an invalid JUMP), we got one. Test succeeded.");
              } else {
                // if the error is something else (e.g., the assert from previous promise), then we fail the test
                assert(false, error.toString());
              }

              console.log("Offer punk 1001 for sale only to account 2.");
              return contract.offerWaifuForSaleToAddress(
                1001,
                100,
                accounts[2],
                { from: accounts[0] }
              );
              // return contract.punkIndexToAddress(1001);
            })
            .then(function (address) {
              console.log("Try to get account 1 to buy punk 1001 but fail.");
              return contract.buyWaifu(1001, {
                from: accounts[1],
                value: 100,
              });
            })
            .then(function () {
              // console.log("Bought punk.");
              assert(false, "Was supposed to throw but didn't.");
            })
            .catch(function (error) {
              if (error.toString().indexOf("invalid opcode") != -1) {
                // Expecting a throw here
                // console.log("We were expecting a Solidity throw (aka an invalid JUMP), we got one. Test succeeded.");
              } else {
                // if the error is something else (e.g., the assert from previous promise), then we fail the test
                assert(false, error.toString());
              }
              // Get account 0 to buy a punk with enough ether
              console.log(
                "Buying punk 1001 with account 2 which should be allowed."
              );
              return contract.buyWaifu(1001, {
                from: accounts[2],
                value: 100,
              });
            })
            .then(function (address) {
              console.log("Checking punk 1001 now owned by account 2.");
              return contract.punkIndexToAddress(1001);
            })
            .then(function (address) {
              assert.equal(
                accounts[2],
                address,
                "Account 2 did not buy the punk successfully."
              );
              console.log("Offer punk 1001 again.");
              return contract.offerWaifuForSale(1001, 100, {
                from: accounts[2],
              });
            })
            .then(function (address) {
              console.log("Try to make it no longer available for sale.");
              return contract.punkNoLongerForSale(1001, { from: accounts[2] });
            })
            .then(function (address) {
              return contract.waifusOfferedForSale(1001);
            })
            .then(function (offer) {
              console.log("Offer for sale: " + offer);
              assert.equal(offer[0], false, "Waifu was still for sale.");
              console.log(
                "Check that punk purchase price is available for withdrawal."
              );
              return contract.pendingWithdrawals(accounts[1]);
            })
            .then(function (balance) {
              assert.equal(balance, 100, "Account 1 balance incorrect.");
            })
            .then(function () {
              return web3.eth.getBalance(accounts[1]);
            })
            .then(function (balance) {
              previousBalance = balance;
              console.log("Previous account 1 balance: " + balance);
              console.log("Withdrawing balance for account 1 from contract.");
              return contract.withdraw({ from: accounts[1] });
            })
            .then(function () {
              console.log("Checking new account balance after withdrawal.");
              return web3.eth.getBalance(accounts[1]);
            })
            .then(function (balance) {
              console.log("Balance after withdrawal: " + balance);
              var strPrevBalance = String(previousBalance);
              var digitsToCompare = 8;
              var subPrevBalance = strPrevBalance.substr(
                strPrevBalance.length - digitsToCompare,
                strPrevBalance.length
              );
              var strBalance = String(balance);
              var subCurrBalance = strBalance.substr(
                strBalance.length - digitsToCompare,
                strBalance.length
              );
              console.log(
                "Comparing only least significant digits: " +
                  subPrevBalance +
                  " vs. " +
                  subCurrBalance
              );
              return assert.equal(
                Number(subCurrBalance),
                Number(subPrevBalance) + 100,
                "Account 1 balance incorrect after withdrawal."
              );
            });
          // return contract.nextWaifuIndexToAssign();
        });
    }),
    it("should not be able to send bad number to setInitialOwner", function () {
      var contract;
      return CryptoWaifusMarket.deployed()
        .then(function (instance) {
          contract = instance;
          return instance.setInitialOwner(accounts[0], 100);
        })
        .then(function () {
          // console.log("Bought punk.");
          assert(false, "Was supposed to throw but didn't.");
        })
        .catch(function (error) {
          if (error.toString().indexOf("invalid opcode") != -1) {
            // Expecting a throw here
            // console.log("We were expecting a Solidity throw (aka an invalid JUMP), we got one. Test succeeded.");
          } else {
            // if the error is something else (e.g., the assert from previous promise), then we fail the test
            assert(false, error.toString());
          }
          // Get account 0 to buy a punk with enough ether
          // console.log("Buying punk 1001 with account 2 which should be allowed.");
          // return contract.buyWaifu(1001, {from: accounts[2], value: 100});
        });
    }),
    it("only owner can call setInitialOwner", async function () {
      var contract = await CryptoWaifusMarket.deployed();
      try {
        await instance.setInitialOwner(accounts[1], 100);
        assert(false, "Should have thrown exception.");
      } catch (err) {
        // Should catch an exception
      }
    });
});
