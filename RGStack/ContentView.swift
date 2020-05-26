//
//  ContentView.swift
//  RGStack
//
//  Created by ROBERA GELETA on 5/25/20.
//  Copyright © 2020 ROBERA GELETA. All rights reserved.
//

import SwiftUI

enum Test {
    static var testDemos: [DemoCard.Demo] {
        return (0 ... 10).map { DemoCard.Demo(color: Test.colors[$0 % Test.colors.count], text: "\($0)") }
    }
    static let colors: [Color] = [.blue, .red, .orange, .green, .yellow]
    static let width: CGFloat = 320
    static let cardSize = CGSize(width: Test.width, height: Test.width * 1.5)
}

struct DemoCard: View {
    struct Demo {
        let color: Color
        let text: String
    }

    let demo: Demo

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 27, style: .continuous)
                .fill(demo.color)
                .cornerRadius(22)
                .shadow(radius: 5)
            Text(demo.text)
                .font(.largeTitle)
                .foregroundColor(.white)
        }
    }
}

extension DemoCard: ConfigurableCard {
    static func new(data: Demo?) -> DemoCard {
        guard let demoValue = data else { return DemoCard(demo: .default) }
        return DemoCard(demo: demoValue)
    }
}

extension DemoCard.Demo: DefaultValue {
    static var `default`: DemoCard.Demo {
        return .init(color: .black, text: "*E*")
    }
}

struct ContentView: View {
    var body: some View {
        ContentView_Previews.previews
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Headline")
                .font(.headline)
            RGStack<DemoCard>(data: Test.testDemos,
                             size: Test.cardSize,
                             gapDistance: 30,
                             minScaleForBackCard: 0.8)
        }
    }
}
