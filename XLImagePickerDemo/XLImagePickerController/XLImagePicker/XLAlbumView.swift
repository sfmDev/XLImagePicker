//
//  XLAlbumView.swift
//  XLImagePickerController
//
//  Created by PixelShi on 16/8/2.
//  Copyright © 2016年 shifengming. All rights reserved.
//

import UIKit
import Photos

@objc protocol XLAlbumViewDelegate: class {

    func albumViewCameraRollUnauthorized()
}

enum Direction {
    case Scroll
    case Stop
    case Up
    case Down
}

private extension Selector {
    static let bePanned = #selector(XLAlbumView.bePanned(_:))
    static let updateImage = #selector(XLAlbumView.upDatedImage(_:))
}

final class XLAlbumView: UIView, PHPhotoLibraryChangeObserver, UIGestureRecognizerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var imageContainerView: UIView!
    @IBOutlet weak var imageView: XLImageBrowerView!
    @IBOutlet weak var collectionViewConstraintHeight: NSLayoutConstraint!
    @IBOutlet weak var imageViewConstraintTop: NSLayoutConstraint!

    weak var delegate: XLAlbumViewDelegate? = nil

    var images: PHFetchResult!
    var imageManager: PHCachingImageManager?
    var previousPreheatRect: CGRect = CGRectZero
    let cellSize                    = CGSize(width: 100, height: 100)
    var phAsset: PHAsset!
    var phAssetArray: [PHAsset] = []

    let imageViewOriginalConstraintTop: CGFloat     = 50
    let imageViewMinVisibleHeight: CGFloat          = 100
    var dragDirection                               = Direction.Up
    var imageCollectionViewOffsetStartPosY: CGFloat = 0.0

    var cropBottomY: CGFloat  = 0.0
    var dragStartPos: CGPoint = CGPointZero
    let dragDiff: CGFloat     = 20.0

//    var seletedImageArray: [PHAsset] = []
    var seletedImageArray: [PHAsset] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: .updateImage, name: Handle.KUpImageWithAssetNotification, object: nil)
    }

    static func instance() -> XLAlbumView {
        return UINib(nibName: "XLAlbumView", bundle: NSBundle(forClass: self.classForCoder())).instantiateWithOwner(self, options: nil)[0] as! XLAlbumView
    }

    func initialize() {
        if images != nil {
            return
        }

        self.hidden = false

        let pan = UIPanGestureRecognizer(target: self, action: .bePanned)
        pan.delegate = self
        self.addGestureRecognizer(pan)

        collectionViewConstraintHeight.constant = self.frame.height - imageView.frame.width - imageViewOriginalConstraintTop
        imageViewConstraintTop.constant = 50
        dragDirection = Direction.Up

        imageContainerView.layer.shadowColor = UIColor.blackColor().CGColor
        imageContainerView.layer.shadowRadius = 10.0
        imageContainerView.layer.shadowOpacity = 0.9
        imageContainerView.layer.shadowOffset = CGSizeZero

        collectionView.registerNib(UINib(nibName: "XLAlbumViewCell", bundle: NSBundle(forClass: self.classForCoder)), forCellWithReuseIdentifier: "XLAlbumViewCell")
        collectionView.backgroundColor = Handle.backgroudColor
        collectionView.delegate = self
        collectionView.dataSource = self

        checkPhotoAuth()

        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]

        images = PHAsset.fetchAssetsWithMediaType(.Image, options: options)

        if images.count > 0 {
            changeImage(images[0] as! PHAsset)
            collectionView.reloadData()
        }

        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
    }

    deinit {
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized {
            PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
        }
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        return true
    }

    func bePanned(sender: UIPanGestureRecognizer) {

        if sender.state == UIGestureRecognizerState.Began {
            let view    = sender.view
            let loc     = sender.locationInView(view)
            let subview = view?.hitTest(loc, withEvent: nil)

            if subview == imageView && imageViewConstraintTop.constant == imageViewOriginalConstraintTop {
                return
            }

            dragStartPos = sender.locationInView(self)

            cropBottomY = self.imageContainerView.frame.origin.y + self.imageContainerView.frame.height

            if dragDirection == .Stop {
                dragDirection = (imageViewConstraintTop.constant == imageViewOriginalConstraintTop) ? .Up : .Down
            }

            if (dragDirection == .Up && dragStartPos.y < cropBottomY + dragDiff) || (dragDirection == .Down && dragStartPos.y > cropBottomY ) {

                dragDirection = .Stop
                imageView.changeScrollable(false)
            } else {
                imageView.changeScrollable(true)
            }
        } else if sender.state == .Changed {
            let currentPos = sender.locationInView(self)

            if dragDirection == .Up && currentPos.y < cropBottomY - dragDiff {

                imageViewConstraintTop.constant = max(imageViewMinVisibleHeight - self.imageContainerView.frame.height, currentPos.y + dragDiff - imageContainerView.frame.height)
                collectionViewConstraintHeight.constant = min(self.frame.height - imageViewMinVisibleHeight,  self.frame.height - imageViewConstraintTop.constant - imageContainerView.frame.height)

            } else if dragDirection == .Down && currentPos.y > cropBottomY {

                imageViewConstraintTop.constant = min(imageViewOriginalConstraintTop, currentPos.y - imageContainerView.frame.height)
                collectionViewConstraintHeight.constant = max(self.frame.height - imageViewOriginalConstraintTop - imageContainerView.frame.height, self.frame.height - imageViewConstraintTop.constant - imageContainerView.frame.height)

            } else if dragDirection == .Stop && collectionView.contentOffset.y < 0 {

                dragDirection = .Scroll
                imageCollectionViewOffsetStartPosY = currentPos.y

            } else if dragDirection == .Scroll {

                imageViewConstraintTop.constant = imageViewMinVisibleHeight - self.imageContainerView.frame.height + currentPos.y - imageCollectionViewOffsetStartPosY
                collectionViewConstraintHeight.constant = max(self.frame.height - imageViewOriginalConstraintTop - imageContainerView.frame.height, self.frame.height - imageViewConstraintTop.constant - imageContainerView.frame.height)
            }
        } else {

            imageCollectionViewOffsetStartPosY = 0.0

            if sender.state == .Ended && dragDirection == .Stop {
                imageView.changeScrollable(true)
                return
            }

            let currentPos = sender.locationInView(self)

            if currentPos.y < cropBottomY - dragDiff && imageViewConstraintTop.constant != imageViewOriginalConstraintTop {
                imageView.changeScrollable(true)

                imageViewConstraintTop.constant = imageViewMinVisibleHeight - self.imageContainerView.frame.height

                collectionViewConstraintHeight.constant = self.frame.height - imageViewMinVisibleHeight

                UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseOut, animations: { 
                    self.layoutIfNeeded()
                    }, completion: nil)
                dragDirection = .Down
            } else {
                imageView.changeScrollable(true)

                imageViewConstraintTop.constant = imageViewOriginalConstraintTop
                collectionViewConstraintHeight.constant = self.frame.height - imageViewOriginalConstraintTop - imageContainerView.frame.height

                UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseOut, animations: {
                    self.layoutIfNeeded()
                    }, completion: nil)

                dragDirection = .Up
            }
        }

    }

    func upDatedImage(noti: NSNotification) {
        self.images = noti.userInfo!["assets"] as! PHFetchResult
        changeImage(images[0] as! PHAsset)
        self.collectionView.reloadData()
    }

    //MARK: - PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(changeInstance: PHChange) {

        dispatch_async(dispatch_get_main_queue()) {

            let collectionChanges = changeInstance.changeDetailsForFetchResult(self.images)
            if collectionChanges != nil {

                self.images = collectionChanges!.fetchResultAfterChanges

                let collectionView = self.collectionView!

                if !collectionChanges!.hasIncrementalChanges || collectionChanges!.hasMoves {

                    collectionView.reloadData()

                } else {

                    collectionView.performBatchUpdates({
                        let removedIndexes = collectionChanges!.removedIndexes
                        if (removedIndexes?.count ?? 0) != 0 {
                            collectionView.deleteItemsAtIndexPaths(removedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                        }
                        let insertedIndexes = collectionChanges!.insertedIndexes
                        if (insertedIndexes?.count ?? 0) != 0 {
                            collectionView.insertItemsAtIndexPaths(insertedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                        }
                        let changedIndexes = collectionChanges!.changedIndexes
                        if (changedIndexes?.count ?? 0) != 0 {
                            collectionView.reloadItemsAtIndexPaths(changedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                        }
                        }, completion: nil)
                }

                self.resetCachedAssets()
            }
        }
    }
}

extension XLAlbumView {

    private func checkPhotoAuth() {
        PHPhotoLibrary.requestAuthorization { (status) -> Void in
            switch status {

            case .Authorized:
                self.imageManager = PHCachingImageManager()
                if self.images != nil && self.images.count > 0 {
                    // MARK: - other function
                }

            case .Restricted,.Denied:
                dispatch_async(dispatch_get_main_queue(), { () -> Void in

                    self.delegate?.albumViewCameraRollUnauthorized()

                })
                
            default:
                break
            }
        }
    }

    func changeImage(asset: PHAsset) {
        self.imageView.image = nil
        self.phAsset = asset

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { 
            let options = PHImageRequestOptions()
            options.networkAccessAllowed = true

            self.imageManager?.requestImageForAsset(asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .AspectFill, options: options, resultHandler: { result, info in

                dispatch_async(dispatch_get_main_queue(), { 

                    self.imageView.imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                    self.imageView.image = result
                })
            })
        }
    }

    // MARK: - Asset 
    func resetCachedAssets() {
        imageManager?.stopCachingImagesForAllAssets()
        previousPreheatRect = CGRectZero
    }

    func updateCachedAssets() {

        var preheatRect = self.collectionView.bounds
        preheatRect = CGRectInset(preheatRect, 0.0, -0.5 * CGRectGetHeight(preheatRect))

        let delta = abs(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect))
        if delta > CGRectGetHeight(self.collectionView!.bounds) / 3.0 {

            var addedIndexPaths: [NSIndexPath] = []
            var removedIndexPaths: [NSIndexPath] = []

            self.computeDifferenceBetweenRect(self.previousPreheatRect, andRect: preheatRect, removedHandler: { (removedRect) in

                }, addedHandler: { addRect in

            })

            self.computeDifferenceBetweenRect(self.previousPreheatRect, andRect: preheatRect, removedHandler: {removedRect in
                let indexPaths = self.collectionView.aapl_indexPathsForElementsInRect(removedRect)
                removedIndexPaths += indexPaths
                }, addedHandler: {addedRect in
                    let indexPaths = self.collectionView.aapl_indexPathsForElementsInRect(addedRect)
                    addedIndexPaths += indexPaths
            })

            let assetsToStartCaching = assetsAtIndexPaths(addedIndexPaths)
            let assetsToStopCaching = assetsAtIndexPaths(removedIndexPaths)

            self.imageManager?.startCachingImagesForAssets(assetsToStartCaching,
                                                           targetSize: cellSize,
                                                           contentMode: .AspectFill,
                                                           options: nil)
            self.imageManager?.stopCachingImagesForAssets(assetsToStopCaching,
                                                          targetSize: cellSize,
                                                          contentMode: .AspectFill,
                                                          options: nil)
            
            self.previousPreheatRect = preheatRect

        }
    }

    func computeDifferenceBetweenRect(oldRect: CGRect, andRect newRect: CGRect, removedHandler: CGRect->Void, addedHandler: CGRect->Void) {
        if CGRectIntersectsRect(newRect, oldRect) {
            let oldMaxY = CGRectGetMaxY(oldRect)
            let oldMinY = CGRectGetMinY(oldRect)
            let newMaxY = CGRectGetMaxY(newRect)
            let newMinY = CGRectGetMinY(newRect)
            if newMaxY > oldMaxY {
                let rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY))
                addedHandler(rectToAdd)
            }
            if oldMinY > newMinY {
                let rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY))
                addedHandler(rectToAdd)
            }
            if newMaxY < oldMaxY {
                let rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY))
                removedHandler(rectToRemove)
            }
            if oldMinY < newMinY {
                let rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY))
                removedHandler(rectToRemove)
            }
        } else {
            addedHandler(newRect)
            removedHandler(oldRect)
        }
    }

    func assetsAtIndexPaths(indexPaths: [NSIndexPath]) -> [PHAsset] {
        if indexPaths.count == 0 { return [] }

        var assets: [PHAsset] = []
        assets.reserveCapacity(indexPaths.count)
        for indexPath in indexPaths {
            let asset = self.images[indexPath.item] as! PHAsset
            assets.append(asset)
        }
        return assets
    }

    func countAtIndex(index: Int, array: [Int]) -> Int {
        var count: Int = 0
        var atIndex: Int = 0
        _ = array.map {
            if $0 == 1 && atIndex <= index {
                count += 1
            }
            atIndex += 1
        }
        return  count
    }

    func canAddPhoto() -> Bool {
        return self.seletedImageArray.count < 9
    }
}

//private typealias FlowOut = XLAlbumView

private typealias Delegate = XLAlbumView
extension Delegate: UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
         return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count ?? 0
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        let width = (collectionView.frame.width - 3) / 4
        return CGSize(width: width, height: width)
    }
}

private typealias DataSource = XLAlbumView
extension DataSource: UICollectionViewDataSource {

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("XLAlbumViewCell", forIndexPath: indexPath) as! XLAlbumViewCell

        let currentTag = cell.tag + 1
        cell.tag = currentTag

        let asset = self.images[indexPath.item] as! PHAsset
        self.imageManager?.requestImageForAsset(asset, targetSize: cellSize, contentMode: .AspectFill, options: nil) { result, info in
            if cell.tag == currentTag {
                cell.image = result
            }

        }

        if self.seletedImageArray.contains(asset) {
            let selectionIndex = self.seletedImageArray.indexOf(asset)
            print("selectionIndex ===\(selectionIndex)")
            cell.selectionOrder = selectionIndex! + 1
        }
        return cell
    }

    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        if cell is XLAlbumViewCell {
            (cell as! XLAlbumViewCell).animateHigtLight(true)
        }
    }

    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {

        if !self.canAddPhoto() {
            return false
        }

        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        if cell is XLAlbumViewCell {
            let albumViewCell = cell as! XLAlbumViewCell
            albumViewCell.setNeedsAniamteSection()
            albumViewCell.selectionOrder = self.seletedImageArray.count + 1
        }
        return true
    }

    func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        if cell is XLAlbumViewCell {
            (cell as! XLAlbumViewCell).animateHigtLight(false)
        }
    }

    func collectionView(collectionView: UICollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        if cell is XLAlbumViewCell {
            (cell as! XLAlbumViewCell).setNeedsAniamteSection()
        }
        return true
    }

    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {

        let fetchResult = self.images
        let asset = self.images[indexPath.item] as! PHAsset

        let removedIndex: Int = self.seletedImageArray.indexOf(asset)!
        print("removedIndex=====\(removedIndex)")
        
        for index in (removedIndex)..<(self.seletedImageArray.count) {

            let needReloadAsset = self.seletedImageArray[index]
            let cell = collectionView.cellForItemAtIndexPath(NSIndexPath.init(forItem: (fetchResult.indexOfObject(needReloadAsset)), inSection: indexPath.section)) as! XLAlbumViewCell
            cell.selectionOrder = cell.selectionOrder!
        }

//        self.seletedImageArray =  self.seletedImageArray.filter({ $0 != asset})

        if self.seletedImageArray.count == 0 {

        }
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        changeImage(images[indexPath.item] as! PHAsset)

        let asset = self.images[indexPath.row] as! PHAsset
        self.seletedImageArray.append(asset)
        NSNotificationCenter.defaultCenter().postNotificationName(Handle.KUpImageCountNotification, object: nil)

        imageView.changeScrollable(true)

        imageViewConstraintTop.constant = imageViewOriginalConstraintTop
        collectionViewConstraintHeight.constant = self.frame.height - imageViewOriginalConstraintTop - imageContainerView.frame.height

        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut, animations: { 
            self.layoutIfNeeded()
            }, completion: nil)

        dragDirection = Direction.Up
        collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView == collectionView {
            self.updateCachedAssets()
        }
    }
}

extension UICollectionView {

    func aapl_indexPathsForElementsInRect(rect: CGRect) -> [NSIndexPath] {
        let allLayoutAttributes = self.collectionViewLayout.layoutAttributesForElementsInRect(rect)
        if (allLayoutAttributes?.count ?? 0) == 0 {return []}
        var indexPaths: [NSIndexPath] = []
        indexPaths.reserveCapacity(allLayoutAttributes!.count)
        for layoutAttributes in allLayoutAttributes! {
            let indexPath = layoutAttributes.indexPath
            indexPaths.append(indexPath)
        }
        return indexPaths
    }
}

extension NSIndexSet {

    func aapl_indexPathsFromIndexesWithSection(section: Int) -> [NSIndexPath] {
        var indexPaths: [NSIndexPath] = []
        indexPaths.reserveCapacity(self.count)
        self.enumerateIndexesUsingBlock {idx, stop in
            indexPaths.append(NSIndexPath(forItem: idx, inSection: section))
        }
        return indexPaths
    }
}

