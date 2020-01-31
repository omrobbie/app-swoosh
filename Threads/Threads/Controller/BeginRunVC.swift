//
//  FirstViewController.swift
//  Threads
//
//  Created by omrobbie on 30/01/20.
//  Copyright © 2020 omrobbie. All rights reserved.
//

import UIKit
import MapKit

class BeginRunVC: LocationVC {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var lastRunBgView: UIView!
    @IBOutlet weak var lastRunStackView: UIStackView!
    @IBOutlet weak var lastRunBtn: UIButton!
    @IBOutlet weak var paceLbl: UILabel!
    @IBOutlet weak var distanceLbl: UILabel!
    @IBOutlet weak var durationLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkLocationAuthStatus()
    }

    override func viewWillAppear(_ animated: Bool) {
        mapView.delegate = self
        manager?.delegate = self
        manager?.startUpdatingLocation()
    }

    override func viewDidAppear(_ animated: Bool) {
        setupMapView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        manager?.stopUpdatingLocation()
    }

    func setupMapView() {
        if let overlay = addLastRunToMap() {
            if mapView.overlays.count > 0 {
                mapView.removeOverlays(mapView.overlays)
            }
            mapView.addOverlay(overlay)

            lastRunBgView.isHidden = false
            lastRunStackView.isHidden = false
            lastRunBtn.isHidden = false
        } else {
            lastRunBgView.isHidden = true
            lastRunStackView.isHidden = true
            lastRunBtn.isHidden = true
        }
    }

    func addLastRunToMap() -> MKPolyline? {
        guard let lastRun = Run.getAllRuns()?.first else {return nil}

        paceLbl.text = lastRun.pace.formatTimeDurationToString()
        distanceLbl.text = "\(lastRun.distance.metersToMiles(places: 2)) mi"
        durationLbl.text = lastRun.duration.formatTimeDurationToString()

        var coordinate = [CLLocationCoordinate2D]()

        for location in lastRun.locations {
            coordinate.append(CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
        }

        return MKPolyline(coordinates: coordinate, count: lastRun.locations.count)
    }

    func centerMapOnUserLocation() {
        let coordinateRegion = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)

        mapView.userTrackingMode = .follow
        mapView.setRegion(coordinateRegion, animated: true)
    }

    @IBAction func locationCenterBtnPressed(_ sender: Any) {
        centerMapOnUserLocation()
    }

    @IBAction func lastRunBtnPressed(_ sender: Any) {
        lastRunBgView.isHidden = true
        lastRunStackView.isHidden = true
        lastRunBtn.isHidden = true
    }
}

extension BeginRunVC: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            checkLocationAuthStatus()
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polyline = overlay as! MKPolyline
        let renderer = MKPolylineRenderer(polyline: polyline)

        renderer.strokeColor = #colorLiteral(red: 0.1764705926, green: 0.01176470611, blue: 0.5607843399, alpha: 1)
        renderer.lineWidth = 4
        return renderer
    }
}
