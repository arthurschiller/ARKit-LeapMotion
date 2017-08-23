# ARKit + LeapMotion

![alt header](https://raw.githubusercontent.com/arthurschiller/ARKit-LeapMotion/master/Docs/header.png)

A sample projects demonstrating how a lhttpseap motion device can be hooked to an iPhone to control an ARKit Scene.
**Note:** to run the project you will need a Mac computer running a current system version, a LeapMotion Controller 
and an iOS Device(iPhone 6S or better) running iOS 11. You will also need to install the [LeapMotion V2 Desktop Tracking SDK](https://developer.leapmotion.com/sdk/v2).

### Gettings started
1. Open up the project with XCode 9.
2. Connect your LeapMotion Controller and run the Mac App target.
3. Now run the iOS target. You will see a live view of the camera with a simple cube placed in front of you.
4. In the iOS app tap the »Connect To Controller« button. Another view will open, where you can select »LMDSupply« from the list.
5. Confirm the alert on your Mac app and you should be good to go.
6. Move you hand around to control the cube.

For now translation(change of position) and rotation are supported.

### How it works
The Mac app handles the interpretation of the data coming from the LeapMotion. 
It then bundles it into a small object which gets streamed to the iOS Device via Multipeer Connectivity.
I tried achieving the same by using only Bluetooth. The current solution is way more stable and should produce almost no noticeable lag.

### Credits & Links
- https://github.com/FlexMonkey/3D-Motion-Controller
- https://blog.markdaws.net/arkit-by-example-part-2-plane-detection-visualization-10f05876d53
- https://swifting.io/blog/2017/07/05/44-watch-your-bluetooth/
- https://www.captechconsulting.com/blogs/arkit-fundamentals-in-ios-11
- https://developer.leapmotion.com/documentation/objc/index.html

> More to come…
