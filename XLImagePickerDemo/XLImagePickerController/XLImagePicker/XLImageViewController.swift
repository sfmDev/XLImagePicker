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

typealias FetchAlbums = ((PHFetchResult) -> (Void))

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
    var currentCollectionItem: [String: AnyObject] = [:]
    var weakFetchAlbums = FetchAlbums?()
    var delegate: XLImageDelegate? = nil
    var collectionItems: [Dictionary<String,AnyObject>] = []
    var albumButton: UIButton = UIButton()

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

//        let smartAlbum = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: .AlbumRegular, options: nil)
//        print(smartAlbum)
        self.fetchCollections()
        self.createAlbumBtn()
        self.updateViewWithCollectionItem(self.collectionItems.first!)
    }

    private func fetchCollections() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        var allAblums: [Dictionary<String,AnyObject>] = []
//        var allAblums: [String: AnyObject] = []
        let smartAlbums: PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: .AlbumRegular, options: nil)

        var fetchAlbums: ((collections: PHFetchResult) -> Void)
        fetchAlbums = { [weak self] collections in
            guard let `self` = self else { return }

            let options = PHFetchOptions.init()
            options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.Image.rawValue)
            options.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: false)]

//            for item in collections {
//
//            }

            for i in 0 ..< collections.count {
                if collections.objectAtIndex(i) is PHAssetCollection {
                    let collection = collections.objectAtIndex(i) as! PHCollection
                    let assetCollection = collection as! PHAssetCollection
                    let assetFetchResult = PHAsset.fetchAssetsInAssetCollection(assetCollection, options: options)
                    if assetFetchResult.count > 0 {
//                        allAblums.append(["collection": assetCollection])
//                        allAblums.append(["assets": assetFetchResult])
                        allAblums.insert(["collection": collection, "assets": assetFetchResult], atIndex: allAblums.count)
                    }
                } else if collections.objectAtIndex(i) is PHCollectionList {
                    let collectionList = collections.objectAtIndex(i) as! PHCollectionList
                    let fetchResult = PHCollectionList.fetchCollectionsInCollectionList(collectionList, options: nil)
                    self.weakFetchAlbums!(fetchResult)
                }
            }
        }

        let topLevelUserCollections: PHFetchResult = PHCollectionList.fetchTopLevelUserCollectionsWithOptions(nil)
        fetchAlbums(collections: topLevelUserCollections)

        for index in 0..<smartAlbums.count {
            let collection = smartAlbums.objectAtIndex(index) as! PHAssetCollection
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.Image.rawValue)
            options.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: false)]

            let assetsFetchResult = PHAsset.fetchAssetsInAssetCollection(collection, options: options)
            if assetsFetchResult.count > 0 {
                if collection.assetCollectionSubtype == .SmartAlbumUserLibrary {
                    allAblums.insert(["collection": collection, "assets": assetsFetchResult], atIndex: 0)
                }
            } else {
//                allAblums.insert(["collection": collection, "assets": assetsFetchResult], atIndex: allAblums.count)
//                allAblums.append(["collection": collection])
//                allAblums.append(["assets": assetsFetchResult])
            }

        }
        self.collectionItems = allAblums
    }

    @IBAction func closeButtonTapped(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    private func updateViewWithCollectionItem(collectionItem: [String: AnyObject]) {
        self.currentCollectionItem = collectionItem
        let photoCollection: PHCollection = self.currentCollectionItem["collection"]! as! PHCollection

        albumButton.setTitle(photoCollection.localizedTitle, forState: .Normal)

        var arrowDownImage = UIImage(named: "YMSIconSpinnerDropdwon", inBundle: NSBundle.init(forClass: self.classForCoder), compatibleWithTraitCollection: nil)
        arrowDownImage = arrowDownImage?.imageWithRenderingMode(.AlwaysTemplate)

        albumButton.sizeToFit()
        albumButton.setImage(arrowDownImage, forState: .Normal)
        albumButton.imageEdgeInsets = UIEdgeInsetsMake(0.0, albumButton.frame.size.width - (arrowDownImage!.size.width) + 10, 0.0, 0.0)
        albumButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, -arrowDownImage!.size.width, 0.0, arrowDownImage!.size.width + 10)
        albumButton.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(albumButton.bounds) + 10, CGRectGetHeight(albumButton.bounds))

        albumButton.center = CGPoint(x: UIScreen.mainScreen().bounds.width / 2, y: self.topView.frame.size.height / 2)
        topView.addSubview(albumButton)
    }

    func createAlbumBtn() {
        self.albumButton = UIButton(type: .System)
        albumButton.tintColor = Handle.tintColor
        albumButton.titleLabel?.font = UIFont.systemFontOfSize(18)
        albumButton.tintAdjustmentMode = .Normal
        albumButton.addTarget(self, action: #selector(XLImageViewController.presentAlbumPickerView(_:)), forControlEvents: .TouchUpInside)
    }

    func presentAlbumPickerView(sender: UIButton) {
        let vc = XLAlbumPickerViewController()
        vc.selectedCollectionItems = self.currentCollectionItem
        vc.collectionItems = self.collectionItems
        vc.dismissHandler = { selectedCollectionItem in
            self.updateViewWithCollectionItem(selectedCollectionItem)
        }
        self.presentViewController(vc, animated: true, completion: nil)
    }

    @IBAction func successButtonTapped(sender: AnyObject) {

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
        albumView.frame = CGRect(origin: CGPoint.zero, size: photoContainerView.frame.size)
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
