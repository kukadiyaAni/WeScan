//
//  EditScanViewController.swift
//  WeScan
//
//  Created by Boris Emorine on 2/12/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import AVFoundation

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hex & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(hex & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

/// The `EditScanViewController` offers an interface for the user to edit the detected quadrilateral.
public final class EditScanViewController: UIViewController {
    
    private var rotationAngle = Measurement<UnitAngle>(value: 0, unit: .degrees)
    private var enhancedImageIsAvailable = false
    private var isCurrentlyDisplayingEnhancedImage = false
    private var isShare = false
    private var isKeepScanning = false
    
   
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        //imageView.isOpaque = true
        imageView.image = image
        imageView.backgroundColor = .black
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        var screenWidth = UIScreen.main.bounds.width;
        let screenHeight = UIScreen.main.bounds.height;
        let size = hasTopNotch ? bottomNotchHeight+60 : 60
  
        imageView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenWidth*2)
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
        let button = UIBarButtonItem(title: "Cancel", style: .plain,  target: self, action: #selector(deleteButtonTapped) )
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
    
    
    
    init(image: UIImage, quad: Quadrilateral?, rotateImage: Bool = false, galleryScan: Bool? = false) {
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
    
    let stackView = UIStackView()
    let containerView = UIView()
    
    let stckVerticle = UIStackView()
    let buttonWidth: CGFloat = 60
    let buttonHeight: CGFloat = 50
    
    let bottomView = UIView()
    let mainView = UIView()
    let stackBottomView = UIStackView()
    
    private func setupViews() {
        containerView.backgroundColor = UIColor.black
        var screenWidth = UIScreen.main.bounds.width;
        let screenHeight = UIScreen.main.bounds.height;
        
        mainView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        
        stckVerticle.axis = .vertical
        stckVerticle.distribution = .equalSpacing
        screenWidth = (screenWidth + 75) - (buttonWidth*4)
        screenWidth = screenWidth/3
        print("Device width: \(screenWidth)")
        stackView.axis = .horizontal
                stackView.distribution = .equalSpacing
        stackView.alignment = .center
//        stackView.spacing = screenWidth
        stackView.addArrangedSubview(shareButtonIcon)
        stackView.addArrangedSubview(enhanceButtonIcon)
        //        stackView.addArrangedSubview(doneButtonIcon)
        stackView.addArrangedSubview(rotateButtonIcon)
        stackView.addArrangedSubview(deleteButtonIcon)
        
        // Inside viewDidLoad()
        print("Stack View Frame: \(stackView.frame)")
        
        // Inside the loop where buttons are created
        print("Button Frame: \(shutterButton.frame)")
        
        //        view.addSubview(imageView)
        //        view.addSubview(quadView)
        stckVerticle.addArrangedSubview(stackView)
        
        stackBottomView.axis = .horizontal
        stackBottomView.distribution = .equalSpacing
        stackBottomView.alignment = .center
        stackBottomView.spacing = 5
        stackBottomView.addArrangedSubview(emptyView)
        stackBottomView.addArrangedSubview(keepScaning)
        stackBottomView.addArrangedSubview(continueButton)
        
        mainView.addSubview(imageView)
        mainView.addSubview(quadView)
        view.addSubview(mainView)
        //        containerView.addSubview(stackView)
        //        bottomView.addSubview(stackBottomView)
        
        stckVerticle.addArrangedSubview(stackBottomView)
        
        containerView.addSubview(stckVerticle)
        view.addSubview(containerView)
        //        view.addSubview(bottomView)
        
        zoomGestureController = ZoomGestureController(image: image, quadView: quadView)
        
        let touchDown = UILongPressGestureRecognizer(target: zoomGestureController, action: #selector(zoomGestureController.handle(pan:)))
        touchDown.minimumPressDuration = 0
        mainView.addGestureRecognizer(touchDown)
        
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
    
    private func setupConstraints() {
        //       stackView.removeConstraints(stackView.constraints)
        
        let size = hasTopNotch ? bottomNotchHeight+60 : 60
        containerView.translatesAutoresizingMaskIntoConstraints = false
        stckVerticle.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        let imageViewConstraints = [
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: imageView.bottomAnchor,constant: size*2),
            view.leadingAnchor.constraint(equalTo: imageView.leadingAnchor)
        ]
        
        var stackViewConstraints = [NSLayoutConstraint]()
        stackViewConstraints = [
            stckVerticle.topAnchor.constraint(equalTo: containerView.topAnchor),
            stckVerticle.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stckVerticle.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stckVerticle.bottomAnchor.constraint(equalTo: containerView.bottomAnchor), // Adjust the height of the container view if needed
            
            
        ]
        var containerViewConstraints = [NSLayoutConstraint]()
        
        containerViewConstraints = [
            //        stackView.topAnchor.constraint(equalTo: imageView.bottomAnchor),
//            stckVerticle.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(size/2)-10),
            stckVerticle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stckVerticle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            //        containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 120),  // Adjust the height of the container view if needed
        ]
        
        quadViewWidthConstraint = quadView.widthAnchor.constraint(equalToConstant: 0.0)
        quadViewHeightConstraint = quadView.heightAnchor.constraint(equalToConstant: 0.0)
        
        let quadViewConstraints = [
            quadView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            quadView.centerYAnchor.constraint(equalTo: view.centerYAnchor,constant: -(size)),
            quadViewWidthConstraint,
            quadViewHeightConstraint
        ]
        
        let mainViewConstraints = [
            mainView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainView.centerYAnchor.constraint(equalTo: view.centerYAnchor,constant: -(size)),
            view.bottomAnchor.constraint(equalTo: mainView.bottomAnchor,constant: size*2),
            view.leadingAnchor.constraint(equalTo: mainView.leadingAnchor)
        ]
        
        let centerButtonCon = [ keepScaning.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                keepScaning.centerYAnchor.constraint(equalTo: view.bottomAnchor, constant: -(size-20)),
                                keepScaning.widthAnchor.constraint(equalToConstant: 150),
                                keepScaning.heightAnchor.constraint(equalToConstant: 50),
        ]
        
        let continueButtonCon = [   continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
                                    continueButton.centerYAnchor.constraint(equalTo: keepScaning.centerYAnchor),
                                    continueButton.widthAnchor.constraint(equalToConstant: 150),
                                    continueButton.heightAnchor.constraint(equalToConstant: 50),
        ]
        NSLayoutConstraint.activate(quadViewConstraints + imageViewConstraints + stackViewConstraints + containerViewConstraints + mainViewConstraints + centerButtonCon + continueButtonCon)
    }
    private lazy var homeButton: UIBarButtonItem = {
        let image = UIImage(systemName: "house.fill", named: "flash", in: Bundle(for: EditScanViewController.self), compatibleWith: nil)
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(cancelButtonTapped))
        button.tintColor = .white
        
        return button
    }()
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.setLeftBarButton(homeButton, animated: false)
        
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
        
        
    }
    
    private func setupToolbar() {
        
        
        
        //            guard enhancedImageIsAvailable else { return }
        
        //            navigationController?.toolbar.backgroundColor = .red
        
        
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        //            toolbarItems = [fixedSpace,shareButton, flexibleSpace,enhanceButton, flexibleSpace,doneButton,flexibleSpace,rotateButton,flexibleSpace,deleteButton, fixedSpace]
        
        
        navigationController?.setToolbarHidden(true, animated: false)
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
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(deleteButtonTapped))
        button.tintColor = .systemBlue
        return button
    }()
    
    private lazy var shareButton: UIBarButtonItem = {
        let image = UIImage(named: "ic_share", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(shareImageButton))
        button.tintColor = .systemBlue
        return button
    }()
    
    
    private lazy var enhanceButtonIcon: UIButton = {
        
        //        let image = UIImage(  named: "ic_disc", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        //        let button = UIButton(frame: CGRect(x: getX(number: 1), y: 0, width: 50, height: 50))
        //        button.setImage(image, for: .normal)
        //        button.addTarget(self, action:#selector(toggleEnhancedImage), for: .touchUpInside)
        //        button.tintColor = .systemBlue
        //        return button
        
        let button = CustomButton()

        button.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: buttonHeight)
        button.setTitle("Enhance", for: .normal)
        let textHexColor: UInt32 = 0x3067FF
        let textColor = UIColor(hex: textHexColor)
        button.setTitleColor(textColor, for: .normal)
        button.setImage(UIImage(named: "ic_disc", in: Bundle(for: ScannerViewController.self), compatibleWith: nil), for: .normal)
        
        button.addTarget(self, action:#selector(toggleEnhancedImage), for: .touchUpInside)

        return button
        
//        // Create the button
//        let button = UIButton(frame: CGRect(x: 0, y: 0, width: buttonWidth, height: buttonHeight))
//        button.tintColor = .systemBlue
//        
//        // Create the image
//        let image = UIImage(named: "ic_disc", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
//        let imageView = UIImageView(image: image)
//        imageView.contentMode = .scaleAspectFit
//        
//        // Calculate the position for the image view to center it horizontally
//        let imageX = (buttonWidth - imageView.frame.width) / 2
//        imageView.frame.origin = CGPoint(x: imageX, y: 0)
//        
//        // Create the label
//        let label = UILabel(frame: CGRect(x: 0, y: buttonHeight - 25, width: buttonWidth, height: 30))
//        label.text = "Enhance"
//        label.textAlignment = .center
//        label.textColor = .white
//        label.font = UIFont(name: "SFProText-Regular", size: 14)
//        
//        // Add the image view and label to the button
//        button.addSubview(imageView)
//        button.addSubview(label)
//        button.addTarget(self, action:#selector(toggleEnhancedImage), for: .touchUpInside)
//        return button
    }()
    
    private lazy var rotateButtonIcon: UIButton = {
        //        let image = UIImage(  named: "ic_rotate", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        //        let button = UIButton(frame: CGRect(x: getX(number: 2), y: 0, width: 50, height: 50))
        //        button.setImage(image, for: .normal)
        //        button.addTarget(self, action:#selector(rotateImage), for: .touchUpInside)
        //        button.tintColor = .systemBlue
        //        return button
        
        let button = CustomButton()

        button.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: buttonHeight)
        button.setTitle("Rotate", for: .normal)
        let textHexColor: UInt32 = 0x3067FF
        let textColor = UIColor(hex: textHexColor)
        button.setTitleColor(textColor, for: .normal)
        button.setImage(UIImage(named: "ic_rotate", in: Bundle(for: ScannerViewController.self), compatibleWith: nil), for: .normal)
        
        button.addTarget(self, action:#selector(rotateImage), for: .touchUpInside)

        return button
        
//        // Create the button
//        let button = UIButton(frame: CGRect(x: 0, y: 0, width: buttonWidth, height: buttonHeight))
//        button.tintColor = .systemBlue
//        
//        // Create the image
//        let image = UIImage(named: "ic_rotate", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
//        let imageView = UIImageView(image: image)
//        imageView.contentMode = .scaleAspectFit
//        
//        // Calculate the position for the image view to center it horizontally
//        let imageX = (buttonWidth - imageView.frame.width) / 2
//        imageView.frame.origin = CGPoint(x: imageX, y: 0)
//        
//        // Create the label
//        let label = UILabel(frame: CGRect(x: 0, y: buttonHeight - 25, width: buttonWidth, height: 30))
//        label.text = "Rotate"
//        label.textAlignment = .center
//        label.textColor = .white
//        label.font = UIFont(name: "SFProText-Regular", size: 14)
//        
//        // Add the image view and label to the button
//        button.addSubview(imageView)
//        button.addSubview(label)
//        button.addTarget(self, action:#selector(rotateImage), for: .touchUpInside)
//        
//        return button
    }()
    
    private lazy var doneButtonIcon: UIButton = {
        //        let image = UIImage(  named: "zdc_tick_icon", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        //        let button = UIButton(frame: CGRect(x: getX(number: 3), y: 0, width: 50, height: 50))
        //        button.setImage(image, for: .normal)
        //        button.addTarget(self, action:#selector(finishScan), for: .touchUpInside)
        //        button.tintColor = .systemBlue
        //        return button
        
        
        let button = CustomButton()

        button.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: buttonHeight)
        button.setTitle("Done", for: .normal)
        let textHexColor: UInt32 = 0x3067FF
        let textColor = UIColor(hex: textHexColor)
        button.setTitleColor(textColor, for: .normal)
        button.setImage(UIImage(named: "zdc_tick_icon", in: Bundle(for: ScannerViewController.self), compatibleWith: nil), for: .normal)
        
        button.addTarget(self, action:#selector(finishScan), for: .touchUpInside)

        return button
//        // Create the button
//        let button = UIButton(frame: CGRect(x: 0, y: 0, width: buttonWidth, height: buttonHeight))
//        button.tintColor = .systemBlue
//        
//        // Create the image
//        let image = UIImage(named: "zdc_tick_icon", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
//        let imageView = UIImageView(image: image)
//        imageView.contentMode = .scaleAspectFit
//        
//        // Calculate the position for the image view to center it horizontally
//        let imageX = (buttonWidth - imageView.frame.width) / 2
//        imageView.frame.origin = CGPoint(x: imageX, y: 0)
//        
//        // Create the label
//        let label = UILabel(frame: CGRect(x: 0, y: buttonHeight - 25, width: buttonWidth, height: 30))
//        label.text = "Done"
//        label.textAlignment = .center
//        label.textColor = .white
//        label.font = UIFont(name: "SFProText-Regular", size: 14)
//        
//        // Add the image view and label to the button
//        button.addSubview(imageView)
//        button.addSubview(label)
//        button.addTarget(self, action:#selector(finishScan), for: .touchUpInside)
//        return button
    }()
    
    
    private lazy var deleteButtonIcon: UIButton = {
        //        let image = UIImage(  named: "ic_trash", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        //        let button = UIButton(frame: CGRect(x: getX(number: 4), y: 0, width: 50, height: 50))
        //        button.setImage(image, for: .normal)
        //        button.addTarget(self, action:#selector(deleteButtonTapped), for: .touchUpInside)
        //        button.tintColor = .systemBlue
        //        return button
        
        let button = CustomButton()

        button.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: buttonHeight)
        button.setTitle("Delete", for: .normal)
        button.setImage(UIImage(named: "ic_trash", in: Bundle(for: ScannerViewController.self), compatibleWith: nil), for: .normal)
        let textHexColor: UInt32 = 0x3067FF
        let textColor = UIColor(hex: textHexColor)
        button.setTitleColor(textColor, for: .normal)
        button.titleLabel?.textColor = .blue
        button.addTarget(self, action:#selector(deleteButtonTapped), for: .touchUpInside)

        return button
//        
//        // Create the button
//        let button = UIButton(frame: CGRect(x: 0, y: 0, width: buttonWidth, height: buttonHeight))
//        button.tintColor = .systemBlue
//        
//        // Create the image
//        let image = UIImage(named: "ic_trash", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
//        let imageView = UIImageView(image: image)
//        imageView.contentMode = .scaleAspectFit
//        
//        // Calculate the position for the image view to center it horizontally
//        let imageX = (buttonWidth - imageView.frame.width) / 2
//        imageView.frame.origin = CGPoint(x: imageX, y: 0)
//        
//        // Create the label
//        let label = UILabel(frame: CGRect(x: 0, y: buttonHeight - 25, width: buttonWidth, height: 30))
//        label.text = "Delete"
//        label.textAlignment = .center
//        label.textColor = .white
//        label.font = UIFont(name: "SFProText-Regular", size: 14)
//        
//        // Add the image view and label to the button
//        button.addSubview(imageView)
//        button.addSubview(label)
//        button.addTarget(self, action:#selector(deleteButtonTapped), for: .touchUpInside)
//        
//        return button
    }()
    
    private lazy var keepScaning: UIButton = {
        let button = UIButton(frame: CGRect(x: getX(number: 4), y: 0, width: 50, height: 50))
        button.setTitle(galleryScan ? "" : "Keep scanning", for: .normal)
        let hexColor: UInt32 = 0xB1B1B1
        let textColor = UIColor(hex: hexColor)
        button.setTitleColor(textColor, for: .normal)
        button.titleLabel?.font = UIFont(name: "SFProText-Regular", size: 19.0)
        button.addTarget(self, action:#selector(keepScanningDcouments), for: .touchUpInside)
        
        //        button.setTitleColor(UIColor(rgb: "0xB1B1B1"), for: .normal)
        
        return button
    }()
    
    private lazy var emptyView: UIButton = {
        let image = UIImage(  named: "ic_trash", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        let button = UIButton(frame: CGRect(x: getX(number: 4), y: 0, width: 50, height: 50))
        button.setTitle("", for: .normal)
        let textHexColor: UInt32 = 0x3067FF
        let textColor = UIColor(hex: textHexColor)
        button.setTitleColor(textColor, for: .normal)
        if #available(iOS 11.0, *) {
            button.setTitleColor(UIColor(named: "#000000"), for: .normal)
        } else {
            // Fallback on earlier versions
        }
        
        
        
        return button
    }()
    
    private lazy var continueButton: UIButton = {
        let button = UIButton(frame: CGRect(x: getX(number: 4), y: 0, width: 50, height: 50))
        button.setTitle("Continue", for: .normal)
        button.showsTouchWhenHighlighted = true
        button.titleLabel?.font = UIFont(name: "SFProText-Regular", size: 19.0)
        let hexColor: UInt32 = 0x3067FF
        let backgroundColor = UIColor(hex: hexColor)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 5.0
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        
        button.addTarget(self, action:#selector(finishScan), for: .touchDown)
        
        return button
    }()
    //
    private lazy var shareButtonIcon: UIButton = {
        let button = CustomButton()

        button.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: buttonHeight)
        button.setTitle("Share", for: .normal)
        let textHexColor: UInt32 = 0x3067FF
        let textColor = UIColor(hex: textHexColor)
        button.setTitleColor(textColor, for: .normal)
        button.setImage(UIImage(named: "ic_share", in: Bundle(for: ScannerViewController.self), compatibleWith: nil), for: .normal)
        
        button.addTarget(self, action:#selector(shareImageButton), for: .touchUpInside)
        return button
        
//        // Create the button
//        let button = UIButton(frame: CGRect(x: 0, y: 0, width: buttonWidth, height: buttonHeight))
//        button.tintColor = .systemBlue
//        
//        // Create the image
//        let image = UIImage(named: "ic_share", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
//        let imageView = UIImageView(image: image)
//        imageView.contentMode = .scaleAspectFit
//        
//        // Calculate the position for the image view to center it horizontally
//        let imageX = (buttonWidth - imageView.frame.width) / 2
//        imageView.frame.origin = CGPoint(x: imageX, y: 0)
//        
//        // Create the label
//        let label = UILabel(frame: CGRect(x: 0, y: buttonHeight - 25, width: buttonWidth, height: 30))
//        label.text = "Share"
//        label.textAlignment = .center
//        label.textColor = .white
//        label.font = UIFont(name: "SFProText-Regular", size: 14)
//        
//        // Add the image view and label to the button
//        button.addSubview(imageView)
//        button.addSubview(label)
//        
//        button.addTarget(self, action:#selector(shareImageButton), for: .touchUpInside)
//        button.backgroundColor = .green
//        return button
    }()
    
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
    
    private lazy var shutterButton: ShutterButton = {
        let button = ShutterButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(retakeButtonTapped), for: .touchUpInside)
        return button
    }()
    lazy var selectPhotoButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "gallery", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.white
        //        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(retakeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    //  MARK: - Actions
    @objc func cancelButtonTapped() {
        if let imageScannerController = navigationController as? ImageScannerController {
            imageScannerController.isDelete = false
            imageScannerController.imageScannerDelegate?.imageScannerControllerDidCancel(imageScannerController)
        }
    }
    
    //  MARK: - Actions
    @objc func deleteButtonTapped() {
        if let imageScannerController = navigationController as? ImageScannerController {
            imageScannerController.isDelete = true
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
        mainView.addGestureRecognizer(touchDown)
        
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
        newResults.doesUserPreferEnhancedScan = isCurrentlyDisplayingEnhancedImage
        newResults.isKeepScannning = false
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
    
    @objc private func keepScanningDcouments() {
        
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
        newResults.doesUserPreferEnhancedScan = isCurrentlyDisplayingEnhancedImage
        newResults.isKeepScannning = true
        imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFinishScanningWithResults: newResults)
        
        navigationController?.popViewController(animated: true)
    }
    
    
}
