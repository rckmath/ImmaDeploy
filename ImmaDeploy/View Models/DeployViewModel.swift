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
    private let fetchInterval: TimeInterval = 14400
    private let launchAtStartupKey = "launchAtStartup"
    private var isSyncingLaunchAtStartup = false

    private var cancellables = Set<AnyCancellable>()
    
    init() {
        isSyncingLaunchAtStartup = true
        launchAtStartup = UserDefaults.standard.bool(forKey: launchAtStartupKey)
        syncLaunchAtStartupState()
        isSyncingLaunchAtStartup = false
        
        loadTimezones()
        detectSystemSettings()
        setupNetworkMonitoring()
        startPeriodicFetching()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func loadTimezones() {
        guard let url = Bundle.main.url(forResource: "timezones", withExtension: "json", subdirectory: "Resources") ??
                      Bundle.main.url(forResource: "timezones", withExtension: "json") else {
            timezones = TimeZone.knownTimeZoneIdentifiers.sorted()
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            timezones = try decoder.decode([String].self, from: data)
        } catch {
            timezones = TimeZone.knownTimeZoneIdentifiers.sorted()
        }
    }
    
    private func detectSystemSettings() {
        selectedTimezone = TimeZone.current.identifier
        
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        let languageCode = String(preferredLanguage.prefix(2))
        
        let supportedLanguages = ["en", "pt", "es"]
        if supportedLanguages.contains(languageCode) {
            selectedLanguage = languageCode
        } else if preferredLanguage.hasPrefix("es-AR") {
            selectedLanguage = "es-AR"
        } else {
            selectedLanguage = "en"
        }
    }

    private func setupNetworkMonitoring() {
        NetworkMonitor.shared.$isReachable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reachable in
                guard let self = self else { return }
                if reachable {
                    if !self.isLoading {
                        self.fetchDeployStatus()
                    }
                } else {
                    self.isLoading = false
                    self.message = "Waiting for network…"
                }
            }
            .store(in: &cancellables)

        if NetworkMonitor.shared.isReachable {
            fetchDeployStatus()
        } else {
            message = "Waiting for network…"
        }
    }
    
    func fetchDeployStatus() {
        if !NetworkMonitor.shared.isReachable {
            isLoading = false
            message = "Waiting for network…"
            return
        }
        
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
    
    private func startPeriodicFetching() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(timeInterval: fetchInterval,
                                     target: self,
                                     selector: #selector(handleTimer(_:)),
                                     userInfo: nil,
                                     repeats: true)
        
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    @objc private func handleTimer(_ timer: Timer) {
        fetchDeployStatus()
    }
    
    func updateLanguage(_ language: String) {
        selectedLanguage = language
        fetchDeployStatus()
    }
    
    func updateTimezone(_ timezone: String) {
        selectedTimezone = timezone
        timezoneFetchTask?.cancel()
        
        timezoneFetchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            
            guard !Task.isCancelled, let self else { return }
            self.fetchDeployStatus()
        }
    }
    
    private func syncLaunchAtStartupState() {
        let isEnabled: Bool
        if #available(macOS 13.0, *) {
            isEnabled = (SMAppService.mainApp.status == .enabled)
        } else {
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
            }
            syncLaunchAtStartupState()
        } else {
            UserDefaults.standard.set(enabled, forKey: launchAtStartupKey)
            isSyncingLaunchAtStartup = true
            launchAtStartup = enabled
            isSyncingLaunchAtStartup = false
        }
    }
}

