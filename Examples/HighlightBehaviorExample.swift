import SwiftUI
import PropertyInspector

/// Public API example demonstrating highlight behavior with .inspectProperty()
/// Shows how multiple properties can be linked and highlighted together
struct HighlightBehaviorExample: View {
    @State private var count = 0
    @State private var progress = 0.5
    @State private var isEnabled = true
    @State private var selectedColor = Color.blue
    @State private var text = "Hello World"
    
    var body: some View {
        PropertyInspector(listStyle: .plain) {
            VStack(spacing: 30) {
                headerSection
                
                Divider()
                
                interactiveControlsSection
                
                Divider()
                
                multiPropertySection
                
                Divider()
                
                complexStateSection
            }
            .padding()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("🎯 Highlight Behavior")
                .font(.title.bold())
            
            Text("Tap any property in the inspector to highlight its view")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Multiple properties inspected together will highlight simultaneously")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Interactive Controls
    
    private var interactiveControlsSection: some View {
        VStack(spacing: 16) {
            Text("Interactive Controls")
                .font(.headline)
            
            // Counter with linked properties
            HStack {
                Button("-") {
                    count -= 1
                }
                .buttonStyle(.bordered)
                
                Text("\(count)")
                    .font(.title2.monospacedDigit())
                    .frame(minWidth: 60)
                    .inspectProperty(count) // Single property
                
                Button("+") {
                    count += 1
                }
                .buttonStyle(.bordered)
            }
            
            // Progress slider with linked value
            VStack(alignment: .leading, spacing: 8) {
                Text("Progress: \(Int(progress * 100))%")
                    .font(.caption)
                
                Slider(value: $progress)
                    .inspectProperty(progress) // Inspect slider value
            }
            
            // Toggle with state
            Toggle("Enabled", isOn: $isEnabled)
                .inspectProperty(isEnabled) // Inspect toggle state
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Multi-Property Section
    
    private var multiPropertySection: some View {
        VStack(spacing: 16) {
            Text("Linked Properties")
                .font(.headline)
            
            Text("These properties are linked - tap one to highlight all")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Multiple properties inspected together
            HStack(spacing: 20) {
                VStack {
                    Text("Count")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(count)")
                        .font(.title2.bold())
                }
                
                VStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(progress * 100))%")
                        .font(.title2.bold())
                }
                
                VStack {
                    Text("Enabled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(isEnabled ? "Yes" : "No")
                        .font(.title2.bold())
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .inspectProperty(count, progress, isEnabled) // All linked together!
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Complex State Section
    
    private var complexStateSection: some View {
        VStack(spacing: 16) {
            Text("Complex State")
                .font(.headline)
            
            // Color picker
            ColorPicker("Color", selection: $selectedColor)
                .inspectProperty(selectedColor)
            
            // Text field
            TextField("Enter text", text: $text)
                .textFieldStyle(.roundedBorder)
                .inspectProperty(text)
            
            // Combined view showing all values
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedColor)
                    .frame(height: 60)
                    .overlay {
                        Text(text)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                
                Text("Tap to highlight the card above")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .inspectProperty(selectedColor, text) // Card linked to its properties
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Simpler Examples

struct SimpleHighlightExample: View {
    @State private var value = 42
    
    var body: some View {
        PropertyInspector {
            VStack(spacing: 20) {
                Text("Simple Highlight Example")
                    .font(.title.bold())
                
                Text("Tap the property in the inspector to see the highlight effect")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack {
                    Button("-") { value -= 1 }
                        .buttonStyle(.bordered)
                    
                    Text("\(value)")
                        .font(.largeTitle.monospacedDigit())
                        .frame(minWidth: 100)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .inspectProperty(value) // Tap this in the inspector!
                    
                    Button("+") { value += 1 }
                        .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }
}

struct MultipleHighlightsExample: View {
    @State private var x = 100.0
    @State private var y = 100.0
    
    var body: some View {
        PropertyInspector {
            VStack(spacing: 20) {
                Text("Multiple Properties")
                    .font(.title.bold())
                
                Text("X and Y are linked - tap either to highlight both")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Circle()
                    .fill(Color.red.opacity(0.7))
                    .frame(width: 50, height: 50)
                    .position(x: x, y: y)
                    .frame(width: 300, height: 300)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .inspectProperty(x, y) // Both properties linked!
                
                HStack(spacing: 30) {
                    VStack {
                        Text("X: \(Int(x))")
                            .font(.caption)
                        Slider(value: $x, in: 0...300)
                            .frame(width: 120)
                    }
                    
                    VStack {
                        Text("Y: \(Int(y))")
                            .font(.caption)
                        Slider(value: $y, in: 0...300)
                            .frame(width: 120)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Previews

#Preview("Full Example") {
    HighlightBehaviorExample()
}

#Preview("Full Example - Dark") {
    HighlightBehaviorExample()
        .preferredColorScheme(.dark)
}

#Preview("Simple Highlight") {
    SimpleHighlightExample()
}

#Preview("Multiple Properties") {
    MultipleHighlightsExample()
}
