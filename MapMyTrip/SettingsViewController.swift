//
//  SettingsViewController.swift
//  MapMyTrip
//
//  Created by Alex on 13/04/2020.
//  Copyright © 2020 Alex Sykes. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    // MARK: Properties
    var defaults : UserDefaults!
    var mainViewController: ViewController?
    
    // MARK: Outlets
    @IBOutlet weak var modeSelect: UISegmentedControl!
    @IBOutlet weak var destroyOptionLabel: NSLayoutConstraint!
    @IBOutlet weak var destroySwitch: UISwitch!
    @IBOutlet weak var allowBackgroundLocationLabel: UILabel!
    @IBOutlet weak var backgroundLocationSwitch: UISwitch!
    @IBOutlet weak var fileFormatSetting: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defaults = UserDefaults.standard
        modeSelect.selectedSegmentIndex = defaults.integer(forKey: "travelMode")
        destroySwitch.isOn = defaults.bool(forKey: "destroyOnSave")
        backgroundLocationSwitch.isOn = defaults.bool(forKey: "bgLocation")
        fileFormatSetting.selectedSegmentIndex = defaults.integer(forKey: "fileFormat")

        // Do any additional setup after loading the view.
    }
    
    // MARK: Actions
    @IBAction func backgroundLocationSwitch(_ sender: UISwitch) {
        let allowBgLocation = backgroundLocationSwitch.isOn
        defaults.set(allowBgLocation, forKey: "bgLocation")
    }
    
    @IBAction func destroySwitch(_ sender: UISwitch, forEvent event: UIEvent) {
        let isOn = destroySwitch.isOn
        defaults.set(isOn, forKey: "destroyOnSave")
    }
    
    // Save mode on change
    @IBAction func modeChanged(_ sender: UISegmentedControl, forEvent event: UIEvent) {
        let mode: Int  = modeSelect.selectedSegmentIndex
        defaults.set(mode, forKey: "travelMode")
        mainViewController?.onReturnFromSettings(mode: mode)
    }
    
    @IBAction func fileFormatChanged(_ sender: UISegmentedControl, forEvent event: UIEvent) {
        let fileFormat = fileFormatSetting.selectedSegmentIndex
        defaults.set(fileFormat, forKey: ("fileFormat"))
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
//    @IBAction func save(_ sender: UIBarButtonItem) {
//        //
//        let mode: Int  = modeSelect.selectedSegmentIndex
//        defaults.set(mode, forKey: "travelMode")
//    }
    
}
