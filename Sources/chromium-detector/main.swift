import Foundation

// ANSI escape codes for colors and styles
struct ANSIColors {
    static let reset = "\u{001B}[0m"
    static let bold = "\u{001B}[1m"
    static let green = "\u{001B}[32m"
    static let yellow = "\u{001B}[33m"
    static let blue = "\u{001B}[34m"
    static let magenta = "\u{001B}[35m"
    static let cyan = "\u{001B}[36m"
}

// Progress indicator class
class ProgressIndicator {
    private var isRunning = false
    private let queue = DispatchQueue(label: "progress.indicator")
    private let spinnerFrames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]  // Consistent size spinner
    private var currentFrame = 0
    private var message: String
    private let startTime = Date()
    
    init(message: String) {
        self.message = message
    }
    
    func start() {
        isRunning = true
        queue.async {
            while self.isRunning {
                let elapsed = Date().timeIntervalSince(self.startTime)
                let dots = String(repeating: ".", count: Int(elapsed) % 4)
                let paddedDots = dots.padding(toLength: 3, withPad: " ", startingAt: 0)
                
                let frame = self.spinnerFrames[self.currentFrame]
                print("\r\(ANSIColors.cyan)[\(frame)] \(self.message)\(paddedDots)\(ANSIColors.reset)", terminator: "")
                fflush(stdout)
                self.currentFrame = (self.currentFrame + 1) % self.spinnerFrames.count
                Thread.sleep(forTimeInterval: 0.05)  // Smoother animation
            }
        }
    }
    
    func stop() {
        isRunning = false
        // Clear the entire line and move cursor to beginning
        print("\r\u{001B}[2K", terminator: "")
        fflush(stdout)
    }
}

// Progress bar class
class ProgressBar {
    private let total: Int
    private var current: Int = 0
    private let width: Int = 30
    private var currentOperation: String = ""
    private let startTime = Date()
    
    init(total: Int) {
        self.total = total
        // Print initial empty progress bar
        let emptyBar = String(repeating: "-", count: width)
        print("[\(emptyBar)] 0% 0s", terminator: "")
        fflush(stdout)
    }
    
    func update(current: Int, operation: String = "") {
        self.current = current
        self.currentOperation = operation
        let percentage = Double(current) / Double(total)
        let filled = Int(Double(width) * percentage)
        let empty = width - filled
        
        // Calculate elapsed time and estimated time remaining
        let elapsed = Date().timeIntervalSince(startTime)
        let estimatedTotal = elapsed / percentage
        let remaining = estimatedTotal - elapsed
        
        // Format times
        let remainingStr = formatTime(remaining)
        let elapsedStr = formatTime(elapsed)
        
        // Create progress bar with color
        let filledChar = "="
        let emptyChar = "-"
        let bar = ANSIColors.green + String(repeating: filledChar, count: filled) + 
                 (filled < width ? ">" : "") + 
                 ANSIColors.reset + String(repeating: emptyChar, count: max(0, empty - (filled < width ? 1 : 0)))
        
        // Create the full status line
        let percentStr = String(format: "%3d%%", Int(percentage * 100))
        var statusLine = "[\(bar)] \(percentStr) \(elapsedStr) eta \(remainingStr)"
        
        // Add current operation if any
        if !operation.isEmpty {
            statusLine += " \(ANSIColors.cyan)[\(operation)]\(ANSIColors.reset)"
        }
        
        // Clear the line and print the new status
        print("\r\u{001B}[2K\(statusLine)", terminator: "")
        fflush(stdout)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        if seconds.isNaN || seconds.isInfinite {
            return "--:--"
        }
        if seconds < 60 {
            return String(format: "%.0fs", seconds)
        }
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if minutes < 60 {
            return String(format: "%d:%02ds", minutes, secs)
        }
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%d:%02d:%02ds", hours, mins, secs)
    }
}

// A struct to hold information about each Chromium-based application
struct ChromiumAppInfo {
    let name: String
    let installDate: Date
    let sizeInBytes: UInt64
    let version: String
    let executablePath: String
    let bundleIdentifier: String?
}

// Directories to scan – you can add more if needed
let directoriesToScan = [
    "/Applications",
    NSHomeDirectory() + "/Applications"
]

// Patterns we look for in the Frameworks directory or via otool
let knownChromiumFrameworks = [
    "Electron Framework.framework",
    "Chromium Embedded Framework.framework",
    "nwjs Framework.framework",
    "MiniBlink.framework",
    "libcef.dylib",
    "Chrome Framework.framework",
    "Brave Framework.framework",
    "Microsoft Edge Framework.framework",
    "Opera Framework.framework"
]

// Function to get app version from Info.plist
func getAppVersion(appPath: String) -> String {
    let infoPlistPath = appPath + "/Contents/Info.plist"
    if let dict = NSDictionary(contentsOfFile: infoPlistPath) as? [String: Any] {
        if let version = dict["CFBundleShortVersionString"] as? String {
            return version
        }
        if let version = dict["CFBundleVersion"] as? String {
            return version
        }
    }
    return "Unknown"
}

// Function to get bundle identifier from Info.plist
func getBundleIdentifier(appPath: String) -> String? {
    let infoPlistPath = appPath + "/Contents/Info.plist"
    if let dict = NSDictionary(contentsOfFile: infoPlistPath) as? [String: Any] {
        return dict["CFBundleIdentifier"] as? String
    }
    return nil
}

// Function to get executable path
func getExecutablePath(appPath: String) -> String {
    let infoPlistPath = appPath + "/Contents/Info.plist"
    if let dict = NSDictionary(contentsOfFile: infoPlistPath) as? [String: Any],
       let executableName = dict["CFBundleExecutable"] as? String {
        return appPath + "/Contents/MacOS/" + executableName
    }
    return "Unknown"
}

// A function to check if an app is Chromium-based using otool
func checkWithOtool(executablePath: String) -> Bool {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/otool")
    task.arguments = ["-L", executablePath]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    
    do {
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            for knownName in knownChromiumFrameworks {
                if output.contains(knownName) {
                    return true
                }
            }
            // Additional checks for common Chromium-related libraries
            let chromiumPatterns = [
                "libchromium",
                "libcef",
                "Chrome Framework",
                "Electron Framework"
            ]
            for pattern in chromiumPatterns {
                if output.contains(pattern) {
                    return true
                }
            }
        }
    } catch {
        print("Error running otool: \(error)")
    }
    return false
}

// A function to check if an app is Chromium-based
func isChromiumBasedApp(appPath: String) -> Bool {
    let fileManager = FileManager.default
    
    // 1) Check the Frameworks folder
    let frameworksPath = appPath + "/Contents/Frameworks"
    if fileManager.fileExists(atPath: frameworksPath) {
        do {
            let frameworksContents = try fileManager.contentsOfDirectory(atPath: frameworksPath)
            for item in frameworksContents {
                for knownName in knownChromiumFrameworks {
                    if item.contains(knownName) {
                        return true
                    }
                }
            }
        } catch {
            print("Error reading frameworks directory: \(error)")
        }
    }
    
    // 2) Check using otool on the main executable
    let execPath = getExecutablePath(appPath: appPath)
    if fileManager.fileExists(atPath: execPath) && execPath != "Unknown" {
        if checkWithOtool(executablePath: execPath) {
            return true
        }
    }
    
    // 3) Check Info.plist for known Chromium-based app identifiers
    if let bundleId = getBundleIdentifier(appPath: appPath) {
        let knownChromiumBundleIds = [
            "com.google.Chrome",
            "com.microsoft.edgemac",
            "com.brave.Browser",
            "com.operasoftware.Opera",
            "org.chromium.Chromium",
            "com.electron."
        ]
        for knownId in knownChromiumBundleIds {
            if bundleId.contains(knownId) {
                return true
            }
        }
    }
    
    return false
}

// A function to get size of the entire .app bundle
func folderSize(atPath path: String) -> UInt64 {
    var size: UInt64 = 0
    let fileManager = FileManager.default

    if let enumerator = fileManager.enumerator(atPath: path) {
        for file in enumerator {
            if let fileName = file as? String {
                let filePath = path + "/" + fileName
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: filePath)
                    if let fileSize = attributes[.size] as? UInt64 {
                        size += fileSize
                    }
                } catch {
                    continue
                }
            }
        }
    }
    return size
}

// Function to count total apps to scan
func countTotalApps() -> Int {
    var total = 0
    for dir in directoriesToScan {
        if let apps = try? FileManager.default.contentsOfDirectory(atPath: dir) {
            total += apps.filter { $0.hasSuffix(".app") }.count
        }
    }
    return total
}

// Main scanning function with progress
func scanForChromiumApps() -> [ChromiumAppInfo] {
    var apps: [ChromiumAppInfo] = []
    let totalApps = countTotalApps()
    
    // Save current cursor position
    print("\u{001B}7", terminator: "")
    print("\n\(ANSIColors.bold)╭──────────────────────────────────╮\(ANSIColors.reset)")
    print("\(ANSIColors.bold)│   🔍 Chromium Scanner Starting    │\(ANSIColors.reset)")
    print("\(ANSIColors.bold)╰──────────────────────────────────╯\(ANSIColors.reset)\n")
    print("\(ANSIColors.cyan)Scanning applications...\(ANSIColors.reset)")
    
    let progressBar = ProgressBar(total: totalApps)
    var scannedCount = 0
    
    for dir in directoriesToScan {
        let fm = FileManager.default
        guard let appsList = try? fm.contentsOfDirectory(atPath: dir) else { continue }
        
        for item in appsList {
            if item.hasSuffix(".app") {
                let appFullPath = dir + "/" + item
                
                // Update progress bar with current operation
                scannedCount += 1
                progressBar.update(current: scannedCount, operation: "Analyzing \(item)")
                
                if isChromiumBasedApp(appPath: appFullPath) {
                    let displayName = item.replacingOccurrences(of: ".app", with: "")
                    let attributes = try? fm.attributesOfItem(atPath: appFullPath)
                    let creationDate = attributes?[.creationDate] as? Date ?? Date.distantPast
                    
                    // Update progress bar for size calculation
                    progressBar.update(current: scannedCount, operation: "Calculating size for \(item)")
                    let appSize = folderSize(atPath: appFullPath)
                    
                    let version = getAppVersion(appPath: appFullPath)
                    let execPath = getExecutablePath(appPath: appFullPath)
                    let bundleId = getBundleIdentifier(appPath: appFullPath)
                    
                    let info = ChromiumAppInfo(
                        name: displayName,
                        installDate: creationDate,
                        sizeInBytes: appSize,
                        version: version,
                        executablePath: execPath,
                        bundleIdentifier: bundleId
                    )
                    apps.append(info)
                }
            }
        }
    }
    
    // Clear the final progress bar
    print("\r\u{001B}[2K", terminator: "")
    
    // Restore cursor to original position and clear the header
    print("\u{001B}8", terminator: "")  // Restore cursor position
    print("\u{001B}[2K", terminator: "")  // Clear first line
    print("\u{001B}[B\u{001B}[2K", terminator: "")  // Move down and clear line
    print("\u{001B}[B\u{001B}[2K", terminator: "")  // Move down and clear line
    print("\u{001B}[B\u{001B}[2K", terminator: "")  // Move down and clear line
    print("\u{001B}[B\u{001B}[2K", terminator: "")  // Move down and clear line
    print("\u{001B}[5A", terminator: "")  // Move cursor back up 5 lines
    fflush(stdout)
    
    return apps
}

// Format date for output
let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

func bytesToGB(_ bytes: UInt64) -> String {
    let gb = Double(bytes) / (1024.0 * 1024.0 * 1024.0)
    return String(format: "%.2f GB", gb)
}

// Main execution
let chromiumApps = scanForChromiumApps()

// Summarize Results
let totalCount = chromiumApps.count
let totalSize = chromiumApps.reduce(0) { $0 + $1.sizeInBytes }

print("\n\(ANSIColors.bold)╭──────────────────────────────────╮\(ANSIColors.reset)")
print("\(ANSIColors.bold)│      Scan Results Summary         │\(ANSIColors.reset)")
print("\(ANSIColors.bold)╰──────────────────────────────────╯\(ANSIColors.reset)")
print("\(ANSIColors.green)▸ Total Apps Found: \(totalCount)\(ANSIColors.reset)")
print("\(ANSIColors.blue)▸ Total Size: \(bytesToGB(totalSize))\(ANSIColors.reset)")

if chromiumApps.count > 0 {
    print("\n\(ANSIColors.bold)╭──────────────────────────────────╮\(ANSIColors.reset)")
    print("\(ANSIColors.bold)│      Detailed Information         │\(ANSIColors.reset)")
    print("\(ANSIColors.bold)╰──────────────────────────────────╯\(ANSIColors.reset)")

    chromiumApps.forEach { app in
        print("\n\(ANSIColors.magenta)◆ Application: \(app.name)\(ANSIColors.reset)")
        print("  \(ANSIColors.cyan)├─ Version: \(app.version)\(ANSIColors.reset)")
        print("  \(ANSIColors.yellow)├─ Bundle ID: \(app.bundleIdentifier ?? "Unknown")\(ANSIColors.reset)")
        print("  \(ANSIColors.green)├─ Installed: \(dateFormatter.string(from: app.installDate))\(ANSIColors.reset)")
        print("  \(ANSIColors.blue)├─ Size: \(bytesToGB(app.sizeInBytes))\(ANSIColors.reset)")
        print("  \(ANSIColors.cyan)└─ Executable: \(app.executablePath)\(ANSIColors.reset)")
    }
}

print("\n\(ANSIColors.green)✨ Scan completed successfully!\(ANSIColors.reset)")
print("\(ANSIColors.bold)════════════════════════════════════\(ANSIColors.reset)\n")
