#if DEBUG
import SwiftUI

/// Internal debug tool for testing PropertyHiglighter animation effects
/// Tests random animation values, multiple simultaneous highlights, and visual variety
/// 
/// This tester demonstrates:
/// - Random animation timing creates dynamic staggered effects
/// - Multiple simultaneous highlights show visual variety
/// - Performance with many concurrent animations
/// - Different shapes (Rectangle vs RoundedRectangle)
struct HighlightAnimationTester: View {
    @State private var highlightMode: HighlightMode = .single
    @State private var isHighlighted1 = false
    @State private var isHighlighted2 = false
    @State private var isHighlighted3 = false
    @State private var isHighlighted4 = false
    @State private var isHighlighted5 = false
    @State private var isHighlighted6 = false
    @State private var allHighlighted = false
    @State private var sequentialDelay = 0.1
    @State private var useRectangle = true
    
    enum HighlightMode: String, CaseIterable {
        case single = "Single"
        case multiple = "Multiple"
        case sequential = "Sequential"
        case rapid = "Rapid Fire"
        case toggle = "Toggle All"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            headerSection
            
            Divider()
            
            controlsSection
            
            Divider()
            
            testCardsSection
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("🎨 Highlight Animation Tester")
                .font(.title.bold())
            
            Text("Internal debug tool for PropertyHiglighter")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Each highlight gets unique random timing & scale")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        VStack(spacing: 12) {
            // Mode Picker
            Picker("Highlight Mode", selection: $highlightMode) {
                ForEach(HighlightMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            
            // Shape Toggle
            Toggle("Use Rectangle (vs RoundedRectangle)", isOn: $useRectangle)
                .font(.caption)
            
            // Sequential Delay Slider
            if highlightMode == .sequential {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sequential Delay: \(String(format: "%.2fs", sequentialDelay))")
                        .font(.caption)
                    Slider(value: $sequentialDelay, in: 0.05...0.5, step: 0.05)
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Trigger") {
                    triggerHighlight()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Clear All") {
                    clearAll()
                }
                .buttonStyle(.bordered)
                
                Button("Reset") {
                    reset()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Test Cards Section
    
    private var testCardsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            testCard(number: 1, isHighlighted: $isHighlighted1, color: .red)
            testCard(number: 2, isHighlighted: $isHighlighted2, color: .orange)
            testCard(number: 3, isHighlighted: $isHighlighted3, color: .yellow)
            testCard(number: 4, isHighlighted: $isHighlighted4, color: .green)
            testCard(number: 5, isHighlighted: $isHighlighted5, color: .blue)
            testCard(number: 6, isHighlighted: $isHighlighted6, color: .purple)
        }
    }
    
    // MARK: - Test Card
    
    private func testCard(number: Int, isHighlighted: Binding<Bool>, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.8))
                    .frame(height: 120)
                
                VStack(spacing: 4) {
                    Text("Card \(number)")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    
                    Text(isHighlighted.wrappedValue ? "HIGHLIGHTED" : "Normal")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .modifier(
                PropertyHiglighter(
                    isOn: isHighlighted,
                    shape: useRectangle ? AnyShape(Rectangle()) : AnyShape(RoundedRectangle(cornerRadius: 12))
                )
            )
            
            // Manual Toggle
            Button(isHighlighted.wrappedValue ? "Hide" : "Show") {
                withAnimation {
                    isHighlighted.wrappedValue.toggle()
                }
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Actions
    
    private func triggerHighlight() {
        switch highlightMode {
        case .single:
            // Highlight one random card
            clearAll()
            let random = Int.random(in: 1...6)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    setHighlight(for: random, to: true)
                }
            }
            
        case .multiple:
            // Highlight 3 random cards simultaneously (shows staggered effect!)
            clearAll()
            let cards = (1...6).shuffled().prefix(3)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    for card in cards {
                        setHighlight(for: card, to: true)
                    }
                }
            }
            
        case .sequential:
            // Highlight cards one by one with delay (shows each animation)
            clearAll()
            for (index, card) in (1...6).enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * sequentialDelay) {
                    withAnimation {
                        setHighlight(for: card, to: true)
                    }
                }
            }
            
        case .rapid:
            // Rapid fire all cards (performance test)
            clearAll()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation {
                    isHighlighted1 = true
                    isHighlighted2 = true
                    isHighlighted3 = true
                    isHighlighted4 = true
                    isHighlighted5 = true
                    isHighlighted6 = true
                }
            }
            
        case .toggle:
            // Toggle all at once
            withAnimation {
                allHighlighted.toggle()
                isHighlighted1 = allHighlighted
                isHighlighted2 = allHighlighted
                isHighlighted3 = allHighlighted
                isHighlighted4 = allHighlighted
                isHighlighted5 = allHighlighted
                isHighlighted6 = allHighlighted
            }
        }
    }
    
    private func clearAll() {
        withAnimation {
            isHighlighted1 = false
            isHighlighted2 = false
            isHighlighted3 = false
            isHighlighted4 = false
            isHighlighted5 = false
            isHighlighted6 = false
            allHighlighted = false
        }
    }
    
    private func reset() {
        clearAll()
        highlightMode = .single
        sequentialDelay = 0.1
        useRectangle = true
    }
    
    private func setHighlight(for card: Int, to value: Bool) {
        switch card {
        case 1: isHighlighted1 = value
        case 2: isHighlighted2 = value
        case 3: isHighlighted3 = value
        case 4: isHighlighted4 = value
        case 5: isHighlighted5 = value
        case 6: isHighlighted6 = value
        default: break
        }
    }
}

// MARK: - Type-Erased Shape

struct AnyShape: Shape {
    private let _path: @Sendable (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// MARK: - Performance Test View

struct PerformanceTestView: View {
    @State private var highlights: [Bool] = Array(repeating: false, count: 20)
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Performance Test")
                .font(.title.bold())
            
            Text("20 concurrent highlight animations")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                Button("Highlight All") {
                    withAnimation {
                        highlights = Array(repeating: true, count: 20)
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Clear All") {
                    withAnimation {
                        highlights = Array(repeating: false, count: 20)
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Random 10") {
                    withAnimation {
                        highlights = (0..<20).map { _ in Bool.random() }
                    }
                }
                .buttonStyle(.bordered)
            }
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach(0..<20, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.3))
                            .frame(height: 60)
                            .overlay {
                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }
                            .modifier(
                                PropertyHiglighter(
                                    isOn: Binding(
                                        get: { highlights[index] },
                                        set: { highlights[index] = $0 }
                                    ),
                                    shape: RoundedRectangle(cornerRadius: 8)
                                )
                            )
                            .onTapGesture {
                                withAnimation {
                                    highlights[index].toggle()
                                }
                            }
                    }
                }
                .padding()
            }
        }
        .padding()
    }
}

// MARK: - Previews

#Preview("Highlight Animation Tester") {
    HighlightAnimationTester()
}

#Preview("Highlight Tester - Dark Mode") {
    HighlightAnimationTester()
        .preferredColorScheme(.dark)
}

#Preview("Single Card Test") {
    VStack {
        Text("Single Card Test")
            .font(.title)
        
        Text("Observe the cyan highlight with random animation timing")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.bottom)
        
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.blue.opacity(0.7))
            .frame(width: 200, height: 200)
            .modifier(
                PropertyHiglighter(
                    isOn: .constant(true),
                    shape: RoundedRectangle(cornerRadius: 20)
                )
            )
        
        Text("Random scale: 2.0-2.5x\nRandom duration: 0.2-0.5s\nRandom delay: 0-0.3s")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
    }
    .padding()
}

#Preview("Performance Test - 20 Cards") {
    PerformanceTestView()
}

#Preview("Performance Test - Dark") {
    PerformanceTestView()
        .preferredColorScheme(.dark)
}

#endif
