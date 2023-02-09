#!/bin/sh

echo "generating witness (with WASM)"
time node ./circuit_js/generate_witness.js circuit.wasm zkinpjq.json witness.wtns

echo "generating proof (with rapidsnark)"
time ~/bin/prover circuit.zkey witness.wtns proof.json public.json
