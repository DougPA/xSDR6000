# xSDR6000 v3


![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)


## Mac Client for the FlexRadio (TM) 6000 series software defined radios.

### Built on:
*  ![MacOS](https://img.shields.io/badge/macOS-10.14.6-orange.svg?style=flat)
*  ![Xcode](https://img.shields.io/badge/Xcode-10.13(10G8)-orange.svg?style=flat)
*  ![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat)



## Usage

![Flex](https://img.shields.io/badge/Flex_Version-v2.5.x-blue.svg)


## This is my initial work on the v3 API, it is not fully tested and is only compatible with Flex v2.5.x Radios. 

Please see the v2 Branch of this repo for a version that is compatible with pre-v2.5.x Radios.
A Future version of this library will support all Radio versions.

Flex Radios can have one of four different version groups:
*  v1.x.x, the v1 API
*  v2.0.x thru v2.4.9, the v2 API <<-- supported by the v2 branch
*  v2.5.1 to less than v3.0.0, the v3 API without MultiFlex <<-- supported by this branch
*  v3.x.x, the v3 API with MultiFlex



If you want to learn more about the 6000 series API using a simple app, please click the following:

[![xAPITester](https://img.shields.io/badge/K3TZR-xAPITester-informational)]( https://github.com/DougPA/xAPITester)


If you require a Mac version of DAX and/or CAT, please click the following:

[![DL3LSM](https://img.shields.io/badge/DL3LSM-xDAX,_xCAT-informational)](https://dl3lsm.blogspot.com)

If you require a Mac-based Voice Keyer , please see.
(works with xSDR6000 on macOS or SmartSDR on Windows)

[![W6OP](https://img.shields.io/badge/W6OP-Voice_Keyer-informational)](https://w6op.com)


## Builds

Periodically I will create a compiled RELEASE build and place it in the GitHub Release.  

If you require a DEBUG build you will have to build from sources.   


## Comments / Questions

douglas.adams@me.com


## Credits

[![CocoaAsyncSocket](https://img.shields.io/badge/CocoaAsyncSocket-v7.6.3-informational)](https://github.com/robbiehanson/CocoaAsyncSocket)

CocoaAsyncSocket is embedded in this project as source code. It provides TCP and UDP connectivity.

[![SwiftyUserDefaults](https://img.shields.io/badge/SwiftyUserDefaults-_-informational)](https://github.com/radex/SwiftyUserDefaults)

SwiftyUserDefaults is included in this project as a framework. It provides easy access to User Defaults.

[![Opus](https://img.shields.io/badge/Opus-_-informational)](https://opus-codec.org/downloads/)

Opus is included in this project as a framework. It is used to encode / decode compressed audio.

[![xLib6000](https://img.shields.io/badge/K3TZR-xLib6000-informational)](https://github.com/DougPA/xLib6000)

xLib6000 is included in this project as a framework. It provides the API to the Flex 6000 radios.


## Known Issues

Please see ChangeLog.txt for a running list of changes  and KnownIssues.md for a list of the known issues.

Please report any bugs you observe to douglas.adams@me.com


