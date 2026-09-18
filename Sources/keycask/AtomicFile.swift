import Foundation
import KeycaskCore

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif os(Windows)
    import WinSDK
#endif

enum AtomicFile {
    static func write(_ data: Data, to url: URL) throws {
        let directory = url.deletingLastPathComponent()
        let temp = url.appendingPathExtension("tmp")
        do {
            try FileManager.default.createDirectory(
                at: directory, withIntermediateDirectories: true)
            try writePrivate(data, to: temp)
            try replace(url, with: temp)
        } catch let error as KeycaskError {
            try? FileManager.default.removeItem(at: temp)
            throw error
        } catch {
            try? FileManager.default.removeItem(at: temp)
            throw KeycaskError.io("write \(url.path): \(error)")
        }
    }

    #if os(Windows)
        private static func writePrivate(_ data: Data, to url: URL) throws {
            try data.write(to: url)
            let handle = try FileHandle(forWritingTo: url)
            try handle.synchronize()
            try handle.close()
        }

        private static func replace(_ target: URL, with temp: URL) throws {
            let ok = temp.path.withCString(encodedAs: UTF16.self) { src in
                target.path.withCString(encodedAs: UTF16.self) { dst in
                    MoveFileExW(src, dst, DWORD(MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH))
                }
            }
            guard ok.boolValue else {
                throw KeycaskError.io("rename \(temp.path): error \(GetLastError())")
            }
        }
    #else
        private static func writePrivate(_ data: Data, to url: URL) throws {
            _ = unlink(url.path)
            let fd = open(url.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
            guard fd >= 0 else {
                throw KeycaskError.io("open \(url.path): \(String(cString: strerror(errno)))")
            }
            let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
            try handle.write(contentsOf: data)
            try handle.synchronize()
            try handle.close()
        }

        private static func replace(_ target: URL, with temp: URL) throws {
            guard rename(temp.path, target.path) == 0 else {
                throw KeycaskError.io("rename \(temp.path): \(String(cString: strerror(errno)))")
            }
        }
    #endif
}
