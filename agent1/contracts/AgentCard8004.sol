// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Mock ERC-8004 Agent Card
/// @notice Minimal mock contract inspired by the ERC-8004 "Trustless Agents" proposal
///         used to register, update and execute simple agent tasks for testing.
///         This is NOT a production implementation of ERC-8004.
interface IERC8004Minimal {
    /// @dev Emitted when a new agent is registered
    event AgentRegistered(uint256 indexed agentId, address indexed owner, string metadataURI);

    /// @dev Emitted when agent metadata is updated
    event AgentMetadataUpdated(uint256 indexed agentId, string metadataURI);

    /// @dev Emitted when agent state is updated
    event AgentStateUpdated(uint256 indexed agentId, bytes32 newStateHash);

    /// @dev Emitted when an agent is activated/deactivated
    event AgentStatusChanged(uint256 indexed agentId, bool active);

    /// @dev Emitted when an agent executes with given payload
    event AgentExecuted(uint256 indexed agentId, bytes payload, bytes32 resultHash);
}

contract AgentCard8004 is IERC8004Minimal {
    struct Agent {
        address owner;
        string metadataURI; // off-chain definition / capabilities description
        bytes32 stateHash;  // opaque hash representing agent state snapshot
        bool active;
    }

    uint256 private nextAgentId;
    mapping(uint256 => Agent) private agents;

    error NotAgentOwner();
    error InvalidAgent();

    modifier onlyOwner(uint256 agentId) {
        if (agents[agentId].owner != msg.sender) revert NotAgentOwner();
        _;
    }

    /// @notice Register a new agent card
    /// @param metadataURI URI describing the agent (model, capabilities, policies)
    /// @return agentId Newly created agent identifier
    function registerAgent(string calldata metadataURI) external returns (uint256 agentId) {
        agentId = ++nextAgentId;
        agents[agentId] = Agent({
            owner: msg.sender,
            metadataURI: metadataURI,
            stateHash: bytes32(0),
            active: true
        });
        emit AgentRegistered(agentId, msg.sender, metadataURI);
    }

    /// @notice Update agent metadata URI
    function updateMetadata(uint256 agentId, string calldata newURI) external onlyOwner(agentId) {
        if (agents[agentId].owner == address(0)) revert InvalidAgent();
        agents[agentId].metadataURI = newURI;
        emit AgentMetadataUpdated(agentId, newURI);
    }

    /// @notice Update agent state by supplying an arbitrary payload which is hashed on-chain
    /// @dev In a real implementation this could be the result of off-chain inference/proofs
    function updateState(uint256 agentId, bytes calldata opaqueStatePayload) external onlyOwner(agentId) {
        if (agents[agentId].owner == address(0)) revert InvalidAgent();
        bytes32 newHash = keccak256(opaqueStatePayload);
        agents[agentId].stateHash = newHash;
        emit AgentStateUpdated(agentId, newHash);
    }

    /// @notice Activate or deactivate an agent
    function setActive(uint256 agentId, bool active) external onlyOwner(agentId) {
        if (agents[agentId].owner == address(0)) revert InvalidAgent();
        agents[agentId].active = active;
        emit AgentStatusChanged(agentId, active);
    }

    /// @notice Execute agent with an arbitrary payload
    /// @dev This mock simply hashes the input as a stand-in for real execution
    /// @return resultHash Keccak hash of (agentId, payload, blockhash)
    function execute(uint256 agentId, bytes calldata payload) external returns (bytes32 resultHash) {
        Agent memory a = agents[agentId];
        if (a.owner == address(0)) revert InvalidAgent();
        require(a.active, "AGENT_INACTIVE");

        // Mock execution: derive a deterministic-ish result hash
        resultHash = keccak256(abi.encode(agentId, payload, block.prevrandao, block.timestamp));
        emit AgentExecuted(agentId, payload, resultHash);
    }

    // ----- Views -----

    function getAgent(uint256 agentId)
        external
        view
        returns (address owner, string memory metadataURI, bytes32 stateHash, bool active)
    {
        Agent memory a = agents[agentId];
        if (a.owner == address(0)) revert InvalidAgent();
        return (a.owner, a.metadataURI, a.stateHash, a.active);
    }

    function ownerOf(uint256 agentId) external view returns (address) {
        address o = agents[agentId].owner;
        if (o == address(0)) revert InvalidAgent();
        return o;
    }

    function totalAgents() external view returns (uint256) {
        return nextAgentId;
    }
}


