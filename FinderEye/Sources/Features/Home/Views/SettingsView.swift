import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("Appearance".localized)) {
                Picker("Theme Mode".localized, selection: $settings.appTheme) {
                    ForEach(SettingsManager.AppTheme.allCases) { theme in
                        Text(theme.rawValue.localized).tag(theme)
                    }
                }
                .pickerStyle(.menu)
                
                Picker("Language".localized, selection: $settings.appLanguage) {
                    ForEach(SettingsManager.AppLanguage.allCases) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section(header: Text("General".localized)) {
                Toggle(isOn: $settings.isHapticsEnabled) {
                    Label("Haptics".localized, systemImage: "iphone.radiowaves.left.and.right")
                }
                Toggle(isOn: $settings.isSoundEnabled) {
                    Label("Sounds".localized, systemImage: "speaker.wave.2")
                }
            }
            
            Section(header: Text("Smart Detection".localized)) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Confidence Threshold".localized, systemImage: "eye")
                        Spacer()
                        Text("\(Int(settings.confidenceThreshold * 100))%")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    
                    Slider(value: $settings.confidenceThreshold, in: 0.1...0.9, step: 0.05) {
                        Text("Confidence Threshold".localized)
                    } minimumValueLabel: {
                        Text("Low".localized)
                    } maximumValueLabel: {
                        Text("High".localized)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section(header: Text("Search Display".localized)) {
                Picker("Match Mode".localized, selection: $settings.textMatchMode) {
                    ForEach(SettingsManager.TextMatchMode.allCases) { mode in
                        Text(mode.rawValue.localized).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                    Text(settings.textMatchMode == .wholeLine ? "Match Mode Desc Whole".localized : "Match Mode Desc Specific".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "eye.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.linearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom))
                        Text("FinderEye")
                            .font(.headline)
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Settings".localized)
        .navigationBarTitleDisplayMode(.large)
    }
}
