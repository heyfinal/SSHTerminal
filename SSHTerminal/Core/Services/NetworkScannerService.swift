import Foundation
import Network
import Darwin

struct DiscoveredHost: Identifiable, Equatable {
    let id = UUID()
    let ip: String
    var hostname: String?

    var displayName: String { hostname ?? ip }

    static func == (lhs: DiscoveredHost, rhs: DiscoveredHost) -> Bool {
        lhs.ip == rhs.ip
    }
}

@MainActor
class NetworkScannerService: ObservableObject {
    static let shared = NetworkScannerService()

    @Published var isScanning = false
    @Published var discoveredHosts: [DiscoveredHost] = []
    @Published var progress: Double = 0
    @Published var scannedCount: Int = 0

    private var scanTask: Task<Void, Never>?

    private init() {}

    func startScan() {
        guard !isScanning else { return }
        isScanning = true
        discoveredHosts = []
        progress = 0
        scannedCount = 0

        scanTask = Task {
            await runScan()
            isScanning = false
            progress = 1.0
        }
    }

    func stopScan() {
        scanTask?.cancel()
        isScanning = false
    }

    private func runScan() async {
        guard let subnet = localSubnet() else { return }

        let ips = (1...254).map { "\(subnet).\($0)" }
        let total = Double(ips.count)

        // Scan in batches of 30 concurrent probes
        let batchSize = 30
        var idx = 0

        while idx < ips.count, !Task.isCancelled {
            let batch = Array(ips[idx..<min(idx + batchSize, ips.count)])
            idx += batchSize

            await withTaskGroup(of: DiscoveredHost?.self) { group in
                for ip in batch {
                    group.addTask {
                        await Self.probeSSH(ip: ip)
                    }
                }
                for await result in group {
                    scannedCount += 1
                    progress = Double(scannedCount) / total
                    if let host = result {
                        discoveredHosts.append(host)
                        discoveredHosts.sort { $0.ip.compare($1.ip, options: .numeric) == .orderedAscending }
                    }
                }
            }
        }
    }

    // MARK: - TCP Probe

    private static func probeSSH(ip: String) async -> DiscoveredHost? {
        await withCheckedContinuation { continuation in
            let connection = NWConnection(
                host: NWEndpoint.Host(ip),
                port: 22,
                using: .tcp
            )
            var finished = false

            let finish: (DiscoveredHost?) -> Void = { result in
                guard !finished else { return }
                finished = true
                connection.cancel()
                continuation.resume(returning: result)
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let host = DiscoveredHost(ip: ip, hostname: Self.reverseDNS(ip: ip))
                    finish(host)
                case .failed, .cancelled:
                    finish(nil)
                default:
                    break
                }
            }

            connection.start(queue: .global(qos: .utility))

            // 2-second timeout
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 2.0) {
                finish(nil)
            }
        }
    }

    // MARK: - Reverse DNS

    private static func reverseDNS(ip: String) -> String? {
        var hints = addrinfo()
        hints.ai_flags = AI_NUMERICHOST
        hints.ai_socktype = SOCK_STREAM

        var res: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(ip, nil, &hints, &res) == 0, let addr = res else { return nil }
        defer { freeaddrinfo(res) }

        var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let result = getnameinfo(
            addr.pointee.ai_addr,
            socklen_t(addr.pointee.ai_addrlen),
            &host, socklen_t(host.count),
            nil, 0,
            NI_NAMEREQD
        )
        guard result == 0 else { return nil }
        let name = String(cString: host)
        return name == ip ? nil : name
    }

    // MARK: - Local Subnet Detection

    func localSubnet() -> String? {
        guard let ip = localIPAddress() else { return nil }
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return nil }
        return "\(parts[0]).\(parts[1]).\(parts[2])"
    }

    func localIPAddress() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(firstAddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = ptr {
            let iface = current.pointee
            if iface.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                let name = String(cString: iface.ifa_name)
                if name.hasPrefix("en") || name.hasPrefix("wlan") || name.hasPrefix("wifi") {
                    var buf = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        iface.ifa_addr, socklen_t(iface.ifa_addr.pointee.sa_len),
                        &buf, socklen_t(buf.count), nil, 0, NI_NUMERICHOST
                    )
                    let ip = String(cString: buf)
                    if ip.hasPrefix("192.168") || ip.hasPrefix("10.") || ip.hasPrefix("172.") {
                        return ip
                    }
                }
            }
            ptr = current.pointee.ifa_next
        }
        return nil
    }
}
