// Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package com.amazon.corretto.crypto.provider;

import java.util.function.ToLongBiFunction;
import java.security.KeyFactory;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.interfaces.DSAPrivateKey;
import java.security.interfaces.DSAPublicKey;
import java.security.interfaces.ECPrivateKey;
import java.security.interfaces.ECPublicKey;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;

import javax.crypto.interfaces.DHPrivateKey;
import javax.crypto.interfaces.DHPublicKey;

/**
 * Corresponds to native constants in OpenSSL which represent keytypes.
 */
enum EvpKeyType {
    RSA("RSA", 6, RSAPublicKey.class, RSAPrivateKey.class),
    DH("DH", 28, DHPublicKey.class, DHPrivateKey.class),
    DSA("DSA", 116, DSAPublicKey.class, DSAPrivateKey.class),
    EC("EC", 408, ECPublicKey.class, ECPrivateKey.class);

    final String jceName;
    final int nativeValue;
    final Class<? extends PublicKey> publicKeyClass;
    final Class<? extends PrivateKey> privateKeyClass;

    private EvpKeyType(
            final String jceName,
            final int nativeValue,
            final Class<? extends PublicKey> publicKeyClass,
            final Class<? extends PrivateKey> privateKeyClass) {
        this.jceName = jceName;
        this.nativeValue = nativeValue;
        this.publicKeyClass = publicKeyClass;
        this.privateKeyClass = privateKeyClass;
    }

    KeyFactory getKeyFactory() {
        try {
            return KeyFactory.getInstance(jceName, AmazonCorrettoCryptoProvider.INSTANCE);
        } catch (NoSuchAlgorithmException e) {
            throw new AssertionError("KeyFactory for " + jceName + " not available");
        }
    }

    PrivateKey buildPrivateKey(ToLongBiFunction<byte[], Integer> fn, PKCS8EncodedKeySpec der) {
        switch (this) {
            case RSA:
                throw new UnsupportedOperationException("Not yet written");
            case DH:
                return new EvpDhPrivateKey(fn.applyAsLong(der.getEncoded(), nativeValue));
            case DSA:
                return new EvpDsaPrivateKey(fn.applyAsLong(der.getEncoded(), nativeValue));
            case EC:
                return new EvpEcPrivateKey(fn.applyAsLong(der.getEncoded(), nativeValue));
            default:
                throw new AssertionError("Unsupported key type");
        }
    }

    PublicKey buildPublicKey(ToLongBiFunction<byte[], Integer> fn, X509EncodedKeySpec der) {
        switch (this) {
            case RSA:
                return new EvpRsaPublicKey(fn.applyAsLong(der.getEncoded(), nativeValue));
            case DH:
                return new EvpDhPublicKey(fn.applyAsLong(der.getEncoded(), nativeValue));
            case DSA:
                return new EvpDsaPublicKey(fn.applyAsLong(der.getEncoded(), nativeValue));
            case EC:
                return new EvpEcPublicKey(fn.applyAsLong(der.getEncoded(), nativeValue));
            default:
                throw new AssertionError("Unsupported key type");
        }
    }
}
