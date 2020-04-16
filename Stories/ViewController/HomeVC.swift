//
//  ViewController.swift
//  Stories
//
//  Created by iim jobs on 09/04/20.
//  Copyright © 2020 Iimjobs. All rights reserved.
//

import UIKit

class HomeVC: UIViewController {
    
    var isDarkStatusBar = true {
        didSet {
            UIView.animate(withDuration: 0.3) {
                self.setNeedsStatusBarAppearanceUpdate()
            }
            
        }
    }
        
    var dotStories: DotStories!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dotStories = DotStories()
        dotStories.initializeStories(parentVC: self)
        dotStories.translatesAutoresizingMaskIntoConstraints = false;
        view.addSubview(dotStories)
        
        dotStories.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true;
        dotStories.rightAnchor.constraint(equalTo:  view.rightAnchor).isActive = true;
        dotStories.topAnchor.constraint(equalTo:  view.safeAreaLayoutGuide.topAnchor).isActive = true;
        dotStories.heightAnchor.constraint(equalToConstant: 100).isActive = true;
        dotStories.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true;
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        //if view is light-dark then .dark-.light
        if #available(iOS 13.0, *) {
            return isDarkStatusBar ? .darkContent : .lightContent
        }
        return isDarkStatusBar ? UIStatusBarStyle.default : .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("MainVC: vc will disappear")
        dotStories.saveToCoreData(companies: dotStories.arrayCompanies)
    }
}
