//
//  BeaconViewController.swift
//  BackgroundTracker
//
//  Created by Rajeev Bhatia on 11/27/17.
//  Copyright © 2017 100grams. All rights reserved.
//

import UIKit
import Trckr
import CoreBluetooth

class BeaconViewController: UIViewController {
    
    fileprivate let peripheralPrefix = "ebeoo"
    
    @IBOutlet weak var tableView: UITableView!
    fileprivate var discoveredPeripherals = Set<CBPeripheral>()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //reset datasource and clear table
        discoveredPeripherals.removeAll()
        tableView.reloadData()
        Beacon.shared.delegate = self
        
    }

}

extension BeaconViewController: BeaconDelegate {
    
    func didPowerOn() {
        Beacon.shared.searchForPeripheral(startingWith: peripheralPrefix)
    }
    
    func didDiscover(peripheral: CBPeripheral) {
        print("did discover \(peripheral)")
        discoveredPeripherals.insert(peripheral)
        tableView.reloadData()
    }
    
    func didFind(peripheral: CBPeripheral, uuid: UUID) {
        print(uuid.uuidString)
    }
    
    func didUpdate(peripheral: CBPeripheral, newUUID: UUID) {
        print(newUUID.uuidString)
        Beacon.shared.addBeacon(proximityUUID: newUUID, notify: Geofence.RegionTriggerType.All)
        performSegue(withIdentifier: "beaconLoggingSegue", sender: nil)
    }
    
    func didFailToUpdateUUID(peripheral: CBPeripheral) {
        print("failed")
    }
    
}

extension BeaconViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredPeripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "beaconCell", for: indexPath)
        
        cell.textLabel?.text = Array(discoveredPeripherals)[indexPath.row].name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let peripheral = Array(discoveredPeripherals)[indexPath.row]
        Beacon.shared.changeUUID(peripheral: peripheral, newUUID: UUID.init())
//        Beacon.shared.getUUID(peripheral: peripheral)
    }
    
}
