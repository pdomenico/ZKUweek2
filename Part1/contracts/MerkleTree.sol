//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {PoseidonT3} from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract
import "hardhat/console.sol";

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves
        // A 3 level 8 elements merkle tree has 15 total hashes (2^3 + 2^2 + 2^1 + 2^0)
        hashes = new uint[](15);
        uint[2] memory input;
        for (uint i = 0; i < 15; i++) {
            if (i < 8) {
                hashes[i] = 0;
            } else {
                input[0] = hashes[(i - 8) * 2];
                input[1] = hashes[((i - 8) * 2) + 1];
                hashes[i] = PoseidonT3.poseidon(input);
            }
        }
        root = hashes[14];
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        require(index < 8, "Merkle tree is full!");

        hashes[index] = hashedLeaf;
        uint[2] memory input;
        for (uint256 i = index; i < 14; ) {
            if (i % 2 == 0) {
                input[0] = hashes[i];
                input[1] = hashes[i + 1];
                hashes[(i / 2) + 8] = PoseidonT3.poseidon(input);
                i = (i / 2) + 8;
            } else {
                input[0] = hashes[i - 1];
                input[1] = hashes[i];
                hashes[((i - 1) / 2) + 8] = PoseidonT3.poseidon(input);
                i = ((i - 1) / 2) + 8;
            }
        }
        index++;
        root = hashes[14];
        return root;
    }

    function verify(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public view returns (bool) {
        // [assignment] verify an inclusion proof and check that the proof root matches current root
        bool zkProof = verifyProof(a, b, c, input);
        bool rootEqual = input[0] == root;
        return zkProof && rootEqual;
    }
}
