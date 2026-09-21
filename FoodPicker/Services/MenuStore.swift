import Foundation
import Observation

// ที่เก็บข้อมูลกลางของแอป: เมนูที่เพิ่มเอง, ประวัติการสุ่ม, ตัวกรอง
// อ่านจาก UserDefaults ครั้งเดียวตอนสร้าง แล้วบันทึกกลับเฉพาะตอนค่าเปลี่ยน
@Observable
final class MenuStore {
    static let historyLimit = 30
    static let mealDaysKept = 60

    var customFoods: [Food] { didSet { save(customFoods, forKey: Keys.customFoods) } }
    var history: [HistoryEntry] { didSet { save(history, forKey: Keys.history) } }
    var filter: FoodFilter { didSet { save(filter, forKey: Keys.filter) } }
    var groups: [DinerGroup] { didSet { save(groups, forKey: Keys.groups) } }
    var activeGroupID: UUID? { didSet { save(activeGroupID, forKey: Keys.activeGroupID) } }
    var settings: SmartSettings { didSet { save(settings, forKey: Keys.settings) } }
    var meals: [MealEntry] { didSet { save(meals, forKey: Keys.meals) } }
    var health: HealthSettings { didSet { save(health, forKey: Keys.health) } }
    var profile: ProfileSettings { didSet { save(profile, forKey: Keys.profile) } }

    // โปรไฟล์เพื่อนที่เพิ่งเปิดลิงก์เข้ามา รอให้เลือกว่าจะใส่กลุ่มไหน (ไม่ต้องบันทึก)
    var pendingProfile: Diner?

    @ObservationIgnored private let defaults: UserDefaults

    private enum Keys {
        static let customFoods = "customFoods"
        static let history = "history"
        static let filter = "filter"
        static let groups = "groups"
        static let activeGroupID = "activeGroupID"
        static let settings = "smartSettings"
        static let meals = "meals"
        static let health = "health"
        static let profile = "profile"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        customFoods = Self.load([Food].self, forKey: Keys.customFoods, from: defaults) ?? []
        history = Self.load([HistoryEntry].self, forKey: Keys.history, from: defaults) ?? []
        filter = Self.load(FoodFilter.self, forKey: Keys.filter, from: defaults) ?? FoodFilter()
        groups = Self.load([DinerGroup].self, forKey: Keys.groups, from: defaults) ?? []
        activeGroupID = Self.load(UUID.self, forKey: Keys.activeGroupID, from: defaults)
        settings = Self.load(SmartSettings.self, forKey: Keys.settings, from: defaults) ?? SmartSettings()
        health = Self.load(HealthSettings.self, forKey: Keys.health, from: defaults) ?? HealthSettings()
        profile = Self.load(ProfileSettings.self, forKey: Keys.profile, from: defaults) ?? ProfileSettings()
        let cutoff = Calendar.current.date(byAdding: .day, value: -Self.mealDaysKept, to: .now) ?? .distantPast
        meals = (Self.load([MealEntry].self, forKey: Keys.meals, from: defaults) ?? []).filter { $0.date > cutoff }
    }

    var allFoods: [Food] { builtInFoods + customFoods }

    func isNameTaken(_ name: String) -> Bool {
        allFoods.contains { $0.name == name }
    }

    func addCustomFood(_ food: Food) {
        var food = food
        food.isCustom = true
        customFoods.append(food)
    }

    func deleteCustomFood(named name: String) {
        customFoods.removeAll { $0.name == name }
    }

    // MARK: - ตัวกรองรวม (ของฉัน + กลุ่ม + โหมดปลายเดือน)

    var hasRestrictions: Bool {
        filter.isActive || activeGroup != nil || isBudgetTight || health.fitRemainingCalories
    }

    var effectiveFilter: FoodFilter {
        var rules = filter
        if let activeGroup { rules = rules.merged(with: activeGroup.filter) }
        if isBudgetTight { rules = rules.merged(with: FoodFilter(maxPrice: .cheap)) }
        if health.fitRemainingCalories { rules = rules.merged(with: FoodFilter(maxCalories: max(remainingCalories, 0))) }
        return rules
    }

    func allows(_ food: Food, in mode: MealMode) -> Bool {
        effectiveFilter.allows(food, in: mode)
    }

    // ชื่อวัตถุดิบที่ผู้ใช้เคยพิมพ์เพิ่มเอง — เอาไว้แสดงเป็นชิปให้เลือกซ้ำได้
    var customIngredientNames: [String] {
        var names = customFoods.reduce(into: Set<String>()) { $0.formUnion($1.ingredients) }
        names.formUnion(filter.avoid)
        names.formUnion(filter.allergies)
        for member in groups.flatMap(\.members) {
            names.formUnion(member.avoid)
            names.formUnion(member.allergies)
        }
        return names.subtracting(Ingredients.knownNames).sorted()
    }

    // MARK: - กินด้วยกัน

    var activeGroup: DinerGroup? {
        groups.first { $0.id == activeGroupID }
    }

    func saveGroup(_ group: DinerGroup) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
        } else {
            groups.append(group)
        }
    }

    func deleteGroup(_ group: DinerGroup) {
        groups.removeAll { $0.id == group.id }
        if activeGroupID == group.id { activeGroupID = nil }
    }

    // MARK: - โปรไฟล์ของฉัน (ใช้ข้อมูลเดียวกับตัวกรองส่วนตัว จะได้ไม่ต้องกรอกซ้ำ)

    var myProfile: Diner {
        Diner(id: profile.id, name: profile.name, vegetarian: filter.vegetarian,
              noSpicy: filter.spicy == .mild, avoid: filter.avoid, allergies: filter.allergies)
    }

    func handleOpenURL(_ url: URL) {
        guard let diner = ProfileLink.diner(from: url) else { return }
        pendingProfile = diner
    }

    // เพื่อนคนเดิม (id เดียวกัน) ส่งมาใหม่ = อัปเดตข้อมูลเดิม ไม่เพิ่มซ้ำ
    func add(_ diner: Diner, toGroupID groupID: DinerGroup.ID) {
        guard let index = groups.firstIndex(where: { $0.id == groupID }) else { return }
        if let memberIndex = groups[index].members.firstIndex(where: { $0.id == diner.id }) {
            groups[index].members[memberIndex] = diner
        } else {
            groups[index].members.append(diner)
        }
    }

    // MARK: - แคลอรี่

    var todayMeals: [MealEntry] {
        meals.filter { Calendar.current.isDateInToday($0.date) }
    }

    var todayCalories: Int { todayMeals.reduce(0) { $0 + $1.calories } }
    var remainingCalories: Int { health.calorieGoal - todayCalories }

    func logMeal(_ food: Food, slot: MealSlot = .current()) {
        meals.append(MealEntry(food: food, slot: slot, date: .now))
    }

    func deleteMeal(_ entry: MealEntry) {
        meals.removeAll { $0.id == entry.id }
    }

    func moveMeal(_ entry: MealEntry, to slot: MealSlot) {
        guard let index = meals.firstIndex(where: { $0.id == entry.id }) else { return }
        meals[index].slot = slot
    }

    func dailyCalories(days: Int) -> [DayCalories] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (1...days).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let total = meals.filter { calendar.isDate($0.date, inSameDayAs: day) }.reduce(0) { $0 + $1.calories }
            return DayCalories(date: day, calories: total)
        }
    }

    // MARK: - โหมดปลายเดือน

    var budgetDaysLeft: Int? {
        guard settings.budgetModeEnabled else { return nil }
        return CalendarRules.daysUntilPayday(settings.payday)
    }

    var isBudgetTight: Bool {
        guard let days = budgetDaysLeft else { return false }
        return (1...settings.budgetDaysBefore).contains(days)
    }

    // MARK: - เทศกาลกินเจ

    var jayDay: Int? { CalendarRules.jayFestivalDay() }

    var shouldAskJay: Bool {
        settings.askDuringJay && jayDay != nil && !filter.vegetarian
            && settings.jayAskedYear != CalendarRules.gregorianYear()
    }

    func answerJay(turnOnVegetarian: Bool) {
        settings.jayAskedYear = CalendarRules.gregorianYear()
        if turnOnVegetarian {
            filter.vegetarian = true
            settings.jayTurnedOnVegetarian = true
        }
    }

    func endJayIfOver() {
        guard jayDay == nil, settings.jayTurnedOnVegetarian else { return }
        filter.vegetarian = false
        settings.jayTurnedOnVegetarian = false
    }

    // MARK: - ประวัติ

    func record(_ food: Food) {
        history.insert(HistoryEntry(food: food, date: .now), at: 0)
        if history.count > Self.historyLimit {
            history.removeLast(history.count - Self.historyLimit)
        }
    }

    private static func load<T: Decodable>(_ type: T.Type, forKey key: String, from defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }
}
