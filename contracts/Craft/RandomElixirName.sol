// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";



contract RandomElixirName is AccessControl {

    using SafeMath for uint256;

    string[] public name1;

    string[] public name2;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "only admin");
        _;
    }

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addNames(string[] memory _name1, string[] memory _name2) public onlyAdmin {
        uint length1 = _name1.length;
        uint length2 = _name2.length;

        for (uint i=0; i<length1; i++) {
            name1.push(_name1[i]);
        }

        for (uint i=0; i<length2; i++) {
            name2.push(_name2[i]);
        }
    }

    function generateName(uint random) external view returns (string memory) {
        uint r0 = uint(keccak256(abi.encode(random)));
        uint r1 = uint(keccak256(abi.encode(r0)));

        return string(abi.encodePacked(name2[r0.mod(name2.length)], " of ", name1[r1.mod(name1.length)]));
    }
}
