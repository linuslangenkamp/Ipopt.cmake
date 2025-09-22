# Building latest Ipopt 3.14.19 + MUMPS 5.8.1 with CMake

Coin-OR Ipopt repository: [coin-or/Ipopt](https://github.com/coin-or/Ipopt.git)

This CMake version is forked from: [rjodon/coinor-ipopt-with-cmake](https://github.com/rjodon/coinor-ipopt-with-cmake.git)

This repository is still work in progress. You are welcome to open pull requests with fixes / updates, thank you!

---

## How to use

Create a build directory:
```bash
mkdir build && cd build
```

Run CMake configure (the default options should work out):
```bash
cmake .. <Options>
```

### Note:
The default configuration requires **LAPACK** and **Metis** to be available on your system.
It will automatically build and install MUMPS and Ipopt.

### Available CMake Options

You can generate the full table of all options with:
```bash
grep -R --include=CMakeLists.txt --include=\*.cmake "^[[:space:]]*option(" . \
  | sed -E 's/.*option[[:space:]]*\(([A-Za-z0-9_]+)[[:space:]]+"([^"]+)"[[:space:]]+([A-Z]+)\).*/|\1|\2|\3|/' \
  | column -t -s '|'
```

### Note:
Most options are untested for now!

### Build

Compile everything with
```bash
cmake --build . --parallel <Nr. of Cores>
```