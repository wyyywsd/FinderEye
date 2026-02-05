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
                        Text(String(format: "%.1f%%", settings.confidenceThreshold * 100))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    
                    Slider(value: $settings.confidenceThreshold, in: 0.001...0.99, step: 0.001) {
                    Text("Confidence Threshold".localized)
                } minimumValueLabel: {
                    Text("Low".localized)
                } maximumValueLabel: {
                    Text("High".localized)
                }
                }
                .padding(.vertical, 4)
                
                Picker("Detection Model".localized, selection: $settings.modelType) {
                    ForEach(SettingsManager.ModelType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
                
                Text("Model Selection Desc".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle(isOn: $settings.isHighAccuracyModeEnabled) {
                    VStack(alignment: .leading) {
                        Text("High Accuracy Mode".localized)
                        Text("Uses slicing to detect small objects. Disable to improve performance.".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Performance Settings".localized)) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Scanning FPS".localized, systemImage: "waveform.path.ecg")
                        Spacer()
                        Text("\(Int(settings.scanningFPS)) FPS")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    
                    Slider(value: $settings.scanningFPS, in: 1...30, step: 1) {
                        Text("Scanning FPS".localized)
                    } minimumValueLabel: {
                        Text("1")
                    } maximumValueLabel: {
                        Text("30")
                    }
                }
                .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Tracking FPS".localized, systemImage: "speedometer")
                        Spacer()
                        Text("\(Int(settings.trackingFPS)) FPS")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    
                    Slider(value: $settings.trackingFPS, in: 10...60, step: 1) {
                        Text("Tracking FPS".localized)
                    } minimumValueLabel: {
                        Text("10")
                    } maximumValueLabel: {
                        Text("60")
                    }
                }
                .padding(.vertical, 4)
                
                Text("Higher FPS consumes more battery.".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
