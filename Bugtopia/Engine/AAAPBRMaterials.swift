//
//  AAAPBRMaterials.swift
//  Bugtopia
//
//  AAA-Quality PBR Material System for Photorealistic Food Assets
//  Creates physically-based materials using DALL-E generated textures
//

import Foundation
import RealityKit
import Metal
import AppKit  // For NSImage and NSColor

@available(macOS 14.0, *)
class AAAPBRMaterials {
    
    // MARK: - Static Texture Cache
    
    private static var textureCache: [String: TextureResource] = [:]
    
    // MARK: - AAA Plum Material Creation
    
    /// Creates a photorealistic PBR material for plums using DALL-E textures
    /// - Parameters:
    ///   - energyLevel: Food energy level (affects emission/glow)
    ///   - freshness: Freshness factor (affects surface properties)
    /// - Returns: Complete PBR material with all texture maps
    static func createAAAPlumMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        print("🍇 [PBR] Creating AAA plum material...")
        print("⚡ [PBR] Energy: \(energyLevel), Freshness: \(freshness)")
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD DIFFUSE TEXTURE (Main Color)
        if let diffuseTexture = loadTexture(named: "plum-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            print("✅ [PBR] Loaded diffuse texture")
        } else {
            // Fallback color matching our texture
            let fallbackColor = NSColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0) // Purple plum
            pbrMaterial.baseColor = .init(tint: fallbackColor)
            print("⚠️ [PBR] Using fallback diffuse color")
        }
        
        // 🗺️ LOAD NORMAL MAP (Surface Detail)
        if let normalTexture = loadTexture(named: "plum-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            print("✅ [PBR] Loaded normal map")
        } else {
            print("⚠️ [PBR] Normal map not found - using flat surface")
        }
        
        // ✨ LOAD ROUGHNESS MAP (Surface Properties)
        if let roughnessTexture = loadTexture(named: "plum-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            print("✅ [PBR] Loaded roughness map")
        } else {
            // Fallback: Natural fruit roughness
            pbrMaterial.roughness = .init(floatLiteral: 0.6) // Slightly matte like real fruit
            print("⚠️ [PBR] Using fallback roughness value")
        }
        
        // 🥇 METALLIC PROPERTIES: Fruits are non-metallic
        pbrMaterial.metallic = .init(floatLiteral: 0.0)
        
        // 🌟 ENERGY-BASED ENHANCEMENT
        if energyLevel > 1.0 {
            // High-energy food gets subtle magical glow
            let emissionIntensity = min(0.3, (energyLevel - 1.0) * 0.1)
            let emissionColor = NSColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 1.0) // Warm amber glow
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
            print("✨ [PBR] Added energy glow: \(emissionIntensity)")
        }
        
        // 🍃 FRESHNESS EFFECTS
        let freshnessMultiplier = max(0.5, freshness)
        
        // Fresh fruit is slightly more glossy
        // Note: Direct roughness modification for freshness effects
        let baseRoughness: Float = 0.6 // Default fruit roughness
        let adjustedRoughness = baseRoughness * (2.0 - freshnessMultiplier)
        pbrMaterial.roughness = .init(floatLiteral: min(1.0, adjustedRoughness))
        
        // 🌈 SUBSURFACE SCATTERING: Subtle fruit translucency
        pbrMaterial.clearcoat = .init(floatLiteral: 0.1)  // Subtle surface layer
        pbrMaterial.clearcoatRoughness = .init(floatLiteral: 0.3)  // Smooth clearcoat
        
        print("🏆 [PBR] AAA plum material created successfully!")
        return pbrMaterial
    }
    
    // MARK: - Texture Loading System
    
    /// Loads and caches texture resources from Xcode Assets
    /// - Parameter name: Asset name (without extension)
    /// - Returns: TextureResource if successful, nil otherwise
    private static func loadTexture(named name: String) -> TextureResource? {
        
        // Check cache first
        if let cachedTexture = textureCache[name] {
            return cachedTexture
        }
        
        // Load from assets
        guard let image = NSImage(named: name) else {
            print("❌ [PBR] Failed to load image: \(name)")
            return nil
        }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: [:]) else {
            print("❌ [PBR] Failed to convert image to CGImage: \(name)")
            return nil
        }
        
        do {
            // Determine texture semantic based on name
            let semantic: TextureResource.Semantic = {
                if name.contains("normal") {
                    return .normal
                } else if name.contains("roughness") {
                    return .raw  // Roughness should be unprocessed
                } else {
                    return .color  // Diffuse/albedo
                }
            }()
            
            let textureResource = try TextureResource(image: cgImage, options: .init(semantic: semantic))
            
            // Cache for future use
            textureCache[name] = textureResource
            
            print("✅ [PBR] Loaded and cached texture: \(name)")
            return textureResource
            
        } catch {
            print("❌ [PBR] Failed to create TextureResource for \(name): \(error)")
            return nil
        }
    }
    
    // MARK: - Material Variations
    
    /// Creates material variation for different plum states
    static func createPlumVariation(
        ripenessFactor: Float,
        moistureLevel: Float,
        magicalEnergy: Float = 0.0
    ) -> RealityKit.Material {
        
        var material = createAAAPlumMaterial(
            energyLevel: 1.0 + magicalEnergy,
            freshness: ripenessFactor
        ) as! PhysicallyBasedMaterial
        
        // 🍇 RIPENESS EFFECTS
        if ripenessFactor > 0.8 {
            // Very ripe: darker, softer appearance
            let baseColor = NSColor(red: 0.5, green: 0.15, blue: 0.6, alpha: 1.0) // Darker plum
            material.baseColor = .init(tint: baseColor)
        }
        
        // 💧 MOISTURE EFFECTS
        if moistureLevel > 0.7 {
            // Wet fruit: more reflective
            material.clearcoat = .init(floatLiteral: min(0.4, moistureLevel * 0.5))
        }
        
        return material
    }
    
    /// Creates material optimized for mobile performance
    static func createMobilePlumMaterial() -> RealityKit.Material {
        // Simplified material with fewer texture lookups
        var simpleMaterial = PhysicallyBasedMaterial()
        
        // Only use diffuse texture for mobile
        if let diffuseTexture = loadTexture(named: "plum-diffuse") {
            simpleMaterial.baseColor = .init(texture: .init(diffuseTexture))
        } else {
            simpleMaterial.baseColor = .init(tint: NSColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0))
        }
        
        // Simple surface properties
        simpleMaterial.roughness = .init(floatLiteral: 0.6)
        simpleMaterial.metallic = .init(floatLiteral: 0.0)
        
        return simpleMaterial
    }
    
    // MARK: - Cache Management
    
    /// Clears texture cache to free memory
    static func clearTextureCache() {
        textureCache.removeAll()
        print("🗑️ [PBR] Texture cache cleared")
    }
    
    /// Returns current cache size for debugging
    static func getCacheInfo() -> String {
        return "PBR Cache: \(textureCache.count) textures loaded"
    }
}

// MARK: - Material Enhancement Extensions

@available(macOS 14.0, *)
extension AAAPBRMaterials {
    
    /// Applies dynamic lighting enhancement to materials
    static func enhanceForLighting(_ material: inout PhysicallyBasedMaterial, lightIntensity: Float) {
        // Adjust material properties based on lighting conditions
        let lightFactor = max(0.5, min(2.0, lightIntensity))
        
        // Adjust roughness for lighting conditions
        let baseRoughness: Float = 0.6
        let adjustedRoughness = baseRoughness * (1.0 / lightFactor)
        material.roughness = .init(floatLiteral: max(0.1, min(1.0, adjustedRoughness)))
    }
    
    /// Creates animated material properties for magical effects
    static func createAnimatedPlumMaterial() -> RealityKit.Material {
        var material = createAAAPlumMaterial(energyLevel: 1.5) as! PhysicallyBasedMaterial
        
        // Add subtle pulsing emission for magical food
        let pulseColor = NSColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 0.1)
        material.emissiveColor = .init(color: pulseColor)
        
        return material
    }
}
