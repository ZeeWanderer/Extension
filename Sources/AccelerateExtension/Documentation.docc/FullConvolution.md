# Full Convolution

Calculate every overlap between a signal and a finite kernel.

## Overview

Use `vDSP.fullConvolution(_:withKernel:)` when an algorithm needs the complete
linear-convolution result, including the partial overlaps at both boundaries.
The result contains `signal.count + kernel.count - 1` values.

```swift
import AccelerateExtension

let signal: [Float] = [1, 2, 3]
let kernel: [Float] = [1, 1]
let filtered = vDSP.fullConvolution(signal, withKernel: kernel)
// [1, 3, 5, 3]
```

Both `Float` and `Double` buffers are supported. Arrays, contiguous arrays,
array slices, and the other standard `AccelerateBuffer` conformers can be used
without first converting the inputs. If either input is empty, the result is
empty.

The boundary-padding approach is adapted from Surge's full convolution
implementation to use Apple's modern `AccelerateBuffer` API.
