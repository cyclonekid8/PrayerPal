// lib/data/quotes.dart
// All quotes for PrayerPal notifications

enum PrayerQuoteCategory { encouraging, motivating, stern }

class PrayerQuote {
  final String text;
  final String attribution; // named scholar, "Saying of the Salaf", or ""
  final PrayerQuoteCategory category;

  const PrayerQuote({
    required this.text,
    required this.attribution,
    required this.category,
  });
}

class FastingQuote {
  final String text;
  final String attribution;

  const FastingQuote({required this.text, required this.attribution});
}

// ═══════════════════════════════════════════════════
// PRAYER QUOTES
// Category A: Encouraging — used when prayer window opens
// Category B: Motivating — used for 30-min reminders
// Category C: Stern/Warning — used for 15-min urgent alarm
// ═══════════════════════════════════════════════════

const List<PrayerQuote> prayerQuotes = [

  // ── Category A: Encouraging ──────────────────────
  PrayerQuote(
    text: "Prayer brings sustenance, preserves health, removes harm, strengthens the heart, brightens the face, delights the soul, and drives away laziness.",
    attribution: "Ibn al-Qayyim",
    category: PrayerQuoteCategory.encouraging,
  ),
  PrayerQuote(
    text: "Know that prayer is the pillar of religion and the key to Paradise.",
    attribution: "Al-Ghazali",
    category: PrayerQuoteCategory.encouraging,
  ),
  PrayerQuote(
    text: "In the world there is a paradise; whoever does not enter it will not enter the Paradise of the Hereafter.",
    attribution: "Ibn Taymiyyah",
    category: PrayerQuoteCategory.encouraging,
  ),
  PrayerQuote(
    text: "Prayer is not a burden placed on you; it is a door opened for you.",
    attribution: "",
    category: PrayerQuoteCategory.encouraging,
  ),
  PrayerQuote(
    text: "Your prayer is your meeting with Allah — do not arrive late.",
    attribution: "",
    category: PrayerQuoteCategory.encouraging,
  ),
  PrayerQuote(
    text: "When the call to prayer reaches you, the King of kings is calling you.",
    attribution: "",
    category: PrayerQuoteCategory.encouraging,
  ),
  PrayerQuote(
    text: "Every prayer you pray erases what came before it.",
    attribution: "",
    category: PrayerQuoteCategory.encouraging,
  ),
  PrayerQuote(
    text: "The heart that finds comfort in prayer will never be truly lost.",
    attribution: "",
    category: PrayerQuoteCategory.encouraging,
  ),
  PrayerQuote(
    text: "Prayer is the rope that pulls the believer out of the darkness of the world.",
    attribution: "",
    category: PrayerQuoteCategory.encouraging,
  ),
  PrayerQuote(
    text: "Sins darken the heart, but prayer polishes it.",
    attribution: "",
    category: PrayerQuoteCategory.encouraging,
  ),
  PrayerQuote(
    text: "The first step toward reforming your life is reforming your prayer.",
    attribution: "",
    category: PrayerQuoteCategory.encouraging,
  ),
  PrayerQuote(
    text: "The world distracts you from prayer, but prayer saves you from the world.",
    attribution: "",
    category: PrayerQuoteCategory.encouraging,
  ),
  PrayerQuote(
    text: "When prayer becomes difficult for the body, know that the heart has become sick.",
    attribution: "",
    category: PrayerQuoteCategory.encouraging,
  ),
  PrayerQuote(
    text: "If you stand before Allah five times a day, how can you continue to disobey Him?",
    attribution: "",
    category: PrayerQuoteCategory.encouraging,
  ),
  // Story: The Blind Companion
  PrayerQuote(
    text: "A blind companion asked the Prophet ﷺ for permission to pray at home. The Prophet asked: \"Do you hear the call to prayer?\" He said yes. The Prophet ﷺ replied: \"Then answer it.\"",
    attribution: "Narrated from the Sunnah",
    category: PrayerQuoteCategory.encouraging,
  ),
  // Story: Ali ibn Abi Talib
  PrayerQuote(
    text: "When the time for prayer approached, his face would change colour. When asked why, he said: \"The time has come for a trust that the heavens and the earth refused to carry.\"",
    attribution: "Reported of Ali ibn Abi Talib",
    category: PrayerQuoteCategory.encouraging,
  ),
  // Story: Hasan al-Basri
  PrayerQuote(
    text: "I met people who were happier when the time for prayer came than you are when wealth is given to you.",
    attribution: "Hasan al-Basri",
    category: PrayerQuoteCategory.encouraging,
  ),
  // Story: Companion praying through pain
  PrayerQuote(
    text: "A companion asked them to remove an arrow from his leg while he was in prayer — because he would not feel the pain while standing before Allah.",
    attribution: "Saying of the Salaf",
    category: PrayerQuoteCategory.encouraging,
  ),

  // ── Category B: Motivating ───────────────────────
  PrayerQuote(
    text: "O son of Adam, prayer is your path to your Lord. Whoever preserves it preserves his religion.",
    attribution: "Hasan al-Basri",
    category: PrayerQuoteCategory.motivating,
  ),
  PrayerQuote(
    text: "Whoever guards his prayers guards his religion, and whoever neglects them neglects his religion.",
    attribution: "Umar ibn al-Khattab",
    category: PrayerQuoteCategory.motivating,
  ),
  PrayerQuote(
    text: "Nothing weighs heavier on the scale of a servant than a prayer performed at its proper time.",
    attribution: "Sufyan al-Thawri",
    category: PrayerQuoteCategory.motivating,
  ),
  PrayerQuote(
    text: "If you wish to know your rank with Allah, look at the rank prayer holds in your life.",
    attribution: "",
    category: PrayerQuoteCategory.motivating,
  ),
  PrayerQuote(
    text: "The believer runs to prayer; the hypocrite runs away from it.",
    attribution: "",
    category: PrayerQuoteCategory.motivating,
  ),
  PrayerQuote(
    text: "If the kings and the wealthy knew the joy we feel in prayer, they would fight us for it with swords.",
    attribution: "Saying of the Salaf",
    category: PrayerQuoteCategory.motivating,
  ),
  PrayerQuote(
    text: "If you knew what Allah prepares for those who walk to prayer, you would crawl to it.",
    attribution: "Saying of the Salaf",
    category: PrayerQuoteCategory.motivating,
  ),
  PrayerQuote(
    text: "The one who prays on time has already won half the struggle against his soul.",
    attribution: "",
    category: PrayerQuoteCategory.motivating,
  ),
  PrayerQuote(
    text: "Guard your prayer before your prayer becomes your regret.",
    attribution: "",
    category: PrayerQuoteCategory.motivating,
  ),
  // Story: Said ibn al-Musayyib
  PrayerQuote(
    text: "For forty years, the call to prayer never came except that I was already in the mosque.",
    attribution: "Said ibn al-Musayyib",
    category: PrayerQuoteCategory.motivating,
  ),
  // Story: Abdullah ibn Umar
  PrayerQuote(
    text: "When Ibn Umar missed a congregational prayer once, he spent the entire night in prayer out of regret.",
    attribution: "Reported of Abdullah ibn Umar",
    category: PrayerQuoteCategory.motivating,
  ),
  // Story: Early scholars and Fajr
  PrayerQuote(
    text: "How strange is the one who knows Paradise exists yet sleeps through the dawn prayer.",
    attribution: "Saying of the Salaf",
    category: PrayerQuoteCategory.motivating,
  ),
  // Story: Ibrahim al-Nakha'i
  PrayerQuote(
    text: "If they said to me that tomorrow is the Day of Judgment, I could not increase my deeds beyond what I already do.",
    attribution: "Ibrahim al-Nakha'i",
    category: PrayerQuoteCategory.motivating,
  ),
  PrayerQuote(
    text: "The difference between the people of happiness and the people of misery is guarding the prayer.",
    attribution: "Ibn al-Qayyim",
    category: PrayerQuoteCategory.motivating,
  ),

  // ── Category C: Stern / Warning ─────────────────
  PrayerQuote(
    text: "Whoever would be pleased to meet Allah tomorrow as a Muslim, let him guard these prayers where they are called.",
    attribution: "Abdullah ibn Masud",
    category: PrayerQuoteCategory.stern,
  ),
  PrayerQuote(
    text: "If prayer does not restrain you from wrongdoing, it only increases you in distance from Allah.",
    attribution: "Hasan al-Basri",
    category: PrayerQuoteCategory.stern,
  ),
  PrayerQuote(
    text: "The one who neglects prayer is like a body without a soul.",
    attribution: "Ibn al-Qayyim",
    category: PrayerQuoteCategory.stern,
  ),
  PrayerQuote(
    text: "The prayer of one whose heart is absent is like a body without spirit.",
    attribution: "Al-Ghazali",
    category: PrayerQuoteCategory.stern,
  ),
  PrayerQuote(
    text: "There is no share of Islam for the one who abandons prayer.",
    attribution: "Umar ibn al-Khattab",
    category: PrayerQuoteCategory.stern,
  ),
  PrayerQuote(
    text: "Delaying prayer beyond its time without excuse is among the greatest sins.",
    attribution: "Ibn Taymiyyah",
    category: PrayerQuoteCategory.stern,
  ),
  PrayerQuote(
    text: "The first of your deeds to be judged on the Day of Resurrection will be the prayer.",
    attribution: "Sufyan al-Thawri",
    category: PrayerQuoteCategory.stern,
  ),
  PrayerQuote(
    text: "The prayer you delay today will stand as a witness against you tomorrow.",
    attribution: "",
    category: PrayerQuoteCategory.stern,
  ),
  PrayerQuote(
    text: "The distance between you and Allah is measured by the prayers you neglect.",
    attribution: "",
    category: PrayerQuoteCategory.stern,
  ),
  PrayerQuote(
    text: "A day without prayer is a day lived without purpose.",
    attribution: "",
    category: PrayerQuoteCategory.stern,
  ),
  PrayerQuote(
    text: "Between a man and disbelief is abandoning the prayer.",
    attribution: "Narrated from the Sunnah",
    category: PrayerQuoteCategory.stern,
  ),
  PrayerQuote(
    text: "If you take care of prayer, everything else in your religion will follow. If you lose prayer, everything else will be lost.",
    attribution: "Saying of the Salaf",
    category: PrayerQuoteCategory.stern,
  ),
];

// ═══════════════════════════════════════════════════
// FASTING QUOTES — Ramadan only, 10am/12pm/2pm/4pm/6pm
// ═══════════════════════════════════════════════════

const List<FastingQuote> fastingQuotes = [
  FastingQuote(
    text: "Fasting disciplines the soul, breaks desires, and reminds the servant of his need for his Lord.",
    attribution: "Ibn al-Qayyim",
  ),
  FastingQuote(
    text: "Fasting purifies the heart and trains the soul in sincerity.",
    attribution: "Al-Ghazali",
  ),
  FastingQuote(
    text: "Allah made Ramadan a racecourse for His servants to compete in obedience.",
    attribution: "Hasan al-Basri",
  ),
  FastingQuote(
    text: "The fasting person leaves his desires for Allah, so Allah replaces them with His pleasure.",
    attribution: "Ibn Rajab al-Hanbali",
  ),
  FastingQuote(
    text: "Fasting is not deprivation of food; it is nourishment of the soul.",
    attribution: "",
  ),
  FastingQuote(
    text: "Every moment of hunger for Allah becomes reward in the Hereafter.",
    attribution: "",
  ),
  FastingQuote(
    text: "The hunger of the believer today becomes the joy of the believer tomorrow.",
    attribution: "",
  ),
  FastingQuote(
    text: "When you fast, angels witness your patience.",
    attribution: "",
  ),
  FastingQuote(
    text: "Fasting is the hidden act that only Allah truly sees.",
    attribution: "",
  ),
  FastingQuote(
    text: "The difficulty of fasting lasts hours, but its reward lasts forever.",
    attribution: "",
  ),
  FastingQuote(
    text: "Every hunger felt for Allah is recorded as worship.",
    attribution: "",
  ),
  FastingQuote(
    text: "The believer fasts with hope, not merely endurance.",
    attribution: "",
  ),
  FastingQuote(
    text: "The sweetness of iftar reminds the believer of the sweetness of meeting Allah.",
    attribution: "",
  ),
  FastingQuote(
    text: "The gates of mercy open for the fasting person.",
    attribution: "",
  ),
  FastingQuote(
    text: "Fasting weakens the body but strengthens the heart.",
    attribution: "",
  ),
  FastingQuote(
    text: "Fasting is a shield between the servant and sin.",
    attribution: "",
  ),
  FastingQuote(
    text: "Every day you fast builds a barrier between you and the fire.",
    attribution: "",
  ),
  FastingQuote(
    text: "When a servant fasts sincerely, sins fall away like leaves from a tree.",
    attribution: "",
  ),
  FastingQuote(
    text: "The believer never loses through fasting; he only gains.",
    attribution: "",
  ),
  FastingQuote(
    text: "Fasting teaches patience better than any sermon.",
    attribution: "",
  ),
  FastingQuote(
    text: "Hunger reminds the believer of his dependence on Allah.",
    attribution: "",
  ),
  FastingQuote(
    text: "The one who fasts sincerely becomes beloved to Allah.",
    attribution: "",
  ),
  FastingQuote(
    text: "Fasting empties the stomach but fills the heart.",
    attribution: "",
  ),
  FastingQuote(
    text: "Ramadan is a mercy disguised as discipline.",
    attribution: "",
  ),
  FastingQuote(
    text: "The fasting person trades temporary comfort for eternal reward.",
    attribution: "",
  ),
  FastingQuote(
    text: "The thirst of fasting will be quenched by the rivers of Paradise.",
    attribution: "",
  ),
  FastingQuote(
    text: "Every fast carried with sincerity raises a servant's rank.",
    attribution: "",
  ),
  FastingQuote(
    text: "The believer's hunger is known to Allah and rewarded beyond measure.",
    attribution: "",
  ),
  FastingQuote(
    text: "Ramadan is the season when weak hearts become strong.",
    attribution: "",
  ),
  FastingQuote(
    text: "The believer restrains himself today so he may rejoice tomorrow.",
    attribution: "",
  ),
  FastingQuote(
    text: "The tiredness of fasting becomes light on the Day of Judgment.",
    attribution: "",
  ),
  FastingQuote(
    text: "The fasting servant walks through the day with unseen reward.",
    attribution: "",
  ),
  FastingQuote(
    text: "Hunger softens the heart and opens it to remembrance.",
    attribution: "",
  ),
  FastingQuote(
    text: "Fasting teaches the soul that it is stronger than desire.",
    attribution: "",
  ),
  FastingQuote(
    text: "The patient fasting person is surrounded by divine mercy.",
    attribution: "",
  ),
  FastingQuote(
    text: "The fast that is difficult today becomes a treasure tomorrow.",
    attribution: "",
  ),
  FastingQuote(
    text: "Whoever fasts seeking Allah's pleasure has already gained more than he lost.",
    attribution: "",
  ),
  FastingQuote(
    text: "The fast is not only from food and drink, but from every desire — and every desire resisted strengthens the believer.",
    attribution: "Saying of the Salaf",
  ),
];
