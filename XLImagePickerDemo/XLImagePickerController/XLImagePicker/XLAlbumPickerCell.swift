//
//  XLAlbumPickerCell.swift
//  XLImagePickerController
//
//  Created by PixelShi on 16/8/18.
//  Copyright © 2016年 shifengming. All rights reserved.
//

import UIKit

class XLAlbumPickerCell: UITableViewCell {

    @IBOutlet weak var ThumbnailImageView: UIImageView!
    @IBOutlet weak var AlbumNameLabel: UILabel!
    @IBOutlet weak var PhotosCountLabel: UILabel!

    var thumbnail: UIImage?
    var albumNameText: String = ""
    var photoCount: Int = 0
    var representedAssetIdentifier: String = ""

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setThumbnailImage(image: UIImage) {
        self.ThumbnailImageView.image = image
        self.thumbnail = image
    }

    func setAlbumName(albumName: String) {
        self.AlbumNameLabel.text = albumName
        self.albumNameText = albumName
    }

    func setPhotoCountText(photoCount: Int) {
        if photoCount > 0 {
            self.PhotosCountLabel.text = "\(photoCount)"
        } else {
            self.PhotosCountLabel.text = ""
        }
        self.photoCount = photoCount
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
