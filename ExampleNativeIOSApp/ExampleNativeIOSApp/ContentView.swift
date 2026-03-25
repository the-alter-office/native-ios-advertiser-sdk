import SwiftUI
import AdgeistAdvertiserSDK

struct ContentView: View {
    @State private var utmDataString = "No UTM data yet"
    @State private var testDeeplinkURL = "https://beta.altergame.click/brandInfo/4487?utm_campaign=6989b2f4c3f7f3ebe7045dac&utm_data=%2BeGhnjFQ4TEwaYEhMYDC5%2FIh0qqHa%2BBjj6ZxA5ajPCMwrPzImHR6sCr%2FRiz8KXEnoIWtMeDHkxvlY8gEFMXlvRSsHPrIxdKBeEGuVVpgH2qZtu0gBbrExjN90fg9a%2B19Cma7TDjvl7W%2FJ97iFKg%2Ff1p3tGX6tHGJavD%2BI7cdXojVodGbmfTOFfWbmJqVuZYnKRC0H3r8ufxfNn7Bi7y66d%2BSye8aKHNFzoAXidEVfA7OlxXVWh60quL2GFzfGHx6JE5B4sM6friG5Aw0XuP%2FfVfxgdDFYYz588UROs4Q8NCUDq6KbvrbwfJsUNOXFKD7dwHHJFLXMV1BsIidvoBQpeNUEDtBU77tedT0JKmpFJsG%2FKA5q3P4juHUIoCEgpqHBBybKE8oIedPdQY6d5fEbAHqrbthzSbj7lSEbdSDxsfzDqK8HZaWzYk1SWuWlGJo&utm_source=dsclk.cdkcm.cod"

    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // UTM Tracking Section
                    VStack(spacing: 12) {
                        Text("UTM Tracking")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current UTM Data:")
                                .font(.subheadline)
                                .bold()
                                .padding(.horizontal)

                            Text(utmDataString)
                                .font(.caption)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }

                        TextField("Test Deeplink URL", text: $testDeeplinkURL)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            Button("Refresh UTM Data") {
                                refreshUTMData()
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)

                            Button("Simulate Deeplink") {
                                simulateDeeplink()
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)

                        Button("Clear UTM Data") {
                            clearUTMData()
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .padding(.top)
            }
            .navigationTitle("Adgeist UTM Test")
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func refreshUTMData() {
        let utmData = AdgeistCore.getInstance().getUTMData()

        if utmData.isEmpty {
            utmDataString = "No UTM data captured yet"
        } else if let jsonData = try? JSONSerialization.data(withJSONObject: utmData, options: .prettyPrinted),
                  let jsonString = String(data: jsonData, encoding: .utf8) {
            utmDataString = jsonString
        } else {
            utmDataString = utmData.description
        }

        showAlert(title: "UTM Data Refreshed", message: "Check the display above")
    }

    private func simulateDeeplink() {
        guard let url = URL(string: testDeeplinkURL) else {
            showAlert(title: "Invalid URL", message: "Please enter a valid deeplink URL")
            return
        }

        AdgeistCore.getInstance().trackDeeplink(url: url)
        refreshUTMData()
        showAlert(title: "Deeplink Tracked", message: "UTM parameters captured from: \(url.absoluteString)")
    }

    private func clearUTMData() {
        UTMTracker.shared.clearUtmParameters()
        utmDataString = "No UTM data yet"
        showAlert(title: "Cleared", message: "All UTM data has been cleared")
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

#Preview {
    ContentView()
}
