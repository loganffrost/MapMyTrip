//
//  TracksTableViewController.swift
//  MapMyTrip
//
//  Created by Alex on 13/04/2020.
//  Copyright © 2020 Alex Sykes. All rights reserved.
//

import UIKit

class TracksTableViewController: UITableViewController {
    var files = [URL]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getFileList()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    // MARK: Functions
    //
    func getFileList() {
        let docDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let skipsHiddenFiles: Bool = true
        let URLs = try! FileManager.default.contentsOfDirectory(at: docDir, includingPropertiesForKeys: nil, options: skipsHiddenFiles ? .skipsHiddenFiles : [] )
        var csvURLs = URLs.filter{ $0.pathExtension == "csv" }
        csvURLs.sort(by: { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() } )
              
     //   let URLs = try! FileManager.default.contentsOfDirectory(at: docDir, includingPropertiesForKeys: nil)
        for file in csvURLs {
            files.append(file)
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return files.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TracksTableViewCell", for: indexPath) as! TracksTableViewCell
        
        let file = files[indexPath.row]
        var filename = file.lastPathComponent
        filename = String(filename[..<filename.firstIndex(of: ".")!])
        
        do {
            let fileManager = FileManager.default
            let attributes = try fileManager.attributesOfItem(atPath: file.path)
        //    let fileDate = attributes[FileAttributeKey(rawValue: "NSFileCreationDate")]!
            let date: Date = attributes[FileAttributeKey(rawValue: "NSFileCreationDate")] as! Date
            
            
            let dateFormatter = DateFormatter()
          //  formatter.dateFormat = "yyyy"
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            dateFormatter.doesRelativeDateFormatting = true
            let timStr = dateFormatter.string(from: date)
            
       //     cell.dateLabel.text = "\(fileDate)"
            cell.dateLabel.text = timStr
        } catch {
            // 6
            print( "No information available for")
        }
        
        cell.filenameLabel.text = filename
        
        return cell
    }
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let TrackDetailViewController = segue.destination as? TrackDetailViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }
        
        guard let selectedTrackCell = sender as? TracksTableViewCell else {
            fatalError("Unexpected sender: \(String(describing: sender))")
        }
        
        guard let indexPath = tableView.indexPath(for: selectedTrackCell) else {
            fatalError("The selected cell is not being displayed by the table")
        }
        
        let selectedFile = files[indexPath.row]
        TrackDetailViewController.file = selectedFile
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     
    
}
