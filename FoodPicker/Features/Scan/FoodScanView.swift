import SwiftUI
import PhotosUI

struct FoodScanView: View {
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var image: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var guess = FoodGuess()
    @State private var isAnalyzing = false
    @State private var analyzeFailed = false
    @State private var selected: Food?
    @State private var slot = MealSlot.current()
    @State private var search = ""

    private static let canUseCamera = UIImagePickerController.isSourceTypeAvailable(.camera)

    // ข้าวสวยไม่อยู่ในรายการสุ่ม แต่ถ่ายรูปมาบันทึกได้
    private var foods: [Food] { [.steamedRice] + store.allFoods }

    var body: some View {
        NavigationStack {
            List {
                photoSection
                if !search.isEmpty {
                    Section("ผลการค้นหา") {
                        ForEach(foods.filter { $0.name.localizedCaseInsensitiveContains(search) }) { row($0) }
                    }
                } else if image != nil {
                    guessSection
                }
            }
            .searchable(text: $search, prompt: "ไม่ตรง? ค้นหาเมนูเอง")
            .navigationTitle("ถ่ายรูปอาหาร")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("ยกเลิก") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let food = selected { confirmBar(food) }
            }
        }
        .tint(Color.ink)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { picked in
                photoItem = nil
                Task { await analyze(picked) }
            }
            .ignoresSafeArea()
        }
        .task(id: photoItem) {
            guard let photoItem,
                  let data = try? await photoItem.loadTransferable(type: Data.self),
                  let picked = UIImage(data: data) else { return }
            await analyze(picked)
        }
    }

    private var photoSection: some View {
        Section {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(.rect(cornerRadius: 16))
            } else {
                Text("ถ่ายหรือเลือกรูปอาหาร แล้วแอปจะช่วยหาว่าน่าจะเป็นเมนูไหน")
                    .foregroundStyle(Color.ink.opacity(0.7))
            }

            HStack(spacing: 10) {
                if Self.canUseCamera {
                    Button(image == nil ? "ถ่ายรูป" : "ถ่ายใหม่", systemImage: "camera") { showCamera = true }
                }
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label(image == nil ? "เลือกจากอัลบั้ม" : "เลือกรูปอื่น", systemImage: "photo")
                }
            }
            .buttonStyle(.glass)
        }
    }

    private var guessSection: some View {
        Section {
            if isAnalyzing {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("กำลังดูรูป...")
                }
            } else if guess.candidates.isEmpty {
                Text(analyzeFailed ? "ดูรูปนี้ไม่ออก ลองค้นหาเมนูเองแทนนะ" : "ยังเดาไม่ออกว่าเป็นเมนูไหน ลองค้นหาเมนูเองแทนนะ")
                    .foregroundStyle(Color.ink.opacity(0.7))
            } else {
                ForEach(guess.candidates) { row($0) }
            }
        } header: {
            Text("น่าจะเป็น")
        } footer: {
            if !isAnalyzing { Text(guessFooter) }
        }
    }

    private var guessFooter: String {
        let seen = guess.labels.prefix(4)
            .map { "\($0.name.replacingOccurrences(of: "_", with: " ")) \(Int(($0.confidence * 100).rounded()))%" }
            .joined(separator: " · ")
        let note = "เดาจากของที่เห็นในรูปแบบกว้าง ๆ ยังไม่รู้จักชื่อเมนูไทยโดยตรง — ตรวจสอบก่อนบันทึก"
        return seen.isEmpty ? note : "แอปเห็น: \(seen)\n\(note)"
    }

    private func row(_ food: Food) -> some View {
        Button {
            withAnimation(.snappy) { selected = food }
        } label: {
            HStack(spacing: 12) {
                Text(food.emoji).font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.name).foregroundStyle(Color.ink)
                    Text([food.tag, food.calories.map { "~\($0.formatted()) kcal" }].compactMap { $0 }.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(Color.ink.opacity(0.6))
                }
                Spacer()
                if !warnings(for: food).isEmpty {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                }
                if selected?.id == food.id {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.softAqua)
                }
            }
        }
    }

    private func confirmBar(_ food: Food) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(food.emoji).font(.title)
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.name).font(.headline)
                    Text(food.calories.map { "~\($0.formatted()) kcal" } ?? "ไม่ระบุแคลอรี่")
                        .font(.subheadline)
                        .foregroundStyle(Color.ink.opacity(0.7))
                }
            }
            ForEach(warnings(for: food), id: \.self) { line in
                Text(line)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
            }
            HStack {
                Picker("มื้อ", selection: $slot) {
                    ForEach(MealSlot.allCases) { Text("\($0.emoji) \($0.rawValue)").tag($0) }
                }
                .pickerStyle(.menu)
                Spacer()
                Button {
                    store.logMeal(food, slot: slot)
                    dismiss()
                } label: {
                    Label("บันทึก", systemImage: "fork.knife")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.ink)
                }
                .buttonStyle(.glassProminent)
                .tint(Color.softAqua)
            }
        }
        .foregroundStyle(Color.ink)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // เทียบกับข้อมูลของฉันเอง (ไม่ใช่ของกลุ่ม) เพราะเป็นมื้อที่ฉันกิน
    private func warnings(for food: Food) -> [String] {
        var lines: [String] = []
        let allergic = food.ingredients.intersection(store.filter.allergies)
        if !allergic.isEmpty { lines.append("⚠️ มี \(Ingredients.list(allergic)) ที่คุณแพ้ · ถามร้านให้แน่ใจ") }
        let avoided = food.ingredients.intersection(store.filter.avoid)
        if !avoided.isEmpty { lines.append("🚫 มี \(Ingredients.list(avoided)) ที่คุณไม่กิน") }
        return lines
    }

    private func analyze(_ picked: UIImage) async {
        withAnimation(.snappy) {
            image = picked
            selected = nil
            guess = FoodGuess()
            analyzeFailed = false
            isAnalyzing = true
        }
        let result = try? await FoodRecognizer.guess(picked, among: foods)
        guard image === picked else { return }  // ระหว่างรอ ผู้ใช้เปลี่ยนรูปไปแล้ว
        withAnimation(.snappy) {
            guess = result ?? FoodGuess()
            analyzeFailed = result == nil
            isAnalyzing = false
        }
    }
}
