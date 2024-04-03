//
//  DataSource.swift
//  RFBLDC
//
//  Created by Chuanfeng Chou on 2024/3/17.
//

import Foundation
import SwiftUI
import Charts

struct PullForceData: Identifiable{
    var time:Int
    var force:Int
    var id = UUID()//why i need to add this to be identifiable?
}


struct counter{
    static var timercnt:Int = 0
}

var LinechartPageFlag:Bool = false

/*var LineChartData : [PullForceData] = [
    .init(time: 0, force: 0),
    .init(time: 1, force: 0),
    .init(time: 3, force: 0)
]*/




struct Linechart: View{
    @State private var LineChartData: [PullForceData] = []
    @State private var timer: Timer?
    
    var dataPoints: [PullForceData] = []//every time APP receive data from BT, update data
    let maxValue = 100
    
    var body: some View{
        if #available(iOS 16.0, *) {
            GroupBox("E-Wagon Pull force data"){
                Chart{
                    ForEach(LineChartData){
                        AreaMark(
                            x:.value("Time", $0.time),//using $0, it will auto detect the type of enclosed data and no in needed
                            yStart: .value("min", 200),
                            yEnd: .value("max", 2000)
                 //           y:.value("Force", $0.force)
                            
                        )
                        .opacity(0.3)
                        .foregroundStyle(.blue)
                        LineMark(
                            x:.value("Time", $0.time),//using $0, it will auto detect the type of enclosed data and no in needed
                            y:.value("Force", $0.force)
                            
                        )
                        .foregroundStyle(.gray)
                        
                    }
                    .interpolationMethod(.catmullRom)
                }
                .frame(width: 300, height:300)
                .chartXScale(domain: 0...1000)
                .chartLegend(.visible)
                .chartXAxisLabel("Time:50ms", position: .bottomTrailing)
                .chartYAxisLabel("Force:Gram")
               // .frame
            }
            .foregroundColor(.black)
            .fontWeight(.heavy)
            .fontWidth(.standard)
            .font(.headline)
            .onAppear(){//auto update
               StartRealTimeUpdates()
                LinechartPageFlag = true
            }
            .onDisappear()
            {
                counter.timercnt = 0
                LineChartData.removeAll()
                StopRealTimeUpdates()
            }
        }
        else {
            // Fallback on earlier versions
        }
    }
    
    
    func StartRealTimeUpdates(){
        
         timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            timerAction()
        }
    }
    func timerAction(){
 //       let newDataPoint = Int.random(in: 0...1000)
        counter.timercnt+=1//unexpectedly found nil
 //       LineChartData.append(PullForceData(time: counter.timercnt, force: newDataPoint))
        LineChartData.append(PullForceData(time: counter.timercnt, force: Int(GramValue) ?? 0))

        if counter.timercnt >= 1000
        {
            LineChartData.removeAll()
            counter.timercnt = 0
        }
 //       print("timer fired")
 //       print(LineChartData)
    }
    
    func StopRealTimeUpdates(){
        timer?.invalidate()
    }
    
    func LinechartUpdate(_ newDataPoint: PullForceData){

        
        counter.timercnt+=1//unexpectedly found nil
        
//        LineChartData.append(newDataPoint)
        
        if counter.timercnt >= 100
        {
            LineChartData.removeAll()
            counter.timercnt = 0
        }
                             
   //     print("New point:\(newDataPoint)")
     //  print(LineChartData)//still empty， try print in timer
    }
}




struct DataSource_Previews: PreviewProvider{
    static var previews: some View{
        Linechart()
    }
}
