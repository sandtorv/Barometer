//
//  ViewController.swift
//  Barometer
//
//  Created by Sebastian Sandtorv on 17/11/14.
//  Copyright (c) 2014 Sebastian Sandtorv. All rights reserved.
//

import UIKit
import CoreMotion
import CoreLocation
import iAd

class ViewController: UIViewController, CLLocationManagerDelegate, ADBannerViewDelegate {
    
    let locationManager = CLLocationManager()
    var barometer: CMAltimeter!
    var userDefault = NSUserDefaults.standardUserDefaults()
    
    let fullRotation = CGFloat(M_PI * 2)
    
    var heightHolder: String = ""
    // Setup outlets
    @IBOutlet var iconView: UIImageView!
    @IBOutlet var pressureLabel: UILabel!
    @IBOutlet var heightLabel: UILabel!
    
    // iAd
    var bannerView: ADBannerView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the image view to UIView
        self.view.addSubview(iconView)
        
        // Set iAd
        self.canDisplayBannerAds  = true
        self.bannerView?.delegate = self
        self.bannerView?.hidden   = true
        
        // Setup location service
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        } else {
            println("Location services are not enabled");
        }
        
        // Set BG Color and text color
        var BGColor: UIColor = UIColor(red: CGFloat(0.2509803921), green: CGFloat(0.2509803921), blue: CGFloat(0.2509803921), alpha: CGFloat(1))
        UIView.animateWithDuration(1.5){
            self.view.backgroundColor = BGColor
            self.pressureLabel.textColor = UIColor.whiteColor()
        }
        
        
        // Get last value and add text, and the last icon
        if(self.userDefault.objectForKey("oldResult") != nil){
            var oldResult: Int = self.userDefault.objectForKey("oldResult") as! Int
            self.pressureLabel.text = String(oldResult) + " kPa"
        }
        if(self.userDefault.objectForKey("oldIcon") != nil){
            var oldIcon: String = self.userDefault.objectForKey("oldIcon") as! String
            self.animateIcon(oldIcon)
        }
        
        // Start barometer
        barometer = CMAltimeter()
        if CMAltimeter.isRelativeAltitudeAvailable() {
            barometer.startRelativeAltitudeUpdatesToQueue(NSOperationQueue.currentQueue()) {
                (data, error) in
//                println("startRelativeAltitudeUpdatesToQueue!")
                if error != nil {
                    println("There was an error obtaining barometer data: \(error)")
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue()) {
                        println("Height is: \(self.heightHolder)")
                        // Formula: kPa + height/100 or kPa + 10 kPa/1000m
                        let result = (data.pressure as Float * 10.00) + (((self.heightHolder as NSString).floatValue) / 100)
                        // Set .1f, .2f, etc for decimals.
                        self.pressureLabel.text = NSString(format:"%.0f kPa", result) as? String
                        
                        // Change icon view based on pressure
                        if(result >= 1045){
//                            println("Very dry weather")
                            self.animateIcon("dry.png")
                        }
                        if(result >= 1020 && result < 1045){
//                            println("Fair weather")
                            self.animateIcon("fair.png")
                        }
                        if(result >= 980 && result < 1020){
//                            println("Change in weather")
                            self.animateIcon("change.png")
                        }
                        if(result >= 950 && result < 980){
//                            println("Rainy weather")
                            self.animateIcon("rainy.png")
                        }
                        if(result < 950){
//                            println("Stormy weather")
                            self.animateIcon("stormy.png")
                        }

                        // Save last value for next opening of app
                        var myValue: Int = Int(result)
                        self.userDefault.setObject(myValue, forKey:"oldResult")
                        self.userDefault.synchronize()
                        
                    }
                }
            }
        }
    }
    
    func animateIcon(input: String){
//        println("animateIcon input is: \(input)")
        if(iconView.image != UIImage(named: input)){
            UIView.animateWithDuration(1.5){
                self.iconView.alpha = 0
                self.iconView.image = UIImage(named: input)
                self.iconView.alpha = 1
            }
            self.userDefault.setObject(input, forKey:"oldIcon")
            self.userDefault.synchronize()
        }
        else{
//            println("Icon is already equal to input")
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // iAd functions
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        self.bannerView?.hidden = false
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
    return willLeave
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        self.bannerView?.hidden = true
    }
    
    // CoreLocation Delegate Methods
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        locationManager.stopUpdatingLocation()
        if ((error) != nil) {
            print(error)
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
        var alt = newLocation.altitude
        var acc = newLocation.verticalAccuracy
        self.heightLabel.text =  NSString(format:"Altitude: %.0f m ± %.0f", alt, acc) as? String
        heightHolder = NSString(format:"%.0f", alt) as! String
    }
}

