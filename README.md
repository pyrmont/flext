# Flext

Flext is an iOS app for transforming text. It provides a set of built-in
'processors' for performing common transformations and allows the user to add
their own processors.

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
$ cd flext
$ open Flext.xcodeproj
```

## Dependencies

Flext depends on [Down][], a CommonMark renderer built atop cmark.

[Down]: https://github.com/johnxnguyen/Down

## Bugs

Found a bug? I'd love to know about it. It really helps to report bugs in the
[Issues section][ghi] on GitHub.

[ghi]: https://github.com/pyrmont/flext/issues

## Licence

The source code for Flext is released under the Apache Licence, Version 2.0.
See [LICENSE][lc] for more details.

[lc]: https://github.com/pyrmont/flext/blob/master/LICENSE

### Trade Marks

The rights in the 'FLEXT' mark and the 'FLEXT LOGO' mark are reserved and are
not covered by the licence. This means that while you're free to use the source
code to create your own version of the app (which you can even sell on the App
Store), you **cannot** do so using the 'FLEXT' mark and/or the 'FLEXT LOGO'
mark.
