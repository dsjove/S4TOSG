import SwiftUI

/*
 This contrived example shows the difference between runtime polymorphism and compile-time polymorphism;
 preferring compile-time decisions over runtime decisions.
 
 Polymorphism: the use of one symbol to represent multiple different types.
 
 Runtime Polymorphism: the selection of type behavior is made while the code is executing; e.g., inheritence with virtual methods.
 
 Compile-time Polymorphism: the selection of type behavior is made as the code is compiled; e.g., type generics.
 
 Contrived example requirement:
 There shall be no hissing in production. See below...
 */

/*
 We begin by declaring an interface for a Cat. Interfaces are, by definition,
 polymorphic.
 
 The example code solves the same problem using both types of polymorphism.
 We will examine Runtime from top to bottom, and then Compile-time to compare.
 */
protocol Cat {
// Runtime
    // Declare an abstract virtual method on the interface that all
    // adhering classes must implement.
    func purr(forAny other: Any) -> String
    
// Compile-time
    // Instead of runtime virtual method we declare a compile-time generic type variable.
    associatedtype Owner
}

/*
 Declare a concrete type for a valid cat owner.
 */
class Human {
}

/*
 Extensions provide a mechanism to add methods to existing types without subclassing or wrapping.
 */
extension Cat {
// Runtime
    // Provide a default implementation for our interface.
    func purr(forAny other: Any) -> String {
        // The type parameter is type-erased at compile-time, therefore
        // we have to access values of 'other' to see if we can purr. 
        // Since this is a runtime decision that can fail, we have to add
        // code for the failure case of 'hiss'.
        // Bugs, such as the copy-paste error below, can slip through as well.
        other is Human ? "purr" : "hisspu"
    }
    
// Compile-time
    // Tell the compiler that we have a purr method only for our owner and owner must be human. A compiler error is generated if we try to have the cat purr for a different owner type. 
    // No hissing in code, let alone production!
    func purr<O>(for other: O) -> String where O == Self.Owner, O: Human {
        "purr"
    }
}

/*
 Declare a concrete Cat type called SpoiledIndoorCat
 */
class SpoiledIndoorCat: Cat {
// Runtime
    // This cat inherits the default implementation from the extension.
    
// Compile-time
    // SpoiledIndoorCat has a compile-time specified owner of Human
    typealias Owner = Human
}

class FeralCat: Cat {
// Runtime
    // Override the default implementation. 
    // The purr decision is now spead across multiple classes where some
    // actually have to produce the error condition of hissing.
    func purr(forAny other: Any) -> String {
        return "hiss";    
    }
    
// Compile-time
    // The () is an empty structure; no owner; no method to override and test.
    typealias Owner = ()
}

// Runtime
struct ContentViewRuntime: View {
    let cat1 = SpoiledIndoorCat()
    let cat2 = FeralCat()
    let owner1 = Human()
    let owner2: () = ()
    var body: some View {
        VStack {
            Text("We have hissing in production because there are code paths to allow it.\nWe have to test for all these cases and handle the error condition.").multilineTextAlignment(.center).italic()
            Rectangle().frame(height: 3).opacity(0)
            
            let case1 = cat1.purr(forAny: owner1)
            Text("Spoiled \(case1) with Human").foregroundColor(case1 != "purr" ? Color.red : Color.black)
            
            let case2 = cat1.purr(forAny: owner2)
            Text("Spoiled \(case2) with no owner").foregroundColor(case2 != "purr" ? Color.red : Color.black)
            
            let case3 = cat2.purr(forAny: owner1)
            Text("Feral \(case3)  with Human").foregroundColor(case3 != "purr" ? Color.red : Color.black)
            
            let case4 = cat2.purr(forAny: owner2)
            Text("Feral \(case4) with no owner").foregroundColor(case4 != "purr" ? Color.red : Color.black)
        }
    }
    // Start from top with Compile-Time...
}

// Compile-time
struct ContentViewCompileTime: View {
    let cat1 = SpoiledIndoorCat()
    let cat2 = FeralCat()
    let owner1 = Human()
    let owner2: () = ()
    var body: some View {
        VStack {
            Text("There is no hissing in production because not-purring is a compiler error.").multilineTextAlignment(.center).italic()
            Rectangle().frame(height: 3).opacity(0)
            
            let singularCase = cat1.purr(for: owner1)
            Text("Spoiled \(singularCase) with Human")

            // These 3 cases of 'hiss' will now produce compiler errors.
            //Text("Spoiled \(cat1.purr(for: owner2)) with no owner")
            //Text("Feral \(cat2.purr(for: owner1))  with Human")
            //Text("Feral \(cat2.purr(for: owner2)) with no owner")
            
            /*
             An additional benefit to compile-time decisions is optimization.
             The optimizer and SwiftUI reactive object-graph can determine that
             the resulting string is a compile-time constant of "purr" and can
             reduce the SwiftUI to non-reactive, immutable, compile-time-computed `Text("Spoiled purr with Human")`.
             */
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            ContentViewRuntime()
            Divider()
            ContentViewCompileTime()
        }
    }
}
