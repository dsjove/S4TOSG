import SwiftUI
import SbjGauge

/*
 Please open the App Preview panel and select "Compositional Design".
 
 The slider control is used to set the values across several examples of an analog gauge. The radio buttons will select the different gauges.
 
 SwiftUI demands that the application UI be built using declarative statements. For many of us, this requires a different way of thinking when creating a public API. 
 
 Traditional UI frameworks have imperative APIs.
 
 var myButton = new UIButton()
 myButton.text = "Hello"
 myButton.color = Color.red
 ...
 
 Or declared with an init of a hundred parameters. Often new features are added as setters to avoid breaking existing code.
 
 var myButton = new UIButton(
     text: "Hello",
     color: Color.red, ...)
 myButton.sound = "Honk"
 
 This works but has several issues: 
 - Adherence to the RAII Priciple (single statement atomic construction) becomes difficult.
 - Adherence to the Open-Close Principle, i.e., new capbilities are added without breaking existing interfaces.
 - Arduous work is needed to bubble out every possible variable and strategy to the public interface.
 
 The declarative nature of SwiftUI flips this API design inside-out. We will have several examples of an analog gauge view to demonstrate a compositional API, as opposed to an Über class to rule them all.
 
 This is a mindset that I have had to change to write effective SwiftUI code.
 
 Let say we are making an analog gauge view for a client...
 */

// We put a line needle on a circle background.
// This works.
struct SimpleGaugeView: View {
    let value: Double
    
    var body: some View {
        ZStack() {
            Circle().fill(Color.blue)
            Path { path in
                let radius = 100
                let center = CGPoint(x: radius, y: radius)
                let lineEnd = CGPoint(x: center.x, y: center.y - 75)
                path.move(to: center) 
                path.addLine(to: lineEnd)
            }
            .stroke(Color.red, lineWidth: 4.0)
            .rotationEffect(.degrees(360.0 * value))
        }
        .frame(width: 200, height: 200)
    }
}

/*
 But what if we need to have the constants become client configurable?
 It is not too bad at first.
 
 You can see this 'Über' gauge in the preview.
 */
struct ÜberGaugeView: View {
    let value: Double
    let backgroundSize: Double
    let backgroundColor: Color
    let needleWidth: Double
    let needleLength: Double
    let needleColor: Color
    
    init(
        value: Double,
        backgroundSize: Double = 200,
        backgroundColor: Color = Color.blue,
        needleWidth: Double = 4.0,
        needleLength: Double = 75,
        needleColor: Color = Color.red
    ) {
        self.value = value
        self.backgroundSize = backgroundSize
        self.backgroundColor = backgroundColor
        self.needleWidth = needleWidth
        self.needleLength = needleLength
        self.needleColor = needleColor
    }
    
    var body: some View {
        ZStack {
            Circle().fill(backgroundColor)
            Path { path in
                let radius = backgroundSize/2
                let center = CGPoint(x: radius, y: radius)
                let lineEnd = CGPoint(x: center.x, y: center.y - needleLength)
                path.move(to: center) 
                path.addLine(to: lineEnd)
            }
            .stroke(needleColor, lineWidth: needleWidth)
            .rotationEffect(.degrees(360.0 * value))
        }
        .frame(width: backgroundSize, height: backgroundSize)
    }
}

/*
 But now the client wants a better needle. We can add more init parameters to customize the needle. And then they asked for tick marks and text labels as part of the background. 
 
 ÜberGaugeView will end up having an API with exponential growth and complication over time. We cannot future proof it, as designed.
 
 As I was designing the SbjGauge library, I kept trying to create the ÜberGaugeView equivalent; thinking that was the best thing for an API.

 ÜberGaugeView needs to be deleted.
 
 Let the client build their custom gauge view from the inside out, using well designed parts. There will be less and more functional code both inside your library and in the client's application.
*/

/*
 The SbjGauge built-in StandardView, as demonstrated in the preview, only needs 1 declarative to instantiate. This is not an Über class. It cannot be customized. The only value it exposes is the model to calculate the needle angle and tick values.
 
  StandardView was my ÜberView. Everytime I thought of a new customization, I had to change its public interface. That got too much.
 */
struct StandardGaugeView : View {
    let model: SbjGauge.StandardModel
    var body: some View {
        SbjGauge.Standard.StandardView(model)
    }
}

/*
 Instead of attempting to create a future-proof ÜberGaugeView, we provide the 'LEGO pieces' along with a couple building instructions.
 
 Imagine trying to parameterize the differences between StandardView and InsideOutGaugeView, with constructor paramters and setters. It is better just to let them build.
 */
struct InsideOutGaugeView: View {
    let model: StandardModel
    var body: some View {
        // It is recommended to create a GaugeGeometryView to help layering.
        GaugeGeometryView() { geom in
            // Then the client can build out the gauge however they need with the components they need.
            
            // Use the standard backround. Or not.
            Standard.BackgroundView(geom: geom, color: Emotion.colorForMood(model[norm: 0]))
        
            // Add indicators using a built-in layout
            Standard.RadialIndicatorsView(geom: geom, model: model) { model, width in
                Text("Inside Out")
                Standard.defaultIndicator(
                    label: Emotion.face(model[0]), 
                    width: width)
            }
            
            // We can still layer in any SwiftUIView
            Circle().stroke()
            
            // RadialNeedlesView can rotate any 'LEGO Piece'...
            Standard.RadialNeedlesView(geom: geom, model: model, clockwise: false) { _ in
                // ...including the Tick View.
                Standard.RadialTickView(geom, model, model.ticks[0]) { notch in
                    // Draw our unicode smiley faces
                    Standard.TickTextView(
                        geom: geom,
                        text: Emotion.face(notch.value ),
                        length: 0.25)
                }
            }
            
            // The client wanted a different style stationary needle.
            Clock.SecondsHandView(geom: geom, radius: 0.70,  color: Color.black)
        }
    }
}

// Below is support code...

/*
  Microsoft Copilot wrote the Emotion enum and its methods with very brief prompts. It did lean more on the anger side. Hmmm.
*/
enum Emotion: String, CaseIterable {
    case ecstatic = "😄"
    case joy = "☺️"
    case happy = "😊"
    case content = "🙂"
    case neutral = "😐"
    case uncertain = "😕"
    case annoyed = "🙁"
    case frustrated = "😠"
    case angry = "😡"
    case furious = "🤬"
    case enraged = "🔥"
    
    static func face(_ value: Double) -> String {
        allCases[Int(value)].rawValue
    }
    
    static func colorForMood(_ value: Double) -> Color {
        let startColor = Color.yellow
        let endColor = Color.red
        
        return Color(
            red: startColor.components.red + value * (endColor.components.red - startColor.components.red),
            green: startColor.components.green + value * (endColor.components.green - startColor.components.green),
            blue: startColor.components.blue + value * (endColor.components.blue - startColor.components.blue)
        )
    }
}

/*
 The following is the example's ContentView
 */
struct CompositionalExampleView: View {
    @State private var model: StandardModel
    @State private var selectedOption: Int?
    
    init() {
        _model = State(initialValue: .init(standard: 0.0))
        _selectedOption = State(initialValue: .init(0))
    }
    
    var body: some View {
        VStack {
            Text("Slider changes gauge value.") 
            /* 
             As I was was building out this example I chose to use my own 'slider' control. Then I remembered, it is still suffering from the same design issues mentioned in this presentation.
             - Too many init parameters, yet incomplete
             - Parameter interactions not obvious
             - Unintuitive optionals to turn off parts
             - Next feature is going to require significant interface change
             */
            ScrubView(
                value: model.values[0], 
                range: model.range
                //increment: Double?, 
                //autoCentering:Double?, 
                //minMaxSplit: Double?, 
                //gradient: Bool, 
                //thumbColor: Color, 
                //minTrackColor: Color, 
                //maxTrackColor: Color
            ) { value in
                self.model.values[0] = value
            }
            .frame(height: 42)
            
            Text("Select the gauge to present.") 
            HStack(spacing: 20) {
                RadioButton(label: "Über", option: 0, selectedOption: $selectedOption)
                RadioButton(label: "Standard", option: 1, selectedOption: $selectedOption)
                RadioButton(label: "Inside-Out", option: 2, selectedOption: $selectedOption)
            }
            if selectedOption == 0 {
                ÜberGaugeView(value: model[norm: 0])
            }
            else if selectedOption == 1 {
                Standard.StandardView(model)
            }
            else if selectedOption == 2 {
                InsideOutGaugeView(model: model)
            }
            Spacer()
        }
    }
}
