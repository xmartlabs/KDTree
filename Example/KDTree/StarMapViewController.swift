//
//  StarsViewController.swift
//  KDTree
//
//  Created by Konrad Feiler on 21/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import KDTree

class StarMapViewController: UIViewController {
    
    var stars: KDTree<Star>?
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var starMapView: StarMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "StarMap"

        let startLoading = Date()
        DispatchQueue.global(qos: .background).async { [weak self] in
            StarHelper.loadCSVData(onlyVisible: true) { stars in
                DispatchQueue.main.async {
                    xcLog.debug("Completed loading stars: \(Date().timeIntervalSince(startLoading))s")
                    self?.stars = stars
                    
                    xcLog.debug("Finished loading \(stars?.count ?? -1) stars, after \(Date().timeIntervalSince(startLoading))s")
                    self?.loadingIndicator.stopAnimating()
                    
                    self?.reloadStars()
                }
            }
        }
        
        let pinchGR = UIPinchGestureRecognizer(target: self,
                                               action: #selector(StarMapViewController.handlePinch(gestureRecognizer:)))
        let panGR = UIPanGestureRecognizer(target: self,
                                           action: #selector(StarMapViewController.handlePan(gestureRecognizer:)))
        starMapView.addGestureRecognizer(pinchGR)
        starMapView.addGestureRecognizer(panGR)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    @IBAction
    func userTappedMap(recognizer: UITapGestureRecognizer) {
        if let stars = stars {
            let point = recognizer.location(in: self.starMapView)
            StarHelper.selectNearestStar(to: point, starMapView: self.starMapView, stars: stars)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        stars?.forEach({ (star: Star) in
            star.starData?.ref.release()
        })
    }

    func handlePinch(gestureRecognizer: UIPinchGestureRecognizer) {
        xcLog.debug("scale: \(gestureRecognizer.scale), state: \(gestureRecognizer.state)")
        
        switch gestureRecognizer.state {
        case .began:
            startRadius = starMapView.radius
        case .failed, .ended:
            break
        default:
            if let startRadius = startRadius {
                starMapView.radius = startRadius / gestureRecognizer.scale
                reloadStars()
            }
        }
    }
    private var startRadius: CGFloat?
    private var startCenter: CGPoint?

    private var isLoadingMapStars = false
    
    private func reloadStars() {
        guard let starTree = stars else { return }
        guard !isLoadingMapStars else { return }
        isLoadingMapStars = true
        StarHelper.loadForwardStars(starTree: starTree, currentCenter: starMapView.centerPoint.flippedY,
                                    radii: starMapView.currentRadii()) { (starsVisible) in
                                        DispatchQueue.main.async {
                                            self.starMapView.stars = starsVisible
                                            self.isLoadingMapStars = false
                                        }
        }
    }
    
    func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        xcLog.debug("scale: \(gestureRecognizer.translation(in: self.starMapView))")
     
        switch gestureRecognizer.state {
        case .began:
            startCenter = starMapView.centerPoint
        case .failed, .ended:
            break
        default:
            if let startCenter = startCenter {
                let adjVec = starMapView.radius / (0.5 * starMapView.bounds.width) * CGPoint(x: ascensionRange, y: declinationRange)
                starMapView.centerPoint = startCenter - adjVec * gestureRecognizer.translation(in: starMapView)
                reloadStars()
            }
        }
    }
}
