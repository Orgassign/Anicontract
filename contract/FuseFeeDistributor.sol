pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";


contract FuseFeeDistributor is Initializable, OwnableUpgradeable {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    function initialize(uint256 _interestFeeRate) public initializer {
        require(_interestFeeRate <= 1e18, "Interest fee rate cannot be more than 100%.");
        __Ownable_init();
        interestFeeRate = _interestFeeRate;
        maxSupplyEth = uint256(-1);
        maxUtilizationRate = uint256(-1);
    }

 
    uint256 public interestFeeRate;


    function _setInterestFeeRate(uint256 _interestFeeRate) external onlyOwner {
        require(_interestFeeRate <= 1e18, "Interest fee rate cannot be more than 100%.");
        interestFeeRate = _interestFeeRate;
    }


    function _withdrawAssets(address erc20Contract) external {
        if (erc20Contract == address(0)) {
            uint256 balance = address(this).balance;
            require(balance > 0, "No balance available to withdraw.");
            (bool success, ) = owner().call{value: balance}("");
            require(success, "Failed to transfer ETH balance to msg.sender.");
        } else {
            IERC20Upgradeable token = IERC20Upgradeable(erc20Contract);
            uint256 balance = token.balanceOf(address(this));
            require(balance > 0, "No token balance available to withdraw.");
            token.safeTransfer(owner(), balance);
        }
    }

    uint256 public minBorrowEth;

    uint256 public maxSupplyEth;


    uint256 public maxUtilizationRate;

 
    function _setPoolLimits(uint256 _minBorrowEth, uint256 _maxSupplyEth, uint256 _maxUtilizationRate) external onlyOwner {
        minBorrowEth = _minBorrowEth;
        maxSupplyEth = _maxSupplyEth;
        maxUtilizationRate = _maxUtilizationRate;
    }

    receive() external payable { }

 
    function _callPool(address[] calldata targets, bytes[] calldata data) external onlyOwner {
        require(targets.length > 0 && targets.length == data.length, "Array lengths must be equal and greater than 0.");
        for (uint256 i = 0; i < targets.length; i++) targets[i].functionCall(data[i]);
    }

    function _callPool(address[] calldata targets, bytes calldata data) external onlyOwner {
        require(targets.length > 0, "No target addresses specified.");
        for (uint256 i = 0; i < targets.length; i++) targets[i].functionCall(data);
    }
}
