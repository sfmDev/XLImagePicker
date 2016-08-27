//
//  XLAlbumViewCell.swift
//  XLImagePickerController
//
//  Created by PixelShi on 16/8/2.
//  Copyright © 2016年 shifengming. All rights reserved.
//

import UIKit
import Photos

private struct XLAlbumViewHandle {
    static let highLightedAnimationDuration: Double = 0.15
    static let unhightedAnimationDuration: Double = 0.4
    static let hightedAnimationTransformScale: CGFloat = 0.9
    static let unhightedAnimationSpringDamping: CGFloat = 0.5
    static let unhightedAnimationSpringVelocity: CGFloat = 6.0
}

class XLAlbumViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectionVeil: UIView!
    @IBOutlet weak var selectionOrderLabel: UILabel!

    var imageRequestID: PHImageRequestID?
    let imageManager: PHImageManager? = nil
    var animatedHighLight: Bool?
    var enableSelectionIndicatorViewVisibility: Bool?
    var animateSelection: Bool = false
    var image: UIImage? {
        didSet {
            self.imageView.image = image
            self.imageView.contentMode = .ScaleAspectFill
        }
    }
//    var selectImage: UIImage? {
//        didSet {
//            self.selectedImage.image = selectImage
//        }
//    }

    var selectionOrder: Int? {
        didSet {
            self.selectionOrderLabel.text = "\(selectionOrder!)"
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.selected = false

        self.selectionOrderLabel.adjustsFontSizeToFitWidth = true

        self.selectionVeil.layer.borderWidth = 4.0
        self.selectionVeil.layer.borderColor = UIColor.init(red: 72/255, green: 70/255, blue: 109/255, alpha: 1).CGColor

        self.layer.borderColor = selected ? UIColor.init(red: 72/255, green: 70/255, blue: 109/255, alpha: 1).CGColor : UIColor.clearColor().CGColor
        self.layer.borderWidth = selected ? 4 : 0
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.cancelImageRequest()

        self.imageView.image = nil
        self.enableSelectionIndicatorViewVisibility = false
        self.selectionVeil.alpha = 0.0
        self.selectionOrderLabel.alpha = 0.0

    }

    func cancelImageRequest() {
        if self.imageRequestID != PHInvalidImageRequestID {
            self.imageManager?.cancelImageRequest(self.imageRequestID!)
            self.imageRequestID = PHInvalidImageRequestID
        }
    }

    func animateHigtLight(highligted: Bool) {
        if highligted {
            self.animatedHighLight = true
            UIView.animateWithDuration(XLAlbumViewHandle.highLightedAnimationDuration, delay: 0, options: .AllowUserInteraction, animations: {
                self.transform = CGAffineTransformMakeScale(XLAlbumViewHandle.hightedAnimationTransformScale, XLAlbumViewHandle.hightedAnimationTransformScale)
                }, completion: { (isfinished) in
                    self.animateHigtLight(false)
            })
        } else {
            UIView.animateWithDuration(XLAlbumViewHandle.unhightedAnimationDuration,
                                       delay:  XLAlbumViewHandle.highLightedAnimationDuration,
                                       usingSpringWithDamping: XLAlbumViewHandle.unhightedAnimationSpringDamping,
                                       initialSpringVelocity: XLAlbumViewHandle.unhightedAnimationSpringVelocity,
                                       options: .AllowUserInteraction, animations: {
                    self.transform = CGAffineTransformIdentity
            }, completion: nil)
        }
    }

    func setNeedsAniamteSection() {
        self.animateSelection = true
    }

    override var selected: Bool {
        willSet {

            super.selected = selected
//            self.layer.borderColor = UIColor.init(red: 72/255, green: 70/255, blue: 109/255, alpha: 1).CGColor
//            self.layer.borderWidth = 4
            self.setSelected(select: selected, animated: self.animateSelection)
        }
//        didSet {
//            self.setSelected(select: self.selected, animated: self.animateSelection)
//            self.layer.borderColor = selected ? UIColor.init(red: 72/255, green: 70/255, blue: 109/255, alpha: 1).CGColor : UIColor.clearColor().CGColor
//            self.layer.borderWidth = selected ? 4 : 0
//        }
    }

    func setSelected(select isSelected: Bool, animated: Bool) {
        print("isSelected===\(isSelected.boolValue)")
        if !animated {
            self.selectionVeil.alpha = isSelected ? 1.0 : 0.0
            self.selectionOrderLabel.alpha = isSelected ? 1.0 : 0.0
            self.enableSelectionIndicatorViewVisibility = isSelected
        } else {
            self.enableSelectionIndicatorViewVisibility = true
            UIView.animateWithDuration(0.2, delay: 0.0, options: .BeginFromCurrentState, animations: {
                self.selectionVeil.alpha = isSelected ? 1.0 : 0.0
                self.selectionOrderLabel.alpha = isSelected ? 1.0 : 0.0
                }, completion: { (isfinised) in
                    self.enableSelectionIndicatorViewVisibility = isSelected
            })
        }
        self.animateSelection = false
    }

}
