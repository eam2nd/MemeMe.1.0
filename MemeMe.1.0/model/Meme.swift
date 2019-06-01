//
//  Meme.swift
//  MemeMe.1.0
//
//  Created by Edward Morton on 5/25/19.
//  Copyright © 2019 Edward Morton. All rights reserved.
//

import UIKit

public struct Meme {
	var topText: String
	var bottomText: String
	var originalImage: UIImage
	var memedImage: UIImage

	init(topText: String, bottomText: String, originalImage: UIImage, memedImage: UIImage) {
		self.topText = topText
		self.bottomText = bottomText
		self.originalImage = originalImage
		self.memedImage = memedImage
	}
}
