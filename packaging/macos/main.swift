// omiloc.app — native macOS wrapper for the local omi processing stack.
// Finds the omi-local repo, starts the loopback library server through the
// stock launcher, and shows the library in a WKWebView window. When the Mac
// is not prepared yet it opens start.command in Terminal and waits.
import AppKit
import WebKit

let kGitHubURL = "https://github.com/vquaron/omi-local.git"
let kDefaultLibrary = URL(string: "http://127.0.0.1:20001")!

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    var repoPath: String?
    var libraryURL = kDefaultLibrary
    var pollTimer: Timer?

    // MARK: lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()
        buildWindow()
        showStatus("omiloc", "Looking for the local install…")
        DispatchQueue.global(qos: .userInitiated).async { self.bootstrap() }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    // MARK: UI

    func buildWindow() {
        let rect = NSRect(x: 0, y: 0, width: 1280, height: 840)
        window = NSWindow(contentRect: rect,
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "omiloc"
        window.center()
        window.setFrameAutosaveName("omiloc-main")
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        webView = WKWebView(frame: rect, configuration: config)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.width, .height]
        window.contentView = webView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func buildMenu() {
        let main = NSMenu()

        let appItem = NSMenuItem(); main.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About omiloc",
                        action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide omiloc", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Quit omiloc", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu

        let actionsItem = NSMenuItem(); main.addItem(actionsItem)
        let actions = NSMenu(title: "Library")
        actions.addItem(withTitle: "Open in Browser", action: #selector(openInBrowser), keyEquivalent: "b")
        actions.addItem(withTitle: "Record — start.command in Terminal", action: #selector(openRecorder), keyEquivalent: "t")
        actions.addItem(.separator())
        actions.addItem(withTitle: "Reconnect", action: #selector(reconnect), keyEquivalent: "k")
        actionsItem.submenu = actions

        let editItem = NSMenuItem(); main.addItem(editItem)
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit

        let viewItem = NSMenuItem(); main.addItem(viewItem)
        let view = NSMenu(title: "View")
        view.addItem(withTitle: "Reload", action: #selector(reloadPage), keyEquivalent: "r")
        viewItem.submenu = view

        NSApp.mainMenu = main
    }

    func showStatus(_ title: String, _ detail: String) {
        let html = """
        <!doctype html><meta charset="utf-8">
        <style>
          body{margin:0;display:flex;align-items:center;justify-content:center;height:100vh;
               background:#050705;color:#c9d6c9;font:17px/1.6 'Play',-apple-system,'Helvetica Neue',sans-serif}
          .card{max-width:34em;text-align:center;padding:2em}
          h1{font-size:1.6em;font-weight:700;letter-spacing:.02em;color:#fff;margin:0 0 .6em}
          p{margin:0;white-space:pre-line;color:#6f7f6f}
          .dot{display:inline-block;width:.55em;height:.55em;border-radius:50%;background:#52e05a;box-shadow:0 0 8px #52e05a;
               margin-left:.4em;animation:b 1.2s infinite alternate}
          @keyframes b{to{opacity:.15}}
        </style>
        <div class="card"><h1>\(title)<span class="dot"></span></h1><p>\(detail)</p></div>
        """
        DispatchQueue.main.async { self.webView.loadHTMLString(html, baseURL: nil) }
    }

    // MARK: repo discovery

    func configFile() -> URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("omiloc")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("repo")
    }

    func isRepo(_ path: String) -> Bool {
        FileManager.default.isExecutableFile(atPath: path + "/start.command")
            && FileManager.default.fileExists(atPath: path + "/scripts/local-mac.sh")
    }

    func findRepo() -> String? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        var candidates: [String] = []
        if let saved = try? String(contentsOf: configFile(), encoding: .utf8) {
            candidates.append(saved.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        candidates += [home + "/cyber/omi-local", home + "/omiloc", home + "/cyber/omiloc", home + "/omi-local"]
        for path in candidates where isRepo(path) {
            try? path.write(to: configFile(), atomically: true, encoding: .utf8)
            return path
        }
        return nil
    }

    // MARK: bootstrap

    func bootstrap() {
        guard let repo = findRepo() else {
            cloneAndSetup()
            return
        }
        repoPath = repo
        let installed = FileManager.default.isExecutableFile(atPath: repo + "/backend/.venv/bin/python")
        if installed, let url = startLibrary(repo) {
            libraryURL = url
            load(url)
            return
        }
        // Mac is not prepared or the launcher failed: hand over to start.command.
        openTerminal(repo + "/start.command")
        showStatus("Preparing the Mac",
                   "start.command is running in Terminal.\nFinish the setup there — the library opens here on its own.")
        waitForLibrary()
    }

    func cloneAndSetup() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let target = home + "/omiloc"
        let script = """
        #!/bin/bash
        set -e
        cd "$HOME"
        [ -d omiloc ] || git clone \(kGitHubURL) omiloc
        cd omiloc
        ./start.command
        """
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("omiloc-install.command")
        try? script.write(to: tmp, atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tmp.path)
        try? target.write(to: configFile(), atomically: true, encoding: .utf8)
        repoPath = target
        openTerminal(tmp.path)
        showStatus("Installing omiloc",
                   "The project is downloading and configuring in Terminal.\nFinish the setup there — the library opens here on its own.")
        waitForLibrary()
    }

    // Runs the stock launcher without letting it open the system browser.
    func startLibrary(_ repo: String) -> URL? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [repo + "/scripts/local-mac.sh", "launcher"]
        process.currentDirectoryURL = URL(fileURLWithPath: repo)
        var env = ProcessInfo.processInfo.environment
        env["BROWSER"] = "/usr/bin/true"   // webbrowser.open() no-op
        env["HOME"] = FileManager.default.homeDirectoryForCurrentUser.path
        process.environment = env
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do { try process.run() } catch { return nil }
        let deadline = Date().addingTimeInterval(40)
        while process.isRunning && Date() < deadline { usleep(200_000) }
        if process.isRunning { process.terminate(); return nil }
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        guard process.terminationStatus == 0 else { NSLog("launcher: %@", output); return nil }
        if let range = output.range(of: #"http://127\.0\.0\.1:\d+"#, options: .regularExpression) {
            return URL(string: String(output[range]))
        }
        return kDefaultLibrary
    }

    func healthOK(_ base: URL, _ done: @escaping (Bool) -> Void) {
        var request = URLRequest(url: base.appendingPathComponent("health"))
        request.timeoutInterval = 2
        URLSession.shared.dataTask(with: request) { data, _, _ in
            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            done(body.contains("omi-local-library"))
        }.resume()
    }

    func waitForLibrary() {
        DispatchQueue.main.async {
            self.pollTimer?.invalidate()
            self.pollTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                self.healthOK(self.libraryURL) { ok in
                    if ok {
                        DispatchQueue.main.async {
                            self.pollTimer?.invalidate(); self.pollTimer = nil
                            self.load(self.libraryURL)
                        }
                    }
                }
            }
        }
    }

    func load(_ url: URL) {
        DispatchQueue.main.async { self.webView.load(URLRequest(url: url)) }
    }

    // MARK: actions

    func openTerminal(_ path: String) {
        let open = Process()
        open.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        open.arguments = ["-a", "Terminal", path]
        try? open.run()
    }

    @objc func openInBrowser() { NSWorkspace.shared.open(libraryURL) }

    @objc func openRecorder() {
        if let repo = repoPath ?? findRepo() { openTerminal(repo + "/start.command") }
    }

    @objc func reloadPage() { webView.reload() }

    @objc func reconnect() {
        showStatus("omiloc", "Reconnecting…")
        DispatchQueue.global(qos: .userInitiated).async { self.bootstrap() }
    }

    // Keep navigation inside the library; external links go to the browser.
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, let host = url.host,
           !(host == "127.0.0.1" || host == "localhost") {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
