//
//  XLImageViewController.swift
//  XLImagePickerController
//
//  Created by PixelShi on 16/8/2.
//  Copyright © 2016年 shifengming. All rights reserved.
//

import UIKit
import Photos

@objc public protocol XLImageDelegate {
    func XL_imageSelected(image: UIImage)
    optional func XL_dismissWithImage(image: UIImage)
}

public struct Handle {
    static let backgroudColor = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1.0)
    static let tintColor = UIColor(red: 0/255, green: 150/255, blue: 136/255, alpha: 1.0)
    static let KUpImageCountNotification: String = "upImageCountNotification"
}

class XLImageViewController: UIViewController {

    @IBOutlet weak var photoContainerView: UIView!
    @IBOutlet weak var imageCountLabel: UILabel!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIView!

    var delegate: XLImageDelegate? = nil

    lazy var albumView = XLAlbumView.instance()

    override func loadView() {
        if let view = UINib.init(nibName: "XLImageViewController", bundle: NSBundle(forClass: self.classForCoder)).instantiateWithOwner(self, options: nil).first as? UIView {
            self.view = view
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = Handle.backgroudColor

        topView.backgroundColor = Handle.backgroudColor
        topView.addBottomBorder(UIColor.blackColor(), width: 1.0)
        self.view.bringSubviewToFront(topView)

        photoContainerView.addSubview(albumView)

        imageCountLabel.textColor = Handle.tintColor

        self.imageCountLabel.text = "照片: 0 / 9 张 "

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(XLImageViewController.updateImageCountLabel(_:)), name: Handle.KUpImageCountNotification, object: nil)

        let smartAlbum = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: .AlbumRegular, options: nil)
        print(smartAlbum)
    }

    @IBAction func closeButtonTapped(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }


    @IBAction func successButtonTapped(sender: AnyObject) {
//        print(albumView.seletedImageArray)
        print(albumView.phAssetArray.count)
        print(albumView.phAssetArray)

        let view = albumView.imageView

        if albumView.phAssetArray.count > 0 {

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {

                _ = self.albumView.phAssetArray.map { phImage in
                    let normalizedX = view.contentOffset.x / view.contentSize.width
                    let normalizedY = view.contentOffset.y / view.contentSize.height

                    let normalizedWidth = view.frame.width / view.contentSize.width
                    let normalizedHeight = view.frame.height / view.contentSize.height

                    let cropRect = CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)

                    let options = PHImageRequestOptions()
                    options.deliveryMode = .HighQualityFormat
                    options.networkAccessAllowed = true
                    options.normalizedCropRect = cropRect
                    options.resizeMode = .Exact

                    let targetWidth = floor(CGFloat(self.albumView.phAsset.pixelWidth) * cropRect.width)
                    let targetHeight = floor(CGFloat(self.albumView.phAsset.pixelHeight) * cropRect.height)
                    let dimension = max(min(targetHeight, targetWidth), 1024 * UIScreen.mainScreen().scale)

                    let targetSize = CGSize(width: dimension, height: dimension)

                    PHImageManager.defaultManager().requestImageForAsset(phImage, targetSize: targetSize, contentMode: .AspectFill, options: options, resultHandler: { result, info in

                        dispatch_async(dispatch_get_main_queue(), { 
                            self.delegate?.XL_imageSelected(result!)

                            self.dismissViewControllerAnimated(true, completion: { 
                                self.delegate?.XL_dismissWithImage!(result!)
                            })
                        })
                    })
                }
            })

        } else {
            // MARK: - no image
            self.delegate?.XL_imageSelected(view.image)
            self.dismissViewControllerAnimated(true, completion: {
                self.delegate?.XL_dismissWithImage!(view.image)
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        albumView.frame = CGRect(origin: CGPointZero, size: photoContainerView.frame.size)
        albumView.layoutIfNeeded()

        albumView.initialize()
    }

    func updateImageCountLabel(noti: NSNotification) {
        self.imageCountLabel(albumView.phAssetArray.count)
    }

    func imageCountLabel(count: Int) {
        self.imageCountLabel.text = "照片: \(count) / 9 张 "
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension UIView {

    func addBottomBorder(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.borderColor = color.CGColor
        border.frame = CGRect(x: 0, y: self.frame.size.height - width, width:  self.frame.size.width, height: width)
        border.borderWidth = width
        self.layer.addSublayer(border)
    }

}