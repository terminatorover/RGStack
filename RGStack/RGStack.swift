//
//  RGStack.swift
//  UI
//
//  Created by ROBERA GELETA on 4/15/20.
//  Copyright © 2020 ROBERA GELETA. All rights reserved.
//
//swiftlint:disable file_length

import SwiftUI
import UIKit

public protocol DefaultValue {
    static var `default`: Self { get }
}

public protocol ConfigurableCard: View {
    associatedtype Data: DefaultValue
    static func new(data: Data?) -> Self
}

public enum CardMachine {
    public enum Position {
        case back, front, bottom, off
    }

    public struct Layout {
        let size: CGSize
        let offset: CGPoint
        let scale: CGFloat
        let zIndex: Double
        let opacity: Double
        var animated: Bool = false
    }

    public struct CardInfo {
        let size: CGSize
        let gapDistance: CGFloat
        let minScaleForBackCard: CGFloat
        let visibleFractionOfBottomCard: CGFloat
    }

    public enum Movement {
        case forward(CGFloat)
        case backward(CGFloat)
        case none

        init(_ value: CGFloat) {
            if value > 0 {
                self = .forward(value)
            } else if value < 0 {
                self = .backward(value.magnitude)
            } else {
                self = .none
            }
        }

        var isForward: Bool {
            if case .forward = self { return true }
            return false
        }

        var isBackward: Bool {
            if case .backward = self { return true }
            return false
        }

        var isDragging: Bool {
            switch self {
            case .none:
                return false
            case .backward, .forward:
                return true
            }
        }
    }

    public enum Direction {
        case next, back
    }
}

public struct RGStack<CardView: ConfigurableCard>: View {

    init(data: [CardView.Data], cardInfo: CardMachine.CardInfo) {
        self.data = data
        self.cardInfo = cardInfo
    }

    private var data: [CardView.Data]
    var cardInfo: CardMachine.CardInfo
    var size: CGSize { return cardInfo.size }

    // MARK: Constants
    let snapThresholdMangnitude: CGFloat = 0.2
    let index0Positions: [CardMachine.Position] = [.front, .bottom, .off, .off]
    let index1Positions: [CardMachine.Position] = [.back, .front, .bottom, .off]

    private var currentPositons: [CardMachine.Position] { return positions.current }
    private var previousPositions: [CardMachine.Position] {
        let lastMovement: CardMachine.Movement = .init(previousDrag)
        if positions.last == positions.current {
            return currentPositons.map { $0.position(for: lastMovement) }
        } else {
            return positions.last
        }
    }

    // MARK: State
    @State private var positions: (last: [CardMachine.Position], current: [CardMachine.Position]) =
        ([.front, .bottom, .off, .off], [.front, .bottom, .off, .off])
    @State private var index: Int = 0
    @State private var drags: (last: CGFloat, current: CGFloat) = (0.0, 0.0)

    var drag: CGFloat { return drags.current }
    var previousDrag: CGFloat { return drags.last }

    func currentConfiguration() -> RGStackConfiguration<CardView.Data> {
        return configuration(with: .init(drag),
                             currentIndex: index,
                             positions: currentPositons,
                             previousPositions: previousPositions)
    }

    func variance(from translation: CGSize) -> CGFloat {
        return -1 * (translation.height / (size.height + cardInfo.gapDistance))
    }

    private func RGStackSize(style: CardMachine.CardInfo) -> CGSize {
        let cardSize = style.size
        let totalHeight = ((1 + style.visibleFractionOfBottomCard) * cardSize.height) + style.gapDistance
        return CGSize(width: cardSize.width,
                      height: totalHeight)
    }

    public var body: some View {
        let configuration = currentConfiguration()
        return ZStack {
            ForEach(0...3, id: \.self) {
                CardView.new(data: configuration[$0].data)
                .apply(layout: configuration[$0].layout)
            }
        }
        .frame(width: RGStackSize(style: cardInfo).width, height: RGStackSize(style: cardInfo).height, alignment: .top)
        .on(dragged: { value in
            self.set(drag: self.variance(from: value.translation))
        }, ended: { value in
            self.endedDrag(translation: value.translation, threshold: self.snapThresholdMangnitude)
        })
        .onAppear {
            self.set(drag: 0)
        }
    }
}

// MARK: Moving to the next card and going back to the preivous card

public extension RGStack {

    func move(to direction: CardMachine.Direction) {
        let newIndex = direction == .next ? index + 1 : index - 1
        guard let newPositions = move(to: direction, currentIndex: index, currentPositions: currentPositons) else {
            set(drag: 0)
            return
        }
        index = newIndex
        set(drag: 0)
        set(positions: newPositions)
    }

    private func move(to direction: CardMachine.Direction,
                      currentIndex: Int,
                      currentPositions: [CardMachine.Position]) -> [CardMachine.Position]? {
        let newIndex = direction == .next ? currentIndex + 1 : currentIndex - 1
        guard
            newIndex >= 0,
            newIndex < data.count
        else { return nil }
        return updatedPositions(for: newIndex, direction: direction, previous: currentPositions)
    }

    private func updatedPositions(for index: Int,
                                  direction: CardMachine.Direction,
                                  previous: [CardMachine.Position]) -> [CardMachine.Position] {
        switch index {
        case 0:
            return index0Positions
        case 1:
            return index1Positions
        default:
            return updated(positions: previous, in: direction)
        }
    }

    private func updated(positions: [CardMachine.Position],
                         in direction: CardMachine.Direction) -> [CardMachine.Position] {
        return direction == .next ? positions.rightShift() : positions.leftShift()
    }

    private func set(positions new: [CardMachine.Position]) {
        positions = (last: positions.current, current: new)
    }

    private func set(drag: CGFloat) {
        drags = (last: drags.current, current: drag)
        set(positions: currentPositons)
    }
}

// MARK: Buildling Configurations

public extension RGStack {
    internal func configuration(with movement: CardMachine.Movement,
                       currentIndex: Int,
                       positions: [CardMachine.Position],
                       previousPositions: [CardMachine.Position]) -> RGStackConfiguration<CardView.Data> {
        return buildConfiguration(from: positions,
                                  previousPositions: previousPositions,
                                  data: data,
                                  currentIndex: currentIndex,
                                  movement: movement)
    }

    private func dataIndex(with currentIndex: Int, for position: CardMachine.Position) -> Int {
        switch position {
        case .back:
            return currentIndex - 1
        case .front:
            return currentIndex
        case .bottom:
            return currentIndex + 1
        case .off:
            return currentIndex + 2
        }
    }

    private func buildConfiguration(
        from positions: [CardMachine.Position],
        previousPositions: [CardMachine.Position],
        data: [CardView.Data],
        currentIndex: Int,
        movement: CardMachine.Movement
    ) -> RGStackConfiguration<CardView.Data> {
        let isLastCard = currentIndex == (data.count - 1)
        let isFirstCard = currentIndex == 0

        return positions.mapIndex { (positionIndex, position) -> CardConfiguration<CardView.Data> in
            let index = self.dataIndex(with: currentIndex, for: position)
            var config = CardConfiguration(position,
                                           data: data.get(index: index),
                                           movement: movement,
                                           cardInfo: self.cardInfo)

            let previousPosition = previousPositions[positionIndex]
            config.layout.animated = movement.isDragging ?
                false :
                previousPosition.shouldAnimateTransition(to: position)

            if isLastCard {
                if position == .bottom || position == .off {
                    config.set(size: .zero)
                    config.layout.animated = false
                } else if movement.isForward && position == .back {
                    config.set(size: .zero)
                    config.layout.animated = false
                }
            } else if isFirstCard, position == .off, movement.isBackward {
                config.set(size: .zero)
                config.layout.animated = false
            }

            return config
        }
    }
}

// MARK: Handling the Ending of the Dragging Gesture

public extension RGStack {
    private func endedDrag(translation: CGSize, threshold: CGFloat) {
        let endMove: CardMachine.Movement = .init(variance(from: translation))
        switch endMove {
        case .none:
            set(drag: 0)
        case let .backward(progress):
            reconfigurePostInteraction(progress: progress, direction: .back, threshold: threshold)
        case let .forward(progress):
            reconfigurePostInteraction(progress: progress, direction: .next, threshold: threshold)
        }
    }

    private func reconfigurePostInteraction(progress: CGFloat, direction: CardMachine.Direction, threshold: CGFloat) {
        if progress > threshold {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            move(to: direction)
        } else {
            set(drag: 0)
        }
    }
}

// MARK: Card Configuration

typealias RGStackConfiguration<Data> = [CardConfiguration<Data>]

struct CardConfiguration<Data> {
    var layout: CardMachine.Layout
    var data: Data?

    init(_ position: CardMachine.Position,
         data: Data?,
         movement: CardMachine.Movement,
         cardInfo info: CardMachine.CardInfo) {
        self.layout = .init(position, movement: movement, cardInfo: info)
        self.data = data
    }

    mutating func set(size new: CGSize) {
        layout = CardMachine.Layout(size: new,
                                    offset: layout.offset,
                                    scale: layout.scale,
                                    zIndex: layout.zIndex,
                                    opacity: layout.opacity)
    }
}

// MARK: Layout Initializer

public extension CardMachine.Layout {

    init(_ position: CardMachine.Position, cardInfo info: CardMachine.CardInfo) {
        let cardSize = info.size
        switch position {
        case .back:
            self = .init(size: cardSize,
                         offset: .zero,
                         scale: info.minScaleForBackCard,
                         zIndex: 1,
                         opacity: 1)
        case .bottom:
            self = .init(size: cardSize,
                         offset: CGPoint(x: 0,
                                         y: cardSize.height + info.gapDistance),
                         scale: 1,
                         zIndex: 300,
                         opacity: 1)
        case .front:
            self = .init(size: cardSize,
                         offset: .zero,
                         scale: 1,
                         zIndex: 200,
                         opacity: 1)
        case .off:
            self = .init(size: cardSize,
                         offset: CGPoint(x: 0, y: cardSize.height * 2.0),
                         scale: 1,
                         zIndex: 0,
                         opacity: 1)
        }
    }

    init(_ position: CardMachine.Position, movement: CardMachine.Movement, cardInfo info: CardMachine.CardInfo) {
        let currentLayout: CardMachine.Layout = .init(position, cardInfo: info)
        switch movement {
        case .none:
            self = currentLayout
        case let .backward(progress):
            self = currentLayout.interpolate(
                to: .init(position.position(for: movement), cardInfo: info),
                progerss: position.previousTransition.interpolated ? progress : (progress > 0 ? 1 : 0)
            )
        case let .forward(progress):
            self = currentLayout.interpolate(
                to: .init(position.position(for: movement), cardInfo: info),
                progerss: position.nextTransition.interpolated ? progress : (progress > 0 ? 1 : 0)
            )
        }
    }
}

// MARK: Position Transition Specification

public extension CardMachine.Position {

    struct Transition {
        let position: CardMachine.Position
        var interpolated: Bool = true
    }

    func shouldAnimateTransition(to position: CardMachine.Position) -> Bool {
        let next = transitionNeighbours.next.position
        let previous = transitionNeighbours.previous.position
        switch position {
        case next:
            return transitionNeighbours.next.interpolated
        case previous:
            return transitionNeighbours.previous.interpolated
        default:
            return false
        }
    }

    func position(for movement: CardMachine.Movement) -> CardMachine.Position {
        guard let transit = transition(for: movement) else { return self }
        return transit.position
    }

    func transition(for movement: CardMachine.Movement) -> Transition? {
        switch movement {
        case .none:
            return nil
        case .forward:
            return nextTransition
        case .backward:
            return previousTransition
        }
    }

    var nextTransition: Transition { return transitionNeighbours.next }
    var previousTransition: Transition { return transitionNeighbours.previous }
    var nextPosition: CardMachine.Position { return nextTransition.position }
    var previousPosition: CardMachine.Position { return previousTransition.position }

    var transitionNeighbours: (previous: Transition, next: Transition) {
        switch self {
        case .back:
            return (previous: Transition(position: .front), next: Transition(position: .off, interpolated: false))
        case .front:
            return (previous: Transition(position: .bottom), next: Transition(position: .back))
        case .bottom:
            return (previous: Transition(position: .off), next: Transition(position: .front))
        case .off:
            return (previous: Transition(position: .back, interpolated: false), next: Transition(position: .bottom))
        }
    }
}

// MARK: View Extension

public extension View {
    func apply(layout: CardMachine.Layout) -> some View {
        let animation: Animation? = layout.animated ?
            .interactiveSpring(response: 0.25, dampingFraction: 0.75, blendDuration: 0.95) :
            nil
        return frame(width: layout.size.width, height: layout.size.height)
            .scaleEffect(layout.scale)
            .offset(x: layout.offset.x, y: layout.offset.y)
            .zIndex(layout.zIndex)
            .opacity(layout.opacity)
            .animation(animation)
    }

    func on(dragged: @escaping (DragGesture.Value) -> Void,
            ended: @escaping (DragGesture.Value) -> Void) -> some View {
        return gesture(
            DragGesture().onChanged(dragged).onEnded(ended)
        )
    }
}

// MARK: Layout Interpolation

public extension CardMachine.Layout {
    // swiftlint:disable identifier_name
    func interpolate(to: CardMachine.Layout,
                     progerss: CGFloat) -> CardMachine.Layout {
        return CardMachine.Layout(size: size.interpolate(to: to.size, progress: progerss),
                                  offset: offset.interpolate(to: to.offset, progress: progerss),
                                  scale: scale.interpolate(to: to.scale, progress: progerss),
                                  zIndex: zIndex.interpolate(to: to.zIndex, progress: Double(progerss)),
                                  opacity: opacity.interpolate(to: to.opacity, progress: Double(progerss)))
    }
}

// MARK: Convenience Initializer

public extension RGStack {
    init(data: [CardView.Data],
         size: CGSize,
         gapDistance: CGFloat = 50,
         minScaleForBackCard: CGFloat = 0.8,
         visibleFractionOfBottomCard: CGFloat = 0.2) {
        self.data = data
        cardInfo = CardMachine.CardInfo(size: size,
                                        gapDistance: gapDistance,
                                        minScaleForBackCard: minScaleForBackCard,
                                        visibleFractionOfBottomCard: visibleFractionOfBottomCard)
    }
}

