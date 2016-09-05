
import UIKit

class SwirlyBarView: UIView {

  var displayLink:CADisplayLink!
  var animationCounter:Int = 0
  let swirlyBar = SwirlyBar()
  var barArray:[SwirlyBar] = []
  var replaceCounter:Int = 0
  let numberOfBars = 25
  var swirling:Bool = false
  
  override init(frame:CGRect) {
    super.init(frame:frame)
    backgroundColor = UIColor.darkGrayColor()
    displayLink = CADisplayLink(target: self, selector: #selector(SwirlyBarView.displayLinkFired(_:)))
    displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
  }
  
  func startSwirling() {
    swirling = true
  }
  
  func stopSwirling() {
    swirling = false
  }
  
  
  func displayLinkFired(sender:AnyObject!){
    animationCounter += 1
    if swirling {
      if animationCounter%9 == 0{
        if barArray.count < numberOfBars {
          let newSwirlyBar = SwirlyBar()
          layer.addSublayer(newSwirlyBar)
          barArray.append(newSwirlyBar)
        }else {
          let oldSwirlyBar = barArray[(replaceCounter)%barArray.count]
          oldSwirlyBar.reset()
          replaceCounter += 1
          
        }
      }
    } else {
      for bar in barArray {
        bar.fade()
      }
    }
    
    for bar in barArray {
      bar.positionCounter++
    }
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder:aDecoder)
  }
  
  deinit {
    displayLink.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
  }

}

class SwirlyBar: CAShapeLayer {
  let fadeStartingPoint:CGFloat = 70
  var positionCounter:CGFloat = 0 {
    didSet(newValue) {
      move()
      if newValue > fadeStartingPoint {
        tailFade()
      }
    }
  }
  let originalFrame = CGRectMake(screenWidth/2, 100, 2, 40)
  
  override init(layer: AnyObject) {
    super.init(layer: layer)
  }
  
  override init() {
    super.init()
    //set initial position in center
    reset()
    
  }
  
  func move() {
    //opacity increases
    //opacity = Float(positionCounter) * 0.01
    //down one, right/left 100*sin(positionCounter)
    let sinInput = Float(positionCounter) * Float(M_PI/30)
    let sinValue = sin(sinInput)
    let barHeight:CGFloat = 39 + CGFloat(sin(sinInput + Float(M_PI*1/2)))*5
    path = UIBezierPath(roundedRect:
      CGRectMake( CGFloat(sinValue*50),
        originalFrame.origin.y + positionCounter,
        2, barHeight), cornerRadius: 10).CGPath
    let alphaComponent = CGFloat(sin(sinInput + Float(M_PI*1/2)))/3+0.7
    fillColor = UIColor.whiteColor().colorWithAlphaComponent(alphaComponent).CGColor
    
  }
  
  func fade() {
    if opacity > 0.005 {
      opacity *= 0.93
    } else {
      opacity = 0
    }
  }
  
  func tailFade() {
    if opacity > 0.005 {
      opacity *= 0.89
    } else {
      opacity = 0
    }
  }
  
  func disappear() {
    opacity = 0
  }
  
  func reset() {
    positionCounter = 0
    frame = originalFrame
    opacity = 1
    fillColor = UIColor.whiteColor().CGColor
    lineWidth = 0
    path = UIBezierPath(roundedRect:CGRectMake(0, 0, 2, 40), cornerRadius:10).CGPath
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}
