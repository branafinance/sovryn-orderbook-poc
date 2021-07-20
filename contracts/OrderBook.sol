pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";



abstract contract ISovrynNetwork {
    function convertByPath(
        address[] calldata _path, 
        uint256 _amount, 
        uint256 _minReturn, 
        address _beneficiary, 
        address _affiliateAccount, 
        uint256 _affiliateFee
    ) external virtual payable returns (uint256);

    function rateByPath(
        address[] calldata _path, 
        uint256 _amount
    ) external virtual view returns (uint256);

    function conversionPath(
        ERC20 _sourceToken, 
        ERC20 _targetToken
    ) external virtual view returns (address[] memory);
}

contract OrderBook {

     event LogMake(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  maker,
        ERC20             pay_gem,
        ERC20             buy_gem,
        uint128           pay_amt,
        uint128           buy_amt,
        uint64            timestamp
    );


    event LogTake(
        bytes32           id,
        bytes32  indexed  pair,
        address  indexed  maker,
        ERC20             pay_gem,
        ERC20             buy_gem,
        address  indexed  taker,
        uint128           take_amt,
        uint128           give_amt,
        uint64            timestamp
    );

    event LogKill(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  maker,
        ERC20             pay_gem,
        ERC20             buy_gem,
        uint128           pay_amt,
        uint128           buy_amt,
        uint64            timestamp
    );


    mapping (uint => OfferInfo) public offers;
    uint public last_offer_id;
    using SafeMath for uint256;

    ISovrynNetwork sovrynNetwork;

    struct OfferInfo {
        uint     pay_amt;
        ERC20    pay_gem;
        uint     buy_amt;
        ERC20    buy_gem;
        address  owner;
        uint64   timestamp;
    }


    function LoadSwapNetwork(address _t) public {
        sovrynNetwork = ISovrynNetwork(_t);
    }

    function getRateBetwenTokens(address from, address to, uint256 amount) external virtual view returns (uint256) {
        address[] memory path = getSovrynConversionPath(from, to);
        return sovrynNetwork.rateByPath(path, amount);
    }

    function getSovrynConversionPath(address from, address to) public view returns (address[] memory) {
        return sovrynNetwork.conversionPath(ERC20(from),ERC20(to));
    }

    function swapTokens(address from, address to, uint256 amount, uint256 minExpected) 
        external payable returns (uint256) {
        address[] memory path = getSovrynConversionPath(from, to);
        uint256 estimatedTokens = sovrynNetwork.rateByPath(path, amount);
        require(estimatedTokens >= minExpected, "estimatedTokens are not larger than min expectd");
        uint256 fee = 0;
        return sovrynNetwork.convertByPath(path, amount, minExpected, msg.sender, address(this), fee);
    }

    // Make a new offer. Takes funds from the caller into market escrow.
    function makeOffer(uint pay_amt, address payGemAddress, uint buy_amt, address buyGemAddress) public returns (uint id)
    {
        ERC20 pay_gem = ERC20(payGemAddress);
        ERC20 buy_gem = ERC20(buyGemAddress);
        require(uint128(pay_amt) == pay_amt);
        require(uint128(buy_amt) == buy_amt);
        require(pay_amt > 0);
        // require(pay_gem != ERC20(0x0));
        require(buy_amt > 0);
        // require(buy_gem != ERC20(0x0));
        require(pay_gem != buy_gem);

        OfferInfo memory info;
        info.pay_amt = pay_amt;
        info.pay_gem = pay_gem;
        info.buy_amt = buy_amt;
        info.buy_gem = buy_gem;
        info.owner = msg.sender;
        info.timestamp = uint64(block.timestamp);
        id = _next_id();
        offers[id] = info;

        pay_gem.transferFrom(msg.sender, address(this), pay_amt);


        emit LogMake(
            bytes32(id),
            keccak256(abi.encodePacked(info.pay_gem, info.buy_gem)),
            info.owner,
            info.pay_gem,
            info.buy_gem,
            uint128(info.pay_amt),
            uint128(info.buy_amt),
            uint64(block.timestamp)
        );


        return id;


    }

       function _next_id()
        internal
        returns (uint)
    {
        last_offer_id++; return last_offer_id;
    }



       // Accept given `quantity` of an offer. Transfers funds from caller to
    // offer maker, and from market to caller.
    function buy(uint id, uint quantity)
        public
        returns (bool)
    {
        OfferInfo memory offer = offers[id];
        uint spend = quantity.mul(offer.buy_amt) / offer.pay_amt;

        require(uint128(spend) == spend);
        require(uint128(quantity) == quantity);

        if (quantity == 0 || spend == 0 ||
            quantity > offer.pay_amt || spend > offer.buy_amt)
        {
            return false;
        }

        offers[id].pay_amt = offer.pay_amt.sub(quantity);
        offers[id].buy_amt = offer.buy_amt.sub(spend);
        
        offer.buy_gem.transferFrom(msg.sender, offer.owner, spend);

        offer.pay_gem.transfer(msg.sender, quantity);


        if (offers[id].pay_amt == 0) {
          delete offers[id];
        }

        emit LogTake(
            bytes32(id),
            keccak256(abi.encodePacked(offer.pay_gem, offer.buy_gem)),
            offer.owner,
            offer.pay_gem,
            offer.buy_gem,
            msg.sender,
            uint128(offer.pay_amt),
            uint128(offer.buy_amt),
            uint64(block.timestamp)
        );


        return true;
    }


    modifier can_cancel(uint id) {
        require(getOwner(id) == msg.sender);
        _;
    }


    function cancel(uint id)
        public
        can_cancel(id)
        returns (bool success)
    {
        OfferInfo memory offer = offers[id];
        delete offers[id];

        offer.pay_gem.transfer(offer.owner, offer.pay_amt);

         emit LogKill(
            bytes32(id),
            keccak256(abi.encodePacked(offer.pay_gem, offer.buy_gem)),
            offer.owner,
            offer.pay_gem,
            offer.buy_gem,
            uint128(offer.pay_amt),
            uint128(offer.buy_amt),
            uint64(block.timestamp)
        );


        success = true;
    }

    function getOwner(uint id) public view returns (address owner) {
        return offers[id].owner;
    }


}
