//
//  StoryCell.swift
//  Stories
//
//  Created by iim jobs on 10/04/20.
//  Copyright © 2020 Iimjobs. All rights reserved.
//

import UIKit
import Alamofire
import AVKit

protocol StoryPreviewProtocol: class {
    func moveToNextStory(from storyIndex: Int)
    func moveToPreviousStory(from storyIndex: Int)
    func didTapBlockButton(from storyIndex: Int)
}

class VideoView: UIView {
    var playerLayer: AVPlayerLayer?
    
    var snapVideo: AVPlayer = {
        let av = AVPlayer()
        return av
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer!.frame = frame
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer = AVPlayerLayer(player: snapVideo)
        layer.addSublayer(playerLayer!)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class StoryCell: UICollectionViewCell {
    weak var delegate: StoryPreviewProtocol?
    
    let companyIcon: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 25
            iv.contentMode = .scaleAspectFit
            iv.backgroundColor = .white
            iv.clipsToBounds = true
            
            iv.layer.borderWidth = 0.5
            iv.layer.borderColor = UIColor.black.cgColor
            
            iv.frame = CGRect(x: 20, y: 25, width: 50, height: 50)
            return iv
        }()

    let companyTitle: UILabel = {
            let l = UILabel()
            l.textAlignment = .left
            l.textColor = .white
            l.font = UIFont(name: "HelveticaNeue-Bold",size: 19.0)
            
            l.layer.shadowColor = UIColor.black.cgColor
            l.layer.shadowRadius = 2.0
            l.layer.shadowOpacity = 1.0
            l.layer.shadowOffset = CGSize(width: 1, height: 1)
            l.layer.masksToBounds = false
            
            return l
        }()
        
    let dateLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .left
        l.textColor = .white
        l.font = UIFont(name: "HelveticaNeue", size: 15.0)
        
        l.layer.shadowColor = UIColor.black.cgColor
        l.layer.shadowRadius = 2.0
        l.layer.shadowOpacity = 1.0
        l.layer.shadowOffset = CGSize(width: 1, height: 1)
        l.layer.masksToBounds = false
        return l
    }()
        
    let menuBtn: UIButton = {
            let btn = UIButton()
            btn.setBackgroundImage(UIImage(named: "menu"), for: .normal)
            btn.tintColor = .white
            return btn
        }()
        
    let clapCount: UILabel = {
            let l = UILabel()
            l.textAlignment = .left
            l.textColor = .white
            l.font = UIFont(name: "HelveticaNeue-Bold",size: 17.0)
            l.text = "0"
            l.backgroundColor = UIColor(displayP3Red: 20/255, green: 144/255, blue: 117/255, alpha: 1)
    
            l.layer.masksToBounds = true
            l.textAlignment = .center;
            return l
        }()
        
    let clapBtn: UIButton = {
            let btn = UIButton()
            btn.setBackgroundImage(UIImage(named: "clapunfilled"), for: .normal)
            btn.tintColor = .white
            return btn
        }()
        
    let showcaseDetailLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.textColor = .white
        l.font = UIFont(name: "HelveticaNeue-Bold",size: 18.0)
        
        l.layer.shadowColor = UIColor.black.cgColor
        l.layer.shadowRadius = 2.0
        l.layer.shadowOpacity = 1.0
        l.layer.shadowOffset = CGSize(width: 1, height: 1)
        l.layer.masksToBounds = false
        
        return l
    }()

    let snapImage: UIImageView = {
        let iv = UIImageView()
        iv.isHidden = true
        return iv
    }()

    let loadingIndicator: UIActivityIndicatorView = {
        var l = UIActivityIndicatorView()
        if #available(iOS 13.0, *) {
            l = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        } else {
            l = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
        }
        return l
    }()
    
    let videoView: VideoView = {
        let i = VideoView()
        return i
    }()
    
    var progressBar: MyProgressView!
    var stories: [StoryModel]!
    var arrayCompanies: [CompanyModel]!
    var storyCompanyId: String?
    var parentStoryIndex: Int!
    
    var viewInFocus = true
    var progressBarPresent = false
    var isCompletelyVisible = false
    var isAnimating = false
    var blockAlertActive = false
    
    var currentSnap = 0
    
    var clapNumber = 0
    var clapTimer: Timer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(companyIcon)
        
        menuBtn.frame = CGRect(x: frame.width - 50, y: 20, width: 50, height: 50)
        contentView.addSubview(menuBtn)
        menuBtn.addTarget(self, action: #selector(menuBtnAction), for: .touchUpInside)
        
        clapCount.frame = CGRect(x: frame.width - 60, y: frame.height - 220, width: 50, height: 50)
        clapCount.layer.cornerRadius = 25
        clapCount.isHidden = true
        contentView.addSubview(clapCount)
        
        showcaseDetailLabel.frame = CGRect(x: 0, y: frame.height - 80, width: frame.width, height: 50)
        showcaseDetailLabel.text = "Swipe up to Explore"
        contentView.addSubview(showcaseDetailLabel)
        
        clapBtn.frame = CGRect(x: frame.width - 60, y: frame.height - 120, width: 50, height: 50)
        clapBtn.layer.cornerRadius = 25
        contentView.addSubview(clapBtn)
        clapBtn.addTarget(self, action: #selector(clapBtnAction), for: .touchUpInside)
        
        companyTitle.frame = CGRect(x: 75, y: 25, width: frame.width - 75, height: 25 )
        contentView.addSubview(companyTitle)
        
        dateLabel.frame = CGRect(x: 75, y: 45, width: frame.width - 75, height: 25)
        contentView.addSubview(dateLabel)
        
        loadingIndicator.startAnimating()
        loadingIndicator.center = contentView.center
        contentView.addSubview(loadingIndicator)
        
        videoView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        videoView.isHidden = true
        videoView.snapVideo.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        contentView.addSubview(videoView)
        contentView.sendSubviewToBack(videoView)
        
        
        snapImage.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        contentView.addSubview(snapImage)
        snapImage.isHidden = true
        contentView.sendSubviewToBack(snapImage)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.onlongPress(_:)))
        self.addGestureRecognizer(longPressRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onTap(_:)))
        
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        self.addGestureRecognizer(tapRecognizer)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object as AnyObject? === videoView.snapVideo.currentItem {
            if keyPath == "status" {
                if videoView.snapVideo.status == .readyToPlay  && viewInFocus{
                    videoView.snapVideo.play()
                    print("StoryCell: Ready to play video.")
                }
            }
        }
        
        if object as AnyObject? === videoView.snapVideo {
             if keyPath == "timeControlStatus" {
                if #available(iOS 10.0, *) {
                    if videoView.snapVideo.timeControlStatus == .playing {
                        print("StoryCell : timeControlStatus == .playing")
                        if isCompletelyVisible && viewInFocus {
                            startAnimatingStory(duration: (videoView.snapVideo.currentItem?.duration.seconds)!)
                            print("StoryCell: Video started animating.")
                        }
                    }
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.companyIcon.image = nil
        self.snapImage.image = nil
        self.companyTitle.text = ""
        self.currentSnap = 0
        
        self.clapCount.text = "0"
        self.clapNumber = 0
        self.showcaseDetailLabel.isHidden = false
        
        self.clapBtn.setBackgroundImage(UIImage(named: "clapunfilled"), for: .normal)
        
        self.loadingIndicator.isHidden = false
        self.loadingIndicator.startAnimating()
    }
    
    @objc func menuBtnAction() {
        if isAnimating {
            delegate?.didTapBlockButton(from: self.parentStoryIndex)
            self.blockAlertActive = true
        }
    }
    
    @objc func clapBtnAction() {
        if !isAnimating {
            return
        }
        if clapNumber >= 20 {
            return
        }
        
        self.clapCount.isHidden = false
        clapNumber += 1
        
        let parameters = [
            "en_cookie": "sVYq_SLASH_MHl4bYuo6ROMRVrdJpcSg0fZEC_PLUS_NCDpe11acqcLJUauKgx9ynVUafUCTsTBsL_PLUS_uC3HtrHAMRFWc0WkiOw_EQUALS__EQUALS_",
            "payload": "[{\"storyId\":\"\(self.stories[currentSnap].storyId)\",\"count\":\"\(clapNumber)\"}]"
        ]
        
        AF.request(URL.init(string: "https://bidder.hirist.com/api7/story/clap")!, method: .post, parameters: parameters, encoding: URLEncoding.default).responseJSON { (response) in
            switch response.result {
                case .success:
                    print("Clap resp: \(response)")
                    self.stories[self.currentSnap].isClapped = true
                case let .failure(error):
                    print("Clap resp: \(error)")
                }
        }
        
        // animate clap
        UIView.animate(withDuration: 0.2,
        animations: {
            self.clapBtn.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        },
        completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.clapBtn.transform = CGAffineTransform.identity
            }
        })
        
        self.clapBtn.setBackgroundImage(UIImage(named: "clapfilled"), for: .normal)

        self.clapCount.text = "\(clapNumber)"
        if (clapTimer != nil) {
            clapTimer?.invalidate()
        }
        clapTimer = Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(hideClapCount(_:)), userInfo: index, repeats: true)
    }
    
    @objc func hideClapCount(_ timer: Timer) {
        self.clapCount.isHidden = true
        
        timer.invalidate()
    }
    
    @objc func onTap(_ sender: UITapGestureRecognizer) {
        let touch = sender.location(in: self)
        let screenWidthOneThird = self.frame.width / 3
        let screenWidthTwoThird = screenWidthOneThird * 2
        let absoluteTouch = touch.x

        if absoluteTouch < screenWidthOneThird {
            progressBar.rewind()
        } else if absoluteTouch > screenWidthOneThird && absoluteTouch < screenWidthTwoThird {
            //nothing
        } else {
            progressBar.skip()
        }
    }
    
    @objc func onlongPress(_ gesture: UILongPressGestureRecognizer) {
        if isAnimating {
            switch gesture.state {
                case UIGestureRecognizerState.began:
                    progressBar.pause()
                    videoView.snapVideo.pause()
                    hideUiElements()
                    break
                case UIGestureRecognizerState.ended:
                    progressBar.resume()
                    videoView.snapVideo.play()
                    unHideUiElements()
                    break
                default:
                    break
            }
        }
    }
    
    func hideUiElements() {
        self.progressBar.isHidden = true
        self.companyIcon.isHidden = true
        self.dateLabel.isHidden = true
        self.companyTitle.isHidden = true
        self.menuBtn.isHidden = true
        self.clapBtn.isHidden = true
    }
    
    func unHideUiElements() {
        self.progressBar.isHidden = false
        self.companyIcon.isHidden = false
        self.dateLabel.isHidden = false
        self.companyTitle.isHidden = false
        self.menuBtn.isHidden = false
        self.clapBtn.isHidden = false
    }
    
    func initProgressbar() {
        if(self.progressBar != nil) { //avoid overlapping
            self.progressBarPresent = false
            self.progressBar.removeFromSuperview()
        }
        
        if !self.progressBarPresent {
            progressBar = MyProgressView(arrayStories: self.stories.count)
            progressBar.delegate = self
            progressBar.frame = CGRect(x: 0, y: 0, width: frame.width, height: 20)
            contentView.addSubview(progressBar)
            contentView.bringSubviewToFront(progressBar)
            self.progressBarPresent = true
        }
    }
    
    func animate() {
        if isCompletelyVisible {
            print("StoryCell: completely visible")
            loadIconImage()
            loadSnapImage()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func viewFocusGained() {
        if self.blockAlertActive { return }
        self.viewInFocus = true
        if self.stories[self.currentSnap].storyType == 1 {
            if self.isAnimating {
                self.progressBar.resume()
            } else {
                self.animate()
            }
        } else {
            if self.isAnimating {
                self.videoView.snapVideo.play()
                self.progressBar.resume()
            } else {
                if self.videoView.snapVideo.status == .readyToPlay {
                    self.videoView.snapVideo.play()
                } else {
                    // do nothing
                }
            }
        }
    }
    
    func viewFocucLost() {
        if self.blockAlertActive { return }
        self.viewInFocus = false
        self.videoView.snapVideo.pause()
        if self.stories[self.currentSnap].storyType == 1 {
            if self.isAnimating {
                self.progressBar.pause()
            } else {
                //do nothing
            }
        } else {
            if self.isAnimating {
                self.videoView.snapVideo.pause()
                self.progressBar.pause()
            } else {
                //do nothing
            }
        }
    }
}

extension StoryCell: SegmentedProgressBarDelegate {
    func segmentedProgressBarChangedIndex(index: Int) {
        print("StoryCell: index changed delegate")
        if isAnimating {
            self.stories[self.currentSnap].isSeen = true
        }

        currentSnap = index
        isAnimating = false
        
        clapNumber = 0
        
        self.videoView.isHidden = true
        self.videoView.snapVideo.pause()
        
        self.loadingIndicator.isHidden = false
        self.snapImage.image = nil
        self.animate()
    }
    
    func segmentedProgressBarsFinished(left: Bool) {
        if isAnimating {
            self.stories[self.currentSnap].isSeen = true
        }
        
        currentSnap = 0
        
        if left {
            delegate?.moveToPreviousStory(from: parentStoryIndex)
        } else {
            delegate?.moveToNextStory(from: parentStoryIndex)
        }
    }
}

//network requests
extension StoryCell {
    func getIconImage(address: String) {
        if !FileManager.default.fileExists(atPath: filePath(forKey: self.storyCompanyId!, type: 1)!.path) {
            AF.request(address).downloadProgress { progress in
            }.response { response in
                if case .success(let image) = response.result {
                    self.store(image: image!, forKey: self.storyCompanyId!)
                }
            }
        }
    }
    
    func getSnapThumbnail(address: String, type: Int, index: Int) {
        if address != "" {
            AF.request(address).response { response in
                if case .success(let image) = response.result {
                    if type == 1 && self.currentSnap == index && !self.isAnimating {
                        self.videoView.isHidden = true
                        self.snapImage.isHidden = false
                        self.snapImage.image = UIImage(data: image!)
                        self.loadingIndicator.isHidden = true
                    }
                    else {
                        // video thumbnail
                    }
                }
            }
        }
    }
    
    func getSnapImage(address: String, index: Int) {
        let storyId = self.stories[index].storyId
        let type = self.stories[index].storyType
        if !FileManager.default.fileExists(atPath: filePath(forKey: storyId, type: type)!.path) {
            getSnapThumbnail(address: self.stories[index].thumbnailPath, type: type, index: index)
            if type == 1 {
                AF.request(address).response { response in
                    if case .success(let image) = response.result {
                        self.store(image: image!, forKey: storyId)
                        
                        if self.isCompletelyVisible && index == self.currentSnap {
                            self.animate()
                            self.loadingIndicator.isHidden = true
                        }
                    }
                }
            }
        }
    }
}

extension StoryCell {
    func loadIconImage() {
        if FileManager.default.fileExists(atPath: filePath(forKey: self.storyCompanyId!, type: 1)!.path) {
            self.companyIcon.image = retrieveImage(forKey: self.storyCompanyId!)!
        }
    }
    
    func loadSnapImage() {
        let epochTime = self.stories[self.currentSnap].createdOn
        self.dateLabel.text = Date(timeIntervalSince1970: TimeInterval(epochTime / 1000)).getElapsedInterval()
        
        let storyId = self.stories[self.currentSnap].storyId
        let type = self.stories[self.currentSnap].storyType
        
        if (self.stories[self.currentSnap].isClapped) {
            self.clapBtn.setBackgroundImage(UIImage(named: "clapfilled"), for: .normal)
        } else {
            self.clapBtn.setBackgroundImage(UIImage(named: "clapunfilled"), for: .normal)
        }
        
        if FileManager.default.fileExists(atPath: filePath(forKey: storyId, type: type)!.path) {
            if type == 1 {
                self.loadingIndicator.isHidden = true
                self.videoView.isHidden = true
                self.snapImage.isHidden = false
                self.snapImage.image = retrieveImage(forKey: storyId)!
                
                startAnimatingStory(duration: 5)
            }
        } else {
            if type == 2 {
                if isCompletelyVisible {
                    self.snapImage.isHidden = true
                    self.videoView.isHidden = false
                    
                    DispatchQueue.global(qos: .userInitiated).async {
                        let asset = AVAsset(url: URL(string: self.stories[self.currentSnap].s3Path)!)
                        let item = AVPlayerItem(asset: asset)
                        
                        DispatchQueue.main.async {
                            [weak self] in
                            self?.videoView.snapVideo.replaceCurrentItem(with: item)
                            self?.videoView.snapVideo.currentItem?.addObserver(self!, forKeyPath: "status", options: [.old, .new], context: nil)
                        }
                    }
                }
            }
        }
    }
    
    func startAnimatingStory(duration: Double) {
        if !isAnimating && isCompletelyVisible && self.viewInFocus{
            print("StoryCell: Loading snap \(self.currentSnap)")
            self.progressBar.animate(index: self.currentSnap, duration: duration)
            self.isAnimating = true
            self.loadingIndicator.isHidden = true
        }
    }
}

// save/load image
extension StoryCell {
    func store(image: Data, forKey key: String) {
        let pngRepresentation = image
        if let filePath = filePath(forKey: key, type: 1) {
            do  {
                try pngRepresentation.write(to: filePath, options: .atomic)
            } catch let err {
                print("Saving file resulted in error: ", err)
            }
        }
    }
    
    func retrieveImage(forKey key: String) -> UIImage? {
        if let filePath = self.filePath(forKey: key, type: 1),
            let fileData = FileManager.default.contents(atPath: filePath.path),
            let image = UIImage(data: fileData) {
            return image
        }
        return nil
    }
    
    func filePath(forKey key: String, type: Int) -> URL? {
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(for: .cachesDirectory,
                                                in: FileManager.SearchPathDomainMask.userDomainMask).first else { return nil }

        return documentURL.appendingPathComponent(key + "")
    }
}

extension Date {
    func getElapsedInterval(to end: Date = Date()) -> String {

        if let interval = Calendar.current.dateComponents([Calendar.Component.year], from: self, to: end).day {
            if interval > 0 {
                return "\(interval) year\(interval == 1 ? "":"s") ago"
            }
        }

        if let interval = Calendar.current.dateComponents([Calendar.Component.month], from: self, to: end).month {
            if interval > 0 {
                return "\(interval) month\(interval == 1 ? "":"s") ago"
            }
        }

        if let interval = Calendar.current.dateComponents([Calendar.Component.weekOfMonth], from: self, to: end).weekOfMonth {
            if interval > 0 {
                return "\(interval) week\(interval == 1 ? "":"s") ago"
            }
        }

        if let interval = Calendar.current.dateComponents([Calendar.Component.day], from: self, to: end).day {
            if interval > 0 {
                return "\(interval) day\(interval == 1 ? "":"s") ago"
            }
        }

        if let interval = Calendar.current.dateComponents([Calendar.Component.hour], from: self, to: end).hour {
            if interval > 0 {
                return "\(interval) hour\(interval == 1 ? "":"s") ago"
            }
        }

        if let interval = Calendar.current.dateComponents([Calendar.Component.minute], from: self, to: end).minute {
            if interval > 0 {
                return "\(interval) minute\(interval == 1 ? "":"s") ago"
            }
        }
        return "Just now."
    }
}

extension AVPlayer {
   func stop(){
    self.seek(to: CMTime.zero)
    self.pause()
   }
}
