//
//  ViewController.swift
//  MemeMe.1.0
//
//  Created by Edward Morton on 5/25/19.
//  Copyright © 2019 Edward Morton. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

class CreateMemeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

	// MARK: - Properties

	var meme: Meme!
	let defaultText = ["TOP","BOTTOM"]
	let memeTextAttributes: [NSAttributedString.Key: Any] = [
		NSAttributedString.Key.strokeColor: UIColor.black,
		NSAttributedString.Key.foregroundColor: UIColor.white,
		NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
		NSAttributedString.Key.strokeWidth: -6.0
	]

	// MARK: - IBOutlets

	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var topTextField: UITextField!
	@IBOutlet weak var bottomTextField: UITextField!
	@IBOutlet weak var topToolbar: UIToolbar!
	@IBOutlet weak var bottomToolbar: UIToolbar!
	@IBOutlet weak var cameraBarButtonItem: UIBarButtonItem!
	@IBOutlet weak var shareBarButtonItem: UIBarButtonItem!

	// MARK: - IBActions

	@IBAction func pickImageFromLibrary(_ sender: UIBarButtonItem) {
		let authStatus = PHPhotoLibrary.authorizationStatus()
		let pickerController = UIImagePickerController()

		pickerController.delegate = self
		pickerController.sourceType = .photoLibrary

		switch authStatus {
		case .authorized:
			present(pickerController, animated: true, completion: nil)
		case .notDetermined:
			PHPhotoLibrary.requestAuthorization({
				(status) in
				if status == PHAuthorizationStatus.authorized {
					DispatchQueue.main.async {
						self.present(pickerController, animated: true, completion: nil)
					}
				}
			})
		default:
			self.showSettingsAlert("Photo Library", "Open Settings to grant access to Photo Library?")
		}
	}

	@IBAction func pickImageFromCamera(_ sender: UIBarButtonItem) {
		let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
		let pickerController = UIImagePickerController()

		pickerController.delegate = self
		pickerController.sourceType = .camera

		switch authStatus {
		case .authorized:
			present(pickerController, animated: true, completion: nil)
		case .notDetermined:
			AVCaptureDevice.requestAccess(for: .video) { success in
				if success {
					DispatchQueue.main.async {
						self.present(pickerController, animated: true, completion: nil)
					}
				}
			}
		default:
			self.showSettingsAlert("Camera", "Open Settings to grant access to the Camera?")
		}
	}

	@IBAction func shareMeme(_ sender: UIBarButtonItem) {
		let image: UIImage = generateMeme()
		let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)

		activity.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, activityError: Error?) in
			if completed && activityError == nil {
				self.meme = self.saveMeme(image)
				self.dismiss(animated: true, completion: nil)
			}
		}

		present(activity, animated: true, completion: nil)
	}

	@IBAction func cancel(_ sender: UIBarButtonItem) {
		topTextField.text = defaultText[topTextField.tag]
		bottomTextField.text = defaultText[bottomTextField.tag]
		imageView.image = nil
		shareBarButtonItem.isEnabled = false
	}

	// MARK: - Meme Generate & Save

	func generateMeme() -> UIImage {
		// Hide toolbars to not include in Meme Image
		topToolbar.isHidden = true
		bottomToolbar.isHidden = true

		// Render view to an image
		UIGraphicsBeginImageContext(self.view.frame.size)
		view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
		let memedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
		UIGraphicsEndImageContext()

		// Show toolbars after capturing Meme Image
		topToolbar.isHidden = false
		bottomToolbar.isHidden = false

		return memedImage
	}

	func saveMeme(_ memedImage: UIImage) -> Meme {
		let meme = Meme(topText: topTextField.text!, bottomText: bottomTextField.text!, originalImage: imageView.image!, memedImage: memedImage)

		return meme
	}

	// MARK: - Delegate Methods - Image Picker

	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		dismiss(animated: true, completion: nil)

		if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
			imageView.contentMode = .scaleAspectFit
			imageView.image = pickedImage
			shareBarButtonItem.isEnabled = true
		}
	}

	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		dismiss(animated: true, completion: nil)
	}

	// MARK: Delegate Methods - Text Fields

	func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		if defaultText.contains(textField.text!) {
			textField.text = ""
		}

		return true
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		/*
		Moved this to textFieldDidEndEditing due to layout issue when
			tapping button while editing.

		if textField.text == "" {
			textField.text = defaultText[textField.tag]
		}
		*/

		textField.resignFirstResponder()

		return true
	}

	func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
		if textField.text == "" {
			textField.text = defaultText[textField.tag]
		}
	}

	// MARK: - Keyboard Notification Methods

	func subscribeToKeyboardNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
	}

	func unsubscribeFromKeyboardNotifications() {
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
	}

	@objc func keyboardWillShow(_ notification:Notification) {
		if bottomTextField.isEditing && self.view.frame.origin.y == 0 {
			self.view.frame.origin.y -= getKeyboardHeight(notification)
		}
	}

	@objc func keyboardWillHide(_ notification: Notification) {
		if bottomTextField.isEditing && self.view.frame.origin.y != 0 {
			self.view.frame.origin.y += getKeyboardHeight(notification)
		}
	}

	func getKeyboardHeight(_ notification:Notification) -> CGFloat {
		let userInfo = notification.userInfo
		let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue

		return keyboardSize.cgRectValue.height
	}

	// MARK: - Alert Controller to Open Settings

	func showSettingsAlert(_ title: String, _ msg: String) {
		let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)

		alert.addAction(UIAlertAction(title: "NO", style: .default, handler: { action in
			self.dismiss(animated: true, completion: nil)
		}))

		alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { action in
			self.dismiss(animated: true, completion: nil)
			UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
		}))

		present(alert, animated: true)
	}

	// MARK: - Set Default TextField Properties

	func setDefaultTextFieldProperties(_ textField: UITextField) {
		textField.text = defaultText[textField.tag]
		textField.defaultTextAttributes = memeTextAttributes
		textField.textAlignment = .center
		textField.autocapitalizationType = UITextAutocapitalizationType.allCharacters
		textField.borderStyle = .none
		textField.adjustsFontSizeToFitWidth = true
		textField.minimumFontSize = 10
		textField.delegate = self
	}

	// MARK: - View Lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()

		setDefaultTextFieldProperties(topTextField)
		setDefaultTextFieldProperties(bottomTextField)
		cameraBarButtonItem.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
		shareBarButtonItem.isEnabled = false
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		subscribeToKeyboardNotifications()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		unsubscribeFromKeyboardNotifications()
	}

	// dismiss keyboard on orientation change when editing bottom textfield
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)

		if bottomTextField.isEditing {
			bottomTextField.endEditing(true)
		}
	}
}
