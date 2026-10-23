import SwiftUI

struct AdaptiveColors {
    static let textFieldBackground = Color(.textBackgroundColor)
    static let textFieldBorder = Color.secondary
    static let textColor = Color.primary
}

struct Input: View {
    @Binding var text: String
    var placeholder: String
    var icon: String? = nil
    @FocusState private var isFocused: Bool

    var body: some View {
        CustomTextInput(text: $text, placeholder: placeholder, icon: icon, isFocused: _isFocused)
            .frame(height: 32)
    }
}

struct CompactInput: View {
    @Binding var text: String
    var placeholder: String
    var icon: String? = nil
    @FocusState private var isFocused: Bool

    var body: some View {
        CustomTextInput(text: $text, placeholder: placeholder, icon: icon, isFocused: _isFocused)
            .frame(height: 28)
            .padding(.bottom, 4)
    }
}

struct AutocompleteInput: View {
    @Binding var text: String
    let placeholder: String
    let suggestions: [String]
    let onCommit: () -> Void

    @State private var isEditing = false
    @State private var showSuggestions = false
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            CustomTextInput(text: $text, placeholder: placeholder, isFocused: _isFocused)
                .frame(height: 32)
                .onChange(of: isFocused) { focused in
                    isEditing = focused
                    showSuggestions = focused && !suggestions.isEmpty
                }
                .onChange(of: text) { _ in
                    showSuggestions = isEditing && !suggestions.isEmpty
                }

            if showSuggestions {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(suggestions.prefix(5), id: \.self) { suggestion in
                            Text(suggestion)
                                .font(.system(size: 13))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    text = suggestion
                                    showSuggestions = false
                                    onCommit()
                                }
                        }
                    }
                    .padding(4)
                }
                .frame(maxHeight: 150)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: TimefolkTheme.Radius.medium, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: TimefolkTheme.Radius.medium, style: .continuous)
                        .strokeBorder(TimefolkTheme.Colors.hairlineBorder(colorScheme: scheme), lineWidth: 0.5)
                )
                .shadow(color: TimefolkTheme.Colors.subtleShadow(colorScheme: scheme), radius: 8, x: 0, y: 4)
            }
        }
    }
}

struct CustomTextInput: View {
    @Binding var text: String
    var placeholder: String
    var icon: String? = nil
    @FocusState var isFocused: Bool
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.leading, 6)
            }

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .padding(.horizontal, icon == nil ? 8 : 2)
                .focused($isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary.opacity(0.8))
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
                .transition(.opacity)
            }
        }
        .frame(height: 32)
        .background(
            RoundedRectangle(cornerRadius: TimefolkTheme.Radius.medium, style: .continuous)
                .fill(
                    scheme == .dark
                        ? Color.white.opacity(0.06)
                        : Color.black.opacity(0.03)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: TimefolkTheme.Radius.medium, style: .continuous)
                .strokeBorder(
                    isFocused ? Color.accentColor : TimefolkTheme.Colors.hairlineBorder(colorScheme: scheme),
                    lineWidth: isFocused ? 1.5 : 0.5
                )
        )
        .shadow(
            color: isFocused ? Color.accentColor.opacity(0.25) : .clear,
            radius: 3,
            x: 0,
            y: 0
        )
        .animation(TimefolkTheme.Animation.quick, value: isFocused)
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
    }
}
