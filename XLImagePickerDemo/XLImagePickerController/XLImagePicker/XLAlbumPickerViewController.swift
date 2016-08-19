//
//  XLAlbumPickerViewController.swift
//  XLImagePickerController
//
//  Created by PixelShi on 16/8/18.
//  Copyright © 2016年 shifengming. All rights reserved.
//

import UIKit
import Photos

typealias DismissHandler = (selectedItem: Dictionary<String, AnyObject>) -> Void

class XLAlbumPickerViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var collectionItems: [Dictionary<String, AnyObject>] = []
    var selectedCollectionItems: Dictionary<String, AnyObject> = [:]
    var dismissHandler: DismissHandler?
    var imageManager: PHCachingImageManager = PHCachingImageManager.init()

    override func loadView() {
        if let view = UINib.init(nibName: "XLAlbumPickerViewController", bundle: NSBundle(forClass: self.classForCoder)).instantiateWithOwner(self, options: nil).first as? UIView {
            self.view = view
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView()

        self.tableView.registerNib(UINib(nibName: "XLAlbumPickerCell", bundle: nil), forCellReuseIdentifier: "XLAlbumPickerCell")

    }

    @IBAction func dismissBtnTapped(sender: AnyObject) {
        if (self.dismissHandler != nil) {
            self.dismissHandler!(selectedItem: self.selectedCollectionItems)
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func doneBtnTapped(sender: AnyObject) {

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

private typealias Delegate = XLAlbumPickerViewController
extension Delegate : UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let collectionItem = self.collectionItems[indexPath.row]
        self.selectedCollectionItems = collectionItem
        self.tableView.reloadData()
        self.dismissBtnTapped(UIButton())
    }
}

private typealias DataSource = XLAlbumPickerViewController
extension DataSource : UITableViewDataSource {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.collectionItems.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCellWithReuseIdentifier("XLAlbumPickerCell", forIndexPath: indexPath) as! XLAlbumPickerCell
        let cell = tableView.dequeueReusableCellWithIdentifier("XLAlbumPickerCell", forIndexPath: indexPath) as! XLAlbumPickerCell

        let collectionItem = self.collectionItems[indexPath.row]
        print(self.collectionItems[indexPath.row])
        let fetchResult = collectionItem["assets"] as! PHFetchResult
        let collection = collectionItem["collection"]

        cell.setAlbumName((collection?.localizedTitle)!)
        cell.setPhotoCountText(fetchResult.count)

        if String(collectionItem["assets"]) == String(self.selectedCollectionItems["assets"]) {
            cell.accessoryType = .Checkmark;
        } else {
            cell.accessoryType = .None;
        }

        let asset = fetchResult.firstObject as! PHAsset
        cell.representedAssetIdentifier = asset.localIdentifier
        let scale: CGFloat = UIScreen.mainScreen().scale
        let targetSize: CGSize = CGSize(width: 40 * scale, height: 40 * scale)

        self.imageManager.requestImageForAsset(asset, targetSize: targetSize, contentMode: .AspectFill, options: nil, resultHandler: { (image, info) in

            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.setThumbnailImage(image!)
            }
        })
        return cell
    }

}
