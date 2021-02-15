// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// ZooToken
contract ZooToken is ERC20("ZooToken", "ZOO"), Ownable {
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (WanSwapFarm).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }
}
