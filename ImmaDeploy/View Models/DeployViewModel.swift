//
//  DeployViewModel.swift
//  ImmaDeploy
//
//  Created by Erick Matheus on 19/01/26.
//

import Foundation
import SwiftUI
import Combine
import ServiceManagement

@MainActor
class DeployViewModel: ObservableObject {
    @Published var message: String = "Loading..."
    @Published var isLoading: Bool = false
    @Published var selectedLanguage: String = "en"
    @Published var selectedTimezone: String = TimeZone.current.identifier
    @Published var timezones: [String] = []
    @Published var launchAtStartup: Bool = false {
        didSet {
            guard !isSyncingLaunchAtStartup else { return }
            UserDefaults.standard.set(launchAtStartup, forKey: "launchAtStartup")
            setLaunchAtStartup(launchAtStartup)
        }
    }
    
    private var timer: Timer?
    private var timezoneFetchTask: Task<Void, Never>?
    private let apiBaseURL = "https://shouldideploy.today/api"
    private let fetchInterval: TimeInterval = 3600 // 1 hour
    private let launchAtStartupKey = "launchAtStartup"
    private var isSyncingLaunchAtStartup = false
    
    init() {
        // Load saved launch at startup setting
        isSyncingLaunchAtStartup = true
        launchAtStartup = UserDefaults.standard.bool(forKey: launchAtStartupKey)
        // Sync with actual system state
        syncLaunchAtStartupState()
        isSyncingLaunchAtStartup = false
        
        loadTimezones()
        detectSystemSettings()
        fetchDeployStatus()
        startPeriodicFetching()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Timezone Loading
    
    private func loadTimezones() {
        guard let url = Bundle.main.url(forResource: "timezones", withExtension: "json", subdirectory: "Resources") ??
                      Bundle.main.url(forResource: "timezones", withExtension: "json") else {
            // Fallback to system timezones if JSON file not found
            timezones = TimeZone.knownTimeZoneIdentifiers.sorted()
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            timezones = try decoder.decode([String].self, from: data)
        } catch {
            // Fallback to system timezones if parsing fails
            timezones = TimeZone.knownTimeZoneIdentifiers.sorted()
        }
    }
    
    // MARK: - System Detection
    
    private func detectSystemSettings() {
        // Detect timezone
        selectedTimezone = TimeZone.current.identifier
        
        // Detect language
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        let languageCode = String(preferredLanguage.prefix(2))
        
        // Check if language is supported, otherwise default to English
        let supportedLanguages = ["en", "pt", "es"]
        if supportedLanguages.contains(languageCode) {
            selectedLanguage = languageCode
        } else if preferredLanguage.hasPrefix("es-AR") {
            selectedLanguage = "es-AR"
        } else {
            selectedLanguage = "en"
        }
    }
    
    // MARK: - API Fetching
    
    func fetchDeployStatus() {
        guard !isLoading else { return }
        isLoading = true
        message = "Loading..."
        
        var components = URLComponents(string: apiBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "tz", value: selectedTimezone),
            URLQueryItem(name: "lang", value: selectedLanguage)
        ]
        
        guard let url = components?.url else {
            message = "Invalid URL"
            isLoading = false
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoder = JSONDecoder()
                let response = try decoder.decode(ShouldIDeployTodayResponse.self, from: data)
                
                await MainActor.run {
                    self.message = response.message
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.message = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Periodic Fetching
    
    private func startPeriodicFetching() {
        // Invalidate any existing timer before creating a new one
        timer?.invalidate()
        
        // Use selector-based API to avoid capturing `self` in a @Sendable closure
        timer = Timer.scheduledTimer(timeInterval: fetchInterval,
                                     target: self,
                                     selector: #selector(handleTimer(_:)),
                                     userInfo: nil,
                                     repeats: true)
        
        // Ensure timer runs on main run loop
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    @objc private func handleTimer(_ timer: Timer) {
        // We are on the main run loop; fetch on main actor
        fetchDeployStatus()
    }
    
    // MARK: - Settings
    
    func updateLanguage(_ language: String) {
        selectedLanguage = language
        fetchDeployStatus()
    }
    
    func updateTimezone(_ timezone: String) {
        selectedTimezone = timezone
        timezoneFetchTask?.cancel()
        
        timezoneFetchTask = Task { [weak self] in
            // Small delay so the picker menu can close and layout settle smoothly
            try? await Task.sleep(nanoseconds: 250_000_000) // 250ms
            
            guard !Task.isCancelled, let self else { return }
            self.fetchDeployStatus()
        }
    }
    
    // MARK: - Launch at Startup
    
    private func syncLaunchAtStartupState() {
        let isEnabled: Bool
        if #available(macOS 13.0, *) {
            isEnabled = (SMAppService.mainApp.status == .enabled)
        } else {
            // Best-effort fallback for older macOS: use stored preference only
            isEnabled = UserDefaults.standard.bool(forKey: launchAtStartupKey)
        }
        
        if isEnabled != launchAtStartup {
            isSyncingLaunchAtStartup = true
            launchAtStartup = isEnabled
            UserDefaults.standard.set(isEnabled, forKey: launchAtStartupKey)
            isSyncingLaunchAtStartup = false
        }
    }
    
    private func isLaunchAtStartupEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            // On older systems, we can't reliably query the system without deprecated APIs.
            // Return the stored preference as a best-effort signal.
            return UserDefaults.standard.bool(forKey: launchAtStartupKey)
        }
    }
    
    private func setLaunchAtStartup(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // If registration fails, revert the toggle to reflect the actual system state
                // and persist a consistent value.
            }
            // Always resync from the system-reported state after attempting a change
            syncLaunchAtStartupState()
        } else {
            // On older macOS versions, avoid deprecated APIs. Persist the preference only.
            UserDefaults.standard.set(enabled, forKey: launchAtStartupKey)
            isSyncingLaunchAtStartup = true
            launchAtStartup = enabled
            isSyncingLaunchAtStartup = false
        }
    }
}

