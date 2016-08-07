//
//  ViewController.swift
//  XLImagePickerController
//
//  Created by PixelShi on 16/8/2.
//  Copyright © 2016年 shifengming. All rights reserved.
//

import UIKit

class ViewController: UIViewController, XLImageDelegate {

    @IBOutlet weak var collectionView: UICollectionView!

    var selectedImage: [UIImage] = []

    @IBAction func enterButtonTapped(sender: AnyObject) {
        let xl = XLImageViewController()
        xl.delegate = self
        self.presentViewController(xl, animated: true, completion: nil)
    }

    func XL_imageSelected(image: UIImage) {
        self.selectedImage.append(image)
        self.collectionView.reloadData()
    }

    func XL_dismissWithImage(image: UIImage) {
        print("Called just after dismissed")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.registerNib(UINib(nibName: "XLAlbumViewCell", bundle: NSBundle(forClass: self.classForCoder)), forCellWithReuseIdentifier: "XLAlbumViewCell")
        collectionView.backgroundColor = Handle.backgroudColor
    }
}

private typealias Delegate = ViewController
extension Delegate: UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectedImage.count ?? 0
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        let width = (collectionView.frame.width - 3) / 4
        return CGSize(width: width, height: width)
    }
}

private typealias DataSource = ViewController
extension DataSource: UICollectionViewDataSource {

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("XLAlbumViewCell", forIndexPath: indexPath) as! XLAlbumViewCell

        cell.image = selectedImage[indexPath.row]

        return cell
    }

}


