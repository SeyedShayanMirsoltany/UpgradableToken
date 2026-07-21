// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@utils/CustomRoles.sol";
import "@openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
contract CLToken is ERC20CappedUpgradeable, ERC20PausableUpgradeable, ERC20BurnableUpgradeable, UUPSUpgradeable, OwnableUpgradeable, AccessControlUpgradeable {
    error InitialOwnerIsZero();
    error InitialSupplyExceedsCap();
    function initialize(string memory name_, string memory symbol_, uint256 cap_, uint256 initialSupply_, address initialOwner_) public initializer {
        if (initialOwner_ == address(0)) revert InitialOwnerIsZero();
        if (initialSupply_ > cap_) revert InitialSupplyExceedsCap();

        __ERC20_init(name_, symbol_);
        __ERC20Capped_init(cap_);
        __ERC20Pausable_init();
        __ERC20Burnable_init();
        __Ownable_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner_);
        _grantRole(PAUSER_ROLE, initialOwner_);
        _grantRole(MINTER_ROLE, initialOwner_);
        _grantRole(BURNER_ROLE, initialOwner_);
        _transferOwnership(initialOwner_);
        _mint(initialOwner_, initialSupply_);
    }

    constructor() {
        _disableInitializers();
    }

    function mint(address account, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20CappedUpgradeable) onlyRole(MINTER_ROLE) {
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function version() public view virtual returns (uint8) {
        return _getInitializedVersion();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
