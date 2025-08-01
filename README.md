# 🧬 Bugtopia: Evolutionary Arena Simulator

> **An AI-powered evolutionary simulation where digital organisms adapt to complex environmental challenges through genetic algorithms and natural selection.**

![Swift](https://img.shields.io/badge/Swift-6.0+-orange?style=flat&logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Latest-blue?style=flat&logo=apple)
![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20iOS-lightgrey?style=flat&logo=apple)
![License](https://img.shields.io/badge/License-MIT-green?style=flat)

## 🌟 Overview

Bugtopia is a cutting-edge evolutionary simulation where digital organisms with **evolvable neural networks** compete in complex predator-prey ecosystems. Watch as bugs develop artificial intelligence, hunt each other, and evolve increasingly sophisticated brains over generations—all through natural selection and genetic algorithms.

### ✨ What Makes It Revolutionary

- **🧠 Evolvable Neural Networks**: Bugs grow deeper, more complex brains (3-10 layers) through structural evolution
- **🦁 Predator-Prey Dynamics**: Four species types (herbivores, carnivores, omnivores, scavengers) in dynamic food webs
- **🧬 Advanced Genetics**: 10+ evolvable traits including AI parameters, hunting behaviors, and defensive strategies
- **🌍 Environmental Pressure**: 8 distinct terrain types each requiring different survival strategies  
- **🤖 Emergent Intelligence**: Neural decision-making for movement, hunting, fleeing, and social interactions
- **📊 Real-time Evolution**: Watch both genetics AND neural architecture evolve simultaneously
- **🎨 Beautiful Visualization**: Animated terrain, species indicators, neural network displays, and hunting behaviors

## 🎮 Features

### 🧠 Artificial Intelligence Evolution
- **Evolvable Neural Networks**: 3-10 layer networks with variable topology
- **Structural Mutations**: Networks grow/shrink layers and change activation functions
- **Smart Decision Making**: 16 sensory inputs → 8 behavioral outputs
- **Emergent Behaviors**: Hunting strategies, fleeing patterns, exploration drives

### 🦁 Predator-Prey Ecosystem
- **Four Species Types**: Herbivores 🌱, Carnivores 🦁, Omnivores 🐺, Scavengers 🦅
- **Dynamic Food Web**: Hunting, energy transfer, and predator avoidance
- **Species-Specific Traits**: Hunt intensity, prey detection, flee speed, stealth
- **Evolutionary Arms Race**: Predators vs prey intelligence co-evolution

### 🗣️ Communication & Cooperation System
- **8 Signal Types**: Food alerts, danger warnings, hunt calls, group formation, help requests
- **Evolvable Communication**: Signal strength, sensitivity, trust levels, social response rates
- **Pack Behaviors**: Coordinated hunting, group formation, collective danger responses
- **Social Intelligence**: Neural-driven communication decisions and cooperation strategies
- **Information Networks**: Knowledge sharing about food sources, threats, and territories

### 🧬 Advanced Genetic System
- **Core Traits**: Speed, Vision, Energy Efficiency, Size, Strength
- **Neural Traits**: Network topology, weights, biases, activation functions  
- **Behavioral Traits**: Memory, Stickiness, Camouflage, Curiosity, Aggression
- **Communication Traits**: Signal strength, sensitivity, frequency, trust, social response
- **Species Traits**: Hunting/defensive behaviors, metabolic rates, size modifiers
- **Genetic Operations**: Crossover, mutation, structural evolution, selection pressure
- **Multi-Modal Fitness**: Survival, reproduction, terrain adaptation, predator success, social cooperation

### 🌍 Environmental Arena
| Terrain | Challenge | Adaptation Required |
|---------|-----------|-------------------|
| 🪨 **Walls** | Block movement | Memory + pathfinding |
| 🌊 **Water** | Speed challenge | Fast movement + efficiency |
| ⛰️ **Hills** | Climbing difficulty | Physical strength |
| 🌫️ **Shadow** | Limited vision | Enhanced memory |
| 🦁 **Predator** | Danger zones | Aggression or camouflage |
| 💨 **Wind** | Movement disruption | Size and stability |
| 🌱 **Food Zones** | Resource abundance | Exploration skills |
| ⬛ **Open** | Normal terrain | Baseline traits |

### 🎯 Emergent AI Behaviors
- **Neural Decision Making**: AI-driven movement, hunting, and fleeing decisions
- **Predator-Prey Dynamics**: Stalking, ambushing, pack hunting, and escape strategies
- **Communication Networks**: Signal-based information sharing about food, danger, and opportunities
- **Cooperative Strategies**: Group formation, coordinated hunting, collective defense
- **Social Hierarchies**: Leadership roles, specialization (scouts, guards, foragers, hunters)
- **Intelligent Food Seeking**: Line-of-sight vision with wall detection and neural exploration
- **Obstacle Navigation**: Memory-based pathfinding around barriers with AI route optimization
- **Terrain Adaptation**: Dynamic speed/energy modifiers with species-specific advantages
- **Trust & Deception**: Evolving trust levels and potential for misinformation
- **Adaptive Learning**: Neural networks develop specialized strategies over generations

### 📊 Advanced Analytics
- **Neural Network Visualization**: Live topology, weights, and decision outputs for any bug
- **Species Demographics**: Population ratios, predator success rates, extinction events
- **Population Statistics**: Real-time tracking of genetic and neural evolution
- **Individual Inspection**: Detailed DNA, neural architecture, and hunting/defensive behaviors
- **Evolution Tracking**: Cross-generational adaptation in both genetics and AI
- **Ecosystem Analytics**: Food web dynamics, energy flow, and species interactions

## 🚀 Getting Started

### Prerequisites
- **Xcode 15.0+** with Swift 6.0 support
- **macOS 14.0+** or **iOS 17.0+**
- Git for version control

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/bugtopia.git
   cd bugtopia
   ```

2. **Open in Xcode**
   ```bash
   open Bugtopia.xcodeproj
   ```

3. **Build and Run**
   - Select your target device (Mac or iOS Simulator)
   - Press `⌘+R` to build and run

### Quick Start Guide

1. **Launch the Simulation**: The arena auto-generates with 30 initial bugs
2. **Observe Evolution**: Watch bugs navigate terrain and seek food
3. **Inspect Individuals**: Click any bug to see its genetic traits and environmental stats
4. **Track Progress**: Monitor population statistics and genetic averages in the sidebar
5. **Experiment**: Use pause/reset controls to study different evolutionary outcomes

## 🏗️ Architecture

```
🧬 Bugtopia Architecture
├── 🌍 Arena System          # Terrain generation and physics
├── 🧠 AI Engine             # Neural networks and decision making
├── 🗣️ Communication System  # Signal propagation and social behaviors
├── 🦁 Species System        # Predator-prey dynamics and behaviors
├── 🧬 Genetic Engine        # DNA, traits, and evolution
├── 🐛 Bug Entities          # Individual organism AI and physics
├── 🔄 Simulation Engine     # Population management and evolutionary cycles
└── 🎨 Visualization Layer   # SwiftUI + Canvas rendering
```

### Core Components

- **`Arena`**: Tile-based terrain system with procedural generation
- **`NeuralNetwork`**: Evolvable AI brains with structural mutations
- **`Communication`**: Signal system with 8 types and propagation physics
- **`Species`**: Predator-prey types with hunting/defensive behaviors
- **`BugDNA`**: Genetic blueprint with 15+ traits + neural + communication architecture
- **`Bug`**: Individual organism with AI decision-making, species behaviors, and social communication
- **`SimulationEngine`**: Population dynamics, evolution, ecosystem management, and signal distribution
- **`SimulationView`**: Real-time rendering with neural network visualization and communication indicators

## 🧪 The Science

### Neuroevolution Algorithm
1. **Initialization**: Random population with diverse genetics AND neural architectures
2. **Neural Decision Making**: AI brains process sensory input → behavioral output
3. **Ecosystem Pressure**: Predator-prey dynamics create complex survival challenges
4. **Selection Pressure**: Environmental + predation eliminate unfit individuals
5. **Reproduction**: Successful bugs mate using genetic + neural crossover
6. **Dual Mutation**: Both genetic traits AND neural structure mutate
7. **Structural Evolution**: Neural networks grow deeper and more complex
8. **Iteration**: Process creates increasingly intelligent populations

### Multi-Modal Selection Pressures
- **Predator-Prey Arms Race**: Hunters evolve better hunting AI, prey evolve better escape AI
- **Terrain-Based Selection**: Environmental challenges favor specific neural strategies
- **Energy Economics**: Efficient neural decision-making favored over wasteful behaviors
- **Social Dynamics**: Cooperation and competition create complex behavioral evolution
- **Cognitive Complexity**: More sophisticated problems require deeper neural networks

## 🎯 Use Cases

- **🔬 Educational**: Visualize evolutionary principles and natural selection
- **🧠 Research**: Study genetic algorithms and population dynamics  
- **🎮 Entertainment**: Watch fascinating emergent behaviors evolve
- **💻 Development**: Learn SwiftUI, Canvas, and genetic programming

## 🛠️ Customization

### Adding New Terrain Types
```swift
enum TerrainType: String, CaseIterable {
    case lava = "lava"  // New hazardous terrain
    
    var color: Color {
        case .lava: return Color.orange
    }
    
    func speedMultiplier(for bug: BugDNA) -> Double {
        case .lava: return bug.heatResistance > 0.7 ? 0.8 : 0.1
    }
}
```

### Extending Bug Genetics
```swift
struct BugDNA {
    // Add new trait
    let heatResistance: Double
    
    // Update fitness calculation
    var geneticFitness: Double {
        // Include new trait in fitness
    }
}
```

## 📈 Performance

- **30 FPS** real-time simulation
- **100+ bugs** simultaneous population
- **Efficient rendering** with SwiftUI Canvas
- **Optimized pathfinding** with obstacle avoidance
- **Memory management** for long-running simulations

## 🗺️ Roadmap

### ✅ COMPLETED: Phase 1, 2 & 3
- [x] **Evolvable Neural Networks**: Deep AI brains (3-10 layers) with structural evolution
- [x] **Predator-Prey Ecosystem**: Four species with hunting/defensive behaviors
- [x] **Advanced Genetics**: Neural + behavioral + physical trait evolution
- [x] **Communication & Cooperation**: Signal-based pack hunting, group formation, and social intelligence

### 🚀 NEXT: Phase 4-7 (Current Development)
- [ ] **🔧 Environmental Modification**: Tool creation and world-shaping abilities
- [ ] **🧬 Speciation Events**: Population splitting and reproductive isolation
- [ ] **🌦️ Dynamic World**: Seasonal changes, disasters, and environmental cycles
- [ ] **🏛️ Civilization**: Cultural knowledge, technology, and multi-generational progress

### 🌟 Future Expansions
- [ ] **3D Arena**: True 3D terrain with flight and underwater capabilities
- [ ] **Quantum Behaviors**: Quantum-inspired neural network architectures
- [ ] **Multiplayer Evolution**: Compete isolated populations across different worlds
- [ ] **Real-World Integration**: Train on real environmental data

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
```bash
# Fork the repo and clone your fork
git clone https://github.com/yourusername/bugtopia.git

# Create a feature branch
git checkout -b feature/amazing-new-trait

# Make your changes and test thoroughly
# Commit with descriptive messages
git commit -m "Add heat resistance trait for lava terrain"

# Push and create a pull request
git push origin feature/amazing-new-trait
```

## 📚 Technical Details

### Dependencies
- **Pure Swift**: No external dependencies
- **SwiftUI**: Native UI framework
- **Foundation**: Core utilities and data structures
- **Combine**: Reactive programming (optional)

### Minimum Requirements
- **iOS 17.0+** / **macOS 14.0+**
- **Xcode 15.0+**
- **Swift 6.0+**

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Charles Darwin**: For the inspiration from evolutionary theory
- **John Conway**: Game of Life cellular automata concepts  
- **Apple**: SwiftUI and development tools
- **Open Source Community**: Continuous inspiration and support

## 📞 Contact

- **Issues**: [GitHub Issues](https://github.com/yourusername/bugtopia/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/bugtopia/discussions)
- **Email**: your.email@example.com

---

<div align="center">

**🧬 Made with ❤️ in Swift • Watch Evolution in Action • Contribute to Science! 🧬**

[⭐ Star this repo](https://github.com/yourusername/bugtopia) • [🐛 Report Bug](https://github.com/yourusername/bugtopia/issues) • [💡 Request Feature](https://github.com/yourusername/bugtopia/issues)

</div>
