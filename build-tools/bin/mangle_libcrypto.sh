#!/bin/bash
# Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set -ex

LIBCRYPTO_DIRECTORY=$1
LIBCRYPTO_DIRECTORY=${LIBCRYPTO_DIRECTORY%/} # Remove trailing "/" if present
SYMBOL_PREFIX=$2
MANGLE_IGNORE_LIST=$3

ACCP_SHARED_OBJECT="libamazonCorrettoCryptoProvider.so"
ACCP_LOADER_SHARED_OBJECT="libaccpLcLoader.so"
LIBCRYPTO_SHARED_OBJECT="libcrypto.so"
RAW_SYMBOLS_FILE="libcrypto.raw_symbols"
SYMBOLS_FILE="libcrypto.symbols"
REDEFINITION_FILE="libcrypto.redefinitions"

echo "Mangling LibCrypto..."

# Create a file that contains all libcrypto symbols that we plan to redefine
# For nm, we only care about symbols libcrypto exposes externally to other libraries, since internal symbols do not cause collisions
# Next, we use awk to retrieve only the .data and .text symbols that are global with "[D|T|W]" (uppercase letters are global, lowercase are local)
nm --extern-only ${LIBCRYPTO_DIRECTORY}/${LIBCRYPTO_SHARED_OBJECT} | awk '/ [D|T|W] /{print $3}' | LC_ALL=C sort | uniq > ${LIBCRYPTO_DIRECTORY}/${RAW_SYMBOLS_FILE}


# Remove symbols that are in the symbol ignore list from the list of symbols that we plan to mangle
command grep --line-regexp --invert-match --file=${MANGLE_IGNORE_LIST} ${LIBCRYPTO_DIRECTORY}/${RAW_SYMBOLS_FILE} > ${LIBCRYPTO_DIRECTORY}/${SYMBOLS_FILE}
diff --from-file=${LIBCRYPTO_DIRECTORY}/${RAW_SYMBOLS_FILE} --to-file=${LIBCRYPTO_DIRECTORY}/${SYMBOLS_FILE} | colordiff


# Create the symbol redefinition file. Each line contains an original symbol name, a space, and the new symbol name
cat ${LIBCRYPTO_DIRECTORY}/${SYMBOLS_FILE} | awk '{printf "%s '${SYMBOL_PREFIX}'%s\n", $1, $1}' > ${LIBCRYPTO_DIRECTORY}/${REDEFINITION_FILE}


# (Optional) Keep a copy of the original shared objects for debugging purposes
#cp ${LIBCRYPTO_DIRECTORY}/${ACCP_SHARED_OBJECT} ${LIBCRYPTO_DIRECTORY}/original-${ACCP_SHARED_OBJECT}
#cp ${LIBCRYPTO_DIRECTORY}/${ACCP_LOADER_SHARED_OBJECT} ${LIBCRYPTO_DIRECTORY}/original-${ACCP_LOADER_SHARED_OBJECT}
#cp ${LIBCRYPTO_DIRECTORY}/${LIBCRYPTO_SHARED_OBJECT} ${LIBCRYPTO_DIRECTORY}/original-${LIBCRYPTO_SHARED_OBJECT}


# Now, mangle the shared library objects in place using the symbol redefinition file
objcopy --redefine-syms=${LIBCRYPTO_DIRECTORY}/${REDEFINITION_FILE} ${LIBCRYPTO_DIRECTORY}/${ACCP_SHARED_OBJECT}
objcopy --redefine-syms=${LIBCRYPTO_DIRECTORY}/${REDEFINITION_FILE} ${LIBCRYPTO_DIRECTORY}/${ACCP_LOADER_SHARED_OBJECT}
objcopy --redefine-syms=${LIBCRYPTO_DIRECTORY}/${REDEFINITION_FILE} ${LIBCRYPTO_DIRECTORY}/${LIBCRYPTO_SHARED_OBJECT}


# Ensure the Libcrypto object has the executable bit set
chmod +x ${LIBCRYPTO_DIRECTORY}/${LIBCRYPTO_SHARED_OBJECT}

# Add the prefix to the libcrypto.so filename as well
mv ${LIBCRYPTO_DIRECTORY}/${LIBCRYPTO_SHARED_OBJECT} ${LIBCRYPTO_DIRECTORY}/accp_private_${LIBCRYPTO_SHARED_OBJECT}


echo "Mangling Complete..."
