//
//  ViewController.swift
//  Artichoke
//
//  Created by Taylan Pince on 2019-04-29.
//  Copyright © 2019 Hipo. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {
    
    // MARK: - Constants
    
    private let defaultLayoutInset: CGFloat = 10.0
    private let textViewHeight: CGFloat = 50.0

    // MARK: - Properties
    
    @IBOutlet var sceneView: ARSCNView!
    private lazy var textView: UITextView = {
        let view = UITextView()
        
        view.isScrollEnabled = false
        
        return view
    }()
    
    /// A serial queue for thread safety when modifying the SceneKit node graph.
    private let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".serialSceneKitQueue")
    
    private var session: ARSession {
        return sceneView.session
    }
    
    private var lastDetectedImage: ARReferenceImage?
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        setupTapGestureRecognizer()
        setupTextViewLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        runSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        pauseSession()
    }
    
    // MARK: - Layout setup
    
    private func setupTextViewLayout() {
        view.addSubview(textView)
        
        textView.translatesAutoresizingMaskIntoConstraints = false        
        textView.heightAnchor.constraint(equalToConstant: textViewHeight).isActive = true
        textView.leftAnchor
            .constraint(
                equalTo: view.leftAnchor,
                constant: defaultLayoutInset
            ).isActive = true
        
        textView.rightAnchor
            .constraint(
                equalTo: view.rightAnchor,
                constant: -defaultLayoutInset
            ).isActive = true

        textView.safeAreaLayoutGuide.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -defaultLayoutInset
            ).isActive = true
    }
    
    // MARK: - Session
    
    private func runSession() {
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }

        let configuration = ARWorldTrackingConfiguration()
        
        configuration.detectionImages = referenceImages
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func pauseSession() {
        session.pause()
    }
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let referenceImage = imageAnchor.referenceImage
        
        lastDetectedImage = referenceImage
        
        updateQueue.async {
//            self.highlight(referenceImage, for: node)
            self.displayButton(on: referenceImage, addingTo: node)
        }
    }
}

// MARK: - Node Additions

extension ViewController {
    private var imageHighlightAction: SCNAction {
        let actions: [SCNAction] = [
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
        ]
        
        return .sequence(actions)
    }
    
    fileprivate func highlight(_ image: ARReferenceImage, for node: SCNNode) {
        
        // Create a plane to visualize the initial position of the detected image.
        let plane = SCNPlane(width: image.physicalSize.width,
                             height: image.physicalSize.height)
        
        let planeNode = SCNNode(geometry: plane)
        
        planeNode.opacity = 0.25
        
        /*
         `SCNPlane` is vertically oriented in its local coordinate space, but
         `ARImageAnchor` assumes the image is horizontal in its local space, so
         rotate the plane to match.
         */
        planeNode.eulerAngles.x = -.pi / 2
        
        /*
         Image anchors are not tracked after initial detection, so create an
         animation that limits the duration for which the plane visualization appears.
         */
        planeNode.runAction(self.imageHighlightAction)
        
        // Add the plane visualization to the scene.
        node.addChildNode(planeNode)
    }
    
    fileprivate func displayButton(on image: ARReferenceImage, addingTo node: SCNNode) {
        let buttonSize = CGSize(width: 0.04, height: 0.04)
        
        let buttonGeometry = SCNPlane(
            width: buttonSize.width,  // referenceImage.physicalSize.width * ratio,
            height: buttonSize.height // referenceImage.physicalSize.height * ratio
        )
        
        let material = SCNMaterial()
        
        material.diffuse.contents = UIImage(named: "btn-img")
        
        let planeNode = SCNNode(geometry: buttonGeometry)
        
        planeNode.name = image.name
        planeNode.geometry?.firstMaterial = material
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.worldPosition = SCNVector3(
            image.physicalSize.width / 2 - buttonSize.width / 2,   // x
            0,                                                     // y
            -image.physicalSize.height / 2 + buttonSize.height / 2 // z
        )
        
        node.addChildNode(planeNode)
    }
}

// MARK: - Gestures

extension ViewController {
    fileprivate func setupTapGestureRecognizer() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTriggerTapRecognizer(_ :)))
        
        sceneView.addGestureRecognizer(tapRecognizer)
    }
    
    @objc
    private func didTriggerTapRecognizer(_ recognizer: UITapGestureRecognizer) {
        guard
            let detectedImageName = lastDetectedImage?.name,
            sceneView == recognizer.view
            else {
                return
        }
        
        let location = recognizer.location(in: sceneView)
        let results = sceneView.hitTest(
            location,
            options: [
                SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue
            ]
        )
        
        for aResult in results.filter( { $0.node.name != nil } ) {
            if aResult.node.name == detectedImageName {
                print("TAPPED BUTTON ON: \(detectedImageName)")
                textView.text = detectedImageName
            }
        }
    }
}
