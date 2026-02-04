import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "输入搜索内容"
    @FocusState.Binding var isFocused: Bool
    var onCommit: () -> Void = {}
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 18, weight: .medium))
            
            TextField(placeholder, text: $text)
                .font(.system(size: 17))
                .foregroundColor(.primary)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit {
                    onCommit()
                }
            
            if !text.isEmpty {
                Button(action: {
                    withAnimation {
                        text = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 18))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial) // 极简毛玻璃效果
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}
