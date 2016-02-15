
Linphone is a free VoIP and video softphone based on the SIP protocol.

![Dialer screenshot](http://www.linphone.org/img/slideshow-phone.png)

# Getting started

Here's how to launch Linphone for iPhone (more details below):

1. Install [Xcode from AppStore](https://itunes.apple.com/us/app/Xcode/id497799835?mt=12#).
2. Install [HomeBrew, a package manager for OS X](http://brew.sh) (MacPorts is supported but deprecated).
3. Install Linphone dependencies: open iTerm.app in the current directory and list dependencies to install using:
 `./prepare.py`
4. Reorder your path so that brew tools are used instead of Apple's ones which are obsolete:
 `export PATH=/usr/local/bin:$PATH`
5. Build SDK (see below for options and explanations):
 `./prepare.py -c && ./prepare.py && make`
6. Open linphone.xcodeproj in Xcode: `open linphone.xcodeproj`
7. Press `⌘R` and voilà!

# Building the SDK

Linphone for iPhone depends on liblinphone SDK. This SDK is generated from makefiles and shell scripts.

 To generate the liblinphone multi-arch SDK in GPL mode, simply invoke:

        ./prepare.py [options] && make

**The resulting SDK is located in `liblinphone-sdk/` root directory.**

## Licensing: GPL third parties versus non GPL third parties

This SDK can be generated in 2 flavors:

* GPL third parties enabled means that liblinphone includes GPL third parties like FFmpeg or X264. If you choose this flavor, your final application **must comply with GPL in any case**. This is the default mode.

* NO GPL third parties means that Linphone will only use non GPL code except for `liblinphone`, `mediastreamer2`, `oRTP` and `belle-sip`. If you choose this flavor, your final application is **still subject to GPL except if you have a [commercial license for the mentioned libraries](http://www.belledonne-communications.com/products.html)**.
 To generate the liblinphone multi arch SDK without GPL third parties, invoke:

        ./prepare.py --disable-gpl-third-parties [other options] && make

## Customizing features

You can enable non-free codecs by using `--enable-non-free-codecs` and `-DENABLE_<codec>=ON`. To get a list of all features, the simplest way is to invoke `prepare.py` with `--list-features`:

        ./prepare.py --list-features

You can for instance enable X264 by using:
        ./prepare.py -DENABLE_X264=ON [other options]

## Built architectures

4 architectures currently exists on iOS:

- 64 bits ARM64 for iPhone 5s, iPad Air, iPad mini 2, iPhone 6, iPhone 6 Plus, iPad Air 2, iPad mini 3.
- 32 bits ARMv7 for older devices.
- 64 bits x86_64 for simulator for all ARM64 devices.
- 32 bits i386 for simulator for all ARMv7 older devices.

 Note: We are not compiling for the 32 bits i386 simulator by default because Xcode default device (iPhone 6) runs in 64 bits. If you want to enable it, you should invoke `prepare.py` with `i386` argument: `./prepare.py i386 [other options]`.

## Upgrading your iOS SDK

Simply re-invoking `make` should update your SDK. If compilation fails, you may need to rebuilding everything by invoking:

        ./prepare.py -c && ./prepare.py [options] && make

# Building the application

After the SDK is built, just open the Linphone Xcode project with Xcode, and press `Run`.

## Note regarding third party components subject to license

 The liblinphone SDK is compiled with third parties code that are subject to patent license, specially: AMR, SILK G729 and H264 codecs.
 Linphone controls the embedding of these codecs by generating dummy libraries when there are not available. You can enable them using `prepare.py`
 script (see `--enable-non-free-codecs` option). Before embedding these 4 codecs in the final application, **make sure to have the right to do so**.

# Testing the application

We are using the KIF framework to test the UI of Linphone. It is used as a submodule (instead of CocoaPods) for ease.

Simply press `⌘U` and the default simulator / device will launch and try to pass all the tests.


# Limitations and known bugs

* Video capture will not work in simulator (not implemented in it).

# Debugging the SDK

Sometime it can be useful to step into liblinphone SDK functions. To allow Xcode to enable breakpoint within liblinphone, SDK must be built with debug symbols by using option `--debug`:

        ./prepare.py --debug [other options] && make

## Debugging mediastreamer2

For iOS specific media development like audio video capture/playback it may be interesting to use `mediastream` test tool.
The project `submodule/liblinphone.xcodeproj` can be used for this purpose.

# Quick UI reference

- The app is contained in a window, which resides in the MainStoryboard file.
- The delegate is set to LinphoneAppDelegate in main.m, in the UIApplicationMain() by passing its class
- Basic layout:

MainStoryboard
        |
        | (rootViewController)
        |
    PhoneMainView ---> view #--> app background
        |                   |
        |                   #--> statusbar background
        |
        | (mainViewController)
        |
    UICompositeView : TPMultilayout
                |
                #---> view  #--> statusBar
                            |
                            #--> contentView
                            |
                            #--> tabBar


When the application is started, the phoneMainView gets asked to transition to the Dialer view or the Assistant view.
PhoneMainView exposes the -changeCurrentView: method, which will setup its
Any Linphone view is actually presented in the UICompositeView, with or without a statusBar and tabBar.

The UICompositeView consists of 3 areas laid out vertically. From top to bottom: StatusBar, Content and TabBar.
The TabBar is usually the UIMainBar, which is used as a navigation controller: clicking on each of the buttons will trigger
a transition to another "view".
