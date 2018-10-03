# xSDR6000
## Mac Client for the FlexRadio (TM) 6000 series software defined radios.

### Built on:

v2.x.x:
*  macOS 10.14 (Deployment Target of macOS 10.12)
*  Xcode 10
*  Swift 4.2

Requires a v2 build of xLib6000


v1.x.x:
*  macOS 10.13.5 (Deployment Target of macOS 10.11)
*  Xcode 9.4
*  Swift 4.1

Requires a v1 build of xLib6000


**This version supports SmartLink (TM).**  
**It REQUIRES a Mac that supports Metal**  

## Usage

Provides functionality similar to the FlexRadio (TM) SmartSDR (TM) app.

**NOTE: This app is a "work in progress" and is not fully functional**  

Portions of this app do not work and changes may be added from time to time which will break all or part of this app.  
Releases will be created at relatively stable points, please use them.  


If you want to learn more about the 6000 series API, please take a look at the xLib6000 project. 

* https://github.com/DougPA/xLib6000

To explore the 6000 series API, please take a look at the xAPITester project.

* https://github.com/DougPA/xAPITester

If you require a Mac version of DAX and/or CAT, please see.

* https://dl3lsm.blogspot.com


## Builds

A compiled RELEASE build executable (with  embedded frameworks) is contained in the GitHub  
Release if you would rather not build from sources.  

If you require a DEBUG build you will have to build from sources. The required frameworks are   
contained in this repo.


## Comments / Questions

douglas.adams@me.com


## Credits

AudioLibrary:     Use in early v1.x.x only

* http://www.w7ay.net/site/Software/Audio%20Library/index.html

XCGLogger & ObjcExceptionBridging:      Used in v1.x.x only

* https://github.com/DaveWoodCom/XCGLogger

SwiftyUserDefaults:

* https://github.com/radex/SwiftyUserDefaults

OpusOSX:

* https://opus-codec.org/downloads/

xLib6000:

* https://github.com/DougPA/xLib6000


## Known Issues

* Although the side area will open/close, many / all of the side panels are not yet implemented
* CWX is not implemented
* Memories are not fully implemented

Please reports any bugs you observe to douglas.adams@me.com


