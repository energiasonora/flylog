// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PilotBrevet
 * @author Xunorus & Gemini
 * @notice A smart contract to manage pilot licenses (brevets), flight logs, and certifications on the blockchain.
 */
contract PilotBrevet {

    // --- State Variables ---

    address public owner;

    struct Pilot {
        string name;
        address walletAddress;
        bool isRegistered;
    }

    struct Flight {
        uint256 timestamp;
        uint256 duration; // in seconds
        uint256 distance; // in meters
    }

    // Mapping from pilot's wallet address to their profile
    mapping(address => Pilot) public pilots;

    // Mapping from pilot's wallet address to their flight logs
    mapping(address => Flight[]) public flightLogs;

    // Mapping to track authorized attesters (e.g., flight clubs, instructors)
    mapping(address => bool) public isAttester;

    // Mapping to track certified pilots
    mapping(address => bool) public isCertified;


    // --- Events ---

    event PilotRegistered(address indexed pilotAddress, string name);
    event ProfileUpdated(address indexed pilotAddress, string newName);
    event FlightLogged(address indexed pilotAddress, uint256 timestamp, uint256 duration, uint256 distance);
    event PilotCertified(address indexed pilotAddress, address indexed attester);
    event AttesterAdded(address indexed attesterAddress);
    event AttesterRemoved(address indexed attesterAddress);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "PilotBrevet: Caller is not the owner");
        _;
    }

    modifier onlyAttester() {
        require(isAttester[msg.sender], "PilotBrevet: Caller is not an authorized attester");
        _;
    }

    modifier onlyRegisteredPilot() {
        require(pilots[msg.sender].isRegistered, "PilotBrevet: Caller is not a registered pilot");
        _;
    }


    // --- Functions ---

    /**
     * @notice Sets the contract deployer as the owner.
     */
    constructor() {
        owner = msg.sender;
    }

    // --- Owner Functions ---

    /**
     * @notice Allows the owner to add a new authorized attester.
     * @param _attesterAddress The address of the new attester.
     */
    function addAttester(address _attesterAddress) external onlyOwner {
        require(_attesterAddress != address(0), "PilotBrevet: Invalid attester address");
        isAttester[_attesterAddress] = true;
        emit AttesterAdded(_attesterAddress);
    }

    /**
     * @notice Allows the owner to remove an authorized attester.
     * @param _attesterAddress The address of the attester to remove.
     */
    function removeAttester(address _attesterAddress) external onlyOwner {
        isAttester[_attesterAddress] = false;
        emit AttesterRemoved(_attesterAddress);
    }

    // --- Attester Functions ---

    /**
     * @notice Allows an attester to register a new pilot.
     * @param _pilotAddress The wallet address of the new pilot.
     * @param _name The name of the pilot.
     */
    function registerPilot(address _pilotAddress, string calldata _name) external onlyAttester {
        require(_pilotAddress != address(0), "PilotBrevet: Invalid pilot address");
        require(!pilots[_pilotAddress].isRegistered, "PilotBrevet: Pilot is already registered");

        pilots[_pilotAddress] = Pilot({
            name: _name,
            walletAddress: _pilotAddress,
            isRegistered: true
        });

        emit PilotRegistered(_pilotAddress, _name);
    }

    /**
     * @notice Allows an attester to certify a registered pilot.
     * @param _pilotAddress The address of the pilot to certify.
     */
    function certifyPilot(address _pilotAddress) external onlyAttester {
        require(pilots[_pilotAddress].isRegistered, "PilotBrevet: Pilot is not registered");
        isCertified[_pilotAddress] = true;
        emit PilotCertified(_pilotAddress, msg.sender);
    }

    // --- Pilot Functions ---

    /**
     * @notice Allows a registered pilot to update their own name.
     * @param _newName The new name for the pilot.
     */
    function updateProfile(string calldata _newName) external onlyRegisteredPilot {
        pilots[msg.sender].name = _newName;
        emit ProfileUpdated(msg.sender, _newName);
    }

    /**
     * @notice Allows a registered pilot to log a flight.
     * @param _duration The duration of the flight in seconds.
     * @param _distance The distance of the flight in meters.
     */
    function logFlight(uint256 _duration, uint256 _distance) external onlyRegisteredPilot {
        flightLogs[msg.sender].push(Flight({
            timestamp: block.timestamp,
            duration: _duration,
            distance: _distance
        }));
        emit FlightLogged(msg.sender, block.timestamp, _duration, _distance);
    }

    // --- View Functions ---

    /**
     * @notice Retrieves the total number of flights logged by a pilot.
     * @param _pilotAddress The address of the pilot.
     * @return The count of flights.
     */
    function getFlightCount(address _pilotAddress) external view returns (uint256) {
        return flightLogs[_pilotAddress].length;
    }
}
