import UIKit
import Cartography
import AVFoundation

class CameraView: UIView, UIGestureRecognizerDelegate {

  lazy var closeButton: UIButton = self.makeCloseButton()
  lazy var flashButton: TripleButton = self.makeFlashButton()
  lazy var rotateButton: UIButton = self.makeRotateButton()
  lazy var bottomContainer: UIView = self.makeBottomContainer()
  lazy var stackView: StackView = self.makeStackView()
  lazy var shutterButton: ShutterButton = self.makeShutterButton()
  lazy var doneButton: UIButton = self.makeDoneButton()
  lazy var focusImageView: UIImageView = self.makeFocusImageView()
  lazy var tapGR: UITapGestureRecognizer = self.makeTapGR()

  var timer: NSTimer?
  var previewLayer: AVCaptureVideoPreviewLayer?

  // MARK: - Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = UIColor.blackColor()
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Setup

  func setup() {
    addGestureRecognizer(tapGR)

    [closeButton, flashButton, rotateButton, bottomContainer].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      self.addSubview($0)
    }

    [stackView, shutterButton, doneButton].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      self.bottomContainer.addSubview($0)
    }

    [closeButton, flashButton, rotateButton].forEach {
      Utils.addShadow($0)
    }

    insertSubview(focusImageView, belowSubview: bottomContainer)

    constrain(closeButton, flashButton, rotateButton, bottomContainer) {
      closeButton, flashButton, rotateButton, bottomContainer in

      closeButton.top == closeButton.superview!.top + 10
      closeButton.left == closeButton.superview!.left + 12
      closeButton.width == 44
      closeButton.height == 44

      flashButton.centerY == closeButton.centerY
      flashButton.centerX == flashButton.superview!.centerX
      flashButton.height == 44
      flashButton.width == 60

      rotateButton.top == rotateButton.superview!.top + 10
      rotateButton.right == rotateButton.superview!.right - 12
      rotateButton.width == 44
      rotateButton.height == 44

      bottomContainer.left == bottomContainer.superview!.left
      bottomContainer.right == bottomContainer.superview!.right
      bottomContainer.bottom == bottomContainer.superview!.bottom
      bottomContainer.height == 80
    }

    constrain(stackView, shutterButton, doneButton) {
      stackView, shutterButton, doneButton in

      stackView.centerY == stackView.superview!.centerY
      stackView.left == stackView.superview!.left + 38
      stackView.width == 44
      stackView.height == 44

      shutterButton.center == shutterButton.superview!.center
      shutterButton.width == 60
      shutterButton.height == 60

      doneButton.centerY == doneButton.superview!.centerY
      doneButton.right == doneButton.superview!.right - 38
    }
  }

  func setupPreviewLayer(session: AVCaptureSession) {
    guard previewLayer == nil else { return }

    let layer = AVCaptureVideoPreviewLayer(session: session)
    layer.autoreverses = true
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill

    self.layer.insertSublayer(layer, atIndex: 0)
    layer.frame = self.layer.bounds

    previewLayer = layer
  }

  // MARK: - Action

  func viewTapped(gr: UITapGestureRecognizer) {
    let point = gr.locationInView(self)

    focusImageView.transform = CGAffineTransformIdentity
    timer?.invalidate()

    focusImageView.center = point

    UIView.animateWithDuration(0.5, animations: {
      self.focusImageView.alpha = 1
      self.focusImageView.transform = CGAffineTransformMakeScale(0.6, 0.6)
    }, completion: { _ in
      self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self,
        selector: #selector(CameraView.timerFired(_:)), userInfo: nil, repeats: false)
    })
  }

  // MARK: - Timer

  func timerFired(timer: NSTimer) {
    UIView.animateWithDuration(0.3, animations: {
      self.focusImageView.alpha = 0
    }, completion: { _ in
      self.focusImageView.transform = CGAffineTransformIdentity
    })
  }

  // MARK: - UIGestureRecognizerDelegate
  override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
    let point = gestureRecognizer.locationInView(self)

    return point.y > closeButton.frame.maxY + focusImageView.frame.size.height/3
      && point.y < bottomContainer.frame.origin.y - focusImageView.frame.size.height/3
  }

  // MARK: - Controls

  func makeCloseButton() -> UIButton {
    let button = UIButton(type: .Custom)
    button.setImage(BundleAsset.image("gallery_close"), forState: .Normal)

    return button
  }

  func makeFlashButton() -> TripleButton {
    let states: [TripleButton.State] = [
      TripleButton.State(title: "AUTO", image: BundleAsset.image("gallery_camera_flash_auto")!),
      TripleButton.State(title: "ON", image: BundleAsset.image("gallery_camera_flash_on")!),
      TripleButton.State(title: "OFF", image: BundleAsset.image("gallery_camera_flash_off")!),
    ]

    let button = TripleButton(states: states)

    return button
  }

  func makeRotateButton() -> UIButton {
    let button = UIButton(type: .Custom)
    button.setImage(BundleAsset.image("gallery_camera_rotate"), forState: .Normal)

    return button
  }

  func makeBottomContainer() -> UIView {
    let view = UIView()
    view.backgroundColor = UIColor(red: 3/255, green: 15/255, blue: 29/255, alpha: 0.7)

    return view
  }

  func makeStackView() -> StackView {
    let view = StackView()

    return view
  }

  func makeShutterButton() -> ShutterButton {
    let button = ShutterButton()

    return button
  }

  func makeDoneButton() -> UIButton {
    let button = UIButton(type: .System)
    button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
    button.titleLabel?.font = UIFont.systemFontOfSize(16)
    button.setTitle("Done", forState: .Normal)

    return button
  }

  func makeFocusImageView() -> UIImageView {
    let view = UIImageView()
    view.frame.size = CGSize(width: 110, height: 110)
    view.image = BundleAsset.image("gallery_camera_focus")
    view.backgroundColor = .clearColor()
    view.alpha = 0

    return view
  }

  func makeTapGR() -> UITapGestureRecognizer {
    let gr = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
    gr.delegate = self

    return gr
  }

}