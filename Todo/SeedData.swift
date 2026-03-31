import Foundation

struct SeedData {
    static func seed(into service: FirebaseService) {
        let nodes = getSeedNodes()
        for node in nodes {
            service.addNode(node)
        }
    }

    static func getSeedNodes() -> [Node] {
        var list: [Node] = []

        // Helper to convert category string to enum
        func cat(_ s: String) -> NodeCategory {
            NodeCategory(rawValue: s) ?? .oneTime
        }
        
        // Helper to convert status string to enum
        func stat(_ s: String) -> NodeStatus {
            NodeStatus(rawValue: s) ?? .open
        }

        // KEY BLOCKERS
        list += [
            Node(id: "dad_talk", title: "דיבור עם אבא", category: cat("keyBlockers"), status: stat("open"), notes: "שיחה אחת שפותחת: רופאים, שחייה, דירה, כירופרקט, תלתלים, ארסנל, כותל, אתרים, Apple Watch, כרית גב", priority: 1),
            Node(id: "haifa", title: "חיפה", category: cat("keyBlockers"), status: stat("open"), notes: "אירוע אישי חד פעמי. פותח את כל מפגשי החברים", priority: 2),
            Node(id: "citron", title: "ציטרון", category: cat("keyBlockers"), status: stat("open"), notes: "אירוע אישי חד פעמי. פותח: צמידים מוארים, פרויקטים יצירתיים", priority: 3),
            Node(id: "learning_curve", title: "עקומת למידה", category: cat("keyBlockers"), status: stat("inProgress"), notes: "אינפי 1 → אינפי 2 → אלגברה לינארית → ... → חזרה לטכניון → הנדסה כימית. כרגע: אינפי 1", priority: 4),
            Node(id: "run_streak", title: "ריצה 90 יום", category: cat("keyBlockers"), status: stat("inProgress"), notes: "רצף ריצה. נדרש לפתוח שחייה", priority: 5),
        ]

        // GOALS
        list += [
            Node(id: "move_apt", title: "מעבר דירה", category: cat("goals"), status: stat("blocked"), dependencies: ["dad_talk"], priority: 10),
            Node(id: "swimming", title: "ללמוד לשחות", category: cat("goals"), status: stat("blocked"), dependencies: ["dad_talk", "run_streak"], priority: 11),
            Node(id: "calisthenics", title: "קליסתניס", category: cat("goals"), status: stat("blocked"), dependencies: ["run_streak"], priority: 12),
            Node(id: "techion", title: "חזרה לטכניון / הנדסה כימית", category: cat("dreams"), status: stat("blocked"), dependencies: ["learning_curve"], priority: 13),
        ]

        // DOCTORS
        list += [
            Node(id: "doctor_general", title: "רופאה כללי", category: cat("doctors"), status: stat("blocked"), dependencies: ["dad_talk"], priority: 20),
            Node(id: "doctor_eyes", title: "עיניים + בדיקת ראייה", category: cat("doctors"), status: stat("blocked"), dependencies: ["dad_talk"], priority: 21),
            Node(id: "eye_surgery", title: "ניתוח עיניים", category: cat("doctors"), status: stat("blocked"), dependencies: ["doctor_eyes"], priority: 22),
            Node(id: "doctor_back", title: "גב", category: cat("doctors"), status: stat("blocked"), dependencies: ["dad_talk"], priority: 23),
            Node(id: "doctor_sweat", title: "ניתוח זיעה", category: cat("doctors"), status: stat("blocked"), dependencies: ["dad_talk"], priority: 24),
            Node(id: "doctor_head", title: "ראש וחום", category: cat("doctors"), status: stat("blocked"), dependencies: ["dad_talk"], priority: 25),
            Node(id: "doctor_throat", title: "גרון", category: cat("doctors"), status: stat("blocked"), dependencies: ["dad_talk"], priority: 26),
            Node(id: "doctor_stomach", title: "בטן", category: cat("doctors"), status: stat("blocked"), dependencies: ["dad_talk"], priority: 27),
            Node(id: "doctor_skin", title: "עור", category: cat("doctors"), status: stat("blocked"), dependencies: ["dad_talk"], priority: 28),
            Node(id: "doctor_blood", title: "בדיקות דם", category: cat("doctors"), status: stat("blocked"), dependencies: ["dad_talk"], priority: 29),
            Node(id: "chiro", title: "לשאול כירופרקט על הסרטונים", category: cat("doctors"), status: stat("blocked"), dependencies: ["dad_talk"], priority: 30),
        ]

        // ONE TIME
        list += [
            Node(id: "back_pillow", title: "כרית לגב לשינה + כירופרקט", category: cat("oneTime"), status: stat("blocked"), dependencies: ["dad_talk"], priority: 40),
            Node(id: "arsenal", title: "ארסנל מחר", category: cat("oneTime"), status: stat("blocked"), dependencies: ["dad_talk"], priority: 41),
            Node(id: "curls", title: "תלתלים", category: cat("oneTime"), status: stat("blocked"), dependencies: ["dad_talk"], priority: 42),
            Node(id: "kotel", title: "כותל (טיול עם אבא)", category: cat("oneTime"), status: stat("blocked"), dependencies: ["dad_talk"], priority: 43),
            Node(id: "sites", title: "אתרים (טיול עם אבא)", category: cat("oneTime"), status: stat("blocked"), dependencies: ["dad_talk"], priority: 44),
        ]

        // FRIENDS
        list += [
            Node(id: "rez_aviv", title: "רזאביב", category: cat("friends"), status: stat("blocked"), dependencies: ["haifa"], priority: 50),
            Node(id: "shai", title: "שי", category: cat("friends"), status: stat("blocked"), dependencies: ["haifa"], priority: 51),
            Node(id: "nir", title: "ניר", category: cat("friends"), status: stat("blocked"), dependencies: ["haifa"], priority: 52),
            Node(id: "amit", title: "עמית", category: cat("friends"), status: stat("blocked"), dependencies: ["haifa"], priority: 53),
            Node(id: "basha", title: "בשה", category: cat("friends"), status: stat("blocked"), dependencies: ["haifa"], priority: 54),
            Node(id: "danik", title: "דניק", category: cat("friends"), status: stat("blocked"), dependencies: ["haifa"], priority: 55),
            Node(id: "ofri", title: "עופרי", category: cat("friends"), status: stat("blocked"), dependencies: ["haifa"], priority: 56),
            Node(id: "bar_yaron", title: "בר ירון", category: cat("friends"), status: stat("blocked"), dependencies: ["haifa"], priority: 57),
            Node(id: "amit_ard", title: "עמית ארד", category: cat("friends"), status: stat("blocked"), dependencies: ["haifa"], priority: 58),
            Node(id: "padel", title: "פאדל חברים", category: cat("friends"), status: stat("blocked"), dependencies: ["haifa"], priority: 59),
        ]

        // CREATIVE
        list += [
            Node(id: "poem_veo3", title: "שיר וסיפור veo3", category: cat("creative"), status: stat("blocked"), dependencies: ["learning_curve", "citron", "dad_talk"], priority: 60),
            Node(id: "veo3", title: "Veo3 — סרטוני סיפורים ושירים", category: cat("creative"), status: stat("blocked"), dependencies: ["learning_curve", "citron"], priority: 61),
            Node(id: "riddles", title: "ללמוד חידות בסמח", category: cat("creative"), status: stat("blocked"), dependencies: ["learning_curve"], priority: 62),
            Node(id: "palm_trees", title: "Palm trees", category: cat("creative"), status: stat("open"), priority: 63),
            Node(id: "songs", title: "לכתוב שירים", category: cat("creative"), status: stat("open"), priority: 64),
            Node(id: "piano", title: "פסנתר — דברים מוזרים / palm trees / da vinci", category: cat("creative"), status: stat("open"), priority: 65),
            Node(id: "scorpion", title: "סדרה Scorpion", category: cat("creative"), status: stat("open"), priority: 66),
            Node(id: "detective", title: "מרגלית הבלשית / האויב", category: cat("creative"), status: stat("open"), priority: 67),
            Node(id: "court_proj", title: "פרוייקט משפט", category: cat("creative"), status: stat("open"), priority: 68),
            Node(id: "lo_naim", title: "לא נעים אחי (skits)", category: cat("creative"), status: stat("open"), priority: 69),
        ]

        // TECH
        list += [
            Node(id: "claude_tools", title: "שני כלים חדשים בקלאוד", category: cat("tech"), status: stat("open"), priority: 70),
            Node(id: "ai_browser", title: "דפדפן AI", category: cat("tech"), status: stat("blocked"), dependencies: ["learning_curve"], priority: 71),
            Node(id: "stars_proj", title: "פרוייקט כוכבים", category: cat("tech"), status: stat("open"), priority: 72),
            Node(id: "beamng", title: "Beamng", category: cat("tech"), status: stat("open"), priority: 73),
            Node(id: "arduino", title: "ארדואינו", category: cat("tech"), status: stat("open"), priority: 74),
            Node(id: "game", title: "לעשות משחק כמו מפעל חיילים", category: cat("tech"), status: stat("open"), priority: 75),
            Node(id: "zoom_earth", title: "Zoom earth / Skyfi / Maxar", category: cat("tech"), status: stat("open"), priority: 76),
        ]

        // PURCHASES
        let purchases = [
            ("pants_poof", "מכנסיים ופוף"), ("socket", "שקע ותקע"), ("teeth_white", "הלבנת שיניים"),
            ("nike_shorts", "נייק מכנסי ספורט"), ("dental_kit", "מדבקות הלבנה וסילון מים דנטלי"),
            ("jaw_grip", "בונה לסתות ומשפר אחיזה"), ("rain_bell", "פעמון גשם קוביות רכות"),
            ("long_pants", "פוך מכנסיים ארוכים"), ("face_mask", "מסכה אף פנים"),
            ("room_stuff", "שטויות למשרד או לחדר"), ("basketball", "סל וכדורסל לחדר"),
            ("ipad", "אייפד"), ("camera", "מצלמה / מטענים"), ("dashcam", "מצלמת רכב"),
            ("car_scent_disp", "מפיץ ריח לאוטו"), ("car_scratch", "תיקון שריטות ברכב"),
            ("watch_battery", "החלפת סוללה לאפל ווטש"), ("daddy_scrub", "ספוג daddy scrub"),
            ("ankle_guard", "מגן קרסול"), ("tanach", "תנ\"ך ביאור תווים"),
            ("knife_rotate", "סכין מטבח רוטטת"), ("iphone_photo", "אביזר צילום לאייפון"),
            ("fire_ext", "מטף לאוטו"), ("car_audio", "מערכת כריזה לאוטו"),
            ("trash_can", "פח לבית"), ("converter", "ממיר"), ("water_heater", "דוד אוטומטי"),
            ("dentist_kit2", "שיננית"), ("poof", "פוף"), ("phone_holder", "תופס לאייפון לאוטו"),
            ("pl_ball", "כדור פרמייר ליג"), ("nike_clothes", "בגדים נייק"),
            ("rain_jacket", "מעיל גשם נייק"), ("hollister", "הוליסטר"), ("polgat", "פולגת"),
            ("jd", "JD"), ("birkenstock", "בירקנשטוק"), ("iphone_cables", "מטענים לאייפון"),
            ("iphone_lens", "עדשות לאייפון"), ("steam_iron", "מגהץ מתנפח"),
            ("smart_bottle", "תרמוס בקבוק מים חכם"), ("lego_bugatti", "לגו בוגאטי"),
            ("cloud_shoes", "Cloud On נעליים 740 530"), ("metal_board", "קרש חיתוך ממתכת"),
            ("room_decor", "קישוטים לחדר"), ("car_wood", "עץ ריח לאוטו")
        ]
        for (i, p) in purchases.enumerated() {
            list.append(Node(id: p.0, title: p.1, category: cat("purchases"), status: stat("open"), priority: 100 + i, type: "purchase"))
        }

        // PURCHASES BLOCKED BY MOVE_APT
        list += [
            Node(id: "dough_course", title: "קורס בצק + ציוד מטבח", category: cat("purchases"), status: stat("blocked"), dependencies: ["move_apt"], priority: 200, type: "purchase"),
            Node(id: "protein_mix", title: "תערובות שייק חלבון", category: cat("purchases"), status: stat("blocked"), dependencies: ["move_apt"], priority: 201, type: "purchase"),
            Node(id: "hot_discount", title: "הנחה מהוט וממיר אנלוגי", category: cat("purchases"), status: stat("blocked"), dependencies: ["move_apt"], priority: 202, type: "purchase"),
            Node(id: "symbol_shirt", title: "חולצה עם סמלים", category: cat("purchases"), status: stat("blocked"), dependencies: ["move_apt"], priority: 203, type: "purchase"),
            Node(id: "wall_text", title: "קיר עם כיתובים משמעותיים", category: cat("purchases"), status: stat("blocked"), dependencies: ["move_apt"], priority: 204, type: "purchase"),
            Node(id: "electric_knife", title: "סכין חשמלית", category: cat("purchases"), status: stat("blocked"), dependencies: ["move_apt"], priority: 205, type: "purchase"),
            Node(id: "bracelets", title: "צמידים מוארים לבני זוג", category: cat("purchases"), status: stat("blocked"), dependencies: ["citron"], priority: 206, type: "purchase"),
        ]

        // RECURRING
        list += [
            Node(id: "clean_photos", title: "לנקות תמונות", category: cat("recurring"), status: stat("open"), priority: 300),
            Node(id: "check_car", title: "לבדוק שמן מים באוטו", category: cat("recurring"), status: stat("open"), priority: 301),
            Node(id: "haircut", title: "להסתפר", category: cat("recurring"), status: stat("open"), priority: 302),
        ]

        // DREAMS
        list += [
            Node(id: "skydiving", title: "צניחה חופשית", category: cat("dreams"), status: stat("open"), priority: 400),
        ]

        // REMINDERS
        list += [
            Node(id: "arsenal_july", title: "להתכונן לארסנל", category: cat("reminders"), status: stat("open"), notes: "July 1, 2026", priority: 500),
            Node(id: "zara_delivery", title: "לדבר עם Zara על משלוח", category: cat("reminders"), status: stat("open"), priority: 501),
            Node(id: "luna_visit", title: "לבקר את לונה ובתרונות רוחמה", category: cat("reminders"), status: stat("open"), notes: "מחכה לשבת שמש", priority: 502),
        ]

        return list
    }
}
