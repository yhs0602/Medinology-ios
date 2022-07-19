//
//  ContentView.swift
//  Medinology
//
//  Created by 양현서 on 2022/07/19.
//

import SwiftUI

enum Gender {
    case Male
    case Female
    case Other
}

struct ContentView: View {
    @State var gender: Gender = .Other
    @State private var isPregnant = false
    @State private var age = "0"
    @State var isLinkActive = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Medinology - 기초 정보")
                RadioButtonGroup(items: ["Male", "Female", "Other"], selectedId: "Other") { selected in
                    print("Selected is: \(selected)")
                }

                Toggle("임신함", isOn: $isPregnant)

                TextField("나이", text: $age)
                    .padding()
                    .keyboardType(.decimalPad)
                let nage = Int(age) ?? 1
                NavigationLink(destination: SymptomView(isPregnant: isPregnant, age: nage, gender: gender)) {
                    Text("증상 고르러 가기")
                }
            }
        }
    }
}

struct SymptomView: View {
    var symptoms: [String]
    @State var symptomChecked: [Bool]
    let isPregnant: Bool
    let age: Int
    let gender: Gender
    init(isPregnant: Bool, age: Int, gender: Gender) {
        symptomChecked = [Bool]()
        symptoms = [String]()
        if let path = Bundle.main.path(forResource: "symptoms", ofType: "txt") {
            do {
                print("REad success")
                let text = try String(contentsOfFile: path, encoding: .utf8)
                let splitted = text.components(separatedBy: " ")
                self.symptoms = splitted
                print("Components: \(self.symptoms) from \(text) by \(splitted)")
                _symptomChecked = State(initialValue: [Bool](repeating: false, count: splitted.capacity))
            } catch let error {
                // Handle error here
                print(error.localizedDescription)
            }
        }
    }

    //화면을 그리드형식으로 꽉채워줌
    let columns = [GridItem(.adaptive(minimum: 100))]

    func getDrugID(diseaseId: Int) -> Int {
        // TODO
        return 0
    }
    var body: some View {
        ScrollView {
            Text("증상을 모두 체크해 주세요")
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(symptoms.indices, id: \.self) {
                    index in
                    Toggle(symptoms[index], isOn: $symptomChecked[index])
                }
            } .padding(.horizontal)
            NavigationLink(destination: ResultView()) {
                Text("결과 받기").onTapGesture {
                    let wrapper = NativeCodeWrapper()
                    wrapper.initData(isPregnant, Int32(age), 50, symptomChecked, Int32(symptomChecked.capacity), 31)
                    // copy weights to good location
                    wrapper.initWeights()
                    wrapper.calcData()
                    let disId1 = wrapper.getDisID(0)
                    let disId2 = wrapper.getDisID(1)
                    let disId3 = wrapper.getDisID(2)
                    
                    let prob1 = wrapper.getProb(0)
                    let prob2 = wrapper.getProb(1)
                    let prob3 = wrapper.getProb(2)
                    
                    let mediId1 = getDrugID(diseaseId: Int(disId1))
                    let mediId2 = getDrugID(diseaseId: Int(disId2))
                    let mediId3 = getDrugID(diseaseId: Int(disId3))
                    wrapper.finalizeNative()
                    
                }
            }
        }
    }
}

struct ResultView: View {
    init() {
    }
    var body: some View {
        Text("쾌유를 빕니다")

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ColorInvert: ViewModifier {

    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        Group {
            if colorScheme == .dark {
                content.colorInvert()
            } else {
                content
            }
        }
    }
}

struct RadioButton: View {

    @Environment(\.colorScheme) var colorScheme

    let id: String
    let callback: (String) -> ()
    let selectedID: String
    let size: CGFloat
    let color: Color
    let textSize: CGFloat

    init(
        _ id: String,
        callback: @escaping (String) -> (),
        selectedID: String,
        size: CGFloat = 20,
        color: Color = Color.primary,
        textSize: CGFloat = 14
    ) {
        self.id = id
        self.size = size
        self.color = color
        self.textSize = textSize
        self.selectedID = selectedID
        self.callback = callback
    }

    var body: some View {
        Button(action: {
            self.callback(self.id)
        }) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: self.selectedID == self.id ? "largecircle.fill.circle" : "circle")
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: self.size, height: self.size)
                    .modifier(ColorInvert())
                Text(id)
                    .font(Font.system(size: textSize))
                Spacer()
            }.foregroundColor(self.color)
        }
            .foregroundColor(self.color)
    }
}

struct RadioButtonGroup: View {

    let items: [String]

    @State var selectedId: String = ""

    let callback: (String) -> ()

    var body: some View {
        VStack {
            ForEach(0..<items.count) { index in
                RadioButton(self.items[index], callback: self.radioGroupCallback, selectedID: self.selectedId)
            }
        }
    }

    func radioGroupCallback(id: String) {
        selectedId = id
        callback(id)
    }
}
