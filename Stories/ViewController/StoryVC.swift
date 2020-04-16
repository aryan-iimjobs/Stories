//
//  StoryViewController.swift
//  Stories
//
//  Created by iim jobs on 11/04/20.
//  Copyright © 2020 Iimjobs. All rights reserved.
//

import UIKit
import AnimatedCollectionViewLayout
import Alamofire

protocol StoryVCProtocol: class {
    func reloadIconCollectionView(arrayCompanies: [CompanyModel])
}

class StoryVC: UIViewController {
    
    weak var delegate: StoryVCProtocol?
    
    private var hasDoneLayoutSubviews = false // prevent layouting again
    
    var goingToBackground = false
    var firstLaunch = true
    var selectedStoryIndex = 0
    var arrayCompanies: [CompanyModel]
    var currentStoryIndex: Int
    
    //var cellEndingDisplay: IndexPath!
    
    //touch point for swipeDown to dismiss animation
    var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
    
    //retreive value in viewWillLayoutSubViews
    var topSafeAreaMargin: CGFloat?
    
    let cellReuseIdentifier = "StoryCell"
    let collectionView: UICollectionView = {
        let layout = AnimatedCollectionViewLayout()
        layout.animator = CubeAttributesAnimator(perspective: -1/100, totalAngle: .pi/12)
        layout.scrollDirection = .horizontal;
        let cv = UICollectionView(frame: CGRect(x: 0,y: 0,width: UIScreen.main.bounds.width,height:  UIScreen.main.bounds.height), collectionViewLayout: layout);
        cv.register(StoryCell.self, forCellWithReuseIdentifier: "StoryCell")
        cv.showsHorizontalScrollIndicator = false
        cv.isPagingEnabled = true
        return cv;
    }();
    
    init(arrayCompanies: [CompanyModel], selectedStoryIndex: Int ) {
        self.selectedStoryIndex = selectedStoryIndex
        self.arrayCompanies = arrayCompanies
        self.currentStoryIndex = selectedStoryIndex
        super.init(nibName: nil, bundle: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.isIdleTimerDisabled = true // disable auto-lock
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appBackToForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        view.backgroundColor = .black
        
        view.addSubview(collectionView)
    
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .black
        collectionView.decelerationRate = .fast
        collectionView.layer.cornerRadius = 10
        
        let swipeUpRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeUp(_:)))
        swipeUpRecognizer.direction = .up
        swipeUpRecognizer.numberOfTouchesRequired = 1
        view.addGestureRecognizer(swipeUpRecognizer)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.swipeDown(_:)))
        panRecognizer.require(toFail: swipeUpRecognizer)
        view.addGestureRecognizer(panRecognizer)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.topSafeAreaMargin = view.safeAreaInsets.top
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if hasDoneLayoutSubviews { return }
        self.collectionView.frame = CGRect(x: 0,y: self.topSafeAreaMargin!,width: UIScreen.main.bounds.width,height:  UIScreen.main.bounds.height - self.topSafeAreaMargin!)
        
        let indexPath = IndexPath(item: self.selectedStoryIndex, section: 0)
        self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        hasDoneLayoutSubviews = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("StoryVC: viewWillDisappear")
        
        UIApplication.shared.isIdleTimerDisabled = false // enable auto-lock
        
        sortAndAppendSeenCompany()
        
        delegate?.reloadIconCollectionView(arrayCompanies: self.arrayCompanies)
        
        if let firstVC = presentingViewController as? HomeVC {
            firstVC.isDarkStatusBar.toggle()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let cell = collectionView.visibleCells[0] as! StoryCell
        cell.progressBar.resetBar()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        get{
            return .portrait // only portrait allowed
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func appBackToForeground() {
        print("StoryVC: View back in Foreground")
        let cell = collectionView.visibleCells[0] as! StoryCell
        cell.viewFocusGained()
        
        UIApplication.shared.isIdleTimerDisabled = true // enable auto-lock
    }
    
    @objc func appMovedToBackground() {
        print("StoryVC: moved to background")
        let cell = collectionView.visibleCells[0] as! StoryCell
        cell.viewFocucLost()
        
        UIApplication.shared.isIdleTimerDisabled = false // enable auto-lock
    }
    
    func sortAndAppendSeenCompany() {
        var seenCompanyArray: [CompanyModel] = []
        var unSeenCompanyArray: [CompanyModel] = []
        
        for company in arrayCompanies {
            var allSeen = true
            for story in company.stories {
                if !story.isSeen {
                    allSeen = false
                    break
                }
            }
            if allSeen {
                seenCompanyArray.append(company)
            } else {
                unSeenCompanyArray.append(company)
            }
        }
        
        seenCompanyArray.sort {$0.stories[0].createdOn > $1.stories[0].createdOn}
        
        print(arrayCompanies.count)
        
        for company in seenCompanyArray {
            unSeenCompanyArray.append(company)
        }
        
        self.arrayCompanies = unSeenCompanyArray
    }
    
    @objc func swipeUp(_ sender: UISwipeGestureRecognizer) {
        
        if sender.direction == .up {
            print("swipe up")
        }
    }
    
    @objc func swipeDown(_ sender: UIPanGestureRecognizer) {
        let cell = collectionView.visibleCells[0] as! StoryCell
        let touchPoint = sender.location(in: self.view?.window)
        if sender.state == UIGestureRecognizer.State.began {
            initialTouchPoint = touchPoint
            cell.viewFocucLost()
        } else if sender.state == UIGestureRecognizer.State.changed {
            if touchPoint.y - initialTouchPoint.y > 0 {
                self.collectionView.frame = CGRect(x: 0, y: touchPoint.y - initialTouchPoint.y + self.topSafeAreaMargin!, width: self.collectionView.frame.size.width, height: self.collectionView.frame.size.height)
                self.view.backgroundColor = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha:1 - (touchPoint.y - initialTouchPoint.y) / 200)
            }
        } else if sender.state == UIGestureRecognizer.State.ended || sender.state == UIGestureRecognizer.State.cancelled {
            if touchPoint.y - initialTouchPoint.y > 200 {

                UIView.animate(withDuration: 0.15, animations: {
                    self.collectionView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height, width: self.collectionView.frame.size.width, height: self.collectionView.frame.size.height)

                }, completion: { finished in
                    if cell.isAnimating {
                        cell.stories[cell.currentSnap].isSeen = true
                    }
                    self.dismiss(animated: true, completion: nil)
                })

            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.backgroundColor = .black
                    self.collectionView.frame = CGRect(x: 0, y: self.topSafeAreaMargin!, width: self.collectionView.frame.size.width, height: self.collectionView.frame.size.height)
                }, completion: { finished in
                    cell.viewFocusGained()
                })
            }
        }
    }
}

//MARK:- CollectionView DataSource
extension StoryVC: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        arrayCompanies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellReuseIdentifier, for: indexPath) as! StoryCell
        
        cell.parentStoryIndex = indexPath.item
        cell.stories = arrayCompanies[indexPath.item].stories
        cell.arrayCompanies = self.arrayCompanies
        cell.initProgressbar()
        cell.storyCompanyId = arrayCompanies[indexPath.item].storyCompanyId
        
        cell.companyTitle.text = arrayCompanies[indexPath.item].companyName
        
        //get images
        cell.getIconImage(address: arrayCompanies[indexPath.item].companyLogo)
        
        for i in 0...arrayCompanies[indexPath.item].stories.count - 1 {
            let snap = arrayCompanies[indexPath.item].stories[i]
            cell.getSnapImage(address: snap.s3Path, index: i)
        }
        
        cell.delegate = self
        
        if arrayCompanies[indexPath.item].showcaseDetail.v2showcaseId == "" {
            cell.showcaseDetailLabel.isHidden = true
        }
        
        if firstLaunch && selectedStoryIndex == indexPath.row {
            print("StoryVC: first launch")
            firstLaunch = false
            self.currentStoryIndex = selectedStoryIndex
            cell.isCompletelyVisible = true
        }
        
        cell.loadIconImage()
        cell.loadSnapImage()
        
        return cell
    }
}

//MARK:- CollectionView FlowLayout Delegate
extension StoryVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    //Handle progressView when scrolling over stories
    //not called when programmatically scrolling, like on tap/auto
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.collectionView.isUserInteractionEnabled = true
        var cell: StoryCell
        let visibleCells = collectionView.visibleCells
        
        if visibleCells.count > 1 {
            cell = collectionView.cellForItem(at: scrollToMostVisibleCell()) as! StoryCell
        } else {
            cell = visibleCells.first as! StoryCell
        }
        
        //print("StoryVC: endedDecel on \(cell.parentStoryIndex!) .. countvisible \(visibleCells.count)")
        if cell.parentStoryIndex != currentStoryIndex {
            cell.isCompletelyVisible = true
            cell.animate()
            currentStoryIndex = cell.parentStoryIndex
        } else {
            //print("..but same cell")
        }
    }
    
    //disable user interaction when scrolling fast using taps **
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //print("StoryVC: didScroll")
        if self.selectedStoryIndex != 0 && self.firstLaunch {
            //do nothing
        } else {
            self.collectionView.isUserInteractionEnabled = false
        }
    }
    
    //Handle progressView when auto/tap scroll over stories
    //not called when scrolling over cells(stories)
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.collectionView.isUserInteractionEnabled = true
        var cell: StoryCell
        let visibleCells = collectionView.visibleCells
        
        if visibleCells.count > 1 {
            cell = collectionView.cellForItem(at: scrollToMostVisibleCell()) as! StoryCell
        } else {
            cell = visibleCells.first as! StoryCell
        }
        
        //print("StoryVC: endedScrollAnim on \(cell.parentStoryIndex!) .. countvisible \(visibleCells.count) .. oldIndex \(currentStoryIndex!)")
        if cell.parentStoryIndex != currentStoryIndex {
            cell.isCompletelyVisible = true
            cell.animate()
            currentStoryIndex = cell.parentStoryIndex
        } else {
            //print("..but same cell")
        }
    }
    
    func scrollToMostVisibleCell() -> IndexPath {
      let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        let visibleIndexPath: IndexPath = collectionView.indexPathForItem(at: visiblePoint)!
        
        //print("StoryVC: mostVisibleCell is \(visibleIndexPath.item)")
        return visibleIndexPath
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        print("StoryVC: endedDisplay of \(indexPath.item)")
        let oldCell = cell as! StoryCell
        print("---reset cell---")
        
        if oldCell.isAnimating {
            oldCell.stories[oldCell.currentSnap].isSeen = true
        }
        
        oldCell.progressBar.resetBar()
        oldCell.isCompletelyVisible = false
        oldCell.isAnimating = false
        oldCell.videoView.snapVideo.replaceCurrentItem(with: nil)
//        if !goingToBackground {
//
//        } else {
//            self.cellEndingDisplay = indexPath
//        }
    }
}


//MARK:- StoryCell delegates
extension StoryVC: StoryPreviewProtocol {
    func moveToNextStory(from storyIndex: Int) {
        if storyIndex < arrayCompanies.count - 1 {
            print("StoryVC: next Story")
            let indexPath = IndexPath(item: storyIndex + 1, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .right, animated: true)
        } else {
            print("StoryVC: exit from right")
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func moveToPreviousStory(from storyIndex: Int) {
        if storyIndex >= 1 {
            print("StoryVC: previous Story")
            let indexPath = IndexPath(item: storyIndex - 1, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .left, animated: true)
        } else {
            print("StoryVC: exit from left")
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func didTapBlockButton(from storyIndex: Int) {
        let cell = collectionView.visibleCells[0] as! StoryCell
        print("StoryVC: block Company  pressed")
        cell.progressBar.pause()
        cell.videoView.snapVideo.pause()
        
        let alert = UIAlertController(title: "Block '\(arrayCompanies[currentStoryIndex].companyName)'?", message: "You will no longer receive stories from this company. ", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Block", comment: "Default action"), style: .destructive, handler: { _ in
            
            let parameters = [
                "en_cookie": "YfQPsWVCWD2_PLUS_jMqXVYtI1IBJJNpBjdt5LAXzVToFgzdfmcpNVboBZoOb9cHPfl6nO9a59AvIZNir00EB26b0aA_EQUALS__EQUALS_",
                "blockCompany": "\(self.arrayCompanies[self.currentStoryIndex].companyId)"
            ]
            
            AF.request(URL.init(string: "https://bidder.hirist.com/api7/blockstories")!, method: .post, parameters: parameters, encoding: URLEncoding.default).responseJSON { (response) in
                print("Company Blocked \(response)")
            }
            // remove company
            for (company, index) in zip(self.arrayCompanies, 0..<self.arrayCompanies.count) {
                if company.companyId == self.arrayCompanies[self.currentStoryIndex].companyId {
                    self.arrayCompanies.remove(at: index)
                    break
                }
            }
            self.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Default action"), style: .cancel, handler: { _ in
            cell.blockAlertActive = false
            cell.progressBar.resume()
            cell.videoView.snapVideo.play()
        }))
        self.present(alert, animated: true, completion: nil)
    }
}

