//
//  XLAlbumViewCell.swift
//  XLImagePickerController
//
//  Created by PixelShi on 16/8/2.
//  Copyright © 2016年 shifengming. All rights reserved.
//

import UIKit

class XLAlbumViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectedImage: UIImageView!

    var image: UIImage? {
        didSet {
            self.imageView.image = image
            self.imageView.contentMode = .ScaleAspectFill
        }
    }

    var selectImage: UIImage? {
        didSet {
            self.selectedImage.image = selectImage
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selected = false
    }

    override var selected: Bool {
        didSet {
            self.layer.borderColor = selected ? Handle.tintColor.CGColor : UIColor.clearColor().CGColor
            self.layer.borderWidth = selected ? 2 : 0
        }
    }

}
