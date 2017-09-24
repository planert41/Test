//
//  Conversions.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/24/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation

class Conversions {
    
    // Convert from F to C (Integer)
    func fahrenheitToCelsius(tempInF:Int) ->Int {
        let celsius = (tempInF - 32) * (5/9)
        return celsius as Int
    }
    
    // Convert from F to C (Double)
    func fahrenheitToCelsius(tempInF:Double) ->Double {
        let celsius = (tempInF - 32.0) * (5.0/9.0)
        return celsius as Double
    }
    
    // Convert from C to F (Integer)
    func celsiusToFahrenheit(tempInC:Int) ->Int {
        let fahrenheit = (tempInC * 9/5) + 32
        return fahrenheit as Int
    }
    
    // Convert from C to F (Integer)
    func celsiusToFahrenheit(tempInC:Double) ->Double {
        let fahrenheit = (tempInC * 9.0/5.0) + 32.0
        return fahrenheit as Double
    }
    
    // Convert from miles to kilometers (Integer)
//    func milesToKilometers(speedInMPH:Doub) ->Int {
//        let speedInKPH = speedInMPH * 1.60934
//        return speedInKPH as Int
//    }
    
    // Convert from miles to kilometers (Double)
    func milesToKilometers(speedInMPH:Double) ->Double {
        let speedInKPH = speedInMPH * 1.60934
        return speedInKPH as Double
    }
    
    // Convert from kilometers to miles (Integer)
//    func kilometersToMiles(speedInKPH:Int) ->Int {
//        let speedInMPH = speedInKPH / 1.60934
//        return speedInMPH as Int
//    }
    
    // Convert from kilometers to miles (Double)
    func kilometersToMiles(speedInMPH:Double) ->Double {
        let speedInKPH = speedInMPH / 1.60934
        return speedInKPH as Double
    }
    
    // Convert from inches to cm
    func inchesToCentimeters(depthInInches:Double) ->Double {
        let depthInCentimeters = depthInInches * 2.54
        return depthInCentimeters as Double
    }
    
    // Convert from cm to inches
    func centimetersToInches(depthInCentimeters:Double) ->Double {
        let depthInInches = depthInCentimeters / 2.54
        return depthInInches as Double
    }
    
}
