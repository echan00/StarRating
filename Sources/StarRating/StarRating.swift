import SwiftUI

/// A customizable star rating element It shows a star rating and handles user input.
public struct StarRating: View {
    /// clips the rating to the allowed interval and rounds it
    /// depending on the stepType
    public static func normalizedRating(rating: Double, minRating: Double, numberOfStars: Int, stepType: StepType) -> Double {
        let ratingInInterval = min(max(rating, minRating), Double(numberOfStars))
        switch stepType {
        case .half: return round(ratingInInterval * 2) / 2
        case .full: return round(ratingInInterval)
        case .exact: return ratingInInterval
        }
    }
    
    public enum StepType {
        case full, half, exact
    }
    
    /// The configuration of the StarRating control.
    /// Allows you to customize style and behaviour
    @Binding public var configuration: StarRatingConfiguration
    
    /// The currently selected rating
    @State public var rating: Double
    
    /// Gets called when the user changes the rating by tapping or dragging
    private var onRatingChanged: ((Double) -> Void)?
    
    /// - Parameters:
    ///     - initialRating: The initial rating value
    ///     - configuration: The configuration of the StarRating control.
    ///                      Allows you to customize style and behaviour
    ///     - onRatingChanged: Gets called when the user changes the rating
    ///                        by tapping or dragging
    public init (
        initialRating: Double,
        configuration: Binding<StarRatingConfiguration> = .constant(StarRatingConfiguration()),
        onRatingChanged: ((Double) -> Void)? = nil
    ) {
        self.onRatingChanged = onRatingChanged
        
        _configuration = configuration
        let normalizedRating = StarRating.normalizedRating(
            rating: initialRating,
            minRating: configuration.wrappedValue.minRating,
            numberOfStars: configuration.wrappedValue.numberOfStars,
            stepType: configuration.wrappedValue.stepType
        )
        _rating = State(initialValue: normalizedRating)
    }
    
    private var starBorder: some View {
        Star(
            vertices: configuration.starVertices,
            weight: configuration.starWeight
        )
        .stroke(configuration.borderColor,
                lineWidth: configuration.borderWidth)
        .aspectRatio(contentMode: .fit)
    }
    
    private var starBackground: some View {
        Star(
            vertices: configuration.starVertices,
            weight: configuration.starWeight
        )
        .fill(configuration.emptyColor)
        .aspectRatio(contentMode: .fit)
    }
    
    private var starFilling: some View {
        Star(
            vertices: configuration.starVertices,
            weight: configuration.starWeight
        )
        .fill(LinearGradient(
            gradient: .init(colors: configuration.fillColors),
            startPoint: .init(x: 0, y: 0),
            endPoint: .init(x: 1, y: 1)
        ))
        .aspectRatio(contentMode: .fit)
    }
    
    private func updateRatingIfNeeded(width: CGFloat, marginSize: CGFloat, xLocation: CGFloat) {
        guard let onRatingChanged = onRatingChanged else { return }
        
        // Calculate the available width for stars
        let widthWithoutMargin = width - marginSize * 2
        let numberOfSpaces = CGFloat(configuration.numberOfStars - 1)
        let starWidth = (widthWithoutMargin - configuration.spacing * numberOfSpaces) / CGFloat(configuration.numberOfStars)
        
        guard starWidth > 0 else { return }
        
        // Calculate which star was tapped and what portion of it was tapped
        // First, adjust xLocation to account for the horizontal padding
        let adjustedX = xLocation - marginSize
        
        // If tap is outside the valid area, clamp to valid range
        if adjustedX <= 0 {
            // Tapped to the left of the first star
            if rating != configuration.minRating {
                rating = configuration.minRating
                onRatingChanged(rating)
            }
            return
        } else if adjustedX >= widthWithoutMargin {
            // Tapped to the right of the last star
            let maxRating = Double(configuration.numberOfStars)
            if rating != maxRating {
                rating = maxRating
                onRatingChanged(rating)
            }
            return
        }
        
        // Calculate which star was tapped
        let starAndSpaceWidth = starWidth + configuration.spacing
        let starIndex = Int(adjustedX / starAndSpaceWidth)
        let remainingX = adjustedX - (CGFloat(starIndex) * starAndSpaceWidth)
        
        // If the tap is in the spacing between stars, determine which star it's closer to
        if remainingX > starWidth {
            // Tapped in the spacing after this star, so count it as the next star
            let newRatingValue = Double(starIndex + 1)
            if rating != newRatingValue {
                rating = newRatingValue
                onRatingChanged(rating)
            }
        } else {
            // Tapped within the star, calculate partial rating
            let percentOfStar = remainingX / starWidth
            let newRatingValue = Double(starIndex) + Double(percentOfStar)
            
            // Normalize the rating according to step type
            let normalizedRating = Self.normalizedRating(
                rating: newRatingValue,
                minRating: configuration.minRating,
                numberOfStars: configuration.numberOfStars,
                stepType: configuration.stepType
            )
            
            if rating != normalizedRating {
                rating = normalizedRating
                onRatingChanged(rating)
            }
        }
    }
    
    private func ratingWidth(fullWidth: CGFloat, horizontalPadding: CGFloat) -> CGFloat {
        let widthWithoutMargin = fullWidth - horizontalPadding * 2
        let numberOfSpaces = CGFloat(configuration.numberOfStars - 1)
        let starWidth = (widthWithoutMargin - configuration.spacing * numberOfSpaces) / CGFloat(configuration.numberOfStars)
        
        return CGFloat(rating) * starWidth + floor(CGFloat(rating)) * configuration.spacing
    }
    
    public var body: some View {
        GeometryReader { geo in
            let horizontalPadding = geo.size.width / CGFloat(configuration.numberOfStars * 2 + 2)
            
            let maskWidth = ratingWidth(fullWidth:geo.size.width,
                                        horizontalPadding: horizontalPadding)
            
            // A drag gesture with zero minimum distance functions as both a tap and drag
            let dragAndTap = DragGesture(minimumDistance: 0).onChanged { value in
                updateRatingIfNeeded(width: geo.size.width,
                                     marginSize: horizontalPadding,
                                     xLocation: value.location.x)
            }
            
            ZStack {
                // Background layer with empty stars
                HStack(spacing: configuration.spacing) {
                    ForEach((0 ..< configuration.numberOfStars), id: \.self) { index in
                        starBorder
                            .shadow(color: configuration.shadowColor, radius: configuration.shadowRadius)
                            .background(starBackground)
                    }
                }
                
                // Foreground layer with filled stars
                HStack(spacing: configuration.spacing) {
                    ForEach((0 ..< configuration.numberOfStars), id: \.self) { index in
                        starFilling
                            .mask(Rectangle().size(width: maskWidth, height: geo.size.height))
                            .overlay(starBorder)
                    }
                }
                .mask(Rectangle().size(width: maskWidth, height: geo.size.height))
            }
            .padding(.horizontal, horizontalPadding)
            .contentShape(Rectangle()) // Important for proper hit testing
            .gesture(dragAndTap)
        }
        // Make sure the view has a sensible height
        .frame(height: 44) // Add a reasonable default height for better tap targets
    }
}

struct StarRating_Previews: PreviewProvider {
    static var previews: some View {
        StarRating(initialRating: 2.3)
    }
}
