# AI Smart Tourism — Qashqadaryo

Qashqadaryo viloyati turistlari uchun Android ilova (Flutter). Ilova **serversiz ishlaydi**:
38 ta obyekt (koordinatalari OpenStreetMap'dan) va barcha algoritmlar APK ichida.
Dizayn va logotip loyiha veb-saytidan olingan (stone + amber, tog' belgisi).

An Android app (Flutter) for tourists in the Kashkadarya region of Uzbekistan. It **works without a server**.

## Modullar / Modules
| Modul | Ilovada |
|---|---|
| GPS moduli | Joriy koordinatalar, obyektlargacha masofa, "Sayohat rejimi"da harakatni kuzatish |
| GIS bazasi | Ziyoratgohlar, tarixiy obidalar, tabiiy maskanlar, mehmonxona/restoran/dam olish (ish vaqtlari bilan) |
| AI tavsiya | Kontentga asoslangan filtrlash (kosinus o'xshashlik) + reyting + yaqinlik + turist baholaridan o'rganish, byudjet |
| Optimal marshrut | ≤8 joyda barcha tartiblar, ko'proqda genetik algoritm; internet bo'lsa haqiqiy yo'llar (OpenStreetMap OSRM: routing.openstreetmap.de), bo'lmasa A* bilan taxminiy; strategiya: eng qisqa / eng tez / muvozanatli; transport, byudjet, ish vaqti, kunlarga bo'lish |
| Tayyor marshrutlar | 6 ta: Shahrisabz bir kunda, Ziyorat yo'li, Tog'lar va sharsharalar, Qarshi yarim kunda, Yulduzlar va tog' jinslari, Qadimiy Nasaf (`assets/tours.json`) |
| Foydali ma'lumot | Favqulodda raqamlar, transport, pul, SIM, kiyinish qoidalari, xavfsizlik, mavsum, iboralar |
| Yo'l bo'yidagi joylar | Marshrut yo'lagidagi yoqilg'i quyish shoxobchalari (metan/propan/benzin), ovqatlanish joylari va bozorlar (OSM ma'lumotlari, `assets/stops.json`) |
| Real vaqt monitoring | Tirbandlik modeli (tig'iz soatlar), ish vaqtini tekshirish, yo'ldan chiqish yoki yopilishda qayta marshrutlash |
| Virtual yordamchi | O'zbek / rus / ingliz; oflayn savol-javob (ish vaqti, narx, yaqin joylar, tavsiya) |
| Baholash | Baho, izoh, tavsiyalar sifatini baholash (👍/👎) |
| Administrator | PIN bilan (standart 1234): obyektlarni boshqarish, analitika, statistik hisobot |

Hozircha baholar va statistika telefonda saqlanadi; `backend/` (FastAPI) serverga ulash uchun tayyor.

## Tuzilma / Structure
| Papka | Nima bor |
|---|---|
| `mobile/` | Flutter ilova. `lib/algorithms/` — algoritmlar, `lib/screens/` — ekranlar, `assets/attractions.json` — obyektlar (3 tilda) |
| `mobile/test/` | Yordamchi va marshrut algoritmi testlari (`flutter test`) |
| `backend/` | Xuddi shu algoritmlarning Python/FastAPI versiyasi (ixtiyoriy REST API) |
| `data/attractions.csv` | Backend uchun obyektlar ro'yxati |
| `database/schema.sql` | PostgreSQL/PostGIS sxemasi |

## APK yig'ish / Build the APK
    cd mobile
    flutter pub get
    flutter build apk --release
    # APK: mobile/build/app/outputs/flutter-apk/app-release.apk

## Backend (ixtiyoriy)
    docker compose up --build        # API: http://localhost:8000/docs
    # yoki Docker'siz:
    cd backend && pip install -r requirements.txt && uvicorn app.main:app --reload

Joylar rasmlari: Wikimedia Commons (har bir rasm muallifi va litsenziyasi `assets/photos.json` va ilovada ko'rsatilgan). Xarita, yo'llar va yo'l bo'yidagi joylar ma'lumotlari © OpenStreetMap contributors (ODbL). Yo'l marshrutlari: FOSSGIS routing.openstreetmap.de (bepul, kam yuklama uchun).
