//
//  SettingsView.swift
//  ImmaDeploy
//
//  Created by Erick Matheus on 19/01/26.
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var viewModel: DeployViewModel
    @Environment(\.dismiss) private var dismiss
    
    private let supportedLanguages = [
        ("English", "en"),
        ("Português", "pt"),
        ("Español", "es"),
        ("Español (Argentina)", "es-AR")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Form {
                Section {
                    HStack(alignment: .center, spacing: 8) {
                        // Left column: fields
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline, spacing: 3) {
                                Image(systemName: "globe")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                
                                Text("Language")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                
                                Picker("", selection: $viewModel.pendingLanguage) {
                                    ForEach(supportedLanguages, id: \.1) { name, code in
                                        Text(name)
                                            .font(.subheadline)
                                            .tag(code)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            
                            HStack(alignment: .firstTextBaseline, spacing: 3) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                
                                Text("Timezone")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                
                                Picker("", selection: $viewModel.pendingTimezone) {
                                    ForEach(viewModel.timezones, id: \.self) { timezone in
                                        Text(timezone)
                                            .font(.subheadline)
                                            .tag(timezone)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        
                        // Vertical divider between columns
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 1)
                            .padding(.vertical, 2)
                        
                        // Right column: action icons
                        VStack(alignment: .center, spacing: 8) {
                            Button {
                                viewModel.applyPendingChanges()
                                dismiss()
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(.green)
                            .disabled(!viewModel.hasPendingChanges)
                            .help("Apply changes")
                            
                            Button {
                                // Reset pending changes to applied values
                                viewModel.pendingLanguage = viewModel.selectedLanguage
                                viewModel.pendingTimezone = viewModel.selectedTimezone
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(.red)
                            .disabled(!viewModel.hasPendingChanges)
                            .help("Discard changes")
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .font(.subheadline)
            .padding(.vertical, 0)
            .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 2) {
                let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
                Text("Imma Deploy? v\(version)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.trailing, 2)
                Spacer()
                
                HStack(spacing: 4) {
                    Button {
                        if let url = URL(string: "https://github.com/rckmath/ImmaDeploy") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Image("Github")
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .accessibilityLabel("GitHub Repository")
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)
                    .controlSize(.small)
                    
                    Button {
                        if let url = URL(string: "https://buymeacoffee.com/rckmath") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.bordered)
                    .tint(.yellow)
                    .controlSize(.small)
                    
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .controlSize(.small)
                }
                .fixedSize()
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(width: 300)
        .padding(.bottom, 20)
    }
}

