# ``FoundationExtension``

Foundation-focused extensions covering decoding ergonomics, caching, and targeted type helpers.

## Overview

FoundationExtension adds higher-level helpers around decoding, caching, and common Foundation types. It is intentionally modular: use it when you need safer decoding, lightweight caches, or convenience APIs on Foundation primitives like `Decoder`, `JSONDecoder`, `UserDefaults`, and `Data`.

## Topics

### Lossy Decoding

- ``Lossy``
- ``LossyDecodingReporter``
- ``NoopLossyReporter``

### Caching

- ``Cache``
- ``ObjectCache``

### Coding Utilities

- ``AnyCodingKey``
- ``JSONCoding``
- ``JSONCodingError``

### Binary Representation

- ``BinaryRepresentable``
- ``SafeBinaryRepresentable``
- ``BinaryRepresentableCollection``

### Localization

- ``LocalizationDictionary``
- ``LanguageCodeKey``
- ``LocalizedStringValue``

### Guides

- <doc:LossyDecodingAndCaching>
- <doc:BinaryBufferIO>
- <doc:JSONCodingGuide>
