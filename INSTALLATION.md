
# Installation and Using chdb-ruby extensions

This document will help you install the `chdb-ruby` ruby gem. 

## Installation

### Native Gems 

Native (precompiled) gems are available for recent Ruby versions on these platforms:

- `aarch64-linux` 
- `arm64-darwin` 
- `x86_64-linux`
- `x86_64-darwin`

If you are using one of these Ruby versions on one of these platforms, the native gem is the recommended way to install chdb-ruby.

`chdb-ruby` gem does not provide a pure Ruby implementation. Installation will fail if your platform is unsupported.

## Post-Installation: Setting Up libchdb C++ Library

After installing the `chdb-ruby` gem, you must also install the `libchdb` C++ library locally. If the library path is not in your system's default search paths, you'll need to configure the runtime library loading path.

### 1. Download the C++ Library

You can either:
- Use the automated installation script:
  ```bash
  curl -sSL https://github.com/chdb-io/chdb-io.github.io/blob/main/install_libchdb.sh | bash
  ```
  
- Or manually download from chdb releases(example for arm64-darwin (v3.12)):
  ```bash
  wget https://github.com/chdb-io/chdb/releases/download/v3.12/macos-arm64-libchdb.tar.gz
  tar -xzf macos-arm64-libchdb.tar.gz
  ```

### 2. Configure Library Path
- MacOS:
    ```bash
    export DYLD_LIBRARY_PATH="/path/to/libchdb:$DYLD_LIBRARY_PATH"
    ```
  (Add to your shell config file like ~/.zshrc for persistence)

- Linux:
    ```bash
    export LD_LIBRARY_PATH="/path/to/libchdb:$LD_LIBRARY_PATH"
    ```

### 3. Verify Installation
- Ruby:
    ```bash
    require 'chdb'
    ```

- Troubleshooting(If you get "Library not loaded" errors):
  - Verify the path in DYLD_LIBRARY_PATH/LD_LIBRARY_PATH is correct
  - Ensure you downloaded the right version for your platform
