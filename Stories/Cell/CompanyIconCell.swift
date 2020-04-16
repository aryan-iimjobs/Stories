//
//  CompanyIconCell.swift
//  Stories
//
//  Created by iim jobs on 09/04/20.
//  Copyright © 2020 Iimjobs. All rights reserved.
//

import UIKit
import Alamofire

//custom View
class IconImageView: UIView {
    
    let padding: CGFloat = 5 // space between icon and the IconImageView
    
    let imageView: UIImageView = {
        let iv = UIImageView()
        
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .white
        iv.clipsToBounds = false
        
        return iv
    }()
    
    let imageBackShadow: UIView = {
        let iv = UIView()
        
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageBackShadow.frame = CGRect(x: padding, y: padding, width: frame.width - (padding * 2), height: frame.height - (padding * 2))
        imageBackShadow.backgroundColor = .white
        imageBackShadow.layer.cornerRadius = (frame.width - (padding * 2)) / 2
        imageBackShadow.addShadow(offset: CGSize.init(width: 0, height: 5), color: UIColor.black, radius: 8.0, opacity: 0.15)
        imageBackShadow.layer.shouldRasterize = true
        imageBackShadow.layer.rasterizationScale = UIScreen.main.scale
        addSubview(imageBackShadow)
        sendSubviewToBack(imageBackShadow)
        
        imageView.layer.cornerRadius = (frame.width - (padding * 2)) / 2
        imageView.layer.masksToBounds = true
        imageView.frame = CGRect(x: padding, y: padding, width: frame.width - (padding * 2), height: frame.height - (padding * 2))
        imageView.layer.borderColor = UIColor(displayP3Red: 128/255, green: 128/255, blue: 128/255, alpha: 0.11).cgColor
        imageView.layer.borderWidth = 1
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class CompanyIconCell: UICollectionViewCell {
    var companyId: String?
    let gapIconAndTitle: CGFloat = 0 //space bw icon and title label
    
    let icon: IconImageView = {
        let i = IconImageView()
        i.backgroundColor = .white
        return i
    }()
    
    let companyTitle: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.textColor = .gray
        l.font = UIFont(name: "HelveticaNeue",size: 15.0)
//        l.layer.borderColor = UIColor.red.cgColor
//        l.layer.borderWidth = 1
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        icon.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.width)
        icon.layer.cornerRadius = frame.width / 2
        addSubview(icon)
        
        companyTitle.frame = CGRect(x: 0, y: icon.frame.height + self.gapIconAndTitle, width: frame.width, height: frame.height - icon.frame.height - self.gapIconAndTitle)
        addSubview(companyTitle)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        icon.imageView.image = nil
        companyTitle.text = ""
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//network requests
extension CompanyIconCell {
    
    func getImage(address: String) {
        let key = self.companyId!
        
        if FileManager.default.fileExists(atPath: filePath(forKey: key)!.path) {
            self.icon.imageView.image = retrieveImage(forKey: key)!
        } else {
            AF.request(address).downloadProgress { progress in
            }.response { response in
                if case .success(let imageData) = response.result {
                    self.icon.imageView.image = UIImage(data: imageData!)!
                    self.store(data: imageData!, forKey: key)
                }
            }
        }
    }
}

// save/load image
extension CompanyIconCell {
    func store(data: Data, forKey key: String) {
        let pngRepresentation = data
            if let filePath = filePath(forKey: key) {
                do  {
                    try pngRepresentation.write(to: filePath, options: .atomic)
                } catch let err {
                    print("Saving Company Icon resulted in error: ", err)
                }
            }
        
    }
    
    func retrieveImage(forKey key: String) -> UIImage? {
        if let filePath = filePath(forKey: key),
            let fileData = FileManager.default.contents(atPath: filePath.path),
            let image = UIImage(data: fileData) {
            return image
        }
        return nil
    }
    
    func filePath(forKey key: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(for: .cachesDirectory,
                                                in: FileManager.SearchPathDomainMask.userDomainMask).first else { return nil }
        
        return documentURL.appendingPathComponent(key + "")
    }
}

extension UIView {

    func addShadow(offset: CGSize, color: UIColor, radius: CGFloat, opacity: Float) {
        layer.masksToBounds = false
        layer.shadowOffset = offset
        layer.shadowColor = color.cgColor
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity

        let backgroundCGColor = backgroundColor?.cgColor
        backgroundColor = nil
        layer.backgroundColor =  backgroundCGColor
    }
}
