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
    
    /// Creates AAA PBR material based on food type
    /// - Parameters:
    ///   - foodType: The type of food to create material for
    ///   - energyLevel: Food energy level (affects emission/glow)
    ///   - freshness: Freshness factor (affects surface properties)
    /// - Returns: Complete PBR material with all texture maps
    static func createAAAFoodMaterial(for foodType: FoodType, energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        switch foodType {
        case .plum:
            return createAAAPlumMaterial(energyLevel: energyLevel, freshness: freshness)
        case .apple:
            return createAAAAppleMaterial(energyLevel: energyLevel, freshness: freshness)
        case .orange:
            return createAAAOrangeMaterial(energyLevel: energyLevel, freshness: freshness)
        case .melon:
            return createAAAMelonMaterial(energyLevel: energyLevel, freshness: freshness)
        case .meat:
            return createAAAMeatMaterial(energyLevel: energyLevel, freshness: freshness)
        case .fish:
            return createAAAFishMaterial(energyLevel: energyLevel, freshness: freshness)
        case .seeds:
            return createAAASeedsMaterial(energyLevel: energyLevel, freshness: freshness)
        case .nuts:
            return createAAANutsMaterial(energyLevel: energyLevel, freshness: freshness)
        }
    }
    
    // MARK: - Individual Food Materials
    
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
    
    /// Creates a photorealistic PBR material for apples using DALL-E textures
    /// - Parameters:
    ///   - energyLevel: Food energy level (affects emission/glow)
    ///   - freshness: Freshness factor (affects surface properties)
    /// - Returns: Complete PBR material with all texture maps
    static func createAAAAppleMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        print("🍎 [PBR] Creating AAA apple material...")
        print("⚡ [PBR] Energy: \(energyLevel), Freshness: \(freshness)")
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD DIFFUSE TEXTURE (Main Color)
        if let diffuseTexture = loadTexture(named: "apple-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            print("✅ [PBR] Loaded apple diffuse texture")
        } else {
            // Fallback color matching apple
            let fallbackColor = NSColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0) // Red apple
            pbrMaterial.baseColor = .init(tint: fallbackColor)
            print("⚠️ [PBR] Using fallback apple color")
        }
        
        // 🗺️ LOAD NORMAL MAP (Surface Detail)
        if let normalTexture = loadTexture(named: "apple-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            print("✅ [PBR] Loaded apple normal map")
        } else {
            print("⚠️ [PBR] Apple normal map not found")
        }
        
        // ✨ LOAD ROUGHNESS MAP (Surface Properties)
        if let roughnessTexture = loadTexture(named: "apple-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            print("✅ [PBR] Loaded apple roughness map")
        } else {
            // Fallback: Glossy apple skin
            pbrMaterial.roughness = .init(floatLiteral: 0.3) // Glossy like real apple
            print("⚠️ [PBR] Using fallback apple roughness")
        }
        
        // 🥇 METALLIC PROPERTIES: Apples are non-metallic but can have slight sheen
        pbrMaterial.metallic = .init(floatLiteral: 0.1) // Slight natural sheen
        
        // 🌟 ENERGY-BASED ENHANCEMENT
        if energyLevel > 1.0 {
            let emissionIntensity = min(0.2, (energyLevel - 1.0) * 0.08)
            let emissionColor = NSColor(red: 1.0, green: 0.9, blue: 0.8, alpha: 1.0) // Warm glow
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
            print("✨ [PBR] Added apple energy glow: \(emissionIntensity)")
        }
        
        // 🍃 FRESHNESS EFFECTS: Fresh apples are very glossy
        let baseRoughness: Float = 0.3
        let adjustedRoughness = baseRoughness * (2.0 - max(0.5, freshness))
        pbrMaterial.roughness = .init(floatLiteral: min(1.0, adjustedRoughness))
        
        // 🌈 NATURAL APPLE SURFACE: Waxy coating
        pbrMaterial.clearcoat = .init(floatLiteral: 0.2)  // Natural waxy surface
        pbrMaterial.clearcoatRoughness = .init(floatLiteral: 0.1)  // Very smooth wax
        
        print("🏆 [PBR] AAA apple material created successfully!")
        return pbrMaterial
    }
    
    /// Creates a photorealistic PBR material for oranges using DALL-E textures
    /// - Parameters:
    ///   - energyLevel: Food energy level (affects emission/glow)
    ///   - freshness: Freshness factor (affects surface properties)
    /// - Returns: Complete PBR material with all texture maps
    static func createAAAOrangeMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        print("🍊 [PBR] Creating AAA orange material...")
        print("⚡ [PBR] Energy: \(energyLevel), Freshness: \(freshness)")
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD DIFFUSE TEXTURE (Main Color)
        if let diffuseTexture = loadTexture(named: "orange-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            print("✅ [PBR] Loaded orange diffuse texture")
        } else {
            // Fallback color matching orange
            let fallbackColor = NSColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0) // Bright orange
            pbrMaterial.baseColor = .init(tint: fallbackColor)
            print("⚠️ [PBR] Using fallback orange color")
        }
        
        // 🗺️ LOAD NORMAL MAP (Surface Detail)
        if let normalTexture = loadTexture(named: "orange-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            print("✅ [PBR] Loaded orange normal map")
        } else {
            print("⚠️ [PBR] Orange normal map not found")
        }
        
        // ✨ LOAD ROUGHNESS MAP (Surface Properties)
        if let roughnessTexture = loadTexture(named: "orange-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            print("✅ [PBR] Loaded orange roughness map")
        } else {
            // Fallback: Textured orange peel
            pbrMaterial.roughness = .init(floatLiteral: 0.7) // Rough citrus peel
            print("⚠️ [PBR] Using fallback orange roughness")
        }
        
        // 🥇 METALLIC PROPERTIES: Oranges are completely non-metallic
        pbrMaterial.metallic = .init(floatLiteral: 0.0)
        
        // 🌟 ENERGY-BASED ENHANCEMENT
        if energyLevel > 1.0 {
            let emissionIntensity = min(0.25, (energyLevel - 1.0) * 0.1)
            let emissionColor = NSColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0) // Citrus glow
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
            print("✨ [PBR] Added orange energy glow: \(emissionIntensity)")
        }
        
        // 🍃 FRESHNESS EFFECTS: Fresh oranges have consistent texture
        let baseRoughness: Float = 0.7
        let adjustedRoughness = baseRoughness * (1.0 + (1.0 - max(0.5, freshness)) * 0.3)
        pbrMaterial.roughness = .init(floatLiteral: min(1.0, adjustedRoughness))
        
        print("🏆 [PBR] AAA orange material created successfully!")
        return pbrMaterial
    }
    
    // MARK: - Placeholder Materials for Future Food Types
    
    static func createAAAMelonMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        print("🍈 [PBR] Creating AAA melon material...")
        print("⚡ [PBR] Energy: \(energyLevel), Freshness: \(freshness)")
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD DIFFUSE TEXTURE (Main Color)
        if let diffuseTexture = loadTexture(named: "melon-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            print("✅ [PBR] Loaded melon diffuse texture")
        } else {
            // Fallback color matching cantaloupe melon
            let fallbackColor = NSColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0) // Orange-tan cantaloupe
            pbrMaterial.baseColor = .init(tint: fallbackColor)
            print("⚠️ [PBR] Using fallback melon color")
        }
        
        // 🗺️ LOAD NORMAL MAP (Surface Detail)
        if let normalTexture = loadTexture(named: "melon-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            print("✅ [PBR] Loaded melon normal map")
        } else {
            print("⚠️ [PBR] Melon normal map not found")
        }
        
        // ✨ LOAD ROUGHNESS MAP (Surface Properties)
        if let roughnessTexture = loadTexture(named: "melon-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            print("✅ [PBR] Loaded melon roughness map")
        } else {
            // Fallback: Textured melon rind with netting
            pbrMaterial.roughness = .init(floatLiteral: 0.8) // Rough netted surface
            print("⚠️ [PBR] Using fallback melon roughness")
        }
        
        // 🥇 METALLIC PROPERTIES: Melons are completely non-metallic
        pbrMaterial.metallic = .init(floatLiteral: 0.0)
        
        // 🌟 ENERGY-BASED ENHANCEMENT
        if energyLevel > 1.0 {
            let emissionIntensity = min(0.2, (energyLevel - 1.0) * 0.08)
            let emissionColor = NSColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1.0) // Warm melon glow
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
            print("✨ [PBR] Added melon energy glow: \(emissionIntensity)")
        }
        
        // 🍃 FRESHNESS EFFECTS: Fresh melons have consistent netted texture
        let baseRoughness: Float = 0.8
        let adjustedRoughness = baseRoughness * (1.0 + (1.0 - max(0.5, freshness)) * 0.2)
        pbrMaterial.roughness = .init(floatLiteral: min(1.0, adjustedRoughness))
        
        print("🏆 [PBR] AAA melon material created successfully!")
        return pbrMaterial
    }
    
    static func createAAAMeatMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        print("🥩 [PBR] Creating AAA meat material...")
        print("⚡ [PBR] Energy: \(energyLevel), Freshness: \(freshness)")
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD DIFFUSE TEXTURE (Main Color)
        if let diffuseTexture = loadTexture(named: "meat-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            print("✅ [PBR] Loaded meat diffuse texture")
        } else {
            // Fallback color matching raw red meat
            let fallbackColor = NSColor(red: 0.8, green: 0.2, blue: 0.15, alpha: 1.0) // Rich red meat color
            pbrMaterial.baseColor = .init(tint: fallbackColor)
            print("⚠️ [PBR] Using fallback meat color")
        }
        
        // 🗺️ LOAD NORMAL MAP (Surface Detail)
        if let normalTexture = loadTexture(named: "meat-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            print("✅ [PBR] Loaded meat normal map")
        } else {
            print("⚠️ [PBR] Meat normal map not found")
        }
        
        // ✨ LOAD ROUGHNESS MAP (Surface Properties)
        if let roughnessTexture = loadTexture(named: "meat-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            print("✅ [PBR] Loaded meat roughness map")
        } else {
            // Fallback: Slightly moist meat surface
            pbrMaterial.roughness = .init(floatLiteral: 0.6) // Moist but not wet
            print("⚠️ [PBR] Using fallback meat roughness")
        }
        
        // 🥇 METALLIC PROPERTIES: Meat is completely non-metallic
        pbrMaterial.metallic = .init(floatLiteral: 0.0)
        
        // 🌟 ENERGY-BASED ENHANCEMENT
        if energyLevel > 1.0 {
            let emissionIntensity = min(0.15, (energyLevel - 1.0) * 0.06)
            let emissionColor = NSColor(red: 0.9, green: 0.3, blue: 0.2, alpha: 1.0) // Warm red meat glow
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
            print("✨ [PBR] Added meat energy glow: \(emissionIntensity)")
        }
        
        // 🍃 FRESHNESS EFFECTS: Fresh meat has consistent moisture
        let baseRoughness: Float = 0.6
        let adjustedRoughness = baseRoughness * (1.0 + (1.0 - max(0.3, freshness)) * 0.4) // Gets rougher as it ages
        pbrMaterial.roughness = .init(floatLiteral: min(1.0, adjustedRoughness))
        
        print("🏆 [PBR] AAA meat material created successfully!")
        return pbrMaterial
    }
    
    static func createAAAFishMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        print("🐟 [PBR] Creating AAA fish material...")
        print("⚡ [PBR] Energy: \(energyLevel), Freshness: \(freshness)")
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD DIFFUSE TEXTURE (Main Color)
        if let diffuseTexture = loadTexture(named: "fish-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            print("✅ [PBR] Loaded fish diffuse texture")
        } else {
            // Fallback color matching silvery fish scales
            let fallbackColor = NSColor(red: 0.7, green: 0.8, blue: 0.9, alpha: 1.0) // Silvery blue fish
            pbrMaterial.baseColor = .init(tint: fallbackColor)
            print("⚠️ [PBR] Using fallback fish color")
        }
        
        // 🗺️ LOAD NORMAL MAP (Surface Detail)
        if let normalTexture = loadTexture(named: "fish-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            print("✅ [PBR] Loaded fish normal map")
        } else {
            print("⚠️ [PBR] Fish normal map not found")
        }
        
        // ✨ LOAD ROUGHNESS MAP (Surface Properties)
        if let roughnessTexture = loadTexture(named: "fish-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            print("✅ [PBR] Loaded fish roughness map")
        } else {
            // Fallback: Wet fish scales with some metallic reflection
            pbrMaterial.roughness = .init(floatLiteral: 0.2) // Smooth wet scales
            print("⚠️ [PBR] Using fallback fish roughness")
        }
        
        // 🥇 METALLIC PROPERTIES: Fish scales have natural metallic reflection
        pbrMaterial.metallic = .init(floatLiteral: 0.6) // Natural scale shimmer
        
        // 🌟 ENERGY-BASED ENHANCEMENT
        if energyLevel > 1.0 {
            let emissionIntensity = min(0.3, (energyLevel - 1.0) * 0.1)
            let emissionColor = NSColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0) // Cool blue fish glow
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
            print("✨ [PBR] Added fish energy glow: \(emissionIntensity)")
        }
        
        // 🍃 FRESHNESS EFFECTS: Fresh fish have bright, reflective scales
        let baseMetallic: Float = 0.6
        let adjustedMetallic = baseMetallic * max(0.3, freshness) // Duller scales when not fresh
        pbrMaterial.metallic = .init(floatLiteral: min(1.0, adjustedMetallic))
        
        // Fresh fish are smoother (wet), aged fish get rougher
        let baseRoughness: Float = 0.2
        let adjustedRoughness = baseRoughness * (1.0 + (1.0 - max(0.4, freshness)) * 0.6)
        pbrMaterial.roughness = .init(floatLiteral: min(1.0, adjustedRoughness))
        
        print("🏆 [PBR] AAA fish material created successfully!")
        return pbrMaterial
    }
    
    static func createAAASeedsMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        print("🌱 [PBR] Creating AAA seeds material...")
        print("⚡ [PBR] Energy: \(energyLevel), Freshness: \(freshness)")
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD DIFFUSE TEXTURE (Main Color)
        if let diffuseTexture = loadTexture(named: "seeds-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            print("✅ [PBR] Loaded seeds diffuse texture")
        } else {
            // Fallback color matching natural seed colors
            let fallbackColor = NSColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 1.0) // Tan/brown seeds
            pbrMaterial.baseColor = .init(tint: fallbackColor)
            print("⚠️ [PBR] Using fallback seeds color")
        }
        
        // 🗺️ LOAD NORMAL MAP (Surface Detail)
        if let normalTexture = loadTexture(named: "seeds-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            print("✅ [PBR] Loaded seeds normal map")
        } else {
            print("⚠️ [PBR] Seeds normal map not found")
        }
        
        // ✨ LOAD ROUGHNESS MAP (Surface Properties)
        if let roughnessTexture = loadTexture(named: "seeds-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            print("✅ [PBR] Loaded seeds roughness map")
        } else {
            // Fallback: Rough, matte seed surface
            pbrMaterial.roughness = .init(floatLiteral: 0.85) // Matte, non-reflective
            print("⚠️ [PBR] Using fallback seeds roughness")
        }
        
        // 🥇 METALLIC PROPERTIES: Seeds are completely non-metallic organic matter
        pbrMaterial.metallic = .init(floatLiteral: 0.0)
        
        // 🌟 ENERGY-BASED ENHANCEMENT
        if energyLevel > 1.0 {
            let emissionIntensity = min(0.2, (energyLevel - 1.0) * 0.07)
            let emissionColor = NSColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1.0) // Warm golden seed glow
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
            print("✨ [PBR] Added seeds energy glow: \(emissionIntensity)")
        }
        
        // 🍃 FRESHNESS EFFECTS: Fresh seeds have smoother surfaces, aged ones get rougher
        let baseRoughness: Float = 0.85
        let adjustedRoughness = baseRoughness * (1.0 + (1.0 - max(0.4, freshness)) * 0.2)
        pbrMaterial.roughness = .init(floatLiteral: min(1.0, adjustedRoughness))
        
        print("🏆 [PBR] AAA seeds material created successfully!")
        return pbrMaterial
    }
    
    static func createAAANutsMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: NSColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0))
        material.roughness = .init(floatLiteral: 0.8)
        material.metallic = .init(floatLiteral: 0.0)
        return material
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
