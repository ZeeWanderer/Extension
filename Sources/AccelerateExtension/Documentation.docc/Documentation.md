# ``AccelerateExtension``

Focused conveniences built on Apple's Accelerate framework.

## Overview

AccelerateExtension adds higher-level operations where vDSP materially improves
large numeric-buffer workloads. Binary serialization remains in
`FoundationExtension`; this module uses `AccelerateBuffer` only as the input
contract for Accelerate algorithms and re-exports the relocated binary API for
source compatibility.

## Topics

### Digital Signal Processing

- <doc:FullConvolution>
