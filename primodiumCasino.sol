// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity 0.8.19;

import { ISpawnSystem } from "./ISpawnSystem.sol";
import { UNLIMITED_DELEGATION, ResourceId } from "@latticexyz/world/src/constants.sol";
import { WorldRegistrationSystem } from "@latticexyz/world/src/modules/init/implementations/WorldRegistrationSystem.sol";
// import { IWorld as IPrimodiumWorld } from "./world/IWorld.sol";

interface IPrimodiumWorld {
    function callFrom(
        address delegator,
        ResourceId systemId,
        bytes memory callData
    ) external payable returns (bytes memory);
}

interface IFleetTransferSystem {
    function transferResourcesFromSpaceRockToFleet(
    bytes32 spaceRock,
    bytes32 fleetId,
    uint256[] calldata resourceCounts
  ) external;
}

interface IInterchainExecuteRouter {
    function getRemoteInterchainAccount(uint32 _destination, address _owner) external view returns (address);
    // New
    function callRemote(uint32 _destination, address _to, uint256 _value, bytes calldata _data, bytes memory _callback) external returns (bytes32);
}

interface RandomNumber {
    function returnNumber(address user) external returns(uint16);
}


// WORLDREGISTRATIONSYSTEM - registerDelegation function 
// delegatee: casino contract
// delegationControlId: 0x73790000000000000000000000000000756e6c696d6974656400000000000000
// initCalldata: 0x

contract PrimodiumCasino {
    // bridge state
    uint32 ChainID; //9090
    address randomNumber; // RandomNumber contract in Inco Network 0x8a46f6bDe124D6cB6fC1a9DB2430c960bC0b1184
    address iexRouter; // 0x4B6ba9EDb2BE6753d95665B2D53766a9c889D9Ce
    address caller_contract;
    bool public isInitialized;
    uint256 public lastRandomNumber =0;

    // Primordium State
    // address constant WORLD_CONTRACT = 0x32c856656b2BcDf739aA486A417B46B3d19f54F9;
    address constant WORLD_CONTRACT = 0x060f3f0915999Fa84886F6e993CD95c4B2046B43;
    // address constant EOA = 0xAB99D5f73A13Fae479457A3FaD0836Dd2c75c649;
    ISpawnSystem worldContract = ISpawnSystem(WORLD_CONTRACT);
    ResourceId public test;
    bytes public test2;
    mapping(address => uint256) public copperBalances;
    bytes32 constant syFleetTransferSys = 0x73790000000000000000000000000000466C6565745472616E73666572537973;


    // Constructor
    constructor() {
        ChainID = 9090;
        iexRouter = 0x4B6ba9EDb2BE6753d95665B2D53766a9c889D9Ce;
    }

    function initialize(address _randomNumber) public {
        randomNumber = _randomNumber;
        caller_contract = msg.sender;
    }

    function setCallerContract(address _caller_contract) onlyCallerContract public {
        caller_contract = _caller_contract;
    }

    function getICA() public view returns(address) {
        return IInterchainExecuteRouter(iexRouter).getRemoteInterchainAccount(ChainID, address(this));
    }
    
    modifier onlyCallerContract() {
        require(caller_contract == msg.sender, "not right caller contract");
        _;
    }

    function placeBet() public {
        RandomNumber _RandomNumber = RandomNumber(randomNumber);
        bytes memory _callback = abi.encodePacked(this.betSettlement.selector, (uint256(uint160(msg.sender))));

        IInterchainExecuteRouter(iexRouter).callRemote(
            ChainID,
            address(_RandomNumber),
            0,
            abi.encodeCall(_RandomNumber.returnNumber, (msg.sender)),
            _callback
        );
    }

    function betSettlement(uint256 user, uint16 _Number) external {
        require(caller_contract == msg.sender, "not right caller contract");

        address playerAddress = address(uint160(user));
        uint256 bet = copperBalances[playerAddress];
        lastRandomNumber = _Number;

        if (_Number < 49) {
            copperBalances[playerAddress] += bet;
        } else {
            copperBalances[playerAddress] -= bet;
        }
    }

    function randomNumberView() public view returns(uint256) {
        return lastRandomNumber;
    }

    function balanceView(address player) public view returns(uint256) {
        return copperBalances[player];
    }

    /////////// Team 2 Code //////////
    
    function spawn_asteroid() public {
        worldContract.spawn();
    }

    function delegate_to_asteroid() public {
        WorldRegistrationSystem world = WorldRegistrationSystem(WORLD_CONTRACT);
        world.registerDelegation(
            address(this),
            UNLIMITED_DELEGATION,
                new bytes(0)
        );
    }

    // array positioning for resources
    // [
    //           EResource.Iron,
    //           EResource.Copper,
    //           EResource.Lithium,
    //           EResource.IronPlate,
    //           EResource.PVCell,
    //           EResource.Alloy,
    //           EResource.Titanium,
    //           EResource.Platinum,
    //           EResource.Iridium,
    //           EResource.Kimberlite,
    //         ],

    function deposit_copper(bytes32 fleetId, bytes32 spaceRock, uint256 amount) public {
        uint256[] memory resources = new uint256[](10);  
        resources[1] = amount; 
        IPrimodiumWorld(WORLD_CONTRACT).callFrom(
            msg.sender,
            ResourceId.wrap(syFleetTransferSys),
            abi.encodeWithSignature("transferResourcesFromFleetToSpaceRock(bytes32,bytes32,uint256[])", fleetId, spaceRock, resources)
            );
        copperBalances[msg.sender] += amount;
    }

    function withdraw_copper(bytes32 spaceRock, bytes32 fleetId, uint256 amount) public {
        uint256[] memory resources = new uint256[](10);  
        resources[1] = amount; 
        IFleetTransferSystem(WORLD_CONTRACT).transferResourcesFromSpaceRockToFleet(spaceRock, fleetId, resources);
        copperBalances[msg.sender] -= amount;
    }

    // function view_delegation_bytes() public {
    //     test = UNLIMITED_DELEGATION;
    // }

    // function bytes_0() public {
    //     test2 = new bytes(0);
    // }

    // function delegate_asteroid() public {
    //     WorldRegistrationSystem world = WorldRegistrationSystem(0x32c856656b2BcDf739aA486A417B46B3d19f54F9);
    //     world.registerDelegation(
    //         address(EOA),
    //         UNLIMITED_DELEGATION,
    //             new bytes(0)
    //     );
    // }

}