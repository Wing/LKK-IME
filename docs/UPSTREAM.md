# Upstream and porting scope

Baseline: [YahooArchive/KeyKey](https://github.com/YahooArchive/KeyKey), commit `81e05f070c070af65cac21e8da28ca4ff2d58905`, source version 1.1.2528.

This is a curated import of the official macOS source, rather than a fork of the historical repository containing unrelated platforms, commercial dependency placeholders, legacy data, and Yahoo branding.

The port builds the original `Takao (Loader OSX-IMK)` target and retains its C++, Objective-C and Objective-C++ modules, candidate views and XIB layouts. Compatibility changes address ARM64/compiler types, the original XIB archive format, system SQLite, retired services, independent bundle identifiers, local-only candidate clicks, and the original phrase editor's SQLite import/export format.

The original language model, licensed commercial SQLite extensions, and original mixed-origin conversion dictionaries are not distributed. See [third-party notices](THIRD-PARTY-NOTICES.md) for the replacement data and provenance.

The bundled LKK icon is an independent development placeholder; its local generator is `Resources/IconTool.m`.
