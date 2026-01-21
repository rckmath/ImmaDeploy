//
//  ImmaDeployApp.swift
//  ImmaDeploy
//
//  Created by Erick Matheus on 19/01/26.
//

import SwiftUI
import Combine

@main
struct ImmaDeployApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var viewModel: DeployViewModel!
    private var cancellables = Set<AnyCancellable>()
    private var contextMenu: NSMenu?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        self.viewModel = DeployViewModel()
        
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        setupMenu()
        setupPopover()
        
        // Observe viewModel changes to update menu title
        viewModel.$message
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.updateMenuTitle(message)
            }
            .store(in: &cancellables)
        
        // Observe launchAtStartup changes to update menu item state
        viewModel.$launchAtStartup
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateLaunchAtStartupMenuItem()
            }
            .store(in: &cancellables)
        
        NetworkMonitor.shared.$isReachable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateRefreshMenuItemEnabled()
            }
            .store(in: &cancellables)
        
        updateMenuTitle(viewModel.message)
    }
    
    private func setupMenu() {
        guard let statusButton = statusItem?.button else { return }
        
        statusButton.title = viewModel.message
        statusButton.target = self
        statusButton.action = #selector(statusItemClicked(_:))
        statusButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
        
        let menu = NSMenu()
        
        // Refresh item
        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(refreshAction), keyEquivalent: "r")
        refreshItem.target = self
        refreshItem.isEnabled = NetworkMonitor.shared.isReachable
        menu.addItem(refreshItem)
                
        // Settings item
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
                
        // Launch at Startup item
        let launchAtStartupItem = NSMenuItem(title: "Launch at Startup", action: #selector(toggleLaunchAtStartup), keyEquivalent: "")
        launchAtStartupItem.target = self
        launchAtStartupItem.state = viewModel.launchAtStartup ? .on : .off
        menu.addItem(launchAtStartupItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit item
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        self.contextMenu = menu
    }
    
    private func updateMenuTitle(_ title: String) {
        statusItem?.button?.title = title
    }
    
    @objc private func refreshAction() {
        viewModel.fetchDeployStatus()
    }
    
    @objc private func showSettings() {
        toggleSettingsPopover()
    }
    
    @objc private func toggleLaunchAtStartup() {
        viewModel.launchAtStartup.toggle()
    }
    
    private func updateLaunchAtStartupMenuItem() {
        guard let menu = contextMenu else { return }
        for item in menu.items {
            if item.action == #selector(toggleLaunchAtStartup) {
                item.state = viewModel.launchAtStartup ? .on : .off
                break
            }
        }
    }
    
    private func updateRefreshMenuItemEnabled() {
        guard let menu = contextMenu else { return }
        for item in menu.items {
            if item.action == #selector(refreshAction) {
                item.isEnabled = NetworkMonitor.shared.isReachable
                break
            }
        }
    }
    
    @objc private func quitAction() {
        NSApplication.shared.terminate(nil)
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.behavior = .transient
    }
    
    @objc private func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent, let statusButton = statusItem?.button else { return }
        
        // Check if this is a right-click or Control+Click (secondary click)
        let isRightClick = event.type == .rightMouseUp || event.type == .rightMouseDown
        let isControlClick = (event.type == .leftMouseUp || event.type == .leftMouseDown) && event.modifierFlags.contains(.control)
        
        if isRightClick || isControlClick {
            if let menu = contextMenu {
                // Update menu item state before showing menu
                updateLaunchAtStartupMenuItem()
                updateRefreshMenuItemEnabled()
                NSMenu.popUpContextMenu(menu, with: event, for: statusButton)
            }
        } else if event.type == .leftMouseUp || event.type == .leftMouseDown {
            toggleSettingsPopover()
        }
    }
    
    private func toggleSettingsPopover() {
        if popover?.isShown == true {
            popover?.performClose(nil)
        } else {
            guard let statusButton = statusItem?.button else { return }
            let settingsView = SettingsView(viewModel: viewModel)
            let hostingController = NSHostingController(rootView: settingsView)
            popover?.contentViewController = hostingController
            popover?.show(relativeTo: statusButton.bounds, of: statusButton, preferredEdge: .minY)
            popover?.contentViewController?.view.window?.makeKey()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
    }
}

