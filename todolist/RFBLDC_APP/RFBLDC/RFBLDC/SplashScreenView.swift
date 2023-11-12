//
//  SplashScreenView.swift
//  RFBLDC
//
//  Created by Chuanfeng Chou on 2023/11/5.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        if isActive{
            ContentView()
        }else {
            ZStack{
                Color("Launch screen BG color")
                    .edgesIgnoringSafeArea(.all)
                    VStack{
                        VStack{
                            Image("Launch screen image")
                               // .resizable()
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                            Text("Well come to Radioflyer!")
                                .font(Font.custom("Baskervile-Bold", size: 80))
                                .foregroundColor(.white.opacity((0.80)))
                              //  .font(.largeTitle)
                              }
                        .scaleEffect(size)
                        .opacity(opacity)
                        .onAppear{
                            withAnimation(.easeIn(duration:0.6)){
                                self.size = 0.2
                                self.opacity = 1.0
                            }
                        }
                    }
                    .onAppear{
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0)
                        {
                            self.isActive = true
                        }
                             }
            }
        }
    }
        }


struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
