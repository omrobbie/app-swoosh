//
//  CurrentRunVC.swift
//  Threads
//
//  Created by omrobbie on 30/01/20.
//  Copyright © 2020 omrobbie. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift

class CurrentRunVC: LocationVC {

    @IBOutlet weak var swipeBgImageView: UIImageView!
    @IBOutlet weak var sliderImageView: UIImageView!
    @IBOutlet weak var durationLbl: UILabel!
    @IBOutlet weak var paceLbl: UILabel!
    @IBOutlet weak var distanceLbl: UILabel!
    @IBOutlet weak var pauseBtn: UIButton!

    fileprivate var startLocation: CLLocation!
    fileprivate var lastLocation: CLLocation!
    fileprivate var runDistance = 0.0
    fileprivate var counter = 0
    fileprivate var pace = 0
    fileprivate var timer = Timer()
    fileprivate var dataLocations = List<Location>()

    override func viewDidLoad() {
        super.viewDidLoad()

        let swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(endRunSwipe(sender:)))
        sliderImageView.addGestureRecognizer(swipeGesture)
        sliderImageView.isUserInteractionEnabled = true
        swipeGesture.delegate = self as? UIGestureRecognizerDelegate
    }

    override func viewWillAppear(_ animated: Bool) {
        manager?.delegate = self
        manager?.distanceFilter = 10
        startRun()
    }

    func startRun() {
        manager?.startUpdatingLocation()
        startTimer()

        pauseBtn.setImage(#imageLiteral(resourceName: "pauseButton"), for: .normal)
    }

    func endRun() {
        manager?.stopUpdatingLocation()
        Run.addRunToRealm(pace: pace, distance: runDistance, duration: counter, locations: dataLocations)
    }

    func pauseRun() {
        startLocation = nil
        lastLocation = nil

        timer.invalidate()
        manager?.stopUpdatingLocation()
        pauseBtn.setImage(#imageLiteral(resourceName: "resumeButton"), for: .normal)
    }

    func startTimer() {
        durationLbl.text = counter.formatTimeDurationToString()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }

    func calculatePace(time seconds: Int, miles: Double) -> String {
        pace = Int(Double(seconds) / miles)
        return pace.formatTimeDurationToString()
    }

    @objc func endRunSwipe(sender: UIPanGestureRecognizer) {
        let minAdjust: CGFloat = 80
        let maxAdjust: CGFloat = 130

        if let sliderView = sender.view {
            if sender.state == UIGestureRecognizer.State.began || sender.state == UIGestureRecognizer.State.changed {
                let translation = sender.translation(in: self.view)
                if sliderView.center.x >= (swipeBgImageView.center.x - minAdjust) && sliderView.center.x <= (swipeBgImageView.center.x + maxAdjust) {
                    sliderView.center.x = sliderView.center.x + translation.x
                } else if sliderView.center.x >= (swipeBgImageView.center.x + maxAdjust) {
                    sliderView.center.x = swipeBgImageView.center.x + maxAdjust
                    endRun()
                    dismiss(animated: true, completion: nil)
                } else {
                    sliderView.center.x = swipeBgImageView.center.x - minAdjust
                }

                sender.setTranslation(CGPoint.zero, in: self.view)
            } else if sender.state == UIGestureRecognizer.State.ended {
                UIView.animate(withDuration: 0.1) {
                    sliderView.center.x = self.swipeBgImageView.center.x - minAdjust
                }
            }
        }
    }

    @objc func updateCounter() {
        counter += 1
        durationLbl.text = counter.formatTimeDurationToString()
    }

    @IBAction func pauseBtnPressed(_ sender: Any) {
        if timer.isValid {
            pauseRun()
        } else {
            startRun()
        }
    }
}

extension CurrentRunVC: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            checkLocationAuthStatus()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if startLocation == nil {
            startLocation = locations.first
        } else if let location = locations.last {
            let newLocation = Location(latitude: Double(lastLocation.coordinate.latitude), longitude: Double(lastLocation.coordinate.longitude))
            dataLocations.insert(newLocation, at: 0)

            runDistance += lastLocation.distance(from: location)
            distanceLbl.text = "\(runDistance.metersToMiles(places: 2))"

            if counter > 0 && runDistance > 0 {
                paceLbl.text = calculatePace(time: counter, miles: runDistance.metersToMiles(places: 2))
            }
        }

        lastLocation = locations.last
    }
}
