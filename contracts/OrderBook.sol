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
        require(estimatedTokens >= minExpected);
        uint256 fee = 0;
        return sovrynNetwork.convertByPath(path, amount, minExpected, msg.sender, address(this), fee);
    }

    // Make a new offer. Takes funds from the caller into market escrow.
    function makeOffer(uint pay_amt, ERC20 pay_gem, uint buy_amt, ERC20 buy_gem) public returns (uint id)
    {
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

        safeTransferFrom(pay_gem, msg.sender, address(this), pay_amt);

    }

       function _next_id()
        internal
        returns (uint)
    {
        last_offer_id++; return last_offer_id;
    }

 function _callOptionalReturn(ERC20 token, bytes memory data) private {
        uint256 size;
        assembly { size := extcodesize(token) }
        require(size > 0, "Not a contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "Token call failed");
        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }


    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        safeTransferFrom(offer.buy_gem, msg.sender, offer.owner, spend);
        safeTransfer(offer.pay_gem, msg.sender, quantity);

        if (offers[id].pay_amt == 0) {
          delete offers[id];
        }

        return true;
    }

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }


}
