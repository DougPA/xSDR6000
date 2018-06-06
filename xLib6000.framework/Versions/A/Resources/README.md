# xLib6000
## Mac implementation of the FlexRadio (TM) series 6000 software defined radios API (FlexLib)

### Built on:
*  macOS 10.13.5 (Deployment Target of macOS 10.10)
*  Xcode 9.4
*  Swift 4.1


**This version supports SmartLink (TM).**


## Usage

This framework provides most of the capability of FlexLib but does not provide an identical  interface due to the  
differences between the Windows and macOS environments and system services.

The "xLib6000 Overview.pdf" file in the Documentation folder contains an overview of the structure of this framework  
and an explanation of the Tcp and Udp data flows.  

If you want to learn more about the 6000 series API, please take a look at the xAPITester project. It uses this framework.

* https://github.com/DougPA/xAPITester

For an example of a SmartSDR-like client for the Mac, please take a look at the xSDR6000 project. It uses this framework.

* https://github.com/DougPA/xSDR6000

If you require a Mac version of DAX and/or CAT, please see.

* https://dl3lsm.blogspot.com


## Builds

A compiled DEBUG build executable is contained in the GitHub Release if you would rather not build from sources.  

If you require a RELEASE build you will have to build from sources.   


## Comments / Questions

douglas.adams@me.com


## Credits

Version 7.6.3 of CocoaAsyncSocket is embedded in this project as source code. It can be found on GitHub at:  

* https://github.com/robbiehanson/CocoaAsyncSocket


## Known Issues

* Opus streams are implemented but may not work and/or will generate errors on some Macs

Please reports any bugs you observe to douglas.adams@me.com
