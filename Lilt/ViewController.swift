//
//  ViewController.swift
//  Lilt
//
//  Created by Camvy Films on 2015-01-13.
//  Copyright (c) 2015 June. All rights reserved.
//

import UIKit
import AVFoundation

enum FileReadWrite {
  case Read
  case Write
}

class ViewController: UIViewController {
  
  var audioURL:NSURL!

  var replayButton = UIButton(frame: CGRectMake(50, 460, 220,60))
  var listeningIndicator = UIButton(frame: CGRectMake(50, 100, 220, 60))
  let slider = UISlider(frame: CGRectMake(0, 510, 320, 50))
  var sensitivityLabel = UILabel(frame: CGRectMake(0, 450, 320, 50))
  
  let audioController = AEAudioController(audioDescription: AEAudioController.nonInterleaved16BitStereoAudioDescription(), inputEnabled: true)
  var recorder:AERecorder?
  var recording: Bool = false
  var inputOscilloscope:TPOscilloscopeLayer!
  var powerMonitor:[Float32] = [0.0]
  var listeningTimer: NSTimer!
  let listeningInterval: Double = 0.05
  let listeningSeconds: Double = 2
  var silenceLevel:Float32 = 0
  var listening: Bool = false
  
  //animation code
  var displayLink:CADisplayLink!
  var animationCounter:Int = 0
  var swirlyBarView:SwirlyBarView!
  var barArray:[SwirlyBar] = []
  var replaceCounter:Int = 0
  let numberOfBars = 25
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addSubviews()
    altConfigureAudio()
    
  }
  
  override func viewDidAppear(animated: Bool) {
    startListening()
  }
  
  func startListening() {
    swirlyBarView.startSwirling()
    listeningTimer = NSTimer.scheduledTimerWithTimeInterval(listeningInterval, target: self, selector: "monitoringAudio:", userInfo: nil, repeats: true)
    listeningIndicator.hidden = false
    listeningIndicator.alpha = 1
    listeningIndicator.setTitle("Listening...", forState: .Normal)
    //toggle add bars
  }
  
  func stopListening() {
    swirlyBarView.stopSwirling()
    listeningTimer.invalidate()
    powerMonitor = []
    listeningIndicator.alpha = 0.3
    listeningIndicator.setTitle("Not Listening...", forState: .Normal)
    
  }
  
  func monitoringAudio(timer:NSTimer) {
    var average:Float32 = 0
    var peak:Float32 = 0
    audioController.inputAveragePowerLevel(&average, peakHoldLevel: &peak)
    silenceLevel = -slider.value
    var isSilent:Bool = average < silenceLevel
    if !isSilent { startRecording() }
    powerMonitor.append(average)
    let listeningFrequency: Int = Int(listeningSeconds/listeningInterval)
    if powerMonitor.count < listeningFrequency {return}
    var recentPower = powerMonitor[powerMonitor.count-listeningFrequency ... powerMonitor.count-2]
    var wasSilent:Bool = true
    for power in recentPower {
      if power > silenceLevel {
        wasSilent = false
        break
      }
    }
    
    if wasSilent && isSilent { stopRecording() }
    
    
    
  }
  
  func addSubviews() {
    addSwirlyBarView()
    addOscilloscope()
    addSlider()
    addInstantReplayButton()
    addListeningIndicator()
    addSensitivityLabel()
  }
  func addSlider() {
    slider.maximumValue = 30
    slider.minimumValue = 6
    slider.setValue(20, animated: false)
    slider.continuous = true
    view.addSubview(slider)
  }
  
  func addSensitivityLabel() {
    sensitivityLabel.textAlignment = NSTextAlignment.Center
    sensitivityLabel.font = UIFont(name: "Helvetica", size: 30)
  }
  
  func addOscilloscope() {
    inputOscilloscope = TPOscilloscopeLayer(audioController: audioController)
    inputOscilloscope.frame = CGRectMake(0, 0, 320, 150)
    inputOscilloscope.lineColor = UIColor.redColor().colorWithAlphaComponent(0.2)
    view.layer.addSublayer(inputOscilloscope)
    audioController.addInputReceiver(inputOscilloscope)
    inputOscilloscope.start()
  }
  
  func addInstantReplayButton() {
    replayButton.backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0.3)
    replayButton.setTitle("Instant Replay", forState: UIControlState.Normal)
    replayButton.addTarget(self, action: "replayButtonTapped:", forControlEvents: .TouchUpInside)
    view.addSubview(replayButton)
  }
  
  func addListeningIndicator() {
    
    listeningIndicator.setTitle("Listening...", forState: .Normal)
    listeningIndicator.backgroundColor = UIColor.greenColor()
    listeningIndicator.hidden = true
    view.addSubview(listeningIndicator)
  }
  
  func addSwirlyBarView() {
    swirlyBarView = SwirlyBarView(frame: view.frame)
    view.addSubview(swirlyBarView)
  }
  
  func altConfigureAudio() {
    var error:NSError?
    let result = audioController.start(&error)
    dump(error)
    
  }
  
  func outputPath(readOrWrite:FileReadWrite) -> String {
    var outputPath:String!
    if let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true) {
      if paths.count > 0 {
        outputPath = (paths[0] as? String)! + "/Recording.aiff"
        if readOrWrite == .Write {
          let manager = NSFileManager.defaultManager()
          var error:NSError?
          manager.removeItemAtPath(outputPath, error: &error)
          if let e = error {
            println("outputPath(readOrWrite:FileReadWrite) error: \(e)")
          }
        }
      }
    }
    return outputPath
  }
  
  func replayButtonTapped(sender:UIButton!) {
    stopRecording()
  }
  
  func startRecording() {
    if recording {return}
    var error:NSError?
    recorder = AERecorder(audioController: audioController)
    recorder?.beginRecordingToFileAtPath( outputPath(.Write), fileType: AudioFileTypeID(kAudioFileAIFFType), error: &error)
    if let e = error {
      println("raRRRWAREEWAR recording unsuccessful! error: \(e)")
      recorder = nil
      return
    }
    recording = true
    changeUIForRecording(true)
    audioController.addOutputReceiver(recorder)
    audioController.addInputReceiver(recorder)
    
  }
  
  func changeUIForRecording(isRecording:Bool) {
    if isRecording {
      inputOscilloscope.lineColor = UIColor.redColor()
      replayButton.backgroundColor = UIColor.blueColor()
    } else {
      replayButton.backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0.3)
      inputOscilloscope.lineColor = UIColor.redColor().colorWithAlphaComponent(0.2)
    }
    
  }
  
  func timerFired(timer:NSTimer!){
    stopRecording()
  }
  
  func stopRecording() {
    if !recording {return}
    recorder?.finishRecording()
    recording = false
    changeUIForRecording(false)
    audioController.removeOutputReceiver(recorder)
    audioController.removeInputReceiver(recorder)
    recorder = nil
    playAudioAtPath(outputPath(.Read))
  }
  
  func playAudioAtPath(path:String){
    var error:NSError?
    let player = AEAudioFilePlayer.audioFilePlayerWithURL(NSURL.fileURLWithPath(path), audioController: audioController, error: &error) as? AEAudioFilePlayer
    if let e = error {
      println("oh noes! playAudioAtPath error: \(e)")
      return
    }
    stopListening()
    player?.removeUponFinish = true
    player?.completionBlock = {
      self.startListening()
    }
    audioController.addChannels(NSArray(object: player!))
    
  }


  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}