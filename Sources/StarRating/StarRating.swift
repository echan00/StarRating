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
    
    private func updateRatingIfNeeded(width: CGFloat, xLocation: CGFloat) {
        guard let onRatingChanged = onRatingChanged else { return }
        
        // Calculate the available space for stars (accounting for spacing)
        let numberOfSpaces = CGFloat(configuration.numberOfStars - 1)
        let totalSpacingWidth = configuration.spacing * numberOfSpaces
        let availableStarWidth = width - totalSpacingWidth
        
        // Calculate individual star width
        let starWidth = availableStarWidth / CGFloat(configuration.numberOfStars)
        
        // Determine which star was tapped and the percentage within that star
        var starIndex = 0
        var remainingX = xLocation
        
        // Find which star was tapped
        while remainingX > starWidth && starIndex < configuration.numberOfStars - 1 {
            remainingX -= (starWidth + configuration.spacing)
            starIndex += 1
        }
        
        // Calculate rating based on the position within the star
        let percentOfStar = min(max(remainingX / starWidth, 0), 1)
        let newRating = Double(starIndex) + Double(percentOfStar)
        
        // Normalize the rating according to configuration
        let normalizedRating = Self.normalizedRating(
            rating: newRating,
            minRating: configuration.minRating,
            numberOfStars: configuration.numberOfStars,
            stepType: configuration.stepType
        )
        
        // Only update if the rating changed
        if normalizedRating != rating {
            rating = normalizedRating
            onRatingChanged(rating)
        }
    }
    
    private func ratingWidth(fullWidth: CGFloat) -> CGFloat {
        // Calculate total width excluding spacing
        let numberOfSpaces = CGFloat(configuration.numberOfStars - 1)
        let totalSpacingWidth = configuration.spacing * numberOfSpaces
        let availableStarWidth = fullWidth - totalSpacingWidth
        
        // Calculate width of a single star
        let starWidth = availableStarWidth / CGFloat(configuration.numberOfStars)
        
        // Calculate total width for the current rating
        let fullStars = floor(CGFloat(rating))
        let partialStar = CGFloat(rating) - fullStars
        
        // Width is: (full stars * (star width + spacing)) + (partial star * star width)
        return (fullStars * (starWidth + configuration.spacing)) + (partialStar * starWidth)
    }
    
    public var body: some View {
        GeometryReader { geo in
            let maskWidth = ratingWidth(fullWidth: geo.size.width)
            
            ZStack(alignment: .leading) {
                // Background stars (empty)
                HStack(spacing: configuration.spacing) {
                    ForEach((0..<configuration.numberOfStars), id: \.self) { _ in
                        ZStack {
                            starBackground
                            starBorder
                                .shadow(color: configuration.shadowColor, radius: configuration.shadowRadius)
                        }
                    }
                }
                
                // Filled stars (partial filling based on rating)
                HStack(spacing: configuration.spacing) {
                    ForEach((0..<configuration.numberOfStars), id: \.self) { _ in
                        starFilling
                            .overlay(starBorder)
                    }
                }
                .mask(
                    Rectangle()
                        .frame(width: maskWidth, height: geo.size.height)
                )
            }
            .contentShape(Rectangle()) // Make the entire area tappable
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        updateRatingIfNeeded(
                            width: geo.size.width,
                            xLocation: value.location.x
                        )
                    }
            )
        }
        .frame(height: 44) // Provide a reasonable default height for better hit testing
    }
}

struct StarRating_Previews: PreviewProvider {
    static var previews: some View {
        StarRating(initialRating: 2.3)
    }
}
