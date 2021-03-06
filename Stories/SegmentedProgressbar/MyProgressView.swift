//
//  MyProgressView.swift
//  Stories
//
//  Created by iim jobs on 11/04/20.
//  Copyright © 2020 Iimjobs. All rights reserved.
//

import UIKit

protocol SegmentedProgressBarDelegate: class {
    func segmentedProgressBarChangedIndex(index: Int)
    func segmentedProgressBarsFinished(left: Bool)
}

class MyProgressView: UIView {
    
    weak var delegate: SegmentedProgressBarDelegate?
    
    var arrayBars: [UIProgressView] = []
    
    var padding: CGFloat = 4.0
    
    private var hasDoneLayout = false // prevent layouting again
    
    var currentAnimationIndex = 0
    
    var timer: Timer?
    
    var paused = false
    
    var timerRunning = false
    
    var currentDuration: Double = 5 // default
    
    init(arrayStories: Int) {
        // init var here
        super.init(frame: .zero)
        
        for _ in 0...arrayStories - 1 {
            let bar = UIProgressView()
            arrayBars.append(bar)
            addSubview(bar)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if hasDoneLayout { return }
        
        addBackgroundGradient()
        
        let width = (frame.width - ((padding) * CGFloat(arrayBars.count - 1)) - 16) / CGFloat(arrayBars.count)
        
        for (index, progressBar) in arrayBars.enumerated() {
            
            let segFrame = CGRect(x: (CGFloat(index) * (width + padding)) + 8, y: frame.height/2 - 1, width: width, height: 20)
            progressBar.frame = segFrame
            
            progressBar.progress = 0.0
            
            progressBar.transform = progressBar.transform.scaledBy(x: 1, y: 1)
            
            progressBar.tintColor = .white
            progressBar.backgroundColor = UIColor.lightGray
            progressBar.layer.cornerRadius = progressBar.frame.height / 2
        }
        
        hasDoneLayout = true
    }
    
    func addBackgroundGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = [UIColor(red: 0, green: 0, blue: 0, alpha: 0.3).cgColor,UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func animate(index: Int, duration: Double) {
        currentDuration = duration
        let duration = duration / 200.0
        self.paused = false
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(duration), target: self, selector: #selector(updateProgressBar(_:)), userInfo: index, repeats: true)
        currentAnimationIndex = index
        timerRunning = true
    }
    
    @objc func updateProgressBar(_ timer: Timer) {
        let selectdStoryIndex = timer.userInfo as! Int
        
        let progressBar = arrayBars[selectdStoryIndex]
        progressBar.progress += 0.005
        progressBar.setProgress(progressBar.progress, animated: false)
        
        
        if  progressBar.progress == 1.0 {
            self.next()
        }
    }
    
    private func next() {
        print("PV: invalidate timer")
        
        let newIndex = self.currentAnimationIndex + 1
        
        print("new index...\(newIndex)...array bar count\(arrayBars.count)")
        
        if newIndex < arrayBars.count {
            print("PV: next snap")
            self.timer?.invalidate()
            //self.animate(index: newIndex)
            self.currentAnimationIndex = newIndex
            self.delegate?.segmentedProgressBarChangedIndex(index: newIndex)
        } else {
            print("PV: Story ended")
            self.timer?.invalidate()
            self.delegate?.segmentedProgressBarsFinished(left: false)
        }
    }
    
    func pause() {
        if !paused{
            paused = true
            print("PV: pause")
            self.timer?.invalidate()
        }
    }
    
    func resume() {
        if paused {
            // resume
            paused = false
            print("PV: resume")
            self.animate(index: currentAnimationIndex, duration: currentDuration)
        }
    }
    
    func resetBar() {
        for i in arrayBars {
            i.progress = 0.0
        }
        self.timer?.invalidate()
        timerRunning = false
        currentAnimationIndex = 0
        self.paused = false
        print("PV: reset Bars")
    }
    
    
    func skip() {
        if paused {
            paused = false
        }
        print("PV: skip")
        let currentBar = arrayBars[currentAnimationIndex]
        currentBar.progress = 1.0
        self.next()
    }
    
    func rewind() {
        print("PV: rewind")
        if paused { paused = false }
        
        let currentBar = arrayBars[currentAnimationIndex]
        currentBar.progress = 0.0
        
        let newIndex = self.currentAnimationIndex - 1
        
        if newIndex < 0 {
            print("PV: Story ended , go to previous story")
            self.timer?.invalidate()
            self.delegate?.segmentedProgressBarsFinished(left: true)
            return
        }
        
        let prevBar = arrayBars[newIndex]
        prevBar.setProgress(0.0, animated: false)
        
        self.timer?.invalidate()
        //self.animate(index: newIndex)
        self.delegate?.segmentedProgressBarChangedIndex(index: newIndex)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
