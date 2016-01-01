//
//  ViewController.swift
//  CustomVideoPlayer
//
//  Created by Charles Hsu on 1/1/16.
//  Copyright © 2016 Pro Andy. All rights reserved.
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
    var videoDuration: Float64?
    
    var loadingIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
    let playbackLikelytoKeepUpContext = UnsafeMutablePointer<(Void)>()
    let kCurrentItemPlaybackLikelyToKeepUp = "currentItem.playbackLikelyToKeepUp"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.blackColor()
        
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        view.layer.insertSublayer(avPlayerLayer, atIndex: 0)
        view.addSubview(invisibleButton)
        invisibleButton.addTarget(self, action: "invisibleButtonTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        let url = NSURL(string: "http://content.jwplatform.com/manifests/vM7nH0Kl.m3u8")! as NSURL
        let playerItem = AVPlayerItem(URL: url)
        avPlayer.replaceCurrentItemWithPlayerItem(playerItem)
        
        let timeInterval = CMTimeMakeWithSeconds(1.0, 10)
        timeObserver = avPlayer.addPeriodicTimeObserverForInterval(timeInterval, queue: dispatch_get_main_queue(), usingBlock: { (elapsedTime: CMTime) -> Void in
            self.observeTime(elapsedTime)
        })
        
        timeRemainingLabel.textColor = UIColor.whiteColor()
        view.addSubview(timeRemainingLabel)
        
        view.addSubview(seekSlider)
        seekSlider.addTarget(self, action: "sliderBeganTracking:", forControlEvents: UIControlEvents.TouchDown)
        seekSlider.addTarget(self, action: "sliderEndedTracking:", forControlEvents: [UIControlEvents.TouchUpInside, UIControlEvents.TouchUpOutside])
        seekSlider.addTarget(self, action: "sliderValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
        
        loadingIndicatorView.hidesWhenStopped = true
        view.addSubview(loadingIndicatorView)
        avPlayer.addObserver(self, forKeyPath: kCurrentItemPlaybackLikelyToKeepUp, options: NSKeyValueObservingOptions.New, context: playbackLikelytoKeepUpContext)
        
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == playbackLikelytoKeepUpContext {
            if avPlayer.currentItem!.playbackLikelyToKeepUp {
                loadingIndicatorView.stopAnimating()
            } else {
                loadingIndicatorView.startAnimating()
            }
        }
    }
    
    deinit {
        avPlayer.removeTimeObserver(timeObserver)
        avPlayer.removeObserver(self, forKeyPath: kCurrentItemPlaybackLikelyToKeepUp)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadingIndicatorView.startAnimating()
        avPlayer.play()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Layout subviews manually
        avPlayerLayer.frame = view.bounds // default (0,0,0,0)
        invisibleButton.frame = view.bounds
        
        let controlsHeight: CGFloat = 30
        let controlsY: CGFloat = view.bounds.size.height - controlsHeight
        timeRemainingLabel.frame = CGRect(x: 5, y: controlsY, width: 60, height: controlsHeight)
        
        seekSlider.frame = CGRect(x: timeRemainingLabel.frame.origin.x + timeRemainingLabel.bounds.size.width, y: controlsY, width: view.bounds.size.width - timeRemainingLabel.bounds.size.width - 10, height: controlsHeight)
        
        loadingIndicatorView.center = view.center
    }
    
    func sliderBeganTracking(slider: UISlider!) {
        playerRateBeforeSeek = avPlayer.rate
        avPlayer.pause()
    }
    
    func sliderEndedTracking(slider: UISlider!) {
        let elapsedTime = Float64(seekSlider.value)
        updateTimeLabel(elapsedTime, duration: videoDuration!)
        avPlayer.seekToTime(CMTimeMakeWithSeconds(elapsedTime, 10)) { (completed: Bool) -> Void in
            if self.playerRateBeforeSeek > 0 {
                self.avPlayer.play()
            }
        }
    }
    
    func sliderValueChanged(slider: UISlider!) {
        updateTimeLabel(Float64(seekSlider.value), duration: videoDuration!)
        let elapsedTime = Float64(seekSlider.value)
        avPlayer.seekToTime(CMTimeMakeWithSeconds(elapsedTime, 10))
    }
    
    private func updateTimeLabel(elapsedTime: Float64, duration: Float64) {
        let timeRemaining: Float64 = CMTimeGetSeconds((avPlayer.currentItem!.duration)) - elapsedTime
        timeRemainingLabel.text = String(format: "%02d:%02d", ((lround(timeRemaining) / 60) % 60), lround(timeRemaining % 60))
    }
    
    private func observeTime(elapsedTime: CMTime) {
        videoDuration = CMTimeGetSeconds(avPlayer.currentItem!.duration)
        seekSlider.maximumValue = Float(videoDuration!)
        if isfinite(videoDuration!) {
            let elapsedTime = CMTimeGetSeconds(elapsedTime)
            updateTimeLabel(elapsedTime, duration: videoDuration!)
        }
    }
    
    func invisibleButtonTapped(sender: UIButton!) {
        let playerIsPlayer = avPlayer.rate > 0
        if playerIsPlayer {
            avPlayer.pause()
        } else {
            avPlayer.play()
        }
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Landscape
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    
}

