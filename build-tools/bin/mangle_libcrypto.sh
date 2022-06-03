#!/bin/bash
# Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set -ex

LIBCRYPTO_DIRECTORY=$1
LIBCRYPTO_DIRECTORY=${LIBCRYPTO_DIRECTORY%/} # Remove trailing "/" if present
SYMBOL_PREFIX=$2
ACCP_SHARED_OBJECT="libamazonCorrettoCryptoProvider.so"
ACCP_LOADER_SHARED_OBJECT="libaccpLcLoader.so"
LIBCRYPTO_SHARED_OBJECT="libcrypto.so"
SYMBOL_REDEFINITION_FILE="libcrypto.symbol_redefinitions"

echo "Mangling LibCrypto..."

# Create a file that contains all libcrypto symbol redefinitions.
# Each line in this file contains the original symbol name, and the new symbol name separated by a space.
nm ${LIBCRYPTO_DIRECTORY}/${LIBCRYPTO_SHARED_OBJECT} | awk '/ [T|t] /{print $3" '${SYMBOL_PREFIX}'"$3}' | sort | uniq > ${LIBCRYPTO_DIRECTORY}/${SYMBOL_REDEFINITION_FILE}


# Keep a copy of the original shared objects for comparison
cp ${LIBCRYPTO_DIRECTORY}/${ACCP_SHARED_OBJECT} ${LIBCRYPTO_DIRECTORY}/original-${ACCP_SHARED_OBJECT}
cp ${LIBCRYPTO_DIRECTORY}/${ACCP_LOADER_SHARED_OBJECT} ${LIBCRYPTO_DIRECTORY}/original-${ACCP_LOADER_SHARED_OBJECT}
cp ${LIBCRYPTO_DIRECTORY}/${LIBCRYPTO_SHARED_OBJECT} ${LIBCRYPTO_DIRECTORY}/original-${LIBCRYPTO_SHARED_OBJECT}


# Now, mangle the symbol names in each shared library object using the redefinition file
objcopy --redefine-syms=${LIBCRYPTO_DIRECTORY}/${SYMBOL_REDEFINITION_FILE} ${LIBCRYPTO_DIRECTORY}/${ACCP_SHARED_OBJECT}
objcopy --redefine-syms=${LIBCRYPTO_DIRECTORY}/${SYMBOL_REDEFINITION_FILE} ${LIBCRYPTO_DIRECTORY}/${ACCP_LOADER_SHARED_OBJECT}
objcopy --redefine-syms=${LIBCRYPTO_DIRECTORY}/${SYMBOL_REDEFINITION_FILE} ${LIBCRYPTO_DIRECTORY}/${LIBCRYPTO_SHARED_OBJECT}


# Add the prefix to the libcrypto.so filename as well
# mv ${LIBCRYPTO_DIRECTORY}/${LIBCRYPTO_SHARED_OBJECT} ${LIBCRYPTO_DIRECTORY}/${LIBCRYPTO_SHARED_OBJECT}


echo "Mangling Complete..."
