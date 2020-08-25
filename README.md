# Flext

Flext is an iOS app for transforming text. It provides a set of built-in
'processors' for performing common transformations and allows the user to add
their own processors.

## Usage Rights

Flext will be offered for sale in the App Store but the code is made available
as open source.

Please note that the rights in the name 'FLEXT' and the 'FLEXT LOGO' are
reserved. This means that while you're free to use the source, **you cannot
distribute an app with the same name and logo**.

## Requirements

Flext is a Swift app written for the iOS platform. It includes binaries for
iPhone and iPad as well as an action extension.

Flext was developed against Xcode 11 and Swift 5. It targets iOS devices
running iOS 13.6 and higher.

## Setup

This repository contains the source code and Xcode project files necessary for
compiling the project.

```console
$ git clone git@github.com:pyrmont/flext.git
$ cd pondent
$ open Flext.xcodeproj
```

## Dependencies

Flext includes [Down][], a CommonMark renderer built atop cmark.

[Down]: https://github.com/iwasrobbed/Down

## Bugs

Found a bug? I'd love to know about it. It really helps to report bugs in the
[Issues section][ghi] on GitHub.

[ghi]: https://github.com/pyrmont/flext/issues

## Licence

The source code for Flext is released under a modified form of the 3-clause BSD
licence. See [LICENSE][lc] for more details.

[lc]: https://github.com/pyrmont/flext/blob/master/LICENSE
