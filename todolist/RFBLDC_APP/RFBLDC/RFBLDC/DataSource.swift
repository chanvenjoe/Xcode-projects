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




struct Linechart: View{
    @State private var LineChartData: [PullForceData] = []
    @State private var PWMChartData: [PullForceData] = []
    
    @State private var timer: Timer?
    
    var dataPoints: [PullForceData] = []//every time APP receive data from BT, update data
    var pwmPoints: [PullForceData] = []
    let maxValue = 100
    
    var body: some View{
        if #available(iOS 16.0, *) {
            GroupBox("E-Wagon Pull force data"){
                VStack{
                    Chart{
                        ForEach(LineChartData){
                            AreaMark(
                                x:.value("Time", $0.time),//using $0, it will auto detect the type of enclosed data and no in needed
                                yStart: .value("min", 500),
                                yEnd: .value("max", 1000)
                                //           y:.value("Force", $0.force)
                                
                            )
                            .opacity(0.3)
                            .foregroundStyle(.green)
                            LineMark(
                                x:.value("Time", $0.time),//using $0, it will auto detect the type of enclosed data and no in needed
                                y:.value("Force", $0.force)
                                
                            )
                            //.interpolationMethod(.catmullRom)
                            //                        .foregroundStyle(.green)
                            //                        .foregroundStyle(by: .value("name", $0.time))
                            //                        .symbol(by: .value("name", $0.time))
                            //                        .cornerRadius(5)
                            
                        }
                        .interpolationMethod(.catmullRom)
                    }
                    .frame(width: 300, height:200)
                    .chartXScale(domain: 0...1000)
                    .chartLegend(.visible)
                    .chartXAxisLabel("Time:50ms", position: .bottom)
                    .chartYAxisLabel("Force:Gram", position: .top)
                    .chartYAxis{
                        AxisMarks(preset: .extended, position:.leading)
                    }
                    
                    ZStack{
                        Chart{
                            ForEach(PWMChartData) {
                                LineMark(
                                    x:.value("Time", $0.time),//using $0, it will auto detect the type of enclosed data and no in needed
                                    y:.value("Force", $0.force)
                                )
                                .interpolationMethod(.catmullRom)
                               // .foregroundStyle(.green)
 //                               .foregroundStyle(by: .value("name", $0.time))
//                                .symbol(by: .value("name", $0.time))
                                .cornerRadius(5)
                            }
                            .interpolationMethod(.catmullRom)
                        }
                        .frame(width: 300, height:100)
                        .chartXScale(domain: 0...1000)
                        .chartYScale(domain: 0...100)
                        .chartLegend(.visible)
                        .chartXAxisLabel("Time:50ms", position: .bottom)
                        .chartYAxisLabel("PWM", position: .top)
                        .chartYAxis{
                            AxisMarks(preset: .extended, position:.leading)
                        }
                        Text("PWM:\(PWMValue)")
                            .frame(width: 300, height: 100, alignment:.topTrailing)
                    
                    }
                }
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
                PWMChartData.removeAll()
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
        counter.timercnt+=1//unexpectedly found nil

        LineChartData.append(PullForceData(time: counter.timercnt, force: Int(GramValue) ))
        
        PWMChartData.append(PullForceData(time: counter.timercnt, force: Int(PWMValue) ))

        if counter.timercnt >= 1000
        {
            LineChartData.removeAll()
            PWMChartData.removeAll()
            counter.timercnt = 0
        }
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
    }
}




struct DataSource_Previews: PreviewProvider{
    static var previews: some View{
        Linechart()
    }
}
