import Foundation

// ป้ายที่ Vision เห็นในรูป เช่น "curry" 0.62
struct SeenLabel: Identifiable, Equatable {
    let name: String
    let confidence: Float
    var id: String { name }
}

// Vision รู้จักแค่ของกว้าง ๆ (curry, rice, ramen …) ไม่รู้จักชื่อเมนูไทย
// เลยแปลงป้ายเป็น "คำใบ้" แล้วให้คะแนนเมนูในแอป: ชื่อมีคำใบ้ 3 · หมวดตรง 1 · มีวัตถุดิบตรง 1 (คูณความมั่นใจของป้าย)
enum FoodMatcher {
    // ป้ายต้องมั่นใจอย่างน้อยเท่านี้ ถึงจะใช้เดาเมนูได้
    static let minConfidence: Float = 0.3

    private struct Hint {
        var keywords: [String] = []
        var categories: [String] = []
        var ingredients: Set<String> = []
        // ป้ายกว้างเกิน (ข้าว ซุป) ใช้จัดลำดับได้ แต่ลำพังตัวเองไม่พอจะเดาว่าเป็นเมนูไหน
        var broad = false
    }

    private static let hints: [String: Hint] = {
        var table: [String: Hint] = [:]
        func add(_ labels: [String], _ hint: Hint) {
            for label in labels { table[label] = hint }
        }
        let sweet = ["ของหวาน"]
        let drink = ["เครื่องดื่ม"]

        add(["curry"], Hint(keywords: ["แกง", "กะหรี่", "พะแนง", "ข้าวซอย", "ฮังเล"], categories: ["ต้ม/แกง"]))
        add(["rice"], Hint(keywords: ["ข้าว"], categories: ["จานเดียว"], broad: true))
        add(["soup"], Hint(keywords: ["ต้ม", "แกง", "ซุป", "ก๋วยเตี๋ยว", "เกาเหลา", "โจ๊ก"], categories: ["ต้ม/แกง"], broad: true))
        add(["ramen"], Hint(keywords: ["ราเมง", "รามยอน", "บะหมี่", "ก๋วยเตี๋ยว", "อุด้ง", "โซบะ", "เย็นตาโฟ", "ข้าวซอย"], categories: ["เส้น"]))
        add(["pasta", "spaghetti"], Hint(keywords: ["สปาเกตตี", "ลาซานญ่า", "ผัดไทย", "ผัดซีอิ๊ว", "ผัดขี้เมา", "ผัดหมี่", "จาจังมยอน", "จับเช"], categories: ["เส้น"]))
        add(["sushi"], Hint(keywords: ["ซูชิ", "ซาชิมิ", "คิมบับ", "โอนิกิริ", "แซลมอน"], categories: ["ญี่ปุ่น"]))
        add(["tempura"], Hint(keywords: ["เทมปุระ", "ทงคัตสึ", "คัตสึ"], categories: ["ญี่ปุ่น"]))
        add(["dumpling"], Hint(keywords: ["เกี๊ยว", "ติ่มซำ", "เสี่ยวหลงเปา", "ซาลาเปา"], categories: ["จีน"]))
        add(["salad"], Hint(keywords: ["ตำ", "ข้าวยำ", "ลาบ", "น้ำตก", "สลัด", "ก้อย"], categories: ["อีสาน"]))
        add(["steak"], Hint(keywords: ["สเต๊ก"], categories: ["ฝรั่ง"], ingredients: ["เนื้อ"]))
        add(["beef"], Hint(ingredients: ["เนื้อ"]))
        add(["meat"], Hint(categories: ["ปิ้งย่าง/ทะเล"], ingredients: ["หมู", "เนื้อ"]))
        add(["meatball"], Hint(keywords: ["ลูกชิ้น"]))
        add(["fried_chicken"], Hint(keywords: ["ไก่ทอด"], ingredients: ["ไก่"]))
        add(["grilled_chicken"], Hint(keywords: ["ไก่ย่าง", "ยากิโทริ"], ingredients: ["ไก่"]))
        add(["grill", "kebab"], Hint(keywords: ["ย่าง", "ปิ้ง", "เผา", "หมูกระทะ", "บาร์บีคิว"], categories: ["ปิ้งย่าง/ทะเล"]))
        add(["crab"], Hint(keywords: ["ปู"], ingredients: ["ปู"]))
        add(["seafood", "shellfish", "shellfish_prepared"], Hint(categories: ["ปิ้งย่าง/ทะเล"], ingredients: Set(Ingredients.names(in: .seafood))))
        add(["fish"], Hint(ingredients: ["ปลา"]))
        add(["egg", "fried_egg", "omelet", "scrambled_eggs"], Hint(keywords: ["ไข่เจียว", "ไข่ดาว", "ไข่ข้น"], ingredients: ["ไข่"]))
        add(["hamburger"], Hint(keywords: ["เบอร์เกอร์", "ฮัมบูร์ก"]))
        add(["pizza"], Hint(keywords: ["พิซซ่า"]))
        add(["sandwich"], Hint(keywords: ["แซนด์วิช", "ฮอทดอก", "เบอร์เกอร์"]))
        add(["bread", "white_bread"], Hint(keywords: ["ขนมปัง", "ซาวร์โดว์", "แซนด์วิช", "ครัวซองต์", "ปาท่องโก๋", "โรตี"]))
        add(["taco", "burrito", "tortilla", "nachos"], Hint(keywords: ["ทาโก้", "เบอร์ริโต้"]))
        add(["sausage"], Hint(keywords: ["ไส้กรอก", "ไส้อั่ว", "ฮอทดอก"]))
        add(["fries", "potato"], Hint(keywords: ["ฟิชแอนด์ชิปส์", "มันบด"], categories: ["ฝรั่ง"]))
        add(["cheese"], Hint(keywords: ["ชีส", "พิซซ่า", "ลาซานญ่า"]))
        add(["mussel", "oyster", "clam"], Hint(keywords: ["หอย"], ingredients: ["หอย"]))
        add(["lobster"], Hint(categories: ["ปิ้งย่าง/ทะเล"], ingredients: ["กุ้ง"]))
        add(["mushroom"], Hint(keywords: ["เห็ด"]))
        add(["corn"], Hint(keywords: ["ข้าวโพด"]))
        add(["fondue"], Hint(keywords: ["สุกี้", "ชาบู", "หม้อไฟ", "จิ้มจุ่ม"]))
        add(["oatmeal"], Hint(keywords: ["โจ๊ก", "ข้าวต้ม"]))
        add(["steamer_cookware"], Hint(keywords: ["ติ่มซำ", "เสี่ยวหลงเปา", "ซาลาเปา", "นึ่ง"], categories: ["จีน"]))
        // ภาชนะที่ Vision มักเห็นแทนตัวอาหาร — ให้คะแนนแค่หมวด
        add(["chopsticks"], Hint(categories: ["เส้น", "ญี่ปุ่น", "จีน", "เกาหลี"]))
        add(["bowl"], Hint(categories: ["เส้น", "ต้ม/แกง"]))

        add(["dessert"], Hint(categories: sweet))
        add(["cake", "cake_regular", "birthday_cake", "wedding_cake", "cheesecake", "cupcake", "fruitcake"], Hint(keywords: ["เค้ก"], categories: sweet))
        add(["ice_cream", "frozen_dessert"], Hint(keywords: ["ไอศกรีม", "ไอติม", "บิงซู"], categories: sweet))
        add(["pudding"], Hint(keywords: ["พุดดิ้ง", "ทาร์ตไข่", "สังขยา"], categories: sweet))
        add(["waffle"], Hint(keywords: ["วาฟเฟิล"], categories: sweet))
        add(["pancake"], Hint(keywords: ["แพนเค้ก", "ขนมเบื้อง", "โรตี"], categories: sweet))
        add(["donut"], Hint(keywords: ["โดนัท", "ปาท่องโก๋"], categories: sweet))
        add(["cookie", "gingerbread"], Hint(keywords: ["คุกกี้"], categories: sweet))
        add(["croissant", "pastry", "baked_goods", "muffin", "pie"], Hint(keywords: ["ครัวซองต์", "พาย", "ทาร์ต"], categories: sweet))
        add(["chocolate", "brownie"], Hint(keywords: ["ช็อกโกแลต", "โกโก้"]))
        add(["crepe"], Hint(keywords: ["เครป", "โรตี", "ขนมเบื้อง"], categories: sweet))
        add(["tiramisu"], Hint(keywords: ["เค้ก"], categories: sweet))
        add(["mango"], Hint(keywords: ["มะม่วง"]))
        add(["durian"], Hint(keywords: ["ทุเรียน"]))
        add(["watermelon"], Hint(keywords: ["แตงโม"]))
        add(["strawberry"], Hint(keywords: ["สตรอว์เบอร์รี"]))
        add(["avocado"], Hint(keywords: ["อะโวคาโด"]))
        add(["lime", "lemon", "citrus_fruit", "oranges"], Hint(keywords: ["มะนาว", "น้ำส้ม"]))
        add(["coconut"], Hint(keywords: ["มะพร้าว", "กะทิ", "บัวลอย", "ลอดช่อง", "กล้วยบวชชี", "ทับทิมกรอบ"]))

        add(["drink", "drinking_glass", "straw_drinking", "cup", "mug"], Hint(categories: drink))
        add(["milkshake"], Hint(keywords: ["ปั่น", "สมูทตี้", "นม"], categories: drink))
        add(["soda"], Hint(keywords: ["โซดา"], categories: drink))
        add(["juice", "juicer"], Hint(keywords: ["น้ำส้ม", "น้ำแตงโม", "น้ำมะพร้าว", "ปั่น"], categories: drink))
        add(["smoothie"], Hint(keywords: ["สมูทตี้", "ปั่น"], categories: drink))
        add(["cocktail"], Hint(keywords: ["โซดา", "อัญชัน", "ชามะนาว"], categories: drink))
        add(["bubble_tea"], Hint(keywords: ["ชานม", "ชาไทย", "ชาเขียว"], categories: drink))
        add(["coffee", "coffee_bean"], Hint(keywords: ["กาแฟ", "อเมริกาโน่", "ลาเต้", "โอเลี้ยง"], categories: drink))
        add(["tea_drink", "teapot"], Hint(keywords: ["ชาไทย", "ชานม", "ชาเขียว", "ชามะนาว", "มัทฉะ"], categories: drink))
        return table
    }()

    // เดาเฉพาะเมนูที่ชื่อตรงกับป้ายเฉพาะเจาะจงที่ Vision มั่นใจพอ — เห็นแค่ชาม/ตะเกียบ/ข้าว ให้ขึ้น "ไม่แน่ใจ" ดีกว่าขึ้นรายการมั่ว
    static func rank(_ labels: [SeenLabel], among foods: [Food], limit: Int = 5) -> [Food] {
        let scored = foods.enumerated().map { index, food in
            var score: Float = 0
            var isSure = false
            for label in labels {
                guard let hint = hints[label.name] else { continue }
                let named = hint.keywords.contains { food.name.contains($0) }
                var points: Float = named ? 3 : 0
                if hint.categories.contains(food.tag) { points += 1 }
                if !hint.ingredients.isDisjoint(with: food.ingredients) { points += 1 }
                score += points * label.confidence
                if named && !hint.broad && label.confidence >= minConfidence { isSure = true }
            }
            return (food: food, score: score, isSure: isSure, index: index)
        }
        // คะแนนเท่ากัน ให้เมนูที่อยู่ก่อนในรายการขึ้นก่อน
        return scored
            .filter(\.isSure)
            .sorted { ($0.score, -$0.index) > ($1.score, -$1.index) }
            .prefix(limit)
            .map(\.food)
    }
}
