pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
    component levelHash[n][(2**n)/2];
    for (var i = 0; i < n; i++) {
        for (var j = 0; j < ((2**n) / 2**(i+1)); j++) {
            levelHash[i][j] = Poseidon(2);
            if (i == 0) {
                levelHash[i][j].inputs[0] <== leaves[j*2];
                levelHash[i][j].inputs[1] <== leaves[j*2 + 1];
            } else {
                levelHash[i][j].inputs[0] <== levelHash[i-1][j*2].out;
                levelHash[i][j].inputs[1] <== levelHash[i-1][j*2 + 1].out;
            }
        }
    }
    root <== levelHash[n-1][0].out;
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    component hash[n];
    component mux[n][2];
    for (var i = 0; i < n; i++) {
        hash[i] = Poseidon(2);
        mux[i][0] = Mux1();
        mux[i][1] = Mux1();
        if (i == 0) {
            mux[i][0].c[0] <== leaf;
            mux[i][0].c[1] <== path_elements[i];
            mux[i][0].s <== path_index[i];

            mux[i][1].c[0] <== path_elements[i];
            mux[i][1].c[1] <== leaf;
            mux[i][1].s <== path_index[i];
            
            hash[i].inputs[0] <== mux[i][0].out;
            hash[i].inputs[1] <== mux[i][1].out;
        } else {
            mux[i][0].c[0] <== hash[i-1].out;
            mux[i][0].c[1] <== path_elements[i];
            mux[i][0].s <== path_index[i];

            mux[i][1].c[0] <== path_elements[i];
            mux[i][1].c[1] <== hash[i-1].out; 
            mux[i][1].s <== path_index[i];

            hash[i].inputs[0] <== mux[i][0].out;
            hash[i].inputs[1] <== mux[i][1].out;
        }
    }
    root <== hash[n-1].out;
}