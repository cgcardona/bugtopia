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
        case .blackberry:
            return createAAABlackberryMaterial(energyLevel: energyLevel, freshness: freshness)
        case .tuna:
            return createAAATunaMaterial(energyLevel: energyLevel, freshness: freshness)
        case .mediumSteak:
            return createAAAMediumSteakMaterial(energyLevel: energyLevel, freshness: freshness)
        case .rawFlesh:
            return createAAARawFleshMaterial(energyLevel: energyLevel, freshness: freshness)
        case .rawSteak:
            return createAAARawSteakMaterial(energyLevel: energyLevel, freshness: freshness)
        case .grilledSteak:
            return createAAAGrilledSteakMaterial(energyLevel: energyLevel, freshness: freshness)
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
        
        // Creating AAA plum material (logging disabled for performance)
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD DIFFUSE TEXTURE (Main Color)
        if let diffuseTexture = loadTexture(named: "plum-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            // Diffuse texture loaded
        } else {
            // Fallback color matching our texture
            let fallbackColor = NSColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0) // Purple plum
            pbrMaterial.baseColor = .init(tint: fallbackColor)
        }
        
        // 🗺️ LOAD NORMAL MAP (Surface Detail)
        if let normalTexture = loadTexture(named: "plum-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            // Normal map loaded
        } else {
            // Normal map not found - using flat surface
        }
        
        // ✨ LOAD ROUGHNESS MAP (Surface Properties)
        if let roughnessTexture = loadTexture(named: "plum-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            // Roughness map loaded
        } else {
            // Fallback: Natural fruit roughness
            pbrMaterial.roughness = .init(floatLiteral: 0.6) // Slightly matte like real fruit
            // Using fallback roughness value
        }
        
        // 🥇 METALLIC PROPERTIES: Fruits are non-metallic
        pbrMaterial.metallic = .init(floatLiteral: 0.0)
        
        // 🌟 ENERGY-BASED ENHANCEMENT
        if energyLevel > 1.0 {
            // High-energy food gets subtle magical glow
            let emissionIntensity = min(0.3, (energyLevel - 1.0) * 0.1)
            let emissionColor = NSColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 1.0) // Warm amber glow
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
            // Energy glow added
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
        
        // AAA plum material created successfully
        return pbrMaterial
    }
    
    /// Creates a photorealistic PBR material for apples using DALL-E textures
    /// - Parameters:
    ///   - energyLevel: Food energy level (affects emission/glow)
    ///   - freshness: Freshness factor (affects surface properties)
    /// - Returns: Complete PBR material with all texture maps
    static func createAAAAppleMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        // 🍎 Creating AAA apple material (Energy: \(energyLevel), Freshness: \(freshness))
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD AAA DIFFUSE TEXTURE (Professional PBR Color Map)
        if let diffuseTexture = loadTexture(named: "apple-diffuse-v2") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            // ✅ Loaded professional apple diffuse texture (v2)
        } else {
            // Fallback color matching apple
            let fallbackColor = NSColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0) // Red apple
            pbrMaterial.baseColor = .init(tint: fallbackColor)
            // Using fallback apple color
        }
        
        // 🗺️ LOAD AAA NORMAL MAP (Professional Surface Detail)
        if let normalTexture = loadTexture(named: "apple-normal-v2") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            // ✅ Loaded professional apple normal map (v2)
        } else {
            // Apple normal map not found - using smooth surface
        }
        
        // ✨ LOAD AAA ROUGHNESS MAP (Professional Surface Properties)
        if let roughnessTexture = loadTexture(named: "apple-roughness-v2") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            // ✅ Loaded professional apple roughness map (v2)
        } else {
            // Fallback: Glossy apple skin
            pbrMaterial.roughness = .init(floatLiteral: 0.3) // Glossy like real apple
            // Using fallback apple roughness
        }
        
        // 🥇 AAA METALLIC PROPERTIES: Apples are non-metallic organic material
        pbrMaterial.metallic = .init(floatLiteral: 0.0) // Pure organic material
        
        // 🌟 AAA SUBSURFACE SCATTERING: Simulate light penetration through apple skin
        // Note: RealityKit doesn't have direct SSS, but we can fake it with emission
        let subsurfaceColor = NSColor(red: 0.9, green: 0.3, blue: 0.2, alpha: 0.1)
        pbrMaterial.emissiveColor = .init(color: subsurfaceColor)
        
        // 🍎 AAA CLEARCOAT: Natural waxy apple skin finish
        pbrMaterial.clearcoat = .init(floatLiteral: 0.3)
        pbrMaterial.clearcoatRoughness = .init(floatLiteral: 0.1)
        
        // 🌟 ENERGY-BASED ENHANCEMENT
        if energyLevel > 1.0 {
            let emissionIntensity = min(0.2, (energyLevel - 1.0) * 0.08)
            let emissionColor = NSColor(red: 1.0, green: 0.9, blue: 0.8, alpha: 1.0) // Warm glow
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
            // Apple energy glow added
        }
        
        // 🍃 FRESHNESS EFFECTS: Fresh apples are very glossy
        let baseRoughness: Float = 0.3
        let adjustedRoughness = baseRoughness * (2.0 - max(0.5, freshness))
        pbrMaterial.roughness = .init(floatLiteral: min(1.0, adjustedRoughness))
        
        // 🌈 NATURAL APPLE SURFACE: Waxy coating
        pbrMaterial.clearcoat = .init(floatLiteral: 0.2)  // Natural waxy surface
        pbrMaterial.clearcoatRoughness = .init(floatLiteral: 0.1)  // Very smooth wax
        
        // 🌫️ LOAD APPLE AMBIENT OCCLUSION (Depth Enhancement)
        if let aoTexture = loadTexture(named: "apple-ao") {
            // Note: RealityKit doesn't have direct AO, but we can use it to modulate other properties
            // This is a placeholder for future AO integration
            // print("🍎 ✅ Loaded professional apple AO map")
        } else {
            // print("🍎 ⚠️ Apple AO map not found")
        }
        
        // 🏆 AAA apple material created successfully!
        return pbrMaterial
    }
    
    /// Creates a photorealistic PBR material for blackberries
    /// - Parameters:
    ///   - energyLevel: Food energy level (affects emission/glow)
    ///   - freshness: Freshness factor (affects surface properties)
    /// - Returns: Complete PBR material with all texture maps
    static func createAAABlackberryMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        // 🫐 Creating AAA blackberry material (Energy: \(energyLevel), Freshness: \(freshness))
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD BLACKBERRY DIFFUSE TEXTURE (Professional PBR Color Map)
        if let diffuseTexture = loadTexture(named: "blackberry-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            // print("🫐 ✅ Loaded professional blackberry diffuse texture")
        } else {
            // Fallback color matching blackberry
            let blackberryColor = NSColor(red: 0.15, green: 0.05, blue: 0.25, alpha: 1.0) // Deep purple-black
            pbrMaterial.baseColor = .init(tint: blackberryColor)
            // print("🫐 ⚠️ Using fallback blackberry color - diffuse texture not found")
        }
        
        // 🗺️ LOAD BLACKBERRY NORMAL MAP (Surface Detail)
        if let normalTexture = loadTexture(named: "blackberry-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            // print("🫐 ✅ Loaded professional blackberry normal map")
        } else {
            // print("🫐 ⚠️ Blackberry normal map not found")
        }
        
        // ✨ LOAD BLACKBERRY ROUGHNESS MAP (Surface Properties)
        if let roughnessTexture = loadTexture(named: "blackberry-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            // print("🫐 ✅ Loaded professional blackberry roughness map")
        } else {
            // Fallback: Berry surface properties
            let berryRoughness = 0.4 - (freshness * 0.2) // Fresh berries are glossier
            pbrMaterial.roughness = .init(floatLiteral: max(0.2, berryRoughness))
            // print("🫐 ⚠️ Using fallback blackberry roughness - texture not found")
        }
        
        // 🌫️ LOAD BLACKBERRY AMBIENT OCCLUSION (Depth Enhancement)
        if let aoTexture = loadTexture(named: "blackberry-ao") {
            // Note: RealityKit doesn't have direct AO, but we can use it to modulate other properties
            // This is a placeholder for future AO integration
        }
        
        // 🫐 AAA METALLIC PROPERTIES: Berries are non-metallic organic material
        pbrMaterial.metallic = .init(floatLiteral: 0.0) // Pure organic material
        
        // 🌟 AAA SUBSURFACE SCATTERING: Simulate light penetration through berry skin
        let subsurfaceColor = NSColor(red: 0.4, green: 0.1, blue: 0.3, alpha: 0.1)
        pbrMaterial.emissiveColor = .init(color: subsurfaceColor)
        
        // 🫐 NATURAL BERRY FINISH: Slight natural sheen
        pbrMaterial.clearcoat = .init(floatLiteral: 0.1)
        pbrMaterial.clearcoatRoughness = .init(floatLiteral: 0.3)
        
        // 🌟 ENERGY-BASED ENHANCEMENT
        if energyLevel > 1.0 {
            let emissionIntensity = min(0.15, (energyLevel - 1.0) * 0.06)
            let emissionColor = NSColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0) // Purple glow
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
        }
        
        // 🏆 AAA blackberry material created successfully!
        return pbrMaterial
    }
    
    /// Creates a photorealistic PBR material for oranges using DALL-E textures
    /// - Parameters:
    ///   - energyLevel: Food energy level (affects emission/glow)
    ///   - freshness: Freshness factor (affects surface properties)
    /// - Returns: Complete PBR material with all texture maps
    static func createAAAOrangeMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        // 🍊 Creating AAA orange material (Energy: \(energyLevel), Freshness: \(freshness))
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD ORANGE DIFFUSE TEXTURE (Professional PBR Color Map)
        if let diffuseTexture = loadTexture(named: "orange-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            // print("🍊 ✅ Loaded professional orange diffuse texture")
        } else {
            // Fallback color matching orange
            let fallbackColor = NSColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0) // Bright orange
            pbrMaterial.baseColor = .init(tint: fallbackColor)
            // print("🍊 ⚠️ Using fallback orange color - diffuse texture not found")
        }
        
        // 🗺️ LOAD ORANGE NORMAL MAP (Professional Surface Detail)
        if let normalTexture = loadTexture(named: "orange-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            // print("🍊 ✅ Loaded professional orange normal map")
        } else {
            // print("🍊 ⚠️ Orange normal map not found")
        }
        
        // ✨ LOAD ORANGE ROUGHNESS MAP (Professional Surface Properties)
        if let roughnessTexture = loadTexture(named: "orange-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            // print("🍊 ✅ Loaded professional orange roughness map")
        } else {
            // Fallback: Textured orange peel
            pbrMaterial.roughness = .init(floatLiteral: 0.7) // Rough citrus peel
            // print("🍊 ⚠️ Using fallback orange roughness - texture not found")
        }
        
        // 🌫️ LOAD ORANGE AMBIENT OCCLUSION (Depth Enhancement)
        if let aoTexture = loadTexture(named: "orange-ao") {
            // Note: RealityKit doesn't have direct AO, but we can use it to modulate other properties
            // This is a placeholder for future AO integration
            // print("🍊 ✅ Loaded professional orange AO map")
        } else {
            // print("🍊 ⚠️ Orange AO map not found")
        }
        
        // 🥇 METALLIC PROPERTIES: Oranges are completely non-metallic
        pbrMaterial.metallic = .init(floatLiteral: 0.0)
        
        // 🌟 ENERGY-BASED ENHANCEMENT
        if energyLevel > 1.0 {
            let emissionIntensity = min(0.25, (energyLevel - 1.0) * 0.1)
            let emissionColor = NSColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0) // Citrus glow
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
            // Orange energy glow added
        }
        
        // 🍃 FRESHNESS EFFECTS: Fresh oranges have consistent texture
        let baseRoughness: Float = 0.7
        let adjustedRoughness = baseRoughness * (1.0 + (1.0 - max(0.5, freshness)) * 0.3)
        pbrMaterial.roughness = .init(floatLiteral: min(1.0, adjustedRoughness))
        
        // AAA orange material created successfully
        return pbrMaterial
    }
    
    // MARK: - Placeholder Materials for Future Food Types
    
    static func createAAAMelonMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        // Creating AAA melon material (logging disabled)
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD DIFFUSE TEXTURE (Main Color)
        if let diffuseTexture = loadTexture(named: "melon-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            // Melon diffuse texture loaded
        } else {
            // Fallback color matching cantaloupe melon
            let fallbackColor = NSColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0) // Orange-tan cantaloupe
            pbrMaterial.baseColor = .init(tint: fallbackColor)
            // Using fallback melon color
        }
        
        // 🗺️ LOAD NORMAL MAP (Surface Detail)
        if let normalTexture = loadTexture(named: "melon-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            // print("✅ [PBR] Loaded melon normal map")
        } else {
            // print("⚠️ [PBR] Melon normal map not found")
        }
        
        // ✨ LOAD ROUGHNESS MAP (Surface Properties)
        if let roughnessTexture = loadTexture(named: "melon-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            // print("✅ [PBR] Loaded melon roughness map")
        } else {
            // Fallback: Textured melon rind with netting
            pbrMaterial.roughness = .init(floatLiteral: 0.8) // Rough netted surface
            // print("⚠️ [PBR] Using fallback melon roughness")
        }
        
        // 🥇 METALLIC PROPERTIES: Melons are completely non-metallic
        pbrMaterial.metallic = .init(floatLiteral: 0.0)
        
        // 🌟 ENERGY-BASED ENHANCEMENT
        if energyLevel > 1.0 {
            let emissionIntensity = min(0.2, (energyLevel - 1.0) * 0.08)
            let emissionColor = NSColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1.0) // Warm melon glow
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
            // print("✨ [PBR] Added melon energy glow: \(emissionIntensity)")
        }
        
        // 🍃 FRESHNESS EFFECTS: Fresh melons have consistent netted texture
        let baseRoughness: Float = 0.8
        let adjustedRoughness = baseRoughness * (1.0 + (1.0 - max(0.5, freshness)) * 0.2)
        pbrMaterial.roughness = .init(floatLiteral: min(1.0, adjustedRoughness))
        
        // print("🏆 [PBR] AAA melon material created successfully!")
        return pbrMaterial
    }
    
    static func createAAAMeatMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        // Creating AAA meat material (logging disabled)
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD DIFFUSE TEXTURE (Main Color)
        if let diffuseTexture = loadTexture(named: "meat-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            // Meat diffuse texture loaded
        } else {
            // Fallback color matching raw red meat
            let fallbackColor = NSColor(red: 0.8, green: 0.2, blue: 0.15, alpha: 1.0) // Rich red meat color
            pbrMaterial.baseColor = .init(tint: fallbackColor)
        }
        
        // 🗺️ LOAD NORMAL MAP (Surface Detail)
        if let normalTexture = loadTexture(named: "meat-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            // print("✅ [PBR] Loaded meat normal map")
        } else {
            // print("⚠️ [PBR] Meat normal map not found")
        }
        
        // ✨ LOAD ROUGHNESS MAP (Surface Properties)
        if let roughnessTexture = loadTexture(named: "meat-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            // print("✅ [PBR] Loaded meat roughness map")
        } else {
            // Fallback: Slightly moist meat surface
            pbrMaterial.roughness = .init(floatLiteral: 0.6) // Moist but not wet
            // print("⚠️ [PBR] Using fallback meat roughness")
        }
        
        // 🥇 METALLIC PROPERTIES: Meat is completely non-metallic
        pbrMaterial.metallic = .init(floatLiteral: 0.0)
        
        // 🌟 ENERGY-BASED ENHANCEMENT
        if energyLevel > 1.0 {
            let emissionIntensity = min(0.15, (energyLevel - 1.0) * 0.06)
            let emissionColor = NSColor(red: 0.9, green: 0.3, blue: 0.2, alpha: 1.0) // Warm red meat glow
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
            // print("✨ [PBR] Added meat energy glow: \(emissionIntensity)")
        }
        
        // 🍃 FRESHNESS EFFECTS: Fresh meat has consistent moisture
        let baseRoughness: Float = 0.6
        let adjustedRoughness = baseRoughness * (1.0 + (1.0 - max(0.3, freshness)) * 0.4) // Gets rougher as it ages
        pbrMaterial.roughness = .init(floatLiteral: min(1.0, adjustedRoughness))
        
        // print("🏆 [PBR] AAA meat material created successfully!")
        return pbrMaterial
    }
    
    static func createAAAFishMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        // print("🐟 [PBR] Creating AAA fish material...")
        // print("⚡ [PBR] Energy: \(energyLevel), Freshness: \(freshness)")
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD DIFFUSE TEXTURE (Main Color)
        if let diffuseTexture = loadTexture(named: "fish-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            // print("✅ [PBR] Loaded fish diffuse texture")
        } else {
            // Fallback color matching silvery fish scales
            let fallbackColor = NSColor(red: 0.7, green: 0.8, blue: 0.9, alpha: 1.0) // Silvery blue fish
            pbrMaterial.baseColor = .init(tint: fallbackColor)
            // print("⚠️ [PBR] Using fallback fish color")
        }
        
        // 🗺️ LOAD NORMAL MAP (Surface Detail)
        if let normalTexture = loadTexture(named: "fish-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            // print("✅ [PBR] Loaded fish normal map")
        } else {
            // print("⚠️ [PBR] Fish normal map not found")
        }
        
        // ✨ LOAD ROUGHNESS MAP (Surface Properties)
        if let roughnessTexture = loadTexture(named: "fish-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            // print("✅ [PBR] Loaded fish roughness map")
        } else {
            // Fallback: Wet fish scales with some metallic reflection
            pbrMaterial.roughness = .init(floatLiteral: 0.2) // Smooth wet scales
            // print("⚠️ [PBR] Using fallback fish roughness")
        }
        
        // 🥇 METALLIC PROPERTIES: Fish scales have natural metallic reflection
        pbrMaterial.metallic = .init(floatLiteral: 0.6) // Natural scale shimmer
        
        // 🌟 ENERGY-BASED ENHANCEMENT
        if energyLevel > 1.0 {
            let emissionIntensity = min(0.3, (energyLevel - 1.0) * 0.1)
            let emissionColor = NSColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0) // Cool blue fish glow
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
            // print("✨ [PBR] Added fish energy glow: \(emissionIntensity)")
        }
        
        // 🍃 FRESHNESS EFFECTS: Fresh fish have bright, reflective scales
        let baseMetallic: Float = 0.6
        let adjustedMetallic = baseMetallic * max(0.3, freshness) // Duller scales when not fresh
        pbrMaterial.metallic = .init(floatLiteral: min(1.0, adjustedMetallic))
        
        // Fresh fish are smoother (wet), aged fish get rougher
        let baseRoughness: Float = 0.2
        let adjustedRoughness = baseRoughness * (1.0 + (1.0 - max(0.4, freshness)) * 0.6)
        pbrMaterial.roughness = .init(floatLiteral: min(1.0, adjustedRoughness))
        
        // print("🏆 [PBR] AAA fish material created successfully!")
        return pbrMaterial
    }
    
    static func createAAATunaMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        // print("🍣 [PBR] Creating AAA sushi-grade tuna material...")
        // print("⚡ [PBR] Energy: \(energyLevel), Freshness: \(freshness)")
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD DIFFUSE TEXTURE (Main Color)
        if let diffuseTexture = loadTexture(named: "tuna-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            // print("✅ [PBR] Loaded tuna diffuse texture")
        } else {
            // Fallback color: Deep red sushi tuna
            let fallbackColor = NSColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 1.0) // Deep red tuna
            pbrMaterial.baseColor = .init(tint: fallbackColor)
            // print("⚠️ [PBR] Using fallback sushi tuna color")
        }
        
        // 🗺️ LOAD NORMAL MAP (Surface Detail)
        if let normalTexture = loadTexture(named: "tuna-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            // print("✅ [PBR] Loaded tuna normal map")
        } else {
            // print("⚠️ [PBR] Tuna normal map not found")
        }
        
        // ✨ LOAD ROUGHNESS MAP (Surface Properties)
        if let roughnessTexture = loadTexture(named: "tuna-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            // print("✅ [PBR] Loaded tuna roughness map")
        } else {
            // Fallback: Fresh sushi tuna is smooth and slightly moist
            pbrMaterial.roughness = .init(floatLiteral: 0.15) // Very smooth, fresh cut
            // print("⚠️ [PBR] Using fallback tuna roughness")
        }
        
        // 🌫️ LOAD AMBIENT OCCLUSION MAP (Depth and Shadow Detail)
        if let aoTexture = loadTexture(named: "tuna-ao") {
            pbrMaterial.ambientOcclusion = .init(texture: .init(aoTexture))
            // print("✅ [PBR] Loaded tuna AO map")
        } else {
            // print("⚠️ [PBR] Tuna AO map not found")
        }
        
        // 🥇 METALLIC PROPERTIES: Fresh tuna has subtle sheen but not metallic
        pbrMaterial.metallic = .init(floatLiteral: 0.1) // Minimal metallic, more organic
        
        // 🌟 ENERGY-BASED ENHANCEMENT
        if energyLevel > 1.0 {
            let emissionIntensity = min(0.2, (energyLevel - 1.0) * 0.08)
            let emissionColor = NSColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0) // Warm red glow
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
            // print("✨ [PBR] Added tuna energy glow: \(emissionIntensity)")
        }
        
        // 🍃 FRESHNESS EFFECTS: Fresh sushi tuna is smooth and vibrant
        let baseRoughness: Float = 0.15
        let adjustedRoughness = baseRoughness * (1.0 + (1.0 - max(0.5, freshness)) * 0.4)
        pbrMaterial.roughness = .init(floatLiteral: min(0.6, adjustedRoughness))
        
        // Fresh tuna has more vibrant color, older tuna gets duller
        if freshness < 0.7 {
            let dullnessFactor = 1.0 - (freshness * 0.3)
            let dullColor = NSColor(red: 0.6, green: 0.25, blue: 0.25, alpha: 1.0) // Duller red
            pbrMaterial.baseColor = .init(tint: dullColor)
        }
        
        // print("🏆 [PBR] AAA sushi tuna material created successfully!")
        return pbrMaterial
    }
    
    static func createAAAMediumSteakMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        // print("🥩 [PBR] Creating AAA medium steak material...")
        // print("⚡ [PBR] Energy: \(energyLevel), Freshness: \(freshness)")
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD DIFFUSE TEXTURE (Main Color)
        if let diffuseTexture = loadTexture(named: "steak-medium-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            // print("✅ [PBR] Loaded medium steak diffuse texture")
        } else {
            // Fallback color: Medium-rare steak color
            let fallbackColor = NSColor(red: 0.7, green: 0.3, blue: 0.2, alpha: 1.0) // Medium-rare red-brown
            pbrMaterial.baseColor = .init(tint: fallbackColor)
            // print("⚠️ [PBR] Using fallback medium steak color")
        }
        
        // 🗺️ LOAD NORMAL MAP (Surface Detail)
        if let normalTexture = loadTexture(named: "steak-medium-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            // print("✅ [PBR] Loaded medium steak normal map")
        } else {
            // print("⚠️ [PBR] Medium steak normal map not found")
        }
        
        // ✨ LOAD ROUGHNESS MAP (Surface Properties)
        if let roughnessTexture = loadTexture(named: "steak-medium-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            // print("✅ [PBR] Loaded medium steak roughness map")
        } else {
            // Fallback: Cooked steak has moderate roughness
            pbrMaterial.roughness = .init(floatLiteral: 0.6) // Cooked surface texture
            // print("⚠️ [PBR] Using fallback medium steak roughness")
        }
        
        // 🌫️ LOAD AMBIENT OCCLUSION MAP (Depth and Shadow Detail)
        if let aoTexture = loadTexture(named: "steak-medium-ao") {
            pbrMaterial.ambientOcclusion = .init(texture: .init(aoTexture))
            // print("✅ [PBR] Loaded medium steak AO map")
        } else {
            // print("⚠️ [PBR] Medium steak AO map not found")
        }
        
        // 🥇 METALLIC PROPERTIES: Cooked steak has minimal metallic properties
        pbrMaterial.metallic = .init(floatLiteral: 0.05) // Very minimal metallic, organic surface
        
        // 🌟 ENERGY-BASED ENHANCEMENT
        if energyLevel > 1.0 {
            let emissionIntensity = min(0.15, (energyLevel - 1.0) * 0.06)
            let emissionColor = NSColor(red: 0.8, green: 0.4, blue: 0.2, alpha: 1.0) // Warm steak glow
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
        }
        
        // 🍃 FRESHNESS EFFECTS: Fresh steak is more vibrant and less rough
        let baseRoughness: Float = 0.6
        let adjustedRoughness = baseRoughness * (1.0 + (1.0 - max(0.5, freshness)) * 0.3)
        pbrMaterial.roughness = .init(floatLiteral: min(0.8, adjustedRoughness))
        
        // Fresh steak has more vibrant color, older steak gets grayer
        if freshness < 0.7 {
            let grayColor = NSColor(red: 0.5, green: 0.3, blue: 0.2, alpha: 1.0) // Grayer steak
            pbrMaterial.baseColor = .init(tint: grayColor)
        }
        
        // print("🏆 [PBR] AAA medium steak material created successfully!")
        return pbrMaterial
    }
    
    static func createAAARawFleshMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        // print("🩸 [PBR] Creating AAA raw flesh material...")
        // print("⚡ [PBR] Energy: \(energyLevel), Freshness: \(freshness)")
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD DIFFUSE TEXTURE (Main Color)
        if let diffuseTexture = loadTexture(named: "flesh-raw-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            // print("✅ [PBR] Loaded raw flesh diffuse texture")
        } else {
            // Fallback: Deep red raw flesh color
            let fallbackColor = NSColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
            pbrMaterial.baseColor = .init(tint: fallbackColor)
            // print("⚠️ [PBR] Using fallback raw flesh color")
        }
        
        // 🗺️ LOAD NORMAL MAP (Surface Detail) - RealityKit doesn't support normal scale
        if let normalTexture = loadTexture(named: "flesh-raw-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            // print("✅ [PBR] Loaded raw flesh normal map")
        } else {
            // print("⚠️ [PBR] Raw flesh normal map not found")
        }
        
        // ✨ LOAD ROUGHNESS MAP (Surface Properties)
        if let roughnessTexture = loadTexture(named: "flesh-raw-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            // print("✅ [PBR] Loaded raw flesh roughness map")
        } else {
            // Fallback: Raw flesh is quite rough and wet
            pbrMaterial.roughness = .init(floatLiteral: 0.7)
            // print("⚠️ [PBR] Using fallback raw flesh roughness")
        }
        
        // 🌫️ LOAD AMBIENT OCCLUSION MAP (Depth/Shadows)
        if let aoTexture = loadTexture(named: "flesh-raw-ao") {
            pbrMaterial.ambientOcclusion = .init(texture: .init(aoTexture))
            // print("✅ [PBR] Loaded raw flesh AO map")
        } else {
            // print("⚠️ [PBR] Raw flesh AO map not found")
        }
        
        // 🔧 MATERIAL PROPERTIES: Raw flesh characteristics
        pbrMaterial.metallic = .init(floatLiteral: 0.0)  // Organic material, not metallic
        
        // 💡 ENERGY-BASED EFFECTS: High energy raw flesh might have slight glow
        if energyLevel > 1.0 {
            let emissionIntensity = min(0.15, (energyLevel - 1.0) * 0.06)
            let emissionColor = NSColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
        }
        
        // 🦠 FRESHNESS EFFECTS: Less fresh = more dull and rough
        let baseRoughness: Float = 0.7
        let adjustedRoughness = baseRoughness * (1.0 + (1.0 - max(0.3, freshness)) * 0.5)
        pbrMaterial.roughness = .init(floatLiteral: min(0.9, adjustedRoughness))
        
        // Color degradation for less fresh flesh
        if freshness < 0.6 {
            let dullColor = NSColor(red: 0.7, green: 0.15, blue: 0.15, alpha: 1.0)
            pbrMaterial.baseColor = .init(tint: dullColor)
        }
        
        // print("🏆 [PBR] AAA raw flesh material created successfully!")
        return pbrMaterial
    }
    
    static func createAAARawSteakMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        // print("🥩 [PBR] Creating AAA raw steak material...")
        // print("⚡ [PBR] Energy: \(energyLevel), Freshness: \(freshness)")
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD DIFFUSE TEXTURE (Main Color)
        if let diffuseTexture = loadTexture(named: "steak-raw-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            // print("✅ [PBR] Loaded raw steak diffuse texture")
        } else {
            // Fallback: Raw steak color
            let fallbackColor = NSColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
            pbrMaterial.baseColor = .init(tint: fallbackColor)
            // print("⚠️ [PBR] Using fallback raw steak color")
        }
        
        // 🗺️ LOAD NORMAL MAP (Surface Detail)
        if let normalTexture = loadTexture(named: "steak-raw-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            // print("✅ [PBR] Loaded raw steak normal map")
        } else {
            // print("⚠️ [PBR] Raw steak normal map not found")
        }
        
        // ✨ LOAD ROUGHNESS MAP (Surface Properties)
        if let roughnessTexture = loadTexture(named: "steak-raw-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            // print("✅ [PBR] Loaded raw steak roughness map")
        } else {
            // Fallback: Raw steak surface properties
            pbrMaterial.roughness = .init(floatLiteral: 0.6)
            // print("⚠️ [PBR] Using fallback raw steak roughness")
        }
        
        // 🌫️ LOAD AMBIENT OCCLUSION MAP (Depth/Shadows)
        if let aoTexture = loadTexture(named: "steak-raw-ao") {
            pbrMaterial.ambientOcclusion = .init(texture: .init(aoTexture))
            // print("✅ [PBR] Loaded raw steak AO map")
        } else {
            // print("⚠️ [PBR] Raw steak AO map not found")
        }
        
        // 🔧 MATERIAL PROPERTIES: Raw steak characteristics
        pbrMaterial.metallic = .init(floatLiteral: 0.0)  // Organic material, not metallic
        
        // 💡 ENERGY-BASED EFFECTS: High energy raw steak might have slight glow
        if energyLevel > 1.0 {
            let emissionIntensity = min(0.1, (energyLevel - 1.0) * 0.05)
            let emissionColor = NSColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
        }
        
        // 🥩 FRESHNESS EFFECTS: Less fresh = more dull and rough
        let baseRoughness: Float = 0.6
        let adjustedRoughness = baseRoughness * (1.0 + (1.0 - max(0.4, freshness)) * 0.4)
        pbrMaterial.roughness = .init(floatLiteral: min(0.8, adjustedRoughness))
        
        // Color degradation for less fresh steak
        if freshness < 0.7 {
            let dullColor = NSColor(red: 0.6, green: 0.18, blue: 0.18, alpha: 1.0)
            pbrMaterial.baseColor = .init(tint: dullColor)
        }
        
        // print("🏆 [PBR] AAA raw steak material created successfully!")
        return pbrMaterial
    }
    
    static func createAAAGrilledSteakMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        // print("🔥 [PBR] Creating AAA grilled steak material...")
        // print("⚡ [PBR] Energy: \(energyLevel), Freshness: \(freshness)")
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD DIFFUSE TEXTURE (Main Color)
        if let diffuseTexture = loadTexture(named: "steak-grilled-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            // print("✅ [PBR] Loaded grilled steak diffuse texture")
        } else {
            // Fallback: Grilled steak color
            let fallbackColor = NSColor(red: 0.6, green: 0.3, blue: 0.2, alpha: 1.0)
            pbrMaterial.baseColor = .init(tint: fallbackColor)
            // print("⚠️ [PBR] Using fallback grilled steak color")
        }
        
        // 🗺️ LOAD NORMAL MAP (Surface Detail)
        if let normalTexture = loadTexture(named: "steak-grilled-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            // print("✅ [PBR] Loaded grilled steak normal map")
        } else {
            // print("⚠️ [PBR] Grilled steak normal map not found")
        }
        
        // ✨ LOAD ROUGHNESS MAP (Surface Properties)
        if let roughnessTexture = loadTexture(named: "steak-grilled-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            // print("✅ [PBR] Loaded grilled steak roughness map")
        } else {
            // Fallback: Grilled steak surface properties
            pbrMaterial.roughness = .init(floatLiteral: 0.4)
            // print("⚠️ [PBR] Using fallback grilled steak roughness")
        }
        
        // 🌫️ LOAD AMBIENT OCCLUSION MAP (Depth/Shadows)
        if let aoTexture = loadTexture(named: "steak-grilled-ao") {
            pbrMaterial.ambientOcclusion = .init(texture: .init(aoTexture))
            // print("✅ [PBR] Loaded grilled steak AO map")
        } else {
            // print("⚠️ [PBR] Grilled steak AO map not found")
        }
        
        // 🔧 MATERIAL PROPERTIES: Grilled steak characteristics
        pbrMaterial.metallic = .init(floatLiteral: 0.0)  // Organic material, not metallic
        
        // 💡 ENERGY-BASED EFFECTS: High energy grilled steak might have warm glow
        if energyLevel > 1.0 {
            let emissionIntensity = min(0.15, (energyLevel - 1.0) * 0.08)
            let emissionColor = NSColor(red: 1.0, green: 0.6, blue: 0.3, alpha: 1.0)
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
        }
        
        // 🔥 FRESHNESS EFFECTS: Less fresh = more dull and rough
        let baseRoughness: Float = 0.4  // Grilled surface is smoother than raw
        let adjustedRoughness = baseRoughness * (1.0 + (1.0 - max(0.5, freshness)) * 0.3)
        pbrMaterial.roughness = .init(floatLiteral: min(0.7, adjustedRoughness))
        
        // Color degradation for less fresh grilled steak
        if freshness < 0.8 {
            let dullColor = NSColor(red: 0.5, green: 0.25, blue: 0.18, alpha: 1.0)
            pbrMaterial.baseColor = .init(tint: dullColor)
        }
        
        // print("🏆 [PBR] AAA grilled steak material created successfully!")
        return pbrMaterial
    }
    
    static func createAAASeedsMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        // print("🌱 [PBR] Creating AAA seeds material...")
        // print("⚡ [PBR] Energy: \(energyLevel), Freshness: \(freshness)")
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD DIFFUSE TEXTURE (Main Color)
        if let diffuseTexture = loadTexture(named: "seeds-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            // print("✅ [PBR] Loaded seeds diffuse texture")
        } else {
            // Fallback color matching natural seed colors
            let fallbackColor = NSColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 1.0) // Tan/brown seeds
            pbrMaterial.baseColor = .init(tint: fallbackColor)
            // print("⚠️ [PBR] Using fallback seeds color")
        }
        
        // 🗺️ LOAD NORMAL MAP (Surface Detail)
        if let normalTexture = loadTexture(named: "seeds-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            // print("✅ [PBR] Loaded seeds normal map")
        } else {
            // print("⚠️ [PBR] Seeds normal map not found")
        }
        
        // ✨ LOAD ROUGHNESS MAP (Surface Properties)
        if let roughnessTexture = loadTexture(named: "seeds-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            // print("✅ [PBR] Loaded seeds roughness map")
        } else {
            // Fallback: Rough, matte seed surface
            pbrMaterial.roughness = .init(floatLiteral: 0.85) // Matte, non-reflective
            // print("⚠️ [PBR] Using fallback seeds roughness")
        }
        
        // 🥇 METALLIC PROPERTIES: Seeds are completely non-metallic organic matter
        pbrMaterial.metallic = .init(floatLiteral: 0.0)
        
        // 🌟 ENERGY-BASED ENHANCEMENT
        if energyLevel > 1.0 {
            let emissionIntensity = min(0.2, (energyLevel - 1.0) * 0.07)
            let emissionColor = NSColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1.0) // Warm golden seed glow
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
            // print("✨ [PBR] Added seeds energy glow: \(emissionIntensity)")
        }
        
        // 🍃 FRESHNESS EFFECTS: Fresh seeds have smoother surfaces, aged ones get rougher
        let baseRoughness: Float = 0.85
        let adjustedRoughness = baseRoughness * (1.0 + (1.0 - max(0.4, freshness)) * 0.2)
        pbrMaterial.roughness = .init(floatLiteral: min(1.0, adjustedRoughness))
        
        // print("🏆 [PBR] AAA seeds material created successfully!")
        return pbrMaterial
    }
    
    static func createAAANutsMaterial(energyLevel: Float = 1.0, freshness: Float = 1.0) -> RealityKit.Material {
        
        // print("🥜 [PBR] Creating AAA nuts material...")
        // print("⚡ [PBR] Energy: \(energyLevel), Freshness: \(freshness)")
        
        // 🎨 CREATE PHYSICALLY-BASED MATERIAL
        var pbrMaterial = PhysicallyBasedMaterial()
        
        // 📸 LOAD DIFFUSE TEXTURE (Main Color)
        if let diffuseTexture = loadTexture(named: "nuts-diffuse") {
            pbrMaterial.baseColor = .init(texture: .init(diffuseTexture))
            // print("✅ [PBR] Loaded nuts diffuse texture")
        } else {
            // Fallback color matching mixed nuts
            let fallbackColor = NSColor(red: 0.7, green: 0.5, blue: 0.3, alpha: 1.0) // Rich brown nuts
            pbrMaterial.baseColor = .init(tint: fallbackColor)
            // print("⚠️ [PBR] Using fallback nuts color")
        }
        
        // 🗺️ LOAD NORMAL MAP (Surface Detail)
        if let normalTexture = loadTexture(named: "nuts-normal") {
            pbrMaterial.normal = .init(texture: .init(normalTexture))
            // print("✅ [PBR] Loaded nuts normal map")
        } else {
            // print("⚠️ [PBR] Nuts normal map not found")
        }
        
        // ✨ LOAD ROUGHNESS MAP (Surface Properties)
        if let roughnessTexture = loadTexture(named: "nuts-roughness") {
            pbrMaterial.roughness = .init(texture: .init(roughnessTexture))
            // print("✅ [PBR] Loaded nuts roughness map")
        } else {
            // Fallback: Slightly rough nut shell surface
            pbrMaterial.roughness = .init(floatLiteral: 0.75) // Natural shell texture
            // print("⚠️ [PBR] Using fallback nuts roughness")
        }
        
        // 🥇 METALLIC PROPERTIES: Nuts are completely non-metallic organic matter
        pbrMaterial.metallic = .init(floatLiteral: 0.0)
        
        // 🌟 ENERGY-BASED ENHANCEMENT
        if energyLevel > 1.0 {
            let emissionIntensity = min(0.25, (energyLevel - 1.0) * 0.08)
            let emissionColor = NSColor(red: 0.9, green: 0.7, blue: 0.4, alpha: 1.0) // Warm nutty glow
            pbrMaterial.emissiveColor = .init(color: emissionColor.withAlphaComponent(CGFloat(emissionIntensity)))
            // print("✨ [PBR] Added nuts energy glow: \(emissionIntensity)")
        }
        
        // 🍃 FRESHNESS EFFECTS: Fresh nuts have smoother shells, aged ones get rougher
        let baseRoughness: Float = 0.75
        let adjustedRoughness = baseRoughness * (1.0 + (1.0 - max(0.3, freshness)) * 0.3)
        pbrMaterial.roughness = .init(floatLiteral: min(1.0, adjustedRoughness))
        
        // print("🏆 [PBR] AAA nuts material created successfully!")
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
            // print("❌ [PBR] Failed to load image: \(name)")
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
            
            // print("✅ [PBR] Successfully loaded and cached texture: \(name)")
            return textureResource
            
        } catch {
            // print("❌ [PBR] Failed to create TextureResource for \(name): \(error)")
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
        // print("🗑️ [PBR] Texture cache cleared")
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
