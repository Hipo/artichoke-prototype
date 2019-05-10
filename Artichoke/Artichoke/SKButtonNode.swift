//
//  SKButtonNode.swift
//  Artichoke
//
//  Created by Eray on 10.05.2019.
//  Copyright © 2019 Hipo. All rights reserved.
//
//  Source: https://nathandemick.com/2014/09/buttons-sprite-kit-using-swift/

import SpriteKit

class SKButtonNode: SKNode {
    
    // MARK: - Properties
    
    var normalButton: SKSpriteNode
    var selectedButton: SKSpriteNode
    var action: () -> ()
    
    // MARK: - Intialization
    
    init(normalImageName: String, selectedImageName: String, action: @escaping () -> ()) {
        self.normalButton = SKSpriteNode(imageNamed: normalImageName)
        self.selectedButton = SKSpriteNode(imageNamed: selectedImageName)
        self.action = action
        
        super.init()

        selectedButton.isHidden = true
        isUserInteractionEnabled = true
        
        addChild(normalButton)
        addChild(selectedButton)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Interaction
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        normalButton.isHidden = true
        selectedButton.isHidden = false
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch: UITouch = Array(touches).first else {
            return
        }
        
        let location: CGPoint = touch.location(in: self)
        
        if normalButton.contains(location) {
            normalButton.isHidden = true
            selectedButton.isHidden = false
        } else {
            normalButton.isHidden = false
            selectedButton.isHidden = true
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch: UITouch = Array(touches).first else {
            return
        }

        let location: CGPoint = touch.location(in: self)
        
        if normalButton.contains(location) {
            action()
        }
        
        normalButton.isHidden = false
        selectedButton.isHidden = true
    }
}
