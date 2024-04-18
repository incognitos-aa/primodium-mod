// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity 0.8.19;

import "fhevm/abstracts/EIP712WithModifier.sol";
import "fhevm/lib/TFHE.sol";

interface IInterchainExecuteRouter {
    function getRemoteInterchainAccount(uint32 _destination, address _owner) external view returns (address);
}

contract RandomNumber is EIP712WithModifier {
    uint32 ChainID; //10017
    address public iexRouter; // 0xA5827f5E80005c0112B1e6A2c496d0EBA86Fbd11
    address public caller_contract;
    
    constructor() EIP712WithModifier("Authorization token", "1") {
        ChainID = 10017;
        iexRouter = 0xA5827f5E80005c0112B1e6A2c496d0EBA86Fbd11;
    }
    
    function setCallerContract(address _caller_contract) public {
        caller_contract = _caller_contract;
    }

    function getICA() public view returns(address) {
        return IInterchainExecuteRouter(iexRouter).getRemoteInterchainAccount(ChainID, address(this));
    }
    
    modifier onlyCallerContract() {
        require(caller_contract == msg.sender, "not right caller contract");
        _;
    }
    
    mapping (address => euint16) public encryptedNumbers;

    function returnNumber(address user) external onlyCallerContract returns(uint16) {
        encryptedNumbers[user] = TFHE.rem(TFHE.randEuint16(), 100);
        return TFHE.decrypt(encryptedNumbers[user]);
    }

    function viewNumber(address user) external view returns (uint16) {
        return TFHE.decrypt(encryptedNumbers[user]);
    }
}