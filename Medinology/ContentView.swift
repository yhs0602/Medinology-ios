//
//  ContentView.swift
//  Medinology
//
//  Created by 양현서 on 2022/07/19.
//

import SwiftUI
import CSVImporter
import AVFoundation

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

    @State var isPresented = false

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
    }

    //화면을 그리드형식으로 꽉채워줌
    let columns = [GridItem(.adaptive(minimum: 100))]

    var body: some View {
        ScrollView {
            Text("증상을 모두 체크해 주세요")
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(symptoms.indices, id: \.self) {
                    index in
                    Toggle(symptoms[index], isOn: $symptomChecked[index])
                }
            } .padding(.horizontal)
            NavigationLink(destination: ResultView(isPregnant: isPregnant, age: age, symptomChecked: symptomChecked), isActive: $isPresented) {
                Text("결과 받기")
            }
                .simultaneousGesture(TapGesture().onEnded({

            }))
                .navigationBarTitle(Text("결과"), displayMode: .inline)
        }
    }
}

struct ResultView: View {
    let isPregnant: Bool
    let age: Int
    let symptomChecked: [Bool]

    var disease2drugs = [Int: [Int]]()
    var diseaseNames = [String]()
    var drugNames = [String]()

    func getDrugID(diseaseId: Int) -> [Int] {
        return disease2drugs[diseaseId]!
    }

    var prob1 = 0
    var prob2 = 0
    var prob3 = 0

    var drugNames1 = [String]()
    var drugNames2 = [String]()
    var drugNames3 = [String]()

    var diseaseName1 = ""
    var diseaseName2 = ""
    var diseaseName3 = ""

    var drugDetails = [DrugDetail]()

    var comment1: String? = nil
    var comment2: String? = nil
    var comment3: String? = nil

    let synthsizer = AVSpeechSynthesizer()
    func buildComments(drugIds: [Int]) -> String? {
        let comments: [String] = drugIds.map { id in
            return buildComment(drugId: id)
        }.compactMap { $0 }
        if comments.capacity == 0 {
            return nil
        }
        return comments.joined(separator: ", ")
    }

    func buildComment(drugId: Int) -> String? {
        var result = "\(drugNames[drugId])(은/는)"
        let drugDetail = drugDetails[drugId]
        guard drugDetail.should_consult else {
            return nil
        }

        if drugDetail.need_prescription {
            result += " 처방이 필요합니다."
        }
        if drugDetail.danger_pregnant {
            result += " 임산부에게 위험합니다."
        }
        if drugDetail.danger_children {
            result += " 어린이에게 위험합니다."
        }
        if drugDetail.danger_elderly {
            result += " 어르신께 위험합니다."
        }
        result += " 의사나 약사와 상담하는 것이 안전합니다."
        return result
    }

    init(isPregnant: Bool, age: Int, symptomChecked: [Bool]) {
        self.isPregnant = isPregnant
        self.age = age
        self.symptomChecked = symptomChecked

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
        if let drugdetailpath = Bundle.main.path(forResource: "drugdetail", ofType: "csv") {
            do {
                print("Read drug detail table")
                let importer = CSVImporter<[String]>(path: drugdetailpath)
                let importedRecords = importer.importRecords { $0 }

                for drug in importedRecords {
                    drugDetails.append(DrugDetail(
                        need_prescription: drug[0] == "1", danger_pregnant: drug[1] == "1", danger_children: drug[2] == "2", danger_elderly: drug[3] == "1"
                    ))
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

        let wrapper = NativeCodeWrapper()
        wrapper.initData(isPregnant, Int32(age), 50, symptomChecked, 31)
        // copy weights to good location
        wrapper.initWeights()
        wrapper.calcData()
        let disId1 = Int(wrapper.getDisID(0))
        let disId2 = Int(wrapper.getDisID(1))
        let disId3 = Int(wrapper.getDisID(2))

        self.prob1 = Int(wrapper.getProb(0))
        self.prob2 = Int(wrapper.getProb(1))
        self.prob3 = Int(wrapper.getProb(2))

        wrapper.finalizeNative()
        let mediIds1 = getDrugID(diseaseId: disId1)
        let mediIds2 = getDrugID(diseaseId: disId2)
        let mediIds3 = getDrugID(diseaseId: disId3)

        self.drugNames1 = mediIds1.map { id in
            self.drugNames[try: id]!
        }
        self.drugNames2 = mediIds2.map { id in
            self.drugNames[try: id]!
        }
        self.drugNames3 = mediIds3.map { id in
            self.drugNames[try: id]!
        }
        self.diseaseName1 = diseaseNames[disId1]
        self.diseaseName2 = diseaseNames[disId2]
        self.diseaseName3 = diseaseNames[disId3]
        print(disId1, disId2, disId3, prob1, prob2, prob3, mediIds1, mediIds2, mediIds3)
        print(diseaseName1, diseaseName2, diseaseName3, drugNames1, drugNames2, drugNames3)
        self.comment1 = buildComments(drugIds: mediIds1)
        self.comment2 = buildComments(drugIds: mediIds2)
        self.comment3 = buildComments(drugIds: mediIds3)
    }
    var body: some View {
        VStack {
            Text("이용자님의 진단 질병과 처방 약은 다음과 같습니다.")
            Text("\(prob1)% 확률로 \(diseaseName1)이며 치료제는 \(drugNames1.joined(separator: ", ")) 입니다.")
            if let comment11 = comment1 {
                Text(comment11)
                    .background(.red)
            }
            Text("\(prob2)% 확률로 \(diseaseName2)이며 치료제는 \(drugNames2.joined(separator: ", ")) 입니다.")
            if let comment22 = comment2 {
                Text(comment22)
                    .background(.red)
            }
            Text("\(prob3)% 확률로 \(diseaseName3)이며 치료제는 \(drugNames3.joined(separator: ", ")) 입니다.")
            if let comment33 = comment3 {
                Text(comment33)
                    .background(.red)
            }
            Text("쾌유를 빕니다")
                .background(.green)
            Text("면책 : 이 결과를 맹신하는 것은 위험할 수 있으므로 반드시 병원에서 의사와 상담하시기 바랍니다.")
                .background(.red)
        }
            .background(.cyan)
            .onAppear {
            var text = "이용자님의 진단 질병과 처방 약은 다음과 같습니다." + "\(prob1)% 확률로 \(diseaseName1)이며 치료제는 \(drugNames1.joined(separator: ", ")) 입니다."
            if let comment11 = comment1 {
                text += comment11
            }
            text += "\(prob2)% 확률로 \(diseaseName2)이며 치료제는 \(drugNames2.joined(separator: ", ")) 입니다."
            if let comment22 = comment2 {
                text += comment22
            }
            text += "\(prob3)% 확률로 \(diseaseName3)이며 치료제는 \(drugNames3.joined(separator: ", ")) 입니다."
            if let comment33 = comment3 {
                text += comment33
            }
            text += "쾌유를 빕니다"
            text += "면책 : 이 결과를 맹신하는 것은 위험할 수 있으므로 반드시 병원에서 의사와 상담하시기 바랍니다."
            let soundText = AVSpeechUtterance(string: text)
            soundText.voice = AVSpeechSynthesisVoice(language: "ko-KR")

            synthsizer.speak(soundText)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
