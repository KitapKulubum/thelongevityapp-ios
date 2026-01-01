# Decoding Errors Summary

Bu dosya, iOS app'te yaşanan decoding hatalarını ve backend'de düzeltilmesi gereken alanları özetler.

## Tespit Edilen Hatalar

### 1. `/api/auth/me` - `AuthProfileResponse`
**Hata:** `valueNotFound(Swift.String, ...)` 
**Path:** `profile.chronologicalAgeYears`
**Sorun:** Backend `profile.chronologicalAgeYears` alanını null gönderiyor ama app String bekliyor.

**Beklenen Model:**
```swift
struct AuthProfileResponse: Codable {
    let uid: String
    let email: String?
    let profile: [String: String]?  // Bu bir dictionary, içinde chronologicalAgeYears olabilir
}
```

**Backend Düzeltmesi:**
- `profile.chronologicalAgeYears` alanı null gönderilmemeli
- Veya `profile` dictionary'si içinde bu alan olmamalı (yeni kullanıcılar için)
- Veya `profile` null olabilir ama içindeki alanlar null olmamalı

### 2. `/api/stats/summary` - `StatsSummaryResponse`
**Hata:** `valueNotFound(Swift.Double, ...)`
**Path:** `state.chronologicalAgeYears`
**Sorun:** Backend `state.chronologicalAgeYears` alanını null gönderiyor ama app Double bekliyor.

**Beklenen Model:**
```swift
struct BiologicalAgeState: Codable {
    let chronologicalAgeYears: Double  // ❌ null olamaz
    let baselineBiologicalAgeYears: Double
    let currentBiologicalAgeYears: Double
    let agingDebtYears: Double
    let rejuvenationStreakDays: Int
    let accelerationStreakDays: Int
    let totalRejuvenationDays: Int
    let totalAccelerationDays: Int
}
```

**Backend Düzeltmesi:**
- `state.chronologicalAgeYears` alanı her zaman bir Double değeri göndermeli (null değil)
- Yeni kullanıcılar için bile bu alan gönderilmeli (örneğin 0.0 veya kullanıcının gerçek yaşı)

### 3. `/api/age/daily-update` - `DailyResultDTO`
**Hata:** `dataCorrupted(...)` - "Number -8.5 is not representable in Swift"
**Sorun:** Backend bir sayı gönderiyor ama bu sayı Swift'te temsil edilemiyor. Muhtemelen:
- Int beklenirken Double geliyor (örneğin `rejuvenationStreakDays: -8.5`)
- Veya çok büyük/küçük bir sayı geliyor

**Beklenen Model:**
```swift
struct DailyResultDTO: Codable {
    let state: BiologicalAgeState
    let today: TodayEntry?
}

struct BiologicalAgeState: Codable {
    let chronologicalAgeYears: Double
    let baselineBiologicalAgeYears: Double
    let currentBiologicalAgeYears: Double
    let agingDebtYears: Double
    let rejuvenationStreakDays: Int      // ❌ Int olmalı, Double değil
    let accelerationStreakDays: Int      // ❌ Int olmalı, Double değil
    let totalRejuvenationDays: Int       // ❌ Int olmalı, Double değil
    let totalAccelerationDays: Int       // ❌ Int olmalı, Double değil
}
```

**Backend Düzeltmesi:**
- `rejuvenationStreakDays`, `accelerationStreakDays`, `totalRejuvenationDays`, `totalAccelerationDays` alanları **Int** olarak gönderilmeli (Double değil)
- Negatif değerler gönderilebilir ama Int olmalı (örneğin `-8` değil `-8.5` değil)
- Eğer negatif değer gönderilecekse, Int olarak gönderilmeli

## Önerilen Backend Düzeltmeleri

### 1. Yeni Kullanıcılar İçin Default Değerler
Yeni kullanıcılar için (onboarding tamamlanmamış) şu alanlar için default değerler gönderilmeli:
- `chronologicalAgeYears`: Kullanıcının gerçek yaşı veya 0.0
- `baselineBiologicalAgeYears`: 0.0 veya chronologicalAgeYears ile aynı
- `currentBiologicalAgeYears`: 0.0 veya chronologicalAgeYears ile aynı
- `agingDebtYears`: 0.0
- `rejuvenationStreakDays`: 0
- `accelerationStreakDays`: 0
- `totalRejuvenationDays`: 0
- `totalAccelerationDays`: 0

### 2. Type Consistency
- Tüm `*Days` alanları (rejuvenationStreakDays, accelerationStreakDays, vb.) **Int** olarak gönderilmeli
- Tüm `*Years` alanları **Double** olarak gönderilmeli
- Hiçbir required alan null gönderilmemeli

### 3. Response Format
- Tüm response'lar geçerli JSON formatında olmalı
- Null değerler sadece optional alanlar için gönderilmeli
- Required alanlar her zaman bir değer içermeli

## Test Senaryoları

Backend düzeltmelerinden sonra şu senaryolar test edilmeli:
1. ✅ Yeni kullanıcı login (onboarding öncesi)
2. ✅ Onboarding tamamlandıktan sonra login
3. ✅ Daily check-in submit
4. ✅ Summary fetch
5. ✅ Auth me endpoint

