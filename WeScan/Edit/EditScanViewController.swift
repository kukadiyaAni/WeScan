//
//  EditScanViewController.swift
//  WeScan
//
//  Created by Boris Emorine on 2/12/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import AVFoundation


/// The `EditScanViewController` offers an interface for the user to edit the detected quadrilateral.
public final class EditScanViewController: UIViewController {
    
    private var rotationAngle = Measurement<UnitAngle>(value: 0, unit: .degrees)
    private var enhancedImageIsAvailable = false
    private var isCurrentlyDisplayingEnhancedImage = false
    private var isShare = false
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        //imageView.isOpaque = true
        imageView.image = image
        imageView.backgroundColor = .black
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.frame = CGRect(x: 0, y: 0, width: 250, height: 500)
        return imageView
    }()
    
    private lazy var quadView: QuadrilateralView = {
        let quadView = QuadrilateralView()
        quadView.editable = true
        quadView.translatesAutoresizingMaskIntoConstraints = false
        return quadView
    }()
    
    private lazy var nextButton: UIBarButtonItem = {
//        let title = NSLocalizedString("wescan.edit.button.next", tableName: nil, bundle: Bundle(for: EditScanViewController.self), value: "Next", comment: "A generic next button")
        let button = UIBarButtonItem(title: "Keep", style: .plain, target: self, action: #selector(pushReviewController))
        button.tintColor = .systemBlue
//        button.tintColor = UIColor(displayP3Red: 48, green: 103, blue: 255, alpha: 1)
        return button
    }()
    
    private lazy var cancelButton: UIBarButtonItem = {
//        let title = NSLocalizedString("wescan.scanning.cancel", tableName: nil, bundle: Bundle(for: EditScanViewController.self), value: "Cancel", comment: "A generic cancel button")
        let button = UIBarButtonItem(title: "Cancel", style: .plain,  target: self, action: #selector(cancelButtonTapped) )
        button.tintColor = .systemBlue
        return button
    }()
    
    private lazy var retakeButton: UIBarButtonItem = {
//        let title = NSLocalizedString("wescan.scanning.cancel", tableName: nil, bundle: Bundle(for: EditScanViewController.self), value: "Cancel", comment: "A generic cancel button")
        let button = UIBarButtonItem(title: "Retake", style: .plain,  target: self, action: #selector(retakeButtonTapped) )
        button.tintColor = .systemBlue
        return button
    }()
    
    /// The image the quadrilateral was detected on.
    private var image: UIImage
    
    /// The detected quadrilateral that can be edited by the user. Uses the image's coordinates.
    private var quad: Quadrilateral
    private var orignalPhotoQuad: Quadrilateral
    
    private var zoomGestureController: ZoomGestureController!
    private var galleryScan: Bool = false
    private var quadViewWidthConstraint = NSLayoutConstraint()
    private var quadViewHeightConstraint = NSLayoutConstraint()
    
    // MARK: - Life Cycle
    

    
    init(image: UIImage, quad: Quadrilateral?, rotateImage: Bool = true, galleryScan: Bool? = false) {
        self.image = rotateImage ? image.applyingPortraitOrientation() : image
        self.quad = quad ?? EditScanViewController.defaultQuad(forImage: rotateImage ? image.applyingPortraitOrientation() : image)
        self.orignalPhotoQuad = quad ?? EditScanViewController.orignalQuad(forImage: rotateImage ? image.applyingPortraitOrientation() : image)
        
        self.galleryScan = galleryScan!;
        super.init(nibName: nil, bundle: nil)
        setupToolbar()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setupViews() {
        view.addSubview(imageView)
        view.addSubview(quadView)
        
//        let theHeight = view.frame.size.height //grabs the height of your view
//
//         var bottomBar = UIView()
//        let navigationHeight = navigationController?.navigationBar.frame.size.height ?? 0;
//        bottomBar.backgroundColor = UIColor.red
//        let marginBottom = bottomNotchHeight + topNotchHeight + navigationHeight + 50;
//
//        print("marginBottom",marginBottom)
//        bottomBar.frame = CGRect(x: 0, y: theHeight - marginBottom , width: self.view.frame.width, height: 50)
//
//        bottomBar.addSubview(enhanceButton)
//        bottomBar.addSubview(rotateButton)
//        bottomBar.addSubview(doneButton)
//        bottomBar.addSubview(deleteButton)
//        bottomBar.addSubview(shareButton)
//
//         view.addSubview(bottomBar)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupConstraints()
//        title = NSLocalizedString("wescan.edit.title", tableName: nil, bundle: Bundle(for: EditScanViewController.self), value: "Edit Scan", comment: "The title of the EditScanViewController")
//        navigationItem.rightBarButtonItem = nextButton
        navigationController?.navigationBar.backgroundColor = .black
        navigationItem.titleView?.backgroundColor = .black
        self.view.backgroundColor = .black
//        if let firstVC = self.navigationController?.viewControllers.first, firstVC == self {
//
//            navigationItem.leftBarButtonItem = cancelButton
//        } else {
//            navigationItem.leftBarButtonItem = cancelButton
//        }
        
        zoomGestureController = ZoomGestureController(image: image, quadView: quadView)
        
        let touchDown = UILongPressGestureRecognizer(target: zoomGestureController, action: #selector(zoomGestureController.handle(pan:)))
        touchDown.minimumPressDuration = 0
        view.addGestureRecognizer(touchDown)
    }
    
    private func setupToolbar() {
        
        
        
//            guard enhancedImageIsAvailable else { return }
            
            navigationController?.toolbar.backgroundColor = .black
            
            
            let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            toolbarItems = [fixedSpace,shareButton, flexibleSpace,enhanceButton, flexibleSpace,doneButton,flexibleSpace,rotateButton,flexibleSpace,deleteButton, fixedSpace]
        
        
        navigationController?.setToolbarHidden(false, animated: false)
//
//        navigationItem.rightBarButtonItem = nextButton
//        if(self.galleryScan){
//            navigationItem.leftBarButtonItem = cancelButton
//
//        } else {
//            navigationItem.leftBarButtonItem = retakeButton
//        }
        
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustQuadViewConstraints()
        displayQuad()
        setupToolbar()
//        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        navigationController?.setToolbarHidden(true, animated: true)
        super.viewWillDisappear(animated)
       
        // Work around for an iOS 11.2 bug where UIBarButtonItems don't get back to their normal state after being pressed.
        navigationController?.navigationBar.tintAdjustmentMode = .normal
        navigationController?.navigationBar.tintAdjustmentMode = .automatic
        
    }
    func getX(number: NSNumber) -> CGFloat {
        let width = self.view.frame.width
        let buttonSize = width - 250;
        let spaceSize  = buttonSize / 6;
        print("spaceSize",spaceSize)
        if(number == 1){
            return spaceSize
        } else {
            let spaceCount = spaceSize * CGFloat(number);
            let buttonSizeCount = 50 * CGFloat(Int(number)-1);
            let x = spaceCount + buttonSizeCount;
            print("xValue",x)
            return spaceCount + buttonSizeCount;
        }
        return spaceSize;
        
    }
    
    
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
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(cancelButtonTapped))
        button.tintColor = .systemBlue
        return button
    }()
    
    private lazy var shareButton: UIBarButtonItem = {
        let image = UIImage(named: "ic_share", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(shareImageButton))
        button.tintColor = .systemBlue
        return button
    }()
    
    
//    private lazy var enhanceButton: UIButton = {
//
//        let image = UIImage(  named: "ic_disc", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
//        let button = UIButton(frame: CGRect(x: getX(number: 1), y: 0, width: 50, height: 50))
//        button.setImage(image, for: .normal)
//        button.addTarget(self, action:#selector(toggleEnhancedImage), for: .touchUpInside)
//        button.tintColor = .systemBlue
//        return button
//    }()
//
//    private lazy var rotateButton: UIButton = {
//        let image = UIImage(  named: "ic_rotate", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
//        let button = UIButton(frame: CGRect(x: getX(number: 2), y: 0, width: 50, height: 50))
//        button.setImage(image, for: .normal)
//        button.addTarget(self, action:#selector(toggleEnhancedImage), for: .touchUpInside)
//        button.tintColor = .systemBlue
//        return button
//    }()
//
//    private lazy var doneButton: UIButton = {
//        let image = UIImage(  named: "zdc_tick_icon", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
//        let button = UIButton(frame: CGRect(x: getX(number: 3), y: 0, width: 50, height: 50))
//        button.setImage(image, for: .normal)
//        button.addTarget(self, action:#selector(toggleEnhancedImage), for: .touchUpInside)
//        button.tintColor = .systemBlue
//        return button
//    }()
//
//
//    private lazy var deleteButton: UIButton = {
//        let image = UIImage(  named: "ic_trash", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
//        let button = UIButton(frame: CGRect(x: getX(number: 4), y: 0, width: 50, height: 50))
//        button.setImage(image, for: .normal)
//        button.addTarget(self, action:#selector(toggleEnhancedImage), for: .touchUpInside)
//        button.tintColor = .systemBlue
//        return button
//    }()
//
//    private lazy var shareButton: UIButton = {
//        let image = UIImage(named: "ic_share", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
//        let button = UIButton(frame: CGRect(x: getX(number: 5), y: 0, width: 50, height: 50))
//        button.setImage(image, for: .normal)
//        button.addTarget(self, action:#selector(toggleEnhancedImage), for: .touchUpInside)
//        button.tintColor = .systemBlue
//        return button
//    }()
    
    // MARK: - Setups
   
    
    var hasTopNotch: Bool {
       if #available(iOS 13.0,  *) {
            return UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.safeAreaInsets.top ?? 0 > 20
        }else{
            if #available(iOS 11.0, *) {
                return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 20
            } else {
                return false
                // Fallback on earlier versions
            }
        }
    }
    
    var bottomNotchHeight: CGFloat {
       if #available(iOS 13.0,  *) {
            return UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.safeAreaInsets.bottom ?? 0
        }else{
            if #available(iOS 11.0, *) {
                return UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? 0
            } else {
                return 0
                // Fallback on earlier versions
            }
        }
    }
    
    var topNotchHeight: CGFloat {
       if #available(iOS 13.0,  *) {
            return UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.safeAreaInsets.top ?? 0
        }else{
            if #available(iOS 11.0, *) {
                return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0
            } else {
                return 0
                // Fallback on earlier versions
            }
        }
    }
    
    
    private func setupConstraints() {
        let imageViewConstraints = [
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: imageView.bottomAnchor,constant: hasTopNotch ? bottomNotchHeight : 0),
            view.leadingAnchor.constraint(equalTo: imageView.leadingAnchor)
        ]
        
        quadViewWidthConstraint = quadView.widthAnchor.constraint(equalToConstant: 0.0)
        quadViewHeightConstraint = quadView.heightAnchor.constraint(equalToConstant: 0.0)
        
        let quadViewConstraints = [
            quadView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            quadView.centerYAnchor.constraint(equalTo: view.centerYAnchor,constant: hasTopNotch ? -17 : 0),
            quadViewWidthConstraint,
            quadViewHeightConstraint
        ]
        
        NSLayoutConstraint.activate(quadViewConstraints + imageViewConstraints)
    }
    
    
    //  MARK: - Actions
    @objc func cancelButtonTapped() {
        if let imageScannerController = navigationController as? ImageScannerController {
            imageScannerController.imageScannerDelegate?.imageScannerControllerDidCancel(imageScannerController)
        }
    }
    
    @objc func retakeButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    
    @objc func pushReviewController() {
        guard let quad = quadView.quad,
            let ciImage = CIImage(image: image) else {
                if let imageScannerController = navigationController as? ImageScannerController {
                    let error = ImageScannerControllerError.ciImageCreation
                    imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFailWithError: error)
                }
                return
        }
        let cgOrientation = CGImagePropertyOrientation(image.imageOrientation)
        let orientedImage = ciImage.oriented(forExifOrientation: Int32(cgOrientation.rawValue))
        let scaledQuad = quad.scale(quadView.bounds.size, image.size)
        self.quad = scaledQuad
        
        // Cropped Image
        var cartesianScaledQuad = scaledQuad.toCartesian(withHeight: image.size.height)
        cartesianScaledQuad.reorganize()
        
        let filteredImage = orientedImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: cartesianScaledQuad.bottomLeft),
            "inputTopRight": CIVector(cgPoint: cartesianScaledQuad.bottomRight),
            "inputBottomLeft": CIVector(cgPoint: cartesianScaledQuad.topLeft),
            "inputBottomRight": CIVector(cgPoint: cartesianScaledQuad.topRight)
        ])
        
        let croppedImage = UIImage.from(ciImage: filteredImage)
        // Enhanced Image
        let enhancedImage = filteredImage.applyingAdaptiveThreshold()?.withFixedOrientation()
        let enhancedScan = enhancedImage.flatMap { ImageScannerScan(image: $0) }
        
        let results = ImageScannerResults(detectedRectangle: scaledQuad, originalScan: ImageScannerScan(image: image), croppedScan: ImageScannerScan(image: croppedImage), enhancedScan: enhancedScan)
        
        let reviewViewController = ReviewViewController(results: results)
        navigationController?.pushViewController(reviewViewController, animated: true)
    }
    
    private func displayQuad() {
        let imageSize = image.size
        let imageFrame = CGRect(origin: quadView.frame.origin, size: CGSize(width: quadViewWidthConstraint.constant, height: quadViewHeightConstraint.constant))
        
        let scaleTransform = CGAffineTransform.scaleTransform(forSize: imageSize, aspectFillInSize: imageFrame.size)
        let transforms = [scaleTransform]
        let transformedQuad = quad.applyTransforms(transforms)
        
        quadView.drawQuadrilateral(quad: transformedQuad, animated: false)
    }
    
    /// The quadView should be lined up on top of the actual image displayed by the imageView.
    /// Since there is no way to know the size of that image before run time, we adjust the constraints to make sure that the quadView is on top of the displayed image.
    private func adjustQuadViewConstraints() {
        let frame = AVMakeRect(aspectRatio: image.size, insideRect: imageView.bounds)
        quadViewWidthConstraint.constant = frame.size.width
        quadViewHeightConstraint.constant = frame.size.height
    }
    
    /// Generates a `Quadrilateral` object that's centered and 90% of the size of the passed in image.
    private static func defaultQuad(forImage image: UIImage) -> Quadrilateral {
        let topLeft = CGPoint(x: image.size.width * 0.05, y: image.size.height * 0.05)
        let topRight = CGPoint(x: image.size.width * 0.95, y: image.size.height * 0.05)
        let bottomRight = CGPoint(x: image.size.width * 0.95, y: image.size.height * 0.95)
        let bottomLeft = CGPoint(x: image.size.width * 0.05, y: image.size.height * 0.95)
        
        let quad = Quadrilateral(topLeft: topLeft, topRight: topRight, bottomRight: bottomRight, bottomLeft: bottomLeft)
        
        return quad
    }
    
    private static func orignalQuad(forImage image: UIImage) -> Quadrilateral {
        print("image.size.width",image.size.width)
        print("image.size.height",image.size.width)
        let topLeft = CGPoint(x: 0, y: 0)
        let topRight = CGPoint(x: image.size.width, y: 0)
        let bottomRight = CGPoint(x: image.size.width, y: image.size.height)
        let bottomLeft = CGPoint(x: 0, y: image.size.height)
        
        let quad = Quadrilateral(topLeft: topLeft, topRight: topRight, bottomRight: bottomRight, bottomLeft: bottomLeft)
        
        return quad
    }
    
    
    // MARK: - Actions
    
    @objc private func reloadImage() {
        guard let quad = quadView.quad,
            let ciImage = CIImage(image: image) else {
                if let imageScannerController = navigationController as? ImageScannerController {
                    let error = ImageScannerControllerError.ciImageCreation
                    imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFailWithError: error)
                }
                return
        }
        let cgOrientation = CGImagePropertyOrientation(image.imageOrientation)
        let orientedImage = ciImage.oriented(forExifOrientation: Int32(cgOrientation.rawValue))
        let scaledQuad = self.orignalPhotoQuad
        
//        self.quad = scaledQuad
        
        // Cropped Image
        var cartesianScaledQuad = scaledQuad.toCartesian(withHeight: image.size.height)
        cartesianScaledQuad.reorganize()
        
        let filteredImage = orientedImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: cartesianScaledQuad.bottomLeft),
            "inputTopRight": CIVector(cgPoint: cartesianScaledQuad.bottomRight),
            "inputBottomLeft": CIVector(cgPoint: cartesianScaledQuad.topLeft),
            "inputBottomRight": CIVector(cgPoint: cartesianScaledQuad.topRight)
        ])
        
        let croppedImage = self.image
        // Enhanced Image
        let enhancedImage = filteredImage.applyingAdaptiveThreshold()?.withFixedOrientation()
        let enhancedScan = enhancedImage.flatMap { ImageScannerScan(image: $0) }
        
        let results = ImageScannerResults(detectedRectangle: self.quad, originalScan: ImageScannerScan(image: image), croppedScan: ImageScannerScan(image: croppedImage), enhancedScan: enhancedScan)
        
        print("isCurrentlyDisplayingEnhancedImage", isCurrentlyDisplayingEnhancedImage)
        
        if isCurrentlyDisplayingEnhancedImage {
            imageView.image =  results.enhancedScan?.image
        } else {
            imageView.image = results.croppedScan.image
        }
    }
    
    @objc func toggleEnhancedImage() {
//        guard enhancedImageIsAvailable else { return }
        isCurrentlyDisplayingEnhancedImage.toggle()
        reloadImage()

    }
    
    @objc func rotateImage() {
        rotationAngle = Measurement<UnitAngle>(value: 90, unit: .degrees)
        
        imageView.image = imageView.image?.rotated(by: rotationAngle)
        
        self.image = imageView.image ?? self.image
        self.quad = EditScanViewController.defaultQuad(forImage: image)
        self.orignalPhotoQuad = EditScanViewController.orignalQuad(forImage: image)
        adjustQuadViewConstraints()
        displayQuad()
        zoomGestureController = ZoomGestureController(image: image, quadView: quadView)
        let touchDown = UILongPressGestureRecognizer(target: zoomGestureController,
                                                     action: #selector(zoomGestureController.handle(pan:)))
        touchDown.minimumPressDuration = 0
        view.addGestureRecognizer(touchDown)
        
        self.view.layoutIfNeeded()
    }
    
    @objc private func shareImageButton() {
        isShare = true
        finishScan()
    }
    
    @objc private func finishScan() {
        guard let imageScannerController = navigationController as? ImageScannerController else { return }
        
        guard let quad = quadView.quad,
            let ciImage = CIImage(image: image) else {
                if let imageScannerController = navigationController as? ImageScannerController {
                    let error = ImageScannerControllerError.ciImageCreation
                    imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFailWithError: error)
                }
                return
        }
        let cgOrientation = CGImagePropertyOrientation(image.imageOrientation)
        let orientedImage = ciImage.oriented(forExifOrientation: Int32(cgOrientation.rawValue))
        let scaledQuad = quad.scale(quadView.bounds.size, image.size)
        self.quad = scaledQuad
        
        // Cropped Image
        var cartesianScaledQuad = scaledQuad.toCartesian(withHeight: image.size.height)
        cartesianScaledQuad.reorganize()
        
        let filteredImage = orientedImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: cartesianScaledQuad.bottomLeft),
            "inputTopRight": CIVector(cgPoint: cartesianScaledQuad.bottomRight),
            "inputBottomLeft": CIVector(cgPoint: cartesianScaledQuad.topLeft),
            "inputBottomRight": CIVector(cgPoint: cartesianScaledQuad.topRight)
        ])
        
        let croppedImage = UIImage.from(ciImage: filteredImage)
        // Enhanced Image
        let enhancedImage = filteredImage.applyingAdaptiveThreshold()?.withFixedOrientation()
        let enhancedScan = enhancedImage.flatMap { ImageScannerScan(image: $0) }
        
        let results = ImageScannerResults(detectedRectangle: scaledQuad, originalScan: ImageScannerScan(image: image), croppedScan: ImageScannerScan(image: croppedImage), enhancedScan: enhancedScan)
        
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
