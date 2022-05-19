enum VersionError: Error {
    case invalidBundleInfo, invalidResponse
}

public struct LookupResult: Decodable {
    var resultCount: Int
    var results: [AppVersionInfo]
}

public struct AppVersionInfo: Decodable {
    var version: String
    var description: String
    var releaseNotes: String
    var screenshotUrls: [URL]
    var ipadScreenshotUrls: [URL]
    var trackViewUrl: String
}

@available(iOS 15.0, *)
public func getLastVersion() async throws -> AppVersionInfo {
    
    // You should pay attention on the country that your app is located, in my case I put Brazil */br/*
    // Você deve prestar atenção em que país o app está disponível, no meu caso eu coloquei Brasil */br/*
    guard let info = Bundle.main.infoDictionary
    else {throw VersionError.invalidBundleInfo}
    
    
    guard let identifier = info["CFBundleIdentifier"] as? String, let region = Locale.current.regionCode,
          let url = URL(string: "http://itunes.apple.com/\(region)/lookup?bundleId=\(identifier)") else {
        throw VersionError.invalidBundleInfo
    }
    
    let (data, _) = try await URLSession.shared.data(from: url)
    do {
        let result = try JSONDecoder().decode(LookupResult.self, from: data)
        debug_print("\(result)")
        if let last = result.results.first
        {
            debug_print("\(last)")
            return last
        }
        else
        {
            throw VersionError.invalidResponse
        }
    }
    catch {
        debug_print(error.localizedDescription)
        throw error
    }
}

@available(iOS 15.0, *)
public func getNewAppVersion() async -> AppVersionInfo?
{
    do {
        let last_version = try await getLastVersion()
        
        guard let info = Bundle.main.infoDictionary, let currentVersion = info["CFBundleShortVersionString"] as? String
        else {return nil}
        
        if last_version.version > currentVersion
        {
            return last_version
        }
        else
        {
            return nil
        }
    }
    catch
    {
        return nil
    }
}

@available(iOS 15.0, *)
public func isAppApdateAvailable() async -> Bool
{
    if let _ = await getNewAppVersion()
    {
        return true
    }
    else
    {
        return false
    }
}