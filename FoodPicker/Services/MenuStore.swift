import Foundation
import Observation

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
        customFoods = Self.loadList(Food.self, forKey: Keys.customFoods, from: defaults)
        history = Self.loadList(HistoryEntry.self, forKey: Keys.history, from: defaults)
        filter = Self.load(FoodFilter.self, forKey: Keys.filter, from: defaults) ?? FoodFilter()
        groups = Self.loadList(DinerGroup.self, forKey: Keys.groups, from: defaults)
        activeGroupID = Self.load(UUID.self, forKey: Keys.activeGroupID, from: defaults)
        settings = Self.load(SmartSettings.self, forKey: Keys.settings, from: defaults) ?? SmartSettings()
        health = Self.load(HealthSettings.self, forKey: Keys.health, from: defaults) ?? HealthSettings()
        profile = Self.load(ProfileSettings.self, forKey: Keys.profile, from: defaults) ?? ProfileSettings()
        let cutoff = Calendar.current.date(byAdding: .day, value: -Self.mealDaysKept, to: .now) ?? .distantPast
        meals = Self.loadList(MealEntry.self, forKey: Keys.meals, from: defaults).filter { $0.date > cutoff }
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

    var myProfile: Diner {
        Diner(id: profile.id, name: profile.name, vegetarian: filter.vegetarian,
              noSpicy: filter.spicy == .mild, avoid: filter.avoid, allergies: filter.allergies)
    }

    func handleOpenURL(_ url: URL) {
        guard let diner = ProfileLink.diner(from: url) else { return }
        pendingProfile = diner
    }

    func add(_ diner: Diner, toGroupID groupID: DinerGroup.ID) {
        guard let index = groups.firstIndex(where: { $0.id == groupID }) else { return }
        if let memberIndex = groups[index].members.firstIndex(where: { $0.id == diner.id }) {
            groups[index].members[memberIndex] = diner
        } else {
            groups[index].members.append(diner)
        }
    }

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

    var budgetDaysLeft: Int? {
        guard settings.budgetModeEnabled else { return nil }
        return CalendarRules.daysUntilPayday(settings.payday)
    }

    var isBudgetTight: Bool {
        guard let days = budgetDaysLeft else { return false }
        return (1...settings.budgetDaysBefore).contains(days)
    }

    var jayDay: Int? { CalendarRules.jayFestivalDay() }

    var shouldAskJay: Bool {
        settings.askDuringJay && jayDay != nil && !filter.vegetarian && settings.jayAskedYear != CalendarRules.gregorianYear()
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

    func record(_ food: Food) {
        history.insert(HistoryEntry(food: food, date: .now), at: 0)
        if history.count > Self.historyLimit {
            history.removeLast(history.count - Self.historyLimit)
        }
    }

    // อ่านไม่ผ่าน = เก็บข้อมูลดิบไว้ที่ "<key>.backup" ก่อน ไม่งั้นค่าว่างจะถูกบันทึกทับจนกู้คืนไม่ได้
    private static func load<T: Decodable>(_ type: T.Type, forKey key: String, from defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            defaults.set(data, forKey: "\(key).backup")
            return nil
        }
    }

    // อ่านทีละรายการ — รายการไหนเสียก็ข้ามไป ที่เหลือยังอยู่ครบ
    private static func loadList<T: Decodable>(_ type: T.Type, forKey key: String, from defaults: UserDefaults) -> [T] {
        guard let items = load([Lossy<T>].self, forKey: key, from: defaults) else { return [] }
        let values = items.compactMap(\.value)
        if values.count < items.count, let data = defaults.data(forKey: key) {
            defaults.set(data, forKey: "\(key).backup")
        }
        return values
    }

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}

private struct Lossy<T: Decodable>: Decodable {
    let value: T?

    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}
