#!/bin/sh

# Script to generate the dev-enviorment circuit-artifacts files (compile & trusted setup)

date
npm install
date

SNARKJS=./node_modules/.bin/snarkjs 
BUILD=build
POWERSOFTAU=powersoftau
DEVINFOFILE=oav/dev/circuits-info.md

powers_of_tau() {
	echo "computing powers_of_tau"
	mkdir $POWERSOFTAU
	itime="$(date -u +%s)"
	$SNARKJS powersoftau new bn128 21 $POWERSOFTAU/pot_0000.ptau -v
	$SNARKJS powersoftau contribute $POWERSOFTAU/pot_0000.ptau $POWERSOFTAU/pot_0001.ptau --name=contribution -v -e=random
	$SNARKJS powersoftau beacon $POWERSOFTAU/pot_0001.ptau $POWERSOFTAU/pot_beacon.ptau 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n=Final
	$SNARKJS powersoftau prepare phase2 $POWERSOFTAU/pot_beacon.ptau $POWERSOFTAU/pot_final.ptau -v
	$SNARKJS powersoftau verify $POWERSOFTAU/pot_final.ptau
	ftime="$(date -u +%s)"
	echo "powers_of_tau done in ($(($(date -u +%s)-$itime))s)"
}

compile_and_ts() {
	CIRCUITCODE="pragma circom 2.0.0;
	include \"../../../node_modules/ovote/circuits/src/oav.circom\";
	component main {public [chainID, processID, censusRoot, weight, nullifier, vote]} = oav($NLEVELS);"

	mkdir -p $CIRCUITPATH/$BUILD
	echo "$CIRCUITCODE" > $CIRCUITPATH/circuit.circom

	# reuse already computed powers of tau
	cp $POWERSOFTAU/pot_final.ptau $CIRCUITPATH/$BUILD/pot_final.ptau


	# compile circuit
	echo "compiling the circuit"
	itime="$(date -u +%s)"
	circom $CIRCUITPATH/circuit.circom --c --r1cs --wasm --sym
	mv circuit.* $CIRCUITPATH/$BUILD/
	mv circuit_js $CIRCUITPATH/
	mv circuit_cpp $CIRCUITPATH/

	ftime="$(date -u +%s)"
	echo "circuit compiled in ($(($(date -u +%s)-$itime))s)"
	mv $CIRCUITPATH/circuit_js/circuit.wasm $CIRCUITPATH/circuit.wasm

	# compute trusted setup
	echo "computing the trusted setup"
	itime="$(date -u +%s)"
	$SNARKJS zkey new $CIRCUITPATH/$BUILD/circuit.r1cs $CIRCUITPATH/$BUILD/pot_final.ptau $CIRCUITPATH/$BUILD/circuit_0000.zkey
	$SNARKJS zkey contribute $CIRCUITPATH/$BUILD/circuit_0000.zkey $CIRCUITPATH/$BUILD/circuit_0001.zkey --name=contributor -v -e=random2
	$SNARKJS zkey verify $CIRCUITPATH/$BUILD/circuit.r1cs $CIRCUITPATH/$BUILD/pot_final.ptau $CIRCUITPATH/$BUILD/circuit_0001.zkey
	$SNARKJS zkey beacon $CIRCUITPATH/$BUILD/circuit_0001.zkey $CIRCUITPATH/circuit.zkey 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n=Final
	$SNARKJS zkey verify $CIRCUITPATH/$BUILD/circuit.r1cs $CIRCUITPATH/$BUILD/pot_final.ptau $CIRCUITPATH/circuit.zkey
	$SNARKJS zkey export verificationkey $CIRCUITPATH/circuit.zkey $CIRCUITPATH/verification_key.json
	ftime="$(date -u +%s)"
	echo "trusted setup done in ($(($(date -u +%s)-$itime))s)"

	echo "generate solidityverifier"
	$SNARKJS zkey export solidityverifier $CIRCUITPATH/circuit.zkey $CIRCUITPATH/verifier.sol

	# store circuit info
	echo "\n\n" >> $DEVINFOFILE
	echo "## Circuit $CIRCUITPATH ($NLEVELS levels)\n" >> $DEVINFOFILE
	$SNARKJS r1cs info $CIRCUITPATH/$BUILD/circuit.r1cs >> $DEVINFOFILE
}

compute_hashes() {
	echo "\n## circuit: $NAME ($NLEVELS nLevels) file hashes (sha256) " >> $DEVINFOFILE
	echo "\`\`\`" >> $DEVINFOFILE
	sha256sum $CIRCUITPATH/circuit.zkey >> $DEVINFOFILE
	sha256sum $CIRCUITPATH/circuit.wasm >> $DEVINFOFILE
	sha256sum $CIRCUITPATH/verification_key.json >> $DEVINFOFILE
	sha256sum $CIRCUITPATH/verifier.sol >> $DEVINFOFILE
	echo "\`\`\`" >> $DEVINFOFILE
}

date
if [ -d "$POWERSOFTAU" ]; then
	echo "powers of tau already exist, avoid computing it"
else
	echo "powers of tau does not exist, compute it"
	powers_of_tau
fi
date

echo "# dev env circuits artifacts" > $DEVINFOFILE

NLEVELS=4
NAME=$NLEVELS
CIRCUITPATH=oav/dev/$NAME
echo "compile_and_ts() of $CIRCUITPATH"
compile_and_ts
compute_hashes

date

NLEVELS=10
NAME=$NLEVELS
CIRCUITPATH=oav/dev/$NAME
echo "compile_and_ts() of $CIRCUITPATH"
compile_and_ts
compute_hashes

date

NLEVELS=16
NAME=$NLEVELS
CIRCUITPATH=oav/dev/$NAME
echo "compile_and_ts() of $CIRCUITPATH"
compile_and_ts
compute_hashes

date
