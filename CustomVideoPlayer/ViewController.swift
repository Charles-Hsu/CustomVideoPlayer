//
//  ViewController.swift
//  CustomVideoPlayer
//
//  Created by Charles Hsu on 11/30/15.
//  Copyright © 2015 Pro Andy. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    var avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!
    var invisibleButton = UIButton()
    var timeObserver: AnyObject!
    var timeRemainingLabel = UILabel()
    var seekSlider = UISlider()
    var playerRateBeforeSeek: Float = 0
    var loadingIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
    let playbackLikelyToKeepUpContext = UnsafeMutablePointer<(Void)>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.blackColor()
        
        // An AVPlayerLayer is a CALayer instance to which the AVPlayer can
        // direct its visual output. Without it, the user will see nothing.
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        view.layer.insertSublayer(avPlayerLayer, atIndex: 0)
        
        view.addSubview(invisibleButton)
        invisibleButton.addTarget(self, action: "invisibleButtonTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        
        let url = NSURL(string: "http://content.jwplatform.com/manifests/vM7nH0Kl.m3u8")
        let playerItem = AVPlayerItem(URL: url!)
        avPlayer.replaceCurrentItemWithPlayerItem(playerItem)
        
        let timeInterval = CMTimeMakeWithSeconds(1.0, 10)
        timeObserver = avPlayer.addPeriodicTimeObserverForInterval(timeInterval, queue: dispatch_get_main_queue(), usingBlock: { (elapsedTime: CMTime) -> Void in
//            NSLog("elapsedTime now %f", CMTimeGetSeconds(elapsedTime))
            self.observeTime(elapsedTime)
        })
        
        timeRemainingLabel.textColor = UIColor.whiteColor()
        timeRemainingLabel.backgroundColor = UIColor.redColor()
        view.addSubview(timeRemainingLabel)

        view.addSubview(seekSlider)
        seekSlider.addTarget(self, action: "sliderBeganTracking:", forControlEvents: UIControlEvents.TouchDown)
        seekSlider.addTarget(self, action: "sliderEndedTracking:", forControlEvents: [UIControlEvents.TouchUpInside, UIControlEvents.TouchUpOutside])
        seekSlider.addTarget(self, action: "sliderValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
        
        loadingIndicatorView.hidesWhenStopped = true
        view.addSubview(loadingIndicatorView)
        avPlayer.addObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.New, context: playbackLikelyToKeepUpContext)
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == playbackLikelyToKeepUpContext {
            if avPlayer.currentItem!.playbackLikelyToKeepUp {
                loadingIndicatorView.stopAnimating()
            }
            else {
                loadingIndicatorView.startAnimating()
            }
        }
    }
    
    
    
    private func observeTime(elaspedTime: CMTime) {
        let duration = CMTimeGetSeconds(avPlayer.currentItem!.duration)
        if isfinite(duration) {
            let elaspedTime = CMTimeGetSeconds(elaspedTime)
            updateTimeLabel(elapsedTime: elaspedTime, duration: duration)
        }
    }
    
    private func updateTimeLabel(elapsedTime elaspedTime: Float64, duration: Float64) {
        let timeRemaining: Float64 = CMTimeGetSeconds(avPlayer.currentItem!.duration) - elaspedTime
        let mins = (lround(timeRemaining) / 60) % 60
        let secs = lround(timeRemaining) % 60
        timeRemainingLabel.text = String(format: "%02d:%02d", mins, secs)
    }
    
    
    
    deinit {
        avPlayer.removeTimeObserver(timeObserver)
        avPlayer.removeObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp")
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadingIndicatorView.startAnimating()
        avPlayer.play()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Layout subviews manually
        avPlayerLayer.frame = view.bounds
        invisibleButton.frame = view.bounds
        
        let controlsHeight: CGFloat = 30
        let controlsY: CGFloat = view.bounds.size.height - controlsHeight
        timeRemainingLabel.frame = CGRect(x: 5, y: controlsY, width: 60, height: controlsHeight)
        timeRemainingLabel.textAlignment = NSTextAlignment.Center
        
//        seekSlider.frame = CGRect(x: timeRemainingLabel.frame.origin.x + timeRemainingLabel.bounds.size.width,
//            y: controlsY, width: view.bounds.size.width - timeRemainingLabel.bounds.size.width - 5, height: controlsHeight)

        seekSlider.frame = CGRect(x: timeRemainingLabel.frame.origin.x + timeRemainingLabel.bounds.size.width,
            y: controlsY, width: view.bounds.size.width - timeRemainingLabel.bounds.size.width - 10, height: controlsHeight)
        
        
        print(view.bounds.size.width)
        print(timeRemainingLabel.bounds.size.width)
        
        
        loadingIndicatorView.center = CGPoint(x: CGRectGetMidX(view.bounds), y: CGRectGetMidY(view.bounds))
    }
    
    func sliderBeganTracking(slider: UISlider!) {
        
//        avPlayer.rate = 0.5
        
        playerRateBeforeSeek = avPlayer.rate
        
        
        
//        print(playerRateBeforeSeek)
        
        avPlayer.pause()
    }
    
    func sliderEndedTracking(slider: UISlider!) {
        let videoDuration = CMTimeGetSeconds(avPlayer.currentItem!.duration)
        let elapsedTime: Float64 = videoDuration * Float64(seekSlider.value)
        updateTimeLabel(elapsedTime: elapsedTime, duration: videoDuration)
        
        avPlayer.seekToTime(CMTimeMakeWithSeconds(elapsedTime, 600/*10*/)) { (completed: Bool) -> Void in
            if (self.playerRateBeforeSeek > 0) {
                self.avPlayer.play()
            }
        }
        
//        avPlayer.rate = 0.5
//        print(avPlayer.rate)
        
    }
    
    func sliderValueChanged(slider: UISlider!) {
        let videoDuration = CMTimeGetSeconds(avPlayer.currentItem!.duration)
        let elapsedTime: Float64 = videoDuration * Float64(seekSlider.value)
        updateTimeLabel(elapsedTime: elapsedTime, duration: videoDuration)
    }
    
    func invisibleButtonTapped(sender: UIButton!) {
        let playerIsPlaying: Bool = avPlayer.rate > 0
        if playerIsPlaying {
            avPlayer.pause()
        } else {
            avPlayer.play()
        }
    }
    
    
    // Force the view into landscape mode (which is how most video media is consumed.)
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Landscape
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

