//
//  KolodaPhotoView.swift
//  Koloda
//
//  Created by Eugene Andreyev on 8/20/15.
//  Copyright (c) 2015 CocoaPods. All rights reserved.
//

import UIKit

extension UIImageView {
    public func imageFromUrl(urlString: String) {
        if let url = NSURL(string: urlString) {
            let request = NSURLRequest(URL: url)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {[unowned self] response, data, error in
                if let data = data {
                    self.image = UIImage(data: data)
                }
            })
        }
    }
}

class KolodaPhotoView: UIView {

    @IBOutlet var photoImageView: UIImageView?
    @IBOutlet var photoTitleLabel: UILabel?
    

}
