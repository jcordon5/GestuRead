//
//  PDFReaderViewController.swift
//  GestuRead
//
//  Created by jcordon5 on 2024.
//

import Foundation
import UIKit
import PDFKit
import ARKit
import RealityKit

struct Device {
    
    // Modified from https://github.com/Shiru99/AR-Eye-Tracker
    static var screenSize: CGSize {
        
        let screenWidthPixel: CGFloat = UIScreen.main.nativeBounds.width
        let screenHeightPixel: CGFloat = UIScreen.main.nativeBounds.height
        
        let ppi: CGFloat = UIScreen.main.scale * 163 // Assuming a standard PPI value of 163
        
        let a_ratio=(1125/458)/0.0623908297
        let b_ratio=(2436/458)/0.135096943231532

        return CGSize(width: (screenWidthPixel/ppi)/a_ratio, height: (screenHeightPixel/ppi)/b_ratio)
    }
    
    static var frameSize: CGSize {  // iPhone XR 414,814. It works well with iPhone 14 Pro Max
        return CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height - 82)
    }
}

struct Ranges {
    static let widthRange: ClosedRange<CGFloat> = (0...Device.frameSize.width)
    static let heightRange: ClosedRange<CGFloat> = (0...Device.frameSize.height)
}

extension CGFloat {
    func clamped(to: ClosedRange<CGFloat>) -> CGFloat {
        return to.lowerBound > self ? to.lowerBound
            : to.upperBound < self ? to.upperBound
            : self
    }
}

class PDFReaderViewController: UIViewController, UIGestureRecognizerDelegate, ARSCNViewDelegate{
    
    var sceneView: ARSCNView!
    var pdfView = PDFView()
    var lastPageTurnTime = Date()
    
    var lookAtPoint: CGPoint?
    var gazeIndicator: UIView?
    var markerView: UIImageView?

    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
       
        setupPDFView()
        setupGestureRecognizers()
        setupSceneView()
        
        let gazeViewSize: CGFloat = 20
        gazeIndicator = UIView(frame: CGRect(x: 0, y: 0, width: gazeViewSize, height: gazeViewSize))
        gazeIndicator?.backgroundColor = UIColor.red
        gazeIndicator?.layer.cornerRadius = gazeViewSize / 2
        gazeIndicator?.isHidden = false  // Set to false to make it visible for debugging
        if let gazeIndicator = gazeIndicator {
            view.addSubview(gazeIndicator)
        }
    }
    
    func setupSceneView() {
        sceneView = ARSCNView(frame: self.view.frame)
        sceneView.delegate = self
        view.addSubview(sceneView)
        view.sendSubviewToBack(sceneView)  // This ensures PDFView remains visible
    }

    
    func setupPDFView(){
        
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pdfView)
        pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pdfView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        // Set the display mode to single page
        pdfView.displayMode = .singlePage
        pdfView.autoScales = true
        
    }

    func loadPDF(from url: URL) {
        guard let document = PDFDocument(url: url) else {
            print("Unable to load the PDF document.")
            return
        }
        pdfView.document = document
        
        // Check if there is a saved marked page index
        if let pageIndex = UserDefaults.standard.object(forKey: "markedPageIndex") as? Int,
           let page = pdfView.document?.page(at: pageIndex) {
            pdfView.go(to: page)
            
        }
    }


    func setupGestureRecognizers() {
        let tapRight = UITapGestureRecognizer(target: self, action: #selector(handleRightTap))
        tapRight.numberOfTapsRequired = 1
        tapRight.delegate = self
        view.addGestureRecognizer(tapRight)

        let tapLeft = UITapGestureRecognizer(target: self, action: #selector(handleLeftTap))
        tapLeft.numberOfTapsRequired = 1
        tapLeft.delegate = self
        view.addGestureRecognizer(tapLeft)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard ARFaceTrackingConfiguration.isSupported else {
            print("ARKit Face Tracking is not supported on this device.")
            return
        }

        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)
        print("AR Session is running")
    }
    
    /*func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        return nil
    }*/
    
    func addMarker() {
        
        guard let currentPage = pdfView.currentPage else { return }
        let pageIndex = pdfView.document?.index(for: currentPage) ?? 0
        
        let previousIndex = UserDefaults.standard.object(forKey: "markedPageIndex") as? Int
        if previousIndex == pageIndex {
            print("Marker removed at page: \(pageIndex)")
            self.removeMarkerView()
            UserDefaults.standard.set(nil, forKey: "markedPageIndex")
            return
        }
        print("Marker added at page: \(pageIndex)")
        // Save the marked page index to UserDefaults
        UserDefaults.standard.set(pageIndex, forKey: "markedPageIndex")
        // Add visual marker
        addMarkerView(at: pageIndex)
    }

    func addMarkerView(at pageIndex: Int) {
        guard let page = pdfView.document?.page(at: pageIndex) else { return }
        let pageBounds = pdfView.convert(page.bounds(for: .mediaBox), from: page)
    
        // Create a marker view
        let markerView = UIImageView(image: UIImage(named: "bookmark"))
        markerView.frame = CGRect(x: pageBounds.minX, y: pageBounds.minY, width: 30, height: 30)
        pdfView.addSubview(markerView)
        pdfView.bringSubviewToFront(markerView)

        // Save the marker view for later removal if needed
        self.markerView = markerView
    }

    func removeMarkerView() {
        markerView?.removeFromSuperview()
    }
    
    func pdfGoTo(next: Bool){
        let previousIndex = UserDefaults.standard.object(forKey: "markedPageIndex") as? Int
        
        if next{
            self.pdfView.goToNextPage(nil)
        }
        else{
            self.pdfView.goToPreviousPage(nil)
        }
        guard let currentPage = pdfView.currentPage else { return }
        let pageIndex = pdfView.document?.index(for: currentPage) ?? 0
        
        if previousIndex != nil && pageIndex != previousIndex{
            self.removeMarkerView()
        }
        else if previousIndex != nil && pageIndex == previousIndex {
            self.addMarkerView(at: pageIndex)
        }
        
    }

    func faceRotationFromMatrix(transform: SCNMatrix4) -> (roll: CGFloat, pitch: CGFloat, yaw: CGFloat) {
        let roll = CGFloat(atan2(transform.m21, transform.m22))
        let pitch = CGFloat(atan2(-transform.m31, sqrt(transform.m32 * transform.m32 + transform.m33 * transform.m33)))
        let yaw = CGFloat(atan2(transform.m12, transform.m11))

        return (roll, pitch, yaw)
    }
    
    func isPoint(_ point: CGPoint, inCornerOfSize cornerSize: CGSize, ofScreenWithSize screenSize: CGSize, isRightCorner: Bool) -> Bool {
        let cornerRect: CGRect
        if isRightCorner {
            cornerRect = CGRect(x: screenSize.width - cornerSize.width, y: screenSize.height - cornerSize.height, width: cornerSize.width, height: cornerSize.height)
        } else {
            cornerRect = CGRect(x: 0, y: screenSize.height - cornerSize.height, width: cornerSize.width, height: cornerSize.height)
        }

        return cornerRect.contains(point)
    }

    private func detectGazePoint(faceAnchor: ARFaceAnchor) -> CGPoint {
        // Modified from https://github.com/Shiru99/AR-Eye-Tracker
        let lookAtPoint = faceAnchor.lookAtPoint
        
        guard let cameraTransform = sceneView.session.currentFrame?.camera.transform else {
            return CGPoint(
                x: 200, y: 200
            )
        }
        
        let lookAtPointInWorld = faceAnchor.transform * simd_float4(lookAtPoint, 1)
        
        let transformedLookAtPoint = simd_mul(simd_inverse(cameraTransform), lookAtPointInWorld)
        
        let screenX = transformedLookAtPoint.y / (Float(Device.screenSize.width) / 2) * Float(Device.frameSize.width)
        let screenY = transformedLookAtPoint.x / (Float(Device.screenSize.height) / 2) * Float(Device.frameSize.height)
        
        let focusPoint = CGPoint(
            x: CGFloat(screenX).clamped(to: Ranges.widthRange),
            y: CGFloat(screenY).clamped(to: Ranges.heightRange)
        )
        
        return focusPoint
    }


    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor,
              faceAnchor.isTracked else { return }
                
        let faceTransform = SCNMatrix4(faceAnchor.transform)
        let rotation = faceRotationFromMatrix(transform: faceTransform)
        
        let eyebrowRaised = faceAnchor.blendShapes[.browInnerUp] as? CGFloat ?? 0
    
    
        DispatchQueue.main.async {
            let screenSize = UIScreen.main.bounds.size
            let cornerSize = CGSize(width: screenSize.width / 5, height: screenSize.height / 5)
            let mappedGazePoint = self.detectGazePoint(faceAnchor: faceAnchor)
            self.gazeIndicator?.center = mappedGazePoint
            self.gazeIndicator?.isHidden = false
            print("Gaze Focus Point: \(mappedGazePoint)")
            let now = Date()
            if now.timeIntervalSince(self.lastPageTurnTime) >= 2 { // 2 seconds cooldown
                if self.isPoint(mappedGazePoint, inCornerOfSize: cornerSize, ofScreenWithSize: screenSize, isRightCorner: true) {
                    self.pdfGoTo(next: true)
                    self.lastPageTurnTime = now
                } else if self.isPoint(mappedGazePoint, inCornerOfSize: cornerSize, ofScreenWithSize: screenSize, isRightCorner: false) {
                    self.pdfGoTo(next: false)
                    self.lastPageTurnTime = now
                }
                else if rotation.yaw < -0.15 { // Head turned to the right
                    self.pdfGoTo(next: false)
                    self.lastPageTurnTime = now
                } else if rotation.yaw > 0.15 { // Head turned to the left
                    self.pdfGoTo(next: true)
                    self.lastPageTurnTime = now
                }
                else if eyebrowRaised > 0.5 { // This threshold is based on testing
                    self.addMarker()
                    self.lastPageTurnTime = now
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    @objc func handleRightTap(_ gesture: UITapGestureRecognizer) {
        // Turn to the next page
        if gesture.location(in: view).x > view.bounds.midX {
            pdfView.goToNextPage(nil)
        }
    }

    @objc func handleLeftTap(_ gesture: UITapGestureRecognizer) {
        // Turn to the previous page
        if gesture.location(in: view).x < view.bounds.midX {
            pdfView.goToPreviousPage(nil)
        }
    }
}
