import SwiftUI
import StarRating

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var shadowWhite: Double {
        colorScheme == .light ? 0 : 1
    }
    
    var bigStar: some View {
        ZStack {
            Star()
                .fill(LinearGradient(
                    gradient: .init(colors: [.pink, .blue]),
                    startPoint: .init(x: 0, y: 0),
                    endPoint: .init(x: 1, y: 1)
                ))
                .frame(width: 300, height: 300, alignment: .center)
                .overlay(Star().stroke(Color.white, lineWidth: 4))
                .shadow(
                    color: Color(white: shadowWhite, opacity: 0.33),
                    radius: 7
                )
            
            Text("StarRating")
                .font(.largeTitle)
                .foregroundColor(.white)
                .offset(x: 0, y: -6)
        }
    }
    
    var customStarRatingStyle: StarRatingStyle {
        StarRatingStyle(spacing: 8, numberOfStars: 7, stepType: .full, borderWidth: 1, borderColor: .black, shadowRadius: 0, fillColor1: .pink, fillColor2: .blue, starVertices: 6, starWeight: 0.6)
    }
    
    var body: some View {
        VStack {
            bigStar
                        
            StarRating(rating: 3.7)
                .padding()
            
            StarRating(rating: 3.7, styling: customStarRatingStyle)
                .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .padding()
                .previewLayout(.sizeThatFits)
            
            ContentView()
                .environment(\.colorScheme, .dark)
                .background(Color(red: 0.188, green: 0.192, blue: 0.208, opacity: 1.000))
                .previewLayout(.sizeThatFits)
        }
    }
}
