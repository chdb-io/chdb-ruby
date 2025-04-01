
# Installation and Using chdb-ruby extensions

This document will help you install the `chdb-ruby` ruby gem. 

## Installation

### Compilation During Installation 

The gem will automatically compile native extensions during installation (`gem install`). Supported platforms are:

- `aarch64-linux` 
- `arm64-darwin` 
- `x86_64-linux`
- `x86_64-darwin`

The `chdb-ruby` gem does not provide a pure Ruby implementation. Installation will fail if your platform is unsupported.

## Runtime Dependencies

The `chdb-ruby` gem requires the `libchdb` C++ library as its core engine. The library will be automatically downloaded during installation. The extension uses `dlopen` to dynamically load the library. No manual configuration is required.

## Verify Installation
- Ruby:
    ```bash
    require 'chdb'
    ```
