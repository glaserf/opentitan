// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_ATTESTATION_H_
#define OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_ATTESTATION_H_

#include "sw/device/silicon_creator/lib/error.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

enum {
  /**
   * Size of the additional seed for attestation key generation in bits.
   */
  kAttestationSeedBits = 320,
  /**
   * Size of the additional seed for attestation key generation in bytes.
   */
  kAttestationSeedBytes = kAttestationSeedBits / 8,
  /**
   * Size of the additional seed for attestation key generation in 32b words.
   */
  kAttestationSeedWords = kAttestationSeedBytes / sizeof(uint32_t),
  /**
   * Size of a coordinate for an attestation public key in bits.
   */
  kAttestationPublicKeyCoordBits = 256,
  /**
   * Size of a coordinate for an attestation public key in bytes.
   */
  kAttestationPublicKeyCoordBytes = kAttestationPublicKeyCoordBits / 8,
  /**
   * Size of a coordinate for an attestation public key in 32b words.
   */
  kAttestationPublicKeyCoordWords =
      kAttestationPublicKeyCoordBytes / sizeof(uint32_t),
  /**
   * Size of an attestation signature in bits.
   */
  kAttestationSignatureBits = 512,
  /**
   * Size of an attestation signature in bytes.
   */
  kAttestationSignatureBytes = kAttestationSignatureBits / 8,
  /**
   * Size of an attestation signature in 32b words.
   */
  kAttestationSignatureWords = kAttestationSignatureBytes / sizeof(uint32_t),
};

/**
 * Holds an additional seed for use in attestation key generation.
 */
typedef struct attestation_seed {
  uint32_t seed[kAttestationSeedWords];
} attestation_seed_t;

/**
 * Holds an attestation public key (ECDSA-P256).
 */
typedef struct attestation_public_key {
  /**
   * Affine x-coordinate of the point.
   */
  uint32_t x[kAttestationPublicKeyCoordWords];
  /**
   * Affine y-coordinate of the point.
   */
  uint32_t y[kAttestationPublicKeyCoordWords];
} attestation_public_key_t;

/**
 * Holds an attestation signature (ECDSA-P256).
 */
typedef struct attestation_signature {
  uint32_t sig[kAttestationSignatureWords];
} attestation_signature_t;

#ifdef __cplusplus
}  // extern "C"
#endif  // __cplusplus

#endif  // OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_ATTESTATION_H_
