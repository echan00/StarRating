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
    
    private func updateRatingFromLocation(width: CGFloat, xLocation: CGFloat) {
        guard let onRatingChanged = onRatingChanged else { return }
        
        // Calculate the width of each star including spacing
        let starWidth = width / CGFloat(configuration.numberOfStars)
        
        // Calculate the rating based on the x location
        let rawRating = (xLocation / width) * CGFloat(configuration.numberOfStars)
        let cappedRating = max(min(rawRating, CGFloat(configuration.numberOfStars)), 0)
        
        let normalizedRating = Self.normalizedRating(
            rating: Double(cappedRating),
            minRating: configuration.minRating,
            numberOfStars: configuration.numberOfStars,
            stepType: configuration.stepType
        )
        
        if normalizedRating != rating {
            rating = normalizedRating
            onRatingChanged(rating)
        }
    }
    
    private func ratingWidth(fullWidth: CGFloat) -> CGFloat {
        return (CGFloat(rating) / CGFloat(configuration.numberOfStars)) * fullWidth
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
                .frame(width: geo.size.width, alignment: .leading)
                .mask(
                    Rectangle()
                        .frame(width: maskWidth, height: geo.size.height)
                )
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        updateRatingFromLocation(
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
