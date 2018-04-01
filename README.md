# xSDR6000
## Mac Client for the FlexRadio (TM) 6000 series software defined radios.
### Provides functionality similar to the FlexRadio (TM) SmartSDR (TM) app.

Built on macOS 10.13.4 using XCode 9.3 using Swift 4.1 with a Deployment
Target of macOS 10.11

There is now only one Branch (master), it REQUIRES Metal.

==========================================================================

NOTE: This app is a "work in progress" and is not fully functional.

Portions of this app do not work and changes may be added from time to time
which will break all or part of this app. Releases will be created at
relatively stable points, please use them.

Direct questions and/or comments to:  douglas.adams@me.com

==========================================================================

***** IMPORTANT NOTE *****
To compile this application, you must have
xLib6000.framework, SwiftyUserDefaults.framework, XCGLogger.framework,
ObjcExceptionBridging.framework, AudioLibrary.framework & OpusOSX.framework
in the same folder  as the xCode project file (xSDR6000.xcodeproj) ( i.e. in ${PROJECT_DIR} )

They must be built for the same version of Swift as you are currently using (4.1 in my case).

A DEBUG executable is contained in the Release if you would rather not build
from sources. It has the necessary frameworks embedded in it.

==========================================================================

FRAMEWORK CREDITS:

AudioLibrary: 

http://www.w7ay.net/site/Software/Audio%20Library/index.html

XCGLogger & ObjcExceptionBridging:

https://github.com/DaveWoodCom/XCGLogger

SwiftyUserDefaults:

https://github.com/radex/SwiftyUserDefaults

OpusOSX:

https://opus-codec.org/downloads/

xLib6000:

https://github.com/DougPA/xLib6000
