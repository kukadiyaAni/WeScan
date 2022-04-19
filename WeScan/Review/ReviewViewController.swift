//
//  ReviewViewController.swift
//  WeScan
//
//  Created by Boris Emorine on 2/25/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

/// The `ReviewViewController` offers an interface to review the image after it has been cropped and deskwed according to the passed in quadrilateral.
final class ReviewViewController: UIViewController {
    
    private var rotationAngle = Measurement<UnitAngle>(value: 0, unit: .degrees)
    private var enhancedImageIsAvailable = false
    private var isCurrentlyDisplayingEnhancedImage = false
    private var isShare = false
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.isOpaque = true
        imageView.image = results.croppedScan.image
        imageView.backgroundColor = .black
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    
    
    
    private lazy var enhanceButton: UIBarButtonItem = {
        let image = UIImage(  named: "ic_disc", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(toggleEnhancedImage))
        button.tintColor = .systemBlue
        return button
    }()
    
    private lazy var rotateButton: UIBarButtonItem = {
        let image = UIImage(  named: "ic_rotate", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(rotateImage))
        button.tintColor = .systemBlue
        return button
    }()
    
    private lazy var doneButton: UIBarButtonItem = {
        let image = UIImage(  named: "zdc_tick_icon", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        let button = UIBarButtonItem(image: image, style: .plain,target: self, action: #selector(finishScan))
        button.tintColor = .systemBlue
        return button
    }()
    
    
    private lazy var deleteButton: UIBarButtonItem = {
        let image = UIImage(  named: "ic_trash", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(deleteImageController))
        button.tintColor = .systemBlue
        return button
    }()
    
    private lazy var shareButton: UIBarButtonItem = {
        let image = UIImage(named: "ic_share", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(shareImageButton))
        button.tintColor = .systemBlue
        return button
    }()
    
    @objc private func shareImageButton() {
        isShare = true
        finishScan()
    }
    
    private let results: ImageScannerResults
    
    // MARK: - Life Cycle
    
    init(results: ImageScannerResults) {
        self.results = results
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false

        enhancedImageIsAvailable = results.enhancedScan != nil
        
        setupViews()
        setupToolbar()
        setupConstraints()
        
        title = NSLocalizedString("wescan.review.title", tableName: nil, bundle: Bundle(for: ReviewViewController.self), value: "Review", comment: "The review title of the ReviewController")
//        navigationItem.rightBarButtonItem = doneButton
        //        navigationItem.leftBarButtonItem = deleteButton
//        navigationController?.navigationBar.backgroundColor = .black
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false

        // We only show the toolbar (with the enhance button) if the enhanced image is available.
        if enhancedImageIsAvailable {
            navigationController?.setToolbarHidden(false, animated: true)
        }
    }
    
    @objc private func cancelImageScannerController() {
        guard let imageScannerController = navigationController as? ImageScannerController else { return }
        imageScannerController.imageScannerDelegate?.imageScannerControllerDidCancel(imageScannerController)
    }
    
    @objc private func deleteImageController() {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    // MARK: Setups
    
    private func setupViews() {
        view.addSubview(imageView)
    }
    
    private func setupToolbar() {
        guard enhancedImageIsAvailable else { return }
        
        //        navigationController?.toolbar.barStyle = .default
        navigationController?.toolbar.backgroundColor = .black
        
        
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [fixedSpace,shareButton, flexibleSpace,enhanceButton, flexibleSpace,doneButton,flexibleSpace,rotateButton,flexibleSpace,deleteButton, fixedSpace]
    }
    
    private func setupConstraints() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        var imageViewConstraints: [NSLayoutConstraint] = []
        if #available(iOS 11.0, *) {
            imageViewConstraints = [
                view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: imageView.safeAreaLayoutGuide.topAnchor),
                view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: imageView.safeAreaLayoutGuide.trailingAnchor),
                view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: imageView.safeAreaLayoutGuide.bottomAnchor),
                view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: imageView.safeAreaLayoutGuide.leadingAnchor)
            ]
        } else {
            imageViewConstraints = [
                view.topAnchor.constraint(equalTo: imageView.topAnchor),
                view.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                view.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
                view.leadingAnchor.constraint(equalTo: imageView.leadingAnchor)
            ]
        }
        
        NSLayoutConstraint.activate(imageViewConstraints)
    }
    
    // MARK: - Actions
    
    @objc private func reloadImage() {
        if enhancedImageIsAvailable, isCurrentlyDisplayingEnhancedImage {
            imageView.image = results.enhancedScan?.image.rotated(by: rotationAngle) ?? results.enhancedScan?.image
        } else {
            imageView.image = results.croppedScan.image.rotated(by: rotationAngle) ?? results.croppedScan.image
        }
    }
    
    @objc func toggleEnhancedImage() {
        guard enhancedImageIsAvailable else { return }
        
        isCurrentlyDisplayingEnhancedImage.toggle()
        reloadImage()
        
        if isCurrentlyDisplayingEnhancedImage {
            enhanceButton.tintColor = .systemBlue
        } else {
            enhanceButton.tintColor = .systemBlue
        }
    }
    
    @objc func rotateImage() {
        rotationAngle.value += 90
        
        if rotationAngle.value == 360 {
            rotationAngle.value = 0
        }
        
        reloadImage()
    }
    
    @objc private func finishScan() {
        guard let imageScannerController = navigationController as? ImageScannerController else { return }
        
        var newResults = results
        newResults.croppedScan.rotate(by: rotationAngle)
        newResults.enhancedScan?.rotate(by: rotationAngle)
        newResults.doesUserPreferEnhancedScan = isCurrentlyDisplayingEnhancedImage
        if(isShare){
            isShare = false
            
            if(isCurrentlyDisplayingEnhancedImage){
                let image = newResults.enhancedScan?.image
                let imageShare = [ image! ]
                let activityViewController = UIActivityViewController(activityItems: imageShare , applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.view
                self.present(activityViewController, animated: true, completion: nil)
            } else {
                let image = newResults.croppedScan.image
                let imageShare = [ image ]
                let activityViewController = UIActivityViewController(activityItems: imageShare , applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.view
                self.present(activityViewController, animated: true, completion: nil)
            }
            
        } else {
            imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFinishScanningWithResults: newResults)
        }
    }
    
}
