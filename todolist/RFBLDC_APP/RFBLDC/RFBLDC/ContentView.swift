//
//  ContentView.swift
//  RFBLDC
//
//  Created by Chuanfeng Chou on 2023/8/26.
//

import SwiftUI


struct ContentView: View {
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
}
