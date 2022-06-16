//
//  InteractiveWeatherChart.swift
//  WWDC22
//
//  Created by liang2kl on 2022/6/16.
//

import SwiftUI
import Charts


/// An chart that can be interacted with gestures (on iOS) or hover (on macOS),
/// like those charts in the new Weather app.
struct InteractiveWeatherChart: View {
    var datas: [WeatherData]
    var currentTime: Int = 10
    @State private var selectedTime: Int?
    @State private var isPressing = false
    
    private let gradient = LinearGradient(
        colors: [.teal, .yellow],
        startPoint: .bottom,
        endPoint: .top
    )
    
    var body: some View {
        let axisRange = calculateYAxisDomain()
        
        Chart {
            ForEach(datas) { data in
                // Area with gradient.
                AreaMark(
                    x: .value("Time", data.time),
                    yStart: .value("", axisRange.first!),
                    yEnd: .value("Temperature", data.temperature)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(gradient)
                .opacity(0.4)
                
                // The top line of the chart.
                LineMark(
                    x: .value("Time", data.time),
                    y: .value("Temperature", data.temperature)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(gradient)
                .lineStyle(StrokeStyle(lineWidth: 5))
            }
            
            // Indication of current time
            if currentTime > 0 {
                // Fade out the passed time.
                RectangleMark(
                    xStart: .value("Range start", 0),
                    xEnd: .value("Range end", currentTime)
                )
                .foregroundStyle(.black)
                .opacity(0.2)
                
                RuleMark(
                    x: .value("Current time", currentTime)
                )
                .foregroundStyle(Color.secondary.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1))

            }

            // Show the rule and the point when user interacts with the chart.
            if let selectedTime = selectedTime, selectedTime >= 0, selectedTime <= 24 {
                let data = datas[selectedTime]
                RuleMark(x: .value("Selected Time", selectedTime))
                    .foregroundStyle(Color.secondary)
                    .annotation(
                        position: selectedTime <= 12 ? .trailing : .leading,
                        alignment: .top
                    ) {
                        Label("\(data.temperature)°", systemImage: data.weather.symbolName)
                            .font(.system(.title, weight: .medium))
                            .padding()
                    }
                PointMark(
                    x: .value("Selected Time", selectedTime),
                    y: .value("Selected Tempeature", data.temperature)
                )
                .symbolSize(200)
                .foregroundStyle(Color.secondary)
            }

        }
        // Override axis domains.
        .chartYScale(domain: axisRange)
        .chartXScale(domain: 0...24)
        // Override how the axis are rendered.
        .chartXAxis {
            AxisMarks(values: .stride(by: 4))
        }
        .chartYAxis {
            AxisMarks(values: .stride(by: 6))
        }
        // The overlay view to display extra information and to interact.
        .chartOverlay { proxy in
            GeometryReader { g in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    // Track hover events.
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            guard !isPressing else { return }
                            handleHoverEvent(
                                at: location, chartProxy: proxy, geometryProxy: g
                            )
                        case .ended:
                            selectedTime = nil
                        }
                    }
                    .onHover { _ in
                        // FIXME: Bug in beta 1
                        // It's weird that if we don't add onHover()
                        // then onContinuousHover() won't work.
                    }
                
                    // Track drag events (mainly for touches)
                    .gesture(DragGesture()
                        .onChanged { value in
                            isPressing = true
                            handleHoverEvent(
                                at: value.location, chartProxy: proxy, geometryProxy: g
                            )
                        }
                        .onEnded { _ in
                            selectedTime = nil
                            isPressing = false
                        }
                    )
                
                    // Display the tips.
                    .overlay(alignment: .topLeading) {
                        if selectedTime == nil {
                            Text("Hover or press to get detail weather of specific time")
                                .font(.system(.body, weight: .medium))
                                .frame(maxWidth: 120)
                                .padding()
                        }
                    }

            }
        }

    }
    
    /// Calculate the domain for Y axis to fit the axis.
    private func calculateYAxisDomain() -> ClosedRange<Int> {
        let minTemperature = datas.min(
            by: { $0.temperature < $1.temperature }
        )?.temperature ?? 0
        let maxTemperature = datas.max(
            by: { $0.temperature < $1.temperature }
        )?.temperature ?? 35
        let interval = maxTemperature - minTemperature
        
        // Pad the plot
        var minValue = minTemperature - interval / 2
        var maxValue = maxTemperature + interval / 4
        
        // Align to 6N to fit with the axis
        minValue -= minValue % 6
        maxValue += 6 - maxValue % 6
        return minValue...maxValue
    }
    
    /// Update state with new hover (or drag) events.
    private func handleHoverEvent(
        at location: CGPoint,
        chartProxy: ChartProxy,
        geometryProxy: GeometryProxy
    ) {
        let currentX = location.x - geometryProxy[chartProxy.plotAreaFrame].origin.x
        if let selectedTime: Double = chartProxy.value(atX: currentX) {
            self.selectedTime = lround(selectedTime)
        }
    }

}

// MARK: - Models

enum Weather {
    case sunny, rainy, thunder, cloudy
    
    var symbolName: String {
        switch self {
        case .sunny:
            return "sun.max.fill"
        case .rainy:
            return "cloud.rain.fill"
        case .thunder:
            return "cloud.bolt.fill"
        case .cloudy:
            return "cloud.fill"
        }
    }
}

struct WeatherData: Identifiable {
    let temperature: Int
    let weather: Weather
    let time: Int
    
    var id: Int {
        time
    }
}

// MARK: - Previews

fileprivate let previewData: [WeatherData] = [
    WeatherData(temperature: 21, weather: .thunder, time: 0),
    WeatherData(temperature: 20, weather: .thunder, time: 1),
    WeatherData(temperature: 19, weather: .cloudy, time: 2),
    WeatherData(temperature: 19, weather: .cloudy, time: 3),
    WeatherData(temperature: 18, weather: .cloudy, time: 4),
    WeatherData(temperature: 19, weather: .thunder, time: 5),
    WeatherData(temperature: 19, weather: .cloudy, time: 6),
    WeatherData(temperature: 20, weather: .cloudy, time: 7),
    WeatherData(temperature: 21, weather: .sunny, time: 8),
    WeatherData(temperature: 23, weather: .sunny, time: 9),
    WeatherData(temperature: 25, weather: .sunny, time: 10),
    WeatherData(temperature: 26, weather: .sunny, time: 11),
    WeatherData(temperature: 27, weather: .sunny, time: 12),
    WeatherData(temperature: 28, weather: .sunny, time: 13),
    WeatherData(temperature: 29, weather: .sunny, time: 14),
    WeatherData(temperature: 29, weather: .sunny, time: 15),
    WeatherData(temperature: 30, weather: .sunny, time: 16),
    WeatherData(temperature: 29, weather: .sunny, time: 17),
    WeatherData(temperature: 28, weather: .sunny, time: 18),
    WeatherData(temperature: 27, weather: .sunny, time: 19),
    WeatherData(temperature: 26, weather: .sunny, time: 20),
    WeatherData(temperature: 25, weather: .sunny, time: 21),
    WeatherData(temperature: 24, weather: .cloudy, time: 22),
    WeatherData(temperature: 23, weather: .cloudy, time: 23),
    WeatherData(temperature: 23, weather: .cloudy, time: 24),
]

struct InteractiveWeatherChart_Previews: PreviewProvider {
    @Environment(\.openURL) static var openURL
    static var previews: some View {
        InteractiveWeatherChart(datas: previewData)
            .padding()
            .navigationTitle("Interactive Chart")
            .toolbar {
                Button {
                    openURL(URL(string: "https://developer.apple.com/videos/play/wwdc2022/10137/")!)
                } label: {
                    Image(systemName: "link")
                }
            }
    }
    
}
