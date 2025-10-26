// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Mock ERC-8004 Agent Card (Agent2)
/// @notice Minimal mock contract inspired by the ERC-8004 proposal for testing.
interface IERC8004Minimal {
    event AgentRegistered(uint256 indexed agentId, address indexed owner, string metadataURI);
    event AgentMetadataUpdated(uint256 indexed agentId, string metadataURI);
    event AgentStateUpdated(uint256 indexed agentId, bytes32 newStateHash);
    event AgentStatusChanged(uint256 indexed agentId, bool active);
    event AgentExecuted(uint256 indexed agentId, bytes payload, bytes32 resultHash);
}

contract AgentCard8004 is IERC8004Minimal {
    struct Agent {
        address owner;
        string metadataURI;
        bytes32 stateHash;
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

    function registerAgent(string calldata metadataURI) external returns (uint256 agentId) {
        agentId = ++nextAgentId;
        agents[agentId] = Agent({ owner: msg.sender, metadataURI: metadataURI, stateHash: bytes32(0), active: true });
        emit AgentRegistered(agentId, msg.sender, metadataURI);
    }

    function updateMetadata(uint256 agentId, string calldata newURI) external onlyOwner(agentId) {
        if (agents[agentId].owner == address(0)) revert InvalidAgent();
        agents[agentId].metadataURI = newURI;
        emit AgentMetadataUpdated(agentId, newURI);
    }

    function updateState(uint256 agentId, bytes calldata opaqueStatePayload) external onlyOwner(agentId) {
        if (agents[agentId].owner == address(0)) revert InvalidAgent();
        bytes32 newHash = keccak256(opaqueStatePayload);
        agents[agentId].stateHash = newHash;
        emit AgentStateUpdated(agentId, newHash);
    }

    function setActive(uint256 agentId, bool active) external onlyOwner(agentId) {
        if (agents[agentId].owner == address(0)) revert InvalidAgent();
        agents[agentId].active = active;
        emit AgentStatusChanged(agentId, active);
    }

    function execute(uint256 agentId, bytes calldata payload) external returns (bytes32 resultHash) {
        Agent memory a = agents[agentId];
        if (a.owner == address(0)) revert InvalidAgent();
        require(a.active, "AGENT_INACTIVE");
        resultHash = keccak256(abi.encode(agentId, payload, block.prevrandao, block.timestamp));
        emit AgentExecuted(agentId, payload, resultHash);
    }

    function getAgent(uint256 agentId)
        external
        view
        returns (address owner, string memory metadataURI, bytes32 stateHash, bool active)
    {
        Agent memory a = agents[agentId];
        if (a.owner == address(0)) revert InvalidAgent();
        return (a.owner, a.metadataURI, a.stateHash, a.active);
    }
}


