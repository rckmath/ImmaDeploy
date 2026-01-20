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
                // Language row
                Section {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Image(systemName: "globe")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Text("Language")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $viewModel.selectedLanguage) {
                            ForEach(supportedLanguages, id: \.1) { name, code in
                                Text(name)
                                    .font(.subheadline)
                                    .tag(code)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .onChange(of: viewModel.selectedLanguage) { oldValue, newValue in
                            viewModel.updateLanguage(newValue)
                        }
                    }
                    
                    // Timezone row
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Text("Timezone")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $viewModel.selectedTimezone) {
                            ForEach(viewModel.timezones, id: \.self) { timezone in
                                Text(timezone)
                                    .font(.subheadline)
                                    .tag(timezone)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .onChange(of: viewModel.selectedTimezone) { oldValue, newValue in
                            viewModel.updateTimezone(newValue)
                        }
                    }
                }
                
            }
            .formStyle(.grouped)
            .font(.subheadline)
            .fixedSize(horizontal: false, vertical: true) // let form hug its content instead of filling all available height
            
            HStack(spacing: 2) {
                Text("Imma Deploy? v1.0")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Button {
                        viewModel.fetchDeployStatus()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                                        
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                            Text("Quit app")
                        }
                        .font(.system(size: 10))
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(width: 280)
        .padding(.vertical, 10)
    }
}

