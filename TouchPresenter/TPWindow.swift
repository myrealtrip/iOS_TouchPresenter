//
//  TPWindow.swift
//  Pods
//
//  Created by Benjamin Herzog on 17.07.16.
//
//

import UIKit

private var IndicatorObjectKey: UInt8 = 0

internal extension UITouch {

    /// Hold a strong reference to the view for removing it later
    var indicator: UIView? {
        get {
            return objc_getAssociatedObject(self, &IndicatorObjectKey) as? UIView
        }
        set {
            objc_setAssociatedObject(self, &IndicatorObjectKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

public struct TouchPresenterConfiguration<ViewType: UIView> {

    /// Size of the view
    let size: CGSize

    /// true if 3d touch should be visualized
    let threeDeeTouchEnabled: Bool
    
    public typealias ViewConfiguration = (_ view: ViewType) -> Void
    
    fileprivate(set) var viewConfiguration: ViewConfiguration?

    /**
     Initialize a configuration instance.

     - parameter viewType:          the type of the view that should be used
     - parameter size:              the size of the view
     - parameter forceTouchEnabled: use forcetouch
     - parameter viewConfiguration: the configuration block for the view to use (called on init(frame:_))

     **NOTE** size is default at 50x50 points

     **NOTE** forceTouchEnabled is only available on iOS 9 or greater on appropriate devices
     
     **NOTE** viewConfiguration is being retained in the configuration object, so use weak self if you need self inside!
     */
    public init(viewType: ViewType.Type, size: CGSize = CGSize(width: 50, height: 50), enable3DTouch: Bool = false, viewConfiguration: ViewConfiguration? = nil) {
        self.size = size
        self.threeDeeTouchEnabled = enable3DTouch
        self.viewConfiguration = viewConfiguration
    }

}

/**
 Use this window subclass as your main window, it will catch all touches and highlight them with the given view class.

 Initialize in the following way:

 ```Swift
 TPWindow(frame: UIScreen.mainScreen().bounds, configuration: TouchPresenterConfiguration(viewType: TPLightBlueCircleIndicator.self))
 ```

 You can just override your init method in AppDelegate like the following:

 ```
 override init() {
 let config = TouchPresenterConfiguration(viewType: TPLightBlueCircleIndicator.self, enable3DTouch: true)
 window = TPWindow(frame: UIScreen.mainScreen().bounds, configuration: config)
 super.init()
 }
 ```

 You can set any subclass of UIView as the viewType. The window will then initialize an instance of it in the given size.
 */
open class TPWindow<ViewType: UIView>: UIWindow {

    fileprivate let configuration: TouchPresenterConfiguration<ViewType>

    /**
     Initializes an instance of the window. See class documentation for more details.
     */
    public init(frame: CGRect, configuration: TouchPresenterConfiguration<ViewType>) {
        self.configuration = configuration
        super.init(frame: frame)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)

        event.allTouches?.forEach {
            touch in

            switch touch.phase {

            case .began:
                let touchPosition = touch.location(in: self)
                let origin = CGPoint(x: touchPosition.x - configuration.size.width/2, y: touchPosition.y - configuration.size.height/2)
                let frame = CGRect(origin: origin, size: configuration.size)
                let indicator = ViewType(frame: frame)
                configuration.viewConfiguration?(indicator)
                touch.indicator = indicator
                addSubview(indicator)

            case .stationary:
                break

            case .moved:
                touch.indicator?.center = touch.location(in: self)

            case .ended, .cancelled:
                touch.indicator?.removeFromSuperview()
                touch.indicator = nil
            
            default:
                break
            }

            if configuration.threeDeeTouchEnabled {
                if #available(iOS 9.0, *) {

                    let calculatedForce = max(1, sqrt(touch.force))
                    touch.indicator?.transform = CGAffineTransform(scaleX: calculatedForce, y: calculatedForce)
                }
            }

        }
    }

}
