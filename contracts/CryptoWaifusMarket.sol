pragma solidity ^0.4.8;
contract CryptoWaifusMarket {

    // You can use this hash to verify the image file containing all the waifus
    string public imageHash = "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";

    address owner;

    string public standard = 'CryptoWaifus';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint public nextPunkIndexToAssign = 0;

    bool public allWaifusAssigned = false;
    uint public waifusRemainingToAssign = 0;

    //mapping (address => uint) public addressToPunkIndex;
    mapping (uint => address) public waifuIndexToAddress;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    struct Offer {
        bool isForSale;
        uint waifuIndex;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint waifuIndex;
        address bidder;
        uint value;
    }

    // A record of waifus that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public waifusOfferedForSale;

    // A record of the highest waifu bid
    mapping (uint => Bid) public waifuBids;

    mapping (address => uint) public pendingWithdrawals;

    event Assign(address indexed to, uint256 waifuIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(address indexed from, address indexed to, uint256 waifuIndex);
    event PunkOffered(uint indexed waifuIndex, uint minValue, address indexed toAddress);
    event PunkBidEntered(uint indexed waifuIndex, uint value, address indexed fromAddress);
    event PunkBidWithdrawn(uint indexed waifuIndex, uint value, address indexed fromAddress);
    event PunkBought(uint indexed waifuIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event PunkNoLongerForSale(uint indexed waifuIndex);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function CryptoWaifusMarket() payable {
        //        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        owner = msg.sender;
        totalSupply = 10000;                        // Update total supply
        waifusRemainingToAssign = totalSupply;
        name = "CRYPTOWAIFUS";                                   // Set the name for display purposes
        symbol = "Ͼ";                               // Set the symbol for display purposes
        decimals = 0;                                       // Amount of decimals for display purposes
    }

    function setInitialOwner(address to, uint waifuIndex) {
        if (msg.sender != owner) throw;
        if (allWaifusAssigned) throw;
        if (waifuIndex >= 10000) throw;
        if (waifuIndexToAddress[waifuIndex] != to) {
            if (waifuIndexToAddress[waifuIndex] != 0x0) {
                balanceOf[waifuIndexToAddress[waifuIndex]]--;
            } else {
                waifusRemainingToAssign--;
            }
            waifuIndexToAddress[waifuIndex] = to;
            balanceOf[to]++;
            Assign(to, waifuIndex);
        }
    }

    function setInitialOwners(address[] addresses, uint[] indices) {
        if (msg.sender != owner) throw;
        uint n = addresses.length;
        for (uint i = 0; i < n; i++) {
            setInitialOwner(addresses[i], indices[i]);
        }
    }

    function allInitialOwnersAssigned() {
        if (msg.sender != owner) throw;
        allWaifusAssigned = true;
    }

    function getPunk(uint waifuIndex) {
        if (!allWaifusAssigned) throw;
        if (waifusRemainingToAssign == 0) throw;
        if (waifuIndexToAddress[waifuIndex] != 0x0) throw;
        if (waifuIndex >= 10000) throw;
        waifuIndexToAddress[waifuIndex] = msg.sender;
        balanceOf[msg.sender]++;
        waifusRemainingToAssign--;
        Assign(msg.sender, waifuIndex);
    }

    // Transfer ownership of a waifu to another user without requiring payment
    function transferPunk(address to, uint waifuIndex) {
        if (!allWaifusAssigned) throw;
        if (waifuIndexToAddress[waifuIndex] != msg.sender) throw;
        if (waifuIndex >= 10000) throw;
        if (waifusOfferedForSale[waifuIndex].isForSale) {
            waifuNoLongerForSale(waifuIndex);
        }
        waifuIndexToAddress[waifuIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        Transfer(msg.sender, to, 1);
        PunkTransfer(msg.sender, to, waifuIndex);
        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = waifuBids[waifuIndex];
        if (bid.bidder == to) {
            // Kill bid and refund value
            pendingWithdrawals[to] += bid.value;
            waifuBids[waifuIndex] = Bid(false, waifuIndex, 0x0, 0);
        }
    }

    function waifuNoLongerForSale(uint waifuIndex) {
        if (!allWaifusAssigned) throw;
        if (waifuIndexToAddress[waifuIndex] != msg.sender) throw;
        if (waifuIndex >= 10000) throw;
        waifusOfferedForSale[waifuIndex] = Offer(false, waifuIndex, msg.sender, 0, 0x0);
        PunkNoLongerForSale(waifuIndex);
    }

    function offerPunkForSale(uint waifuIndex, uint minSalePriceInWei) {
        if (!allWaifusAssigned) throw;
        if (waifuIndexToAddress[waifuIndex] != msg.sender) throw;
        if (waifuIndex >= 10000) throw;
        waifusOfferedForSale[waifuIndex] = Offer(true, waifuIndex, msg.sender, minSalePriceInWei, 0x0);
        PunkOffered(waifuIndex, minSalePriceInWei, 0x0);
    }

    function offerPunkForSaleToAddress(uint waifuIndex, uint minSalePriceInWei, address toAddress) {
        if (!allWaifusAssigned) throw;
        if (waifuIndexToAddress[waifuIndex] != msg.sender) throw;
        if (waifuIndex >= 10000) throw;
        waifusOfferedForSale[waifuIndex] = Offer(true, waifuIndex, msg.sender, minSalePriceInWei, toAddress);
        PunkOffered(waifuIndex, minSalePriceInWei, toAddress);
    }

    function buyPunk(uint waifuIndex) payable {
        if (!allWaifusAssigned) throw;
        Offer offer = waifusOfferedForSale[waifuIndex];
        if (waifuIndex >= 10000) throw;
        if (!offer.isForSale) throw;                // waifu not actually for sale
        if (offer.onlySellTo != 0x0 && offer.onlySellTo != msg.sender) throw;  // waifu not supposed to be sold to this user
        if (msg.value < offer.minValue) throw;      // Didn't send enough ETH
        if (offer.seller != waifuIndexToAddress[waifuIndex]) throw; // Seller no longer owner of waifu

        address seller = offer.seller;

        waifuIndexToAddress[waifuIndex] = msg.sender;
        balanceOf[seller]--;
        balanceOf[msg.sender]++;
        Transfer(seller, msg.sender, 1);

        waifuNoLongerForSale(waifuIndex);
        pendingWithdrawals[seller] += msg.value;
        PunkBought(waifuIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = waifuBids[waifuIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            waifuBids[waifuIndex] = Bid(false, waifuIndex, 0x0, 0);
        }
    }

    function withdraw() {
        if (!allWaifusAssigned) throw;
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function enterBidForPunk(uint waifuIndex) payable {
        if (waifuIndex >= 10000) throw;
        if (!allWaifusAssigned) throw;                
        if (waifuIndexToAddress[waifuIndex] == 0x0) throw;
        if (waifuIndexToAddress[waifuIndex] == msg.sender) throw;
        if (msg.value == 0) throw;
        Bid existing = waifuBids[waifuIndex];
        if (msg.value <= existing.value) throw;
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        waifuBids[waifuIndex] = Bid(true, waifuIndex, msg.sender, msg.value);
        PunkBidEntered(waifuIndex, msg.value, msg.sender);
    }

    function acceptBidForPunk(uint waifuIndex, uint minPrice) {
        if (waifuIndex >= 10000) throw;
        if (!allWaifusAssigned) throw;                
        if (waifuIndexToAddress[waifuIndex] != msg.sender) throw;
        address seller = msg.sender;
        Bid bid = waifuBids[waifuIndex];
        if (bid.value == 0) throw;
        if (bid.value < minPrice) throw;

        waifuIndexToAddress[waifuIndex] = bid.bidder;
        balanceOf[seller]--;
        balanceOf[bid.bidder]++;
        Transfer(seller, bid.bidder, 1);

        waifusOfferedForSale[waifuIndex] = Offer(false, waifuIndex, bid.bidder, 0, 0x0);
        uint amount = bid.value;
        waifuBids[waifuIndex] = Bid(false, waifuIndex, 0x0, 0);
        pendingWithdrawals[seller] += amount;
        PunkBought(waifuIndex, bid.value, seller, bid.bidder);
    }

    function withdrawBidForPunk(uint waifuIndex) {
        if (waifuIndex >= 10000) throw;
        if (!allWaifusAssigned) throw;                
        if (waifuIndexToAddress[waifuIndex] == 0x0) throw;
        if (waifuIndexToAddress[waifuIndex] == msg.sender) throw;
        Bid bid = waifuBids[waifuIndex];
        if (bid.bidder != msg.sender) throw;
        PunkBidWithdrawn(waifuIndex, bid.value, msg.sender);
        uint amount = bid.value;
        waifuBids[waifuIndex] = Bid(false, waifuIndex, 0x0, 0);
        // Refund the bid money
        msg.sender.transfer(amount);
    }

}
