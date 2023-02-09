# zk-circuits-artifacts
Scripts to compile circuits, generate the trusted setup, generate solidity smart contract verifier, etc.

Scripts for OVOTE (Offchain Voting with Onchain Trustless Execution) & OAV (Onchain Anonymous Voting) from https://github.com/aragonzkresearch/ovote . More details on the schemes at [ovote.pdf](https://github.com/aragonzkresearch/research/blob/main/ovote/ovote.pdf).

- Run `install-circom.sh`
- For OVOTE trusted setup: `ovote-gen-dev-artifacts.sh`
- For OAV trusted setup: `oav-gen-dev-artifacts.sh`
- Dev env files will be generated at `{ovote/oav}/dev` dir.

