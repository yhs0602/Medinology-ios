//
//  ContentView.swift
//  Medinology
//
//  Created by 양현서 on 2022/07/19.
//

import SwiftUI
import CSVImporter

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
    var disease2drugs = [Int: [Int]]()
    var diseaseNames =  [String]()
    var drugNames = [String]()
    init(isPregnant: Bool, age: Int, gender: Gender) {
        symptomChecked = [Bool]()
        symptoms = [String]()
        self.isPregnant = isPregnant
        self.age = age
        self.gender = gender

        if let path = Bundle.main.path(forResource: "symptoms", ofType: "txt") {
            do {
                print("Read success")
                let text = try String(contentsOfFile: path, encoding: .utf8)
                let splitted = text.components(separatedBy: " ")
                self.symptoms = splitted.map { name in
                    name.trimmingLeadingAndTrailingSpaces()
                }
                print("Components: \(self.symptoms) from \(text) by \(splitted)")
                _symptomChecked = State(initialValue: [Bool](repeating: false, count: splitted.capacity))
            } catch let error {
                // Handle error here
                print(error.localizedDescription)
            }
        }
        if let path2 = Bundle.main.path(forResource: "disdru", ofType: "csv") {
            do {
                print("Read disease-drug table")
                let importer = CSVImporter<[String]>(path: path2)
                let importedRecords = importer.importRecords { $0 }

                for (index, disease) in importedRecords.enumerated() {
                    disease2drugs[index] = []
                    for (drug_index, drug) in disease.enumerated() {
                        if drug == "1" {
                            disease2drugs[index]?.append(drug_index)
                        }
                    }
                }
            }
        }
        if let diseaseNamesPath = Bundle.main.path(forResource: "diseases", ofType: "txt") {
            do {
                print("Read disease name table")
                let text = try String(contentsOfFile: diseaseNamesPath, encoding: .utf8)
                let splitted = text.components(separatedBy: " ")
                self.diseaseNames = splitted.map { name in
                    name.trimmingLeadingAndTrailingSpaces()
                }
            } catch let error {
                // Handle error here
                print(error.localizedDescription)
            }
        }
        if let drugNamesPath = Bundle.main.path(forResource: "drugs", ofType: "txt") {
            do {
                print("Read drug name table")
                let text = try String(contentsOfFile: drugNamesPath, encoding: .utf8)
                let splitted = text.components(separatedBy: " ")
                self.drugNames = splitted.map { name in
                    name.trimmingLeadingAndTrailingSpaces()
                }
            } catch let error {
                // Handle error here
                print(error.localizedDescription)
            }
        }
    }

    //화면을 그리드형식으로 꽉채워줌
    let columns = [GridItem(.adaptive(minimum: 100))]

    func getDrugID(diseaseId: Int) -> [Int] {
        return disease2drugs[diseaseId]!
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
                    wrapper.initData(isPregnant, Int32(age), 50, symptomChecked, 31)
                    // copy weights to good location
                    wrapper.initWeights()
                    wrapper.calcData()
                    let disId1 = Int(wrapper.getDisID(0))
                    let disId2 = Int(wrapper.getDisID(1))
                    let disId3 = Int(wrapper.getDisID(2))

                    let prob1 = wrapper.getProb(0)
                    let prob2 = wrapper.getProb(1)
                    let prob3 = wrapper.getProb(2)
                    
                    wrapper.finalizeNative()
                    let mediIds1 = getDrugID(diseaseId: disId1)
                    let mediIds2 = getDrugID(diseaseId: disId2)
                    let mediIds3 = getDrugID(diseaseId: disId3)
                    
                    let drugNames1 = mediIds1.map { id in
                        self.drugNames[try: id]!
                    }
                    let drugNames2 = mediIds2.map { id in
                        self.drugNames[try: id]!
                    }
                    let drugNames3 = mediIds3.map { id in
                        self.drugNames[try: id]!
                    }
                    let diseaseName1 = diseaseNames[disId1]
                    let diseaseName2 = diseaseNames[disId2]
                    let diseaseName3 = diseaseNames[disId3]
                    print(disId1, disId2, disId3, prob1, prob2, prob3, mediIds1, mediIds2, mediIds3)
                    print(diseaseName1, diseaseName2, diseaseName3, drugNames1, drugNames2, drugNames3)
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
