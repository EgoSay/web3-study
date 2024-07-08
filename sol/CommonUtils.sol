pragma solidity ^0.8.0;

contract CommonUtils {

    // check if EOA
    function isEOA(address user) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(user)
        }
        // eoa account have no codeHash
        return size > 0;
    }
}
