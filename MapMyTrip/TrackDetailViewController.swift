//
//  TrackDetailViewController.swift
//  MapMyTrip
//
//  Created by Alex on 16/04/2020.
//  Copyright © 2020 Alex Sykes. All rights reserved.
//

import UIKit

class TrackDetailViewController: UIViewController {
    // MARK: Properties
    var file: URL?

    override func viewDidLoad() {
        super.viewDidLoad()

       let  filename = file?.lastPathComponent
        print("\(filename!)")
    }



    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
