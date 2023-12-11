//
//  ContentView.swift
//  RFBLDC
//
//  Created by Chuanfeng Chou on 2023/8/26.
//

import SwiftUI
import CoreBluetooth
import UIKit


class BluetoothViewModel: NSObject, ObservableObject, CBPeripheralDelegate {
    private var centralManager: CBCentralManager?
    private var peripherals: [CBPeripheral] = []
    @Published var peripheralNames: [String] = []
    @Published var bluetoothState = ""
    var BTmodule: CBPeripheral?
    
    override init(){
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
}

extension BluetoothViewModel: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state{
        case . unknown:
            break
        case . resetting:
            bluetoothState = "Bluetooth Resetting"
            break
        case . unsupported:
            bluetoothState = "Bluetooth Unsupported"
            break
        case . unauthorized:
            bluetoothState = "Bluetooth Unauthorized"
            break
        case . poweredOff:
            bluetoothState = "Bluetooth Off"
            break
        case . poweredOn:
            self.centralManager? .scanForPeripherals(withServices: nil)
            bluetoothState = "Bluetooth On"
            break
        @unknown default:
            break;
        }
        
            //        bluetoothState = "\(central.state)"
    }

    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let deviceName = advertisementData[CBAdvertisementDataLocalNameKey] as? String, deviceName.contains("ATK")
        {
    //        self.BTmodule = peripheral
     //       self.peripherals.insert(peripheral, at: 1)
    //        self.peripheralNames.insert((peripheral.name ?? "unnamed device"), at: 1)
    //        centralManager?.connect(peripheral)
            //self.centralManager?.stopScan()
            //self.centralManager?.connect(peripheral, options: nil)
        }
            if !peripherals.contains(peripheral) {
            self.peripherals.insert(peripheral, at: 0)
            self.peripheralNames.insert((peripheral.name ?? "unnamed device"), at: 0)
            }
             /*   if self.peripherals.count == 30{
                    self.peripheralNames.removeAll();
                    self.peripherals.removeAll();
                }*/
        else{
           // if NSNumber
        }

    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
    {
       
        print("Connected")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        centralManager?.stopScan()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services{
            for service in services{
                print("Discovered service: \(service.uuid.uuidString)")
                peripheral.discoverCharacteristics(nil, for: service)
                
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics{
            for characteristic in characteristics {
                print("Discovered characteristic: \(characteristic.uuid.uuidString)")
                if characteristic.properties.contains(.read){
                    peripheral.readValue(for: characteristic)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value{
            print("Received data from BT device: \(data)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print(error?.localizedDescription ?? "no error")
    }
    
    
}

struct ContentView: View{
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
    
    var body: some View{
        VStack{
                NavigationView
                {
                    List(bluetoothViewModel.peripheralNames, id: \.self) {
                        peripheral in
                        Text(peripheral)
                        }
                    .navigationTitle("Devices list:")
                }
            Text("Status:\(bluetoothViewModel.bluetoothState)")
                .foregroundColor(.black)
            
            Image("942 Image").resizable()
                .frame(width: 150, height: 150)
            Text("942 Extream Go-Kart")
            PowerButton()
            HStack{
                Text("Battery: ")
                ZStack{
                        RoundedRectangle(cornerRadius: 1)
                        .foregroundColor(.green)
                        .frame(width: 40, height: 15, alignment: .trailing)
                        .padding(.trailing,30)
                    VStack{
                        BatteryView()
                    }

                }
                .frame(width: 70, height:15)
                .padding()
            }
            Text("Voltage:  V")
                .frame(width: 180, height: 10, alignment: .leading)
                
            
        }
    }
}

struct ContentView_Previews: PreviewProvider{
    static var previews: some View{
        ContentView()
    }
}

struct BatteryView : View{
    var body: some View{
            GeometryReader{ geo in
            RoundedRectangle(cornerRadius:5)
                    .stroke(lineWidth: 2)
        }
    }
}

struct PowerButton: View{
    @State private var isPoweredOn = false
    @State private var text:String = "Off"
    
    func changeText(_input: String)->String{
        var newString:String
        if(isPoweredOn)
        {
            newString = "On"
        }
        else{
            newString = "Off"
        }
        return newString
    }
    
    var body:some View{
        Toggle("Power:\(changeText(_input: text))", isOn: $isPoweredOn).padding().font(.system(size: 20,weight: .bold))
            .frame(width: 200, height: 10, alignment: .trailing)
    }
}


//struct


/*struct ContentView: View {
    var emoji = ["🚗","🚕","🚙","🏎","😃","😁","🤣","🚓","🚗","🚕","🚙","🏎","😃","😁","🤣","🏎"]
    @State var emojicount = 8
    var body: some View {
        VStack{
            ScrollView{
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 65))]){
                        ForEach(emoji[0..<emojicount], id: \.self, content:{ emoji in
                            CardView(content: emoji)})
                            .aspectRatio(2/3, contentMode: .fit)
                          }
                            .padding(.horizontal).foregroundColor(.yellow)
                        }
                    Spacer()
                    HStack{
                            add
                            Spacer()
                            remove
                          }
                    .font(.largeTitle)
                    .padding(.horizontal)
                    .padding(.horizontal).foregroundColor(.blue)
        }
    }
    var remove: some View {
        Button(action: {
            if emojicount>1{
                emojicount -= 1}
        }, label: {
                Image(systemName: "minus.circle")
            
        })
    }
    var add: some View{
        Button(action: {
            if emojicount < emoji.count{
                emojicount += 1}
        }, label:{
            Image(systemName: "plus.circle")
        })
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
.previewInterfaceOrientation(.portrait)
        ContentView()
            .preferredColorScheme(.light    )
    }
}

struct CardView: View{
    var content: String
    @State var isFaceup:Bool = true//default value needed in swift
    let shape = RoundedRectangle(cornerRadius: 20)
    var body: some View{
        ZStack{
            if isFaceup{
            shape.fill().foregroundColor(.white)
            shape.strokeBorder(lineWidth: 5)//keep the full card view(not cut off)
            Text(content).font(.largeTitle)
            }
            else{
                shape.fill()
            }
        }
        .onTapGesture {
            isFaceup = !isFaceup
        }
    }
}*/
