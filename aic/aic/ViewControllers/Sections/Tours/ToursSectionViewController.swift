/*
 Abstract:
 Section View controller for Tours Section
*/

import UIKit
import CoreLocation
import Alamofire

protocol ToursSectionViewControllerDelegate {
    func toursSectionDidShowTour(tour: AICTourModel)
    
    func toursSectionDidFocusOnTourOverview(tour:AICTourModel)
    func toursSectionDidFocusOnTourStop(tour:AICTourModel, stopIndex:Int)
    
    func toursSectionDidSelectTourOverview(tour:AICTourModel)
    func toursSectionDidSelectTourStop(tour:AICTourModel, stopIndex:Int)
    
    func toursSectionDidLeaveTour(tour:AICTourModel)
}

class ToursSectionViewController : NewsToursSectionViewController {
    var delegate:ToursSectionViewControllerDelegate?
    
    fileprivate var items:[AICTourModel] = [] {
        didSet {
            listTableView.reloadData()
            self.view.setNeedsUpdateConstraints()
        }
    }
    
    private let tourScrollView = ToursSectionStopsScrollerView()
    
    fileprivate (set) var currentTour:AICTourModel? = nil
    
    init(section:AICSectionModel) {
        let toursView = ToursSectionView(section: section, revealView: tourScrollView)
        super.init(section:section, sectionView: toursView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.items = AppDataManager.sharedInstance.app.tours
        tourScrollView.delegate = self.delegate
    }
    
    override func getModel(forRow row: Int) -> AICNewsTourItemProtocol? {
        return items[row]
    }
    
    override func setAdditionalInformation(forCell cell: NewsToursTableViewCell) {
        if let model = cell.model as? AICTourModel {
            cell.setStops(toValue: model.stops.count)
            listTableView.beginUpdates()
            listTableView.endUpdates()
        }
    }
    
    override func setDistances(fromUserLocation userLocation: CLLocation) {
        if listTableView != nil {
            listTableView.beginUpdates()
            
            for cell in listTableView.visibleCells  {
                if let cell = cell as? NewsToursTableViewCell {
                    if let model = cell.model as? AICTourModel {
                        let closestObject = Common.Location.getClosestObject(toUserLocation: userLocation, forObjects: model.getObjectsForStops())
                        let distance = Common.Location.getTime(fromUserLocation: userLocation, toObjectLocation: closestObject.location)
                        cell.setDistance(toValue: Int(distance))
                    }
                }
            }
            
            listTableView.endUpdates()
        }
        
    }
    
    override func showReveal(forModel model: AICNewsTourItemProtocol) {
        if let tour = model as? AICTourModel {
            tourScrollView.setTour(forTourModel: tour)
            super.showReveal(forModel: model)
            
            if let tour = model as? AICTourModel {
                currentTour = tour
            }
            
            delegate?.toursSectionDidShowTour(tour: tour)
        }
    }
    
    func showTourStop(forStopObjectModel stopObject:AICObjectModel) {
        tourScrollView.setFocusedStop(forObjectModel: stopObject)
    }
    
    func showTour(forTourModel tour:AICTourModel) {
        showReveal(forModel: tour)
    }
    
    func removeCurrentTour() {
        currentTour = nil
    }
    
    
    // Ignore initial reset
    override func reset() {
        if currentTour == nil {
            super.reset()
        }
    }
    
    func forceReset() {
        super.reset()
    }
}

// MARK: UITableViewDelegate
extension ToursSectionViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func newsToursTableViewCellWasTapped(_ cell: NewsToursTableViewCell) {
        super.newsToursTableViewCellWasTapped(cell)
        if cell.mode == .open {
            AICAnalytics.sendTourExpandedEvent(forTour: cell.model as! AICTourModel)
        }
    }
    
    override func revealViewCloseButtonTapped() {
        if let currentTour = currentTour {
            delegate?.toursSectionDidLeaveTour(tour: currentTour)
        }
         
        currentTour = nil
        super.revealViewCloseButtonTapped()
    }
}
