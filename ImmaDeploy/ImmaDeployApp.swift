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
    private var viewModel = DeployViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var contextMenu: NSMenu?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
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
        menu.addItem(refreshItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings item
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
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
    
    @objc private func quitAction() {
        NSApplication.shared.terminate(nil)
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 450, height: 400)
        popover?.behavior = .transient
    }
    
    @objc private func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent, let statusButton = statusItem?.button else { return }
        switch event.type {
        case .rightMouseUp, .rightMouseDown:
            if let menu = contextMenu {
                NSMenu.popUpContextMenu(menu, with: event, for: statusButton)
            }
        case .leftMouseUp, .leftMouseDown:
            toggleSettingsPopover()
        default:
            break
        }
    }
    
    private func toggleSettingsPopover() {
        if popover?.isShown == true {
            popover?.performClose(nil)
        } else {
            guard let statusButton = statusItem?.button else { return }
            let settingsView = SettingsView(viewModel: viewModel)
            let hostingController = NSHostingController(rootView: settingsView)
            hostingController.view.frame = NSRect(x: 0, y: 0, width: 450, height: 400)
            popover?.contentViewController = hostingController
            popover?.show(relativeTo: statusButton.bounds, of: statusButton, preferredEdge: .minY)
            popover?.contentViewController?.view.window?.makeKey()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
    }
}

