# xLib6000 v3

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)


## Mac implementation of the FlexRadio (TM) series 6000 API (FlexLib)

### Built on:
*  ![MacOS](https://img.shields.io/badge/macOS-10.14.6-orange.svg?style=flat)
*  ![Xcode](https://img.shields.io/badge/Xcode-10.13(10G8)-orange.svg?style=flat)
*  ![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat)



## Usage

![Flex](https://img.shields.io/badge/Flex_Version-v2.5.x-blue.svg)


## This is my initial work on the v3 API, it is not fully tested and is only compatible with Flex v2.5.x Radios. I'm in the process of moving 350 miles so I won't be doing much with this for the next 60 days or so (until ~ October, 2019). I am very thankful for all of you who have tried this software and/or reported issues back to me. Please be patient, I'll be back after my move settles down.

Please see the v2 Branch of this repo for a version that is compatible with pre-v2.5.x Radios.
A Future version of this library will support all Radio versions.

Flex Radios can have one of four different version groups:
*  v1.x.x, the v1 API
*  v2.0.x thru v2.4.9, the v2 API <<-- supported by the v2 branch
*  v2.5.1 to less than v3.0.0, the v3 API without MultiFlex <<-- supported by this branch
*  v3.x.x, the v3 API with MultiFlex



This framework provides most of the capability of FlexLib but does not provide an identical  interface due to the  
differences between the Windows and macOS environments and system services.

The "xLib6000 Overview.pdf" file in the Documentation folder contains an overview of the structure of this framework  
and an explanation of the Tcp and Udp data flows.  

The following apps are all built on this framework:

If you want to learn more about the 6000 series API using a simple app, please click the following:

[![xAPITester](https://img.shields.io/badge/K3TZR-xAPITester-informational)]( https://github.com/DougPA/xAPITester)


For an example of a SmartSDR-like client for the Mac, please click the following:

[![xSDR6000](https://img.shields.io/badge/K3TZR-xSDR6000-informational)]( https://github.com/DougPA/xSDR6000)


If you require a Mac version of DAX and/or CAT, please click the following:

[![DL3LSM](https://img.shields.io/badge/DL3LSM-xDAX,_xCAT-informational)](https://dl3lsm.blogspot.com)


## Builds

Periodically I will create a compiled RELEASE build and place it in the GitHub Release.  

If you require a DEBUG build you will have to build from sources.   


## Comments / Questions

douglas.adams@me.com


## Credits

[![CocoaAsyncSocket](https://img.shields.io/badge/CocoaAsyncSocket-v7.6.3-informational)](https://github.com/robbiehanson/CocoaAsyncSocket)

 CocoaAsyncSocket is embedded in this project as source code. It provides TCP and UDP connectivity.


## Known Issues

Please see ChangeLog.txt for a running list of changes and KnownIssues.md for a list of the known issues.

Please reports any bugs you observe to douglas.adams@me.com
