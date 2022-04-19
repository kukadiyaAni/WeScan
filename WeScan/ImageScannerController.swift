//
//  ImageScannerController.swift
//  WeScan
//
//  Created by Boris Emorine on 2/12/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
// updated code

import UIKit
import AVFoundation

/// A set of methods that your delegate object must implement to interact with the image scanner interface.
public protocol ImageScannerControllerDelegate: NSObjectProtocol {
    
    /// Tells the delegate that the user scanned a document.
    ///
    /// - Parameters:
    ///   - scanner: The scanner controller object managing the scanning interface.
    ///   - results: The results of the user scanning with the camera.
    /// - Discussion: Your delegate's implementation of this method should dismiss the image scanner controller.
    func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults)
    
    /// Tells the delegate that the user cancelled the scan operation.
    ///
    /// - Parameters:
    ///   - scanner: The scanner controller object managing the scanning interface.
    /// - Discussion: Your delegate's implementation of this method should dismiss the image scanner controller.
    func imageScannerControllerDidCancel(_ scanner: ImageScannerController)
    
    /// Tells the delegate that an error occured during the user's scanning experience.
    ///
    /// - Parameters:
    ///   - scanner: The scanner controller object managing the scanning interface.
    ///   - error: The error that occured.
    func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error)
}

/// A view controller that manages the full flow for scanning documents.
/// The `ImageScannerController` class is meant to be presented. It consists of a series of 3 different screens which guide the user:
/// 1. Uses the camera to capture an image with a rectangle that has been detected.
/// 2. Edit the detected rectangle.
/// 3. Review the cropped down version of the rectangle.
public final class ImageScannerController: UINavigationController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private var canSelectPhoto: Bool = false
    private var shouldOpenEditor: Bool = false
    private var fileName: String = ""
    private var fromLocalUrl: Bool = false
    /// The object that acts as the delegate of the `ImageScannerController`.
    public weak var imageScannerDelegate: ImageScannerControllerDelegate?
    
    // MARK: - Life Cycle
    
    /// A black UIView, used to quickly display a black screen when the shutter button is presseed.
    internal let blackFlashView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    public required init(canSelect: Bool? = false, shouldOpenEditor: Bool? = false, fileName: String? = "" ,image: UIImage? = nil, delegate: ImageScannerControllerDelegate? = nil) {
       
        
        super.init(rootViewController: ScannerViewController(canSelectPhoto: canSelect!))
        self.shouldOpenEditor = shouldOpenEditor!;
        self.canSelectPhoto = canSelect!;
        self.fileName = fileName!;
        
        self.imageScannerDelegate = delegate
        
        if(self.shouldOpenEditor){
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(self.fileName)
            print("imageURL",url)
            let imageData:NSData = NSData(contentsOf: url)!
         let image = UIImage(data: imageData as Data)
            fromLocalUrl = true
            useImage(image: image!)
        }
        
        if #available(iOS 13.0, *) {
            navigationBar.tintColor = .label
        } else {
            navigationBar.tintColor = .black
        }
        navigationBar.isTranslucent = false
        
        self.view.addSubview(blackFlashView)
        setupConstraints()
        
        // If an image was passed in by the host app (e.g. picked from the photo library), use it instead of the document scanner.
        if let image = image {
            detect(image: image) { [weak self] detectedQuad in
                guard let self = self else { return }
//                let editVC = EditScanViewController(image: image, quad: detectedQuad, rotateImage: false)
//                self.navigationController?.pushViewController(editVC, animated: true)
                
                
//                self.pushViewController(editViewController, animated: true)
//                self.setViewControllers([editViewController], animated: true)
                if(self.shouldOpenEditor){
                    let editViewController = EditScanViewController(image: image, quad: detectedQuad, rotateImage: false, galleryScan: true)
                    self.setViewControllers([editViewController], animated: false)
                } else {
                    let editViewController = EditScanViewController(image: image, quad: detectedQuad, rotateImage: false)
                    self.pushViewController(editViewController, animated: true)
                }
            }
        }
        

    }

    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func detect(image: UIImage, completion: @escaping (Quadrilateral?) -> Void) {
        // Whether or not we detect a quad, present the edit view controller after attempting to detect a quad.
        // *** Vision *requires* a completion block to detect rectangles, but it's instant.
        // *** When using Vision, we'll present the normal edit view controller first, then present the updated edit view controller later.
        
        guard let ciImage = CIImage(image: image) else { return }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let orientedImage = ciImage.oriented(forExifOrientation: Int32(orientation.rawValue))
        
        if #available(iOS 11.0, *) {
            // Use the VisionRectangleDetector on iOS 11 to attempt to find a rectangle from the initial image.
            VisionRectangleDetector.rectangle(forImage: ciImage, orientation: orientation) { (quad) in
                let detectedQuad = quad?.toCartesian(withHeight: orientedImage.extent.height)
                completion(detectedQuad)
            }
        } else {
            // Use the CIRectangleDetector on iOS 10 to attempt to find a rectangle from the initial image.
            let detectedQuad = CIRectangleDetector.rectangle(forImage: ciImage)?.toCartesian(withHeight: orientedImage.extent.height)
            completion(detectedQuad)
        }
    }
    
    public func useImage(image: UIImage) {
        guard topViewController is ScannerViewController else { return }
        
        detect(image: image) { [weak self] detectedQuad in
            guard let self = self else { return }
            (self.topViewController as! ScannerViewController).cleanup()
            
//            let editVC = EditScanViewController(image: image, quad: detectedQuad, rotateImage: false)
//            self.navigationController?.pushViewController(editVC, animated: true)
//
            
            print("fromLocalUrl ",self.fromLocalUrl)
            if(self.shouldOpenEditor){
                    let editViewController = EditScanViewController(image: image.applyingPortraitOrientation(), quad: detectedQuad, rotateImage: self.fromLocalUrl, galleryScan: true)
                    print("fromLocalUrl if")
                    self.setViewControllers([editViewController], animated: false)

                self.fromLocalUrl = false
            } else {
                    let editViewController = EditScanViewController(image: image.applyingPortraitOrientation(), quad: detectedQuad, rotateImage: true)
                    self.pushViewController(editViewController, animated: true)
                self.fromLocalUrl = false
            }
            print("fromLocalUrl ",self.fromLocalUrl)
//            self.navigationController?.pushViewController(editViewController, animated: true)
//
        }
    }
    
    public func resetScanner() {
        setViewControllers([ScannerViewController(canSelectPhoto: canSelectPhoto)], animated: true)
    }
    
    private func setupConstraints() {
        let blackFlashViewConstraints = [
            blackFlashView.topAnchor.constraint(equalTo: view.topAnchor),
            blackFlashView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.bottomAnchor.constraint(equalTo: blackFlashView.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: blackFlashView.trailingAnchor)
        ]
        NSLayoutConstraint.activate(blackFlashViewConstraints)
    }
    
    internal func flashToBlack() {
        view.bringSubviewToFront(blackFlashView)
        blackFlashView.isHidden = false
        let flashDuration = DispatchTime.now() + 0.05
        DispatchQueue.main.asyncAfter(deadline: flashDuration) {
            self.blackFlashView.isHidden = true
        }
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        if(self.shouldOpenEditor){
            self.dismiss(animated: true, completion: nil)
            navigationController?.popViewController(animated: true)
            dismiss(animated: true, completion: nil)
        }
        picker.dismiss(animated: true)
        if let scannerVC = topViewController as? ScannerViewController {
            scannerVC.selectPhotoButton.isHidden = false
            if !CaptureSession.current.isAutoScanEnabled { scannerVC.toggleAutoScan() }
        }
    }

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: false)
        
        if !CaptureSession.current.isAutoScanEnabled &&
            topViewController is ScannerViewController {
            (topViewController as! ScannerViewController).toggleAutoScan()
        }
//        print(info[.originalImage])
        guard let image = info[.originalImage] as? UIImage else { return }
        useImage(image: image)
    }
}

/// Data structure containing information about a scan, including both the image and an optional PDF.
public struct ImageScannerScan {
    public enum ImageScannerError: Error {
        case failedToGeneratePDF
    }
    
    public var image: UIImage
    
    public func generatePDFData(completion: @escaping (Result<Data, ImageScannerError>) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            if let pdfData = self.image.pdfData() {
                completion(.success(pdfData))
            } else {
                completion(.failure(.failedToGeneratePDF))
            }
        }
        
    }
    
    mutating func rotate(by rotationAngle: Measurement<UnitAngle>) {
        guard rotationAngle.value != 0, rotationAngle.value != 360 else { return }
        image = image.rotated(by: rotationAngle) ?? image
    }
}

/// Data structure containing information about a scanning session.
/// Includes the original scan, cropped scan, detected rectangle, and whether the user selected the enhanced scan. May also include an enhanced scan if no errors were encountered.
public struct ImageScannerResults {
    
    /// The original scan taken by the user, prior to the cropping applied by WeScan.
    public var originalScan: ImageScannerScan
    
    /// The deskewed and cropped scan using the detected rectangle, without any filters.
    public var croppedScan: ImageScannerScan
    
    /// The enhanced scan, passed through an Adaptive Thresholding function. This image will always be grayscale and may not always be available.
    public var enhancedScan: ImageScannerScan?
    
    /// Whether the user selected the enhanced scan or not.
    /// The `enhancedScan` may still be available even if it has not been selected by the user.
    public var doesUserPreferEnhancedScan: Bool
    
    /// The detected rectangle which was used to generate the `scannedImage`.
    public var detectedRectangle: Quadrilateral
    
    @available(*, unavailable, renamed: "originalScan")
    public var originalImage: UIImage?
    
    @available(*, unavailable, renamed: "croppedScan")
    public var scannedImage: UIImage?
    
    @available(*, unavailable, renamed: "enhancedScan")
    public var enhancedImage: UIImage?
    
    @available(*, unavailable, renamed: "doesUserPreferEnhancedScan")
    public var doesUserPreferEnhancedImage: Bool = false
    
    init(detectedRectangle: Quadrilateral, originalScan: ImageScannerScan, croppedScan: ImageScannerScan, enhancedScan: ImageScannerScan?, doesUserPreferEnhancedScan: Bool = false) {
        self.detectedRectangle = detectedRectangle
        
        self.originalScan = originalScan
        self.croppedScan = croppedScan
        self.enhancedScan = enhancedScan
        
        self.doesUserPreferEnhancedScan = doesUserPreferEnhancedScan
    }
}
