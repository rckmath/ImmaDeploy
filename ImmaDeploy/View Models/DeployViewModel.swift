//
//  DeployViewModel.swift
//  ImmaDeploy
//
//  Created by Erick Matheus on 19/01/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DeployViewModel: ObservableObject {
    @Published var message: String = "Loading..."
    @Published var isLoading: Bool = false
    @Published var selectedLanguage: String = "en"
    @Published var selectedTimezone: String = TimeZone.current.identifier
    @Published var timezones: [String] = []
    
    private var timer: Timer?
    private var timezoneFetchTask: Task<Void, Never>?
    private let apiBaseURL = "https://shouldideploy.today/api"
    private let fetchInterval: TimeInterval = 3600 // 1 hour
    
    init() {
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
            await self.fetchDeployStatus()
        }
    }
}

