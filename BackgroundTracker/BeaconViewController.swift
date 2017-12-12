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
    fileprivate var discoveredPeripherals = [CBPeripheral]()
    
    fileprivate var beaconUUIDDict = [CBPeripheral: UUID]()
    
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
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
        }
        tableView.reloadData()
    }
    
    func didFind(peripheral: CBPeripheral, uuid: UUID) {
        print(uuid.uuidString)
        beaconUUIDDict[peripheral] = uuid
        
        if discoveredPeripherals.contains(peripheral)
        {
            tableView.reloadData()
        }
    }
    
    func didUpdate(peripheral: CBPeripheral, newUUID: UUID) {
        print(newUUID.uuidString)
        Beacon.shared.addBeacon(proximityUUID: newUUID, notify: Geofence.RegionTriggerType.All, identifier: "Trckr.Beacon.\(newUUID)")
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
        
        let currentPeripheral = Array(discoveredPeripherals)[indexPath.row]
        
        cell.textLabel?.text = currentPeripheral.name

        if let currentUUID = beaconUUIDDict[currentPeripheral] {
            
            let monitoredBeaconUUIDs = Beacon.shared.getMonitoredBeaconRegions().map { $0.proximityUUID }
            
            cell.detailTextLabel?.text = "\(currentUUID): " + (monitoredBeaconUUIDs.contains(currentUUID) ? "connected" : "not connected")
            
        }
        else {
            cell.detailTextLabel?.text = "status unknown"
            Beacon.shared.getUUID(peripheral: currentPeripheral)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let peripheral = Array(discoveredPeripherals)[indexPath.row]
        Beacon.shared.changeUUID(peripheral: peripheral, newUUID: UUID.init())
//        Beacon.shared.getUUID(peripheral: peripheral)
    }
    
}
