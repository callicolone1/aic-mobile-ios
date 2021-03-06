/*
 Abstract:
 Main View controller
*/

import UIKit

class RootViewController: UIViewController {
    enum Mode {
        case loading
        case loaded
        case instructions
        case mainApp
    }
    
    var mode:Mode = .loading {
        didSet {
            modeDidChange()
        }
    }
    
    var loadingVC:LoadingViewController? = nil
    var instructionsVC:InstructionsPageViewController? = nil
    var sectionsVC = SectionsViewController()
    
    var shouldShowInstructions:Bool = false
    
    override var prefersStatusBarHidden: Bool {
        return !Common.Layout.showStatusBar
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.frame = UIScreen.main.bounds
        
        registerSettingsBundle()
        
        // Check for first launch
        let defaults = UserDefaults.standard
        shouldShowInstructions = defaults.bool(forKey: Common.UserDefaults.showInstructionsUserDefaultsKey)
        
        // Set delegates
        AppDataManager.sharedInstance.delegate = self
        sectionsVC.delegate = self
        
        startLoading()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        view.frame.origin.y = 0
        view.frame.size.height = UIScreen.main.bounds.height
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Register the app defaults
    private func registerSettingsBundle(){
        let defaults = UserDefaults.standard
        let appDefaults = [Common.UserDefaults.showInstructionsUserDefaultsKey: true,
                           Common.UserDefaults.showHeadphonesUserDefaultsKey:true,
                           Common.UserDefaults.showEnableLocationUserDefaultsKey:true]
        
        defaults.register(defaults: appDefaults)
        defaults.synchronize()
        
        // Reset defaults if testing instructions
        if Common.Testing.alwaysShowInstructions {
            defaults.set(true, forKey: Common.UserDefaults.showInstructionsUserDefaultsKey)
            defaults.set(true, forKey: Common.UserDefaults.showHeadphonesUserDefaultsKey)
            defaults.set(true, forKey: Common.UserDefaults.showEnableLocationUserDefaultsKey)
            defaults.synchronize()
        }
    }
    
    private func startLoading() {
        cleanUpViews()
        showLoadingVC()
        
        AppDataManager.sharedInstance.load()
    }
    
    
    // If loading got stopped (backgrounding the app?)
    // finish it up
    func resumeLoadingIfNotComplete() {
        if mode != .mainApp {
            startLoading()
        }
    }
    
    // Show a tour, called from deep link handling in app delegate
    func startTour(tour:AICTourModel) {
        // If we haven't loaded yet we should save the tour here
        sectionsVC.startTour(tour: tour)
    }
    
    private func modeDidChange() {
        switch mode {
        case .loading:
            showLoadingVC()
        case .loaded:
            showLoadingVideo()
        case .instructions:
            showInstructionsVC()
        case .mainApp:
            showMainApp()
        }
    }
    
    private func showLoadingVC() {
        loadingVC = LoadingViewController()
        loadingVC?.delegate = self
        
        view.addSubview(loadingVC!.view)
    }
    
    private func showLoadingVideo() {
        loadingVC?.playIntroVideo()
    }
    
    private func showInstructionsVC() {
        instructionsVC = InstructionsPageViewController()
        instructionsVC?.instructionsDelegate = self
        self.view.addSubview(instructionsVC!.view)
    }
    
    // Remove the intro and show the main app
    private func showMainApp() {
        view.addSubview(sectionsVC.view)
        sectionsVC.setSelectedSection(sectionVC: sectionsVC.toursVC)
        sectionsVC.animateInInitialView()
    }
    
    fileprivate func cleanUpViews() {
        // Remove and clean up instructions + loading
        instructionsVC?.view.removeFromSuperview()
        instructionsVC = nil
        
        loadingVC?.view.removeFromSuperview()
        loadingVC = nil
    }
}

// App Data Delegate
extension RootViewController : AppDataManagerDelegate{
    // Animate progress bar, play video when finished animating to 100%
    func downloadProgress(withPctCompleted pct: Float) {
        UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.loadingVC?.updateProgress(forPercentComplete: pct)
            }, completion:  { (value:Bool) in
                if pct == 1.0 {
                    self.mode = .loaded
                }
            }
        )
    }
    
    func downloadFailure(withMessage message: String) {
        let message =  message + "\n\n\(Common.DataConstants.dataLoadFailureMessage)"
        
        let alert = UIAlertController(title: Common.DataConstants.dataLoadFailureTitle, message: message, preferredStyle:UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: Common.DataConstants.dataLoadFailureButtonTitle, style: UIAlertActionStyle.default, handler: { (action) in
            // Try to load the data again
            AppDataManager.sharedInstance.load()
        })
        
        alert.addAction(action)
        
        present(alert, animated:true)
    }
}


// Loading VC delegate
extension RootViewController : LoadingViewControllerDelegate {
    func loadingViewControllerDidFinishPlayingIntroVideo() {
        if shouldShowInstructions {
            self.mode = .instructions
        } else {
            self.mode = .mainApp
        }
    }
}

// Instructions Delegate
extension RootViewController : IntroPageViewControllerDelegate {
    func introPageGetStartedButtonTapped() {
        // Record that we've got through the intro
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: Common.UserDefaults.showInstructionsUserDefaultsKey)
        defaults.synchronize()
        
        // Start the app
        self.mode = .mainApp
    }
}

// Sections view controller Delegate
extension RootViewController : SectionsViewControllerDelegate {
    func sectionsViewControllerDidFinishAnimatingIn() {
        cleanUpViews()
    }
}

