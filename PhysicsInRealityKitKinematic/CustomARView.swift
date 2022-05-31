//
//  CustomARView.swift
//  PhysicsInRealityKitKinematic
//
//  Created by Mark Horgan on 31/05/2022.
//

import RealityKit
import ARKit

class CustomARView: ARView {
    private let colors: [UIColor] = [.green, .red, .blue, .magenta, .yellow]
    private let groundSize: Float = 0.5
    
    required init(frame: CGRect) {
        super.init(frame: frame)
        
        let anchorEntity = try! Experience.loadScene()
        scene.anchors.append(anchorEntity)
        
        let spheres = buildSpheres(amount: 5, radius: 0.03)
        for sphere in spheres {
            anchorEntity.addChild(sphere)
        }
        
        let box = buildBox(size: [0.12, 0.06, 0.06], color: .green)
        anchorEntity.addChild(box)
        
        addCoaching()
    }
    
    @objc required dynamic init?(coder decorder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func buildSpheres(amount: Int, radius: Float) -> [ModelEntity] {
        var spheres: [ModelEntity] = []
        for i in 0..<amount {
            spheres.append(buildSphere(radius: radius, color: colors[i]))
        }
        return spheres
    }
    
    private func buildSphere(radius: Float, color: UIColor) -> ModelEntity {
        let sphere = ModelEntity(mesh: .generateSphere(radius: radius), materials: [SimpleMaterial(color: color, roughness: 0, isMetallic: false)])
        let minMax = (groundSize / 2) - (radius / 2)
        sphere.position = [.random(in: -minMax...minMax), radius / 2, .random(in: -minMax...minMax)]
        let shape = ShapeResource.generateSphere(radius: radius)
        sphere.collision = CollisionComponent(shapes: [shape], mode: .default, filter: .default)
        let massProperties = PhysicsMassProperties(shape: shape, mass: 0.005)
        let physicsMaterial = PhysicsMaterialResource.generate(friction: 0.5, restitution: 1)
        sphere.physicsBody = PhysicsBodyComponent(massProperties: massProperties, material: physicsMaterial, mode: .dynamic)
        sphere.physicsMotion = PhysicsMotionComponent()
        
        let gestureReconizers = installGestures([.translation], for: sphere)
        gestureReconizers.first?.addTarget(self, action: #selector(handleSphereTranslation))
        
        return sphere
    }
    
    private func buildBox(size: simd_float3, color: UIColor) -> ModelEntity {
        let box = ModelEntity(mesh: .generateBox(size: size), materials: [SimpleMaterial(color: color, roughness: 0, isMetallic: false)])
        let minMax: simd_float2 = [(groundSize / 2) - (size.x / 2), (groundSize / 2) - (size.z / 2)]
        box.position = [.random(in: -minMax.x...minMax.x), size.y / 2, .random(in: -minMax.y...minMax.y)]
        let shape = ShapeResource.generateBox(size: size)
        box.collision = CollisionComponent(shapes: [shape], mode: .default, filter: .default)
        let massProperties = PhysicsMassProperties(shape: shape, mass: 0.005)
        let physicsMaterial = PhysicsMaterialResource.generate(friction: 0.1, restitution: 0.8)
        box.physicsBody = PhysicsBodyComponent(massProperties: massProperties, material: physicsMaterial, mode: .kinematic)
        box.physicsMotion = PhysicsMotionComponent()
        
        let gestureReconizers = installGestures([.translation], for: box)
        gestureReconizers.first?.addTarget(self, action: #selector(handleBoxTranslation))
        
        return box
    }
    
    @objc private func handleSphereTranslation(_ recognizer: EntityTranslationGestureRecognizer) {
        let sphere = recognizer.entity as! HasPhysics
        
        if recognizer.state == .began {
            sphere.physicsBody?.mode = .kinematic
        } else if recognizer.state == .ended || recognizer.state == .cancelled {
            sphere.physicsBody?.mode = .dynamic
            return
        }
        
        let velocity = recognizer.velocity(in: sphere.parent)
        sphere.physicsMotion?.linearVelocity = [velocity.x, 0, velocity.z]
    }
    
    @objc private func handleBoxTranslation(_ recognizer: EntityTranslationGestureRecognizer) {
        let box = recognizer.entity as! HasPhysics
        let velocity = recognizer.velocity(in: box.parent)
        box.physicsMotion?.angularVelocity = [0, simd_length(velocity) * 15, 0]
    }
    
    private func addCoaching() {
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = session
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .horizontalPlane
        self.addSubview(coachingOverlay)
    }
}
