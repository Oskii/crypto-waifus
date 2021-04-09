pragma solidity ^0.4.8;

contract CryptoWaifusMarket {
    // You can use this hash to verify the image file containing all the waifus
    string public imageHash =
        "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";

    address owner;

    string public standard = "CryptoWaifus";
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint256 public nextWaifuIndexToAssign = 0;

    bool public allWaifusAssigned = false;
    uint256 public waifusRemainingToAssign = 0;

    //mapping (address => uint) public addressToWaifuIndex;
    mapping(uint256 => address) public waifuIndexToAddress;

    /* This creates an array with all balances */
    mapping(address => uint256) public balanceOf;

    struct Offer {
        bool isForSale;
        uint256 waifuIndex;
        address seller;
        uint256 minValue; // in ether
        address onlySellTo; // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint256 waifuIndex;
        address bidder;
        uint256 value;
    }

    // A record of waifus that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping(uint256 => Offer) public waifusOfferedForSale;

    // A record of the highest waifu bid
    mapping(uint256 => Bid) public waifuBids;

    mapping(address => uint256) public pendingWithdrawals;

    event Assign(address indexed to, uint256 waifuIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event WaifuTransfer(
        address indexed from,
        address indexed to,
        uint256 waifuIndex
    );
    event WaifuOffered(
        uint256 indexed waifuIndex,
        uint256 minValue,
        address indexed toAddress
    );
    event WaifuBidEntered(
        uint256 indexed waifuIndex,
        uint256 value,
        address indexed fromAddress
    );
    event WaifuBidWithdrawn(
        uint256 indexed waifuIndex,
        uint256 value,
        address indexed fromAddress
    );
    event WaifuBought(
        uint256 indexed waifuIndex,
        uint256 value,
        address indexed fromAddress,
        address indexed toAddress
    );
    event WaifuNoLongerForSale(uint256 indexed waifuIndex);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function CryptoWaifusMarket() payable {
        //        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        owner = msg.sender;
        totalSupply = 10000; // Update total supply
        waifusRemainingToAssign = totalSupply;
        name = "CRYPTOWAIFUS"; // Set the name for display purposes
        symbol = "Ͼ"; // Set the symbol for display purposes
        decimals = 0; // Amount of decimals for display purposes
    }

    function setInitialOwner(address to, uint256 waifuIndex) {
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

    function setInitialOwners(address[] addresses, uint256[] indices) {
        if (msg.sender != owner) throw;
        uint256 n = addresses.length;
        for (uint256 i = 0; i < n; i++) {
            setInitialOwner(addresses[i], indices[i]);
        }
    }

    function allInitialOwnersAssigned() {
        if (msg.sender != owner) throw;
        allWaifusAssigned = true;
    }

    function getWaifu(uint256 waifuIndex) {
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
    function transferWaifu(address to, uint256 waifuIndex) {
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
        WaifuTransfer(msg.sender, to, waifuIndex);
        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = waifuBids[waifuIndex];
        if (bid.bidder == to) {
            // Kill bid and refund value
            pendingWithdrawals[to] += bid.value;
            waifuBids[waifuIndex] = Bid(false, waifuIndex, 0x0, 0);
        }
    }

    function waifuNoLongerForSale(uint256 waifuIndex) {
        if (!allWaifusAssigned) throw;
        if (waifuIndexToAddress[waifuIndex] != msg.sender) throw;
        if (waifuIndex >= 10000) throw;
        waifusOfferedForSale[waifuIndex] = Offer(
            false,
            waifuIndex,
            msg.sender,
            0,
            0x0
        );
        WaifuNoLongerForSale(waifuIndex);
    }

    function offerWaifuForSale(uint256 waifuIndex, uint256 minSalePriceInWei) {
        if (!allWaifusAssigned) throw;
        if (waifuIndexToAddress[waifuIndex] != msg.sender) throw;
        if (waifuIndex >= 10000) throw;
        waifusOfferedForSale[waifuIndex] = Offer(
            true,
            waifuIndex,
            msg.sender,
            minSalePriceInWei,
            0x0
        );
        WaifuOffered(waifuIndex, minSalePriceInWei, 0x0);
    }

    function offerWaifuForSaleToAddress(
        uint256 waifuIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) {
        if (!allWaifusAssigned) throw;
        if (waifuIndexToAddress[waifuIndex] != msg.sender) throw;
        if (waifuIndex >= 10000) throw;
        waifusOfferedForSale[waifuIndex] = Offer(
            true,
            waifuIndex,
            msg.sender,
            minSalePriceInWei,
            toAddress
        );
        WaifuOffered(waifuIndex, minSalePriceInWei, toAddress);
    }

    function buyWaifu(uint256 waifuIndex) payable {
        if (!allWaifusAssigned) throw;
        Offer offer = waifusOfferedForSale[waifuIndex];
        if (waifuIndex >= 10000) throw;
        if (!offer.isForSale) throw; // waifu not actually for sale
        if (offer.onlySellTo != 0x0 && offer.onlySellTo != msg.sender) throw; // waifu not supposed to be sold to this user
        if (msg.value < offer.minValue) throw; // Didn't send enough ETH
        if (offer.seller != waifuIndexToAddress[waifuIndex]) throw; // Seller no longer owner of waifu

        address seller = offer.seller;

        waifuIndexToAddress[waifuIndex] = msg.sender;
        balanceOf[seller]--;
        balanceOf[msg.sender]++;
        Transfer(seller, msg.sender, 1);

        waifuNoLongerForSale(waifuIndex);
        pendingWithdrawals[seller] += msg.value;
        WaifuBought(waifuIndex, msg.value, seller, msg.sender);

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
        uint256 amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function enterBidForWaifu(uint256 waifuIndex) payable {
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
        WaifuBidEntered(waifuIndex, msg.value, msg.sender);
    }

    function acceptBidForWaifu(uint256 waifuIndex, uint256 minPrice) {
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

        waifusOfferedForSale[waifuIndex] = Offer(
            false,
            waifuIndex,
            bid.bidder,
            0,
            0x0
        );
        uint256 amount = bid.value;
        waifuBids[waifuIndex] = Bid(false, waifuIndex, 0x0, 0);
        pendingWithdrawals[seller] += amount;
        WaifuBought(waifuIndex, bid.value, seller, bid.bidder);
    }

    function withdrawBidForWaifu(uint256 waifuIndex) {
        if (waifuIndex >= 10000) throw;
        if (!allWaifusAssigned) throw;
        if (waifuIndexToAddress[waifuIndex] == 0x0) throw;
        if (waifuIndexToAddress[waifuIndex] == msg.sender) throw;
        Bid bid = waifuBids[waifuIndex];
        if (bid.bidder != msg.sender) throw;
        WaifuBidWithdrawn(waifuIndex, bid.value, msg.sender);
        uint256 amount = bid.value;
        waifuBids[waifuIndex] = Bid(false, waifuIndex, 0x0, 0);
        // Refund the bid money
        msg.sender.transfer(amount);
    }
}
