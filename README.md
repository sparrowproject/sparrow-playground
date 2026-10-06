# Sparrow Playground

Trying out some ideas with Swift!

## Project overview
This repository contains [SparrowUI](SparrowUI), a cross-platform UI toolkit, currently
supporting macOS and Windows native apps built using Swift.

SparrowUI is a reactive framework built mostly on top of lower level compositor
primitives, CALayer on macOS and Composition Visuals on Windows.

SparrowUI resembles SwiftUI in many ways, but importantly is a bit simpler than SwiftUI.
Instead of maintaining a virtual DOM, the underlying compositor primitives are directly
updated in response to `@Observable` expressions changing value.

[SparrowUIDemo](SparrowUIDemo) is a simple gallery style demo app, showcasing the
framework.

[SparrowBrowser](SparrowBrowser) is a more full featured web browser, intended to put
the framework to the test.

## Build environment setup

### macOS

1. Make sure you have Xcode 26.4 (or later) installed along with the command line tools.
2. Install CMake & Ninja:
```
  $ brew install cmake
  $ brew install ninja
```

### Windows

More steps. TODO: Enumerate them here :-D

## Build commands

Debug:
```
  $ cmake -S . -B build-debug -G Ninja -DCMAKE_BUILD_TYPE=Debug`
  $ cmake --build build-debug --target SparrowUIDemo`
  $ cmake --build build-debug --target SparrowBrowser`
```

Release:
```
  $ cmake -S . -B build-release -G Ninja -DCMAKE_BUILD_TYPE=Release`
  $ cmake --build build-release --target SparrowUIDemo`
  $ cmake --build build-release --target SparrowBrowser`
```

## Run the apps

### macOS

Debug:
```
  $ ./build-debug/SparrowUIDemo/SparrowUIDemo.app/Contents/MacOS/SparrowUIDemo
  $ ./build-debug/SparrowBrowser/Sources/SparrowBrowser/SparrowBrowser.app/Contents/MacOS/SparrowBrowser
```

Release, macOS:
```
  $ ./build-debug/SparrowUIDemo/SparrowUIDemo.app/Contents/MacOS/SparrowUIDemo
  $ ./build-debug/SparrowBrowser/Sources/SparrowBrowser/SparrowBrowser.app/Contents/MacOS/SparrowBrowser
```

### Windows

Debug:
```
  $ ./build-debug/SparrowUIDemo/SparrowUIDemo.exe
  $ ./build-debug/SparrowBrowser/Sources/SparrowBrowser/SparrowBrowser.exe
```

Release, macOS:
```
  $ ./build-release/SparrowUIDemo/SparrowUIDemo.exe
  $ ./build-release/SparrowBrowser/Sources/SparrowBrowser/SparrowBrowser.exe
```

## License

This code is released under the MIT license. See [LICENSE](LICENSE) for details.