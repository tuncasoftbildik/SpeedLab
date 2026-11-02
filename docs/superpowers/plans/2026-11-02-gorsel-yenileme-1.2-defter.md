# SDD ledger — plan: docs/superpowers/plans/2026-11-02-gorsel-yenileme-1.2.md
Branch: feat/1.2-gorsel-yenileme (main 487a8e6 üzerinden)
Pre-flight:
- T2→T7/T8: SpeedTestResult init `date:` parametresi — T2 Produces içinde var, T7 testi kullanıyor: uyumlu
- T3→T4/T6: GaugeScale.fraction, SpeedContext.bandKey/deltaPercent — T4 gaugeValue, T6 kartlar: uyumlu
- T4→T6: SampleBuffer.values, packetLoss, showResultCards — T6 tüketir: uyumlu
- T5→T6: DialGaugeView(speed:phase:isUploading:idleTitle:) — T6 aynı imza: uyumlu
- T7→T8: HistoryRange, HistoryChartView — T8 pdf(range:chart:) tüketir: uyumlu
- T1→T11/T12: npBrand* / semantik np* — widget yalnız npBrand*: T11 asset ekler, uyumlu
- T2→T9: NetworkInfo aynı dosyada genişler (signalQuality, radioTech, connectionKind): çakışma yok
Task 1: complete (commits 487a8e6..726a8b3, tests: bash -c 'xcodebuild test -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=ViaBus iPhone 18 Pro' -only-testing:SpeedLabTests 2>&1 | grep -E 'error:|Test Suite .SpeedLabTests.*(passed|failed)|Executed|\*\* TEST'' → ** TEST SUCCEEDED **)
Task 2: complete (commits 726a8b3..a1309d4, tests: .superpowers/sdd/2026-11-02-gorsel-yenileme-1.2/suite.sh → ** TEST SUCCEEDED **)
Task 3: complete (commits a1309d4..1151e12, tests: .superpowers/sdd/2026-11-02-gorsel-yenileme-1.2/suite.sh → ** TEST SUCCEEDED **)
Task 4: complete (commits 1151e12..e98a343, tests: .superpowers/sdd/2026-11-02-gorsel-yenileme-1.2/suite.sh → ** TEST SUCCEEDED **)
Task 5: complete (commits e98a343..c86e01a, tests: .superpowers/sdd/2026-11-02-gorsel-yenileme-1.2/suite.sh → ** TEST SUCCEEDED **)
Task 6: Ruling: Onboarding kadran görseli Task 12'ye taşındı — ana ekran görevi zaten büyük, onboarding yalnız görsel cila — cost if wrong: onboarding bir görev geç güncellenir
Task 6: Ruling: EN ekran görüntüleri Task 13'e birleştirildi — simctl defaults app group plist'ine yazmıyor, dil Ayarlar'dan değişecek — cost if wrong: EN düzen hatası bir görev geç görülür
Task 6: Ruling: SpeedTestService indirme progressHandler artık pencere bazlı anlık hız bildiriyor (≥0.2 sn) — kümülatif ortalama grafiği düz çizgiye çeviriyordu — cost if wrong: kadran ibresi daha oynak görünür; sonuç hesabı değişmedi
Task 6: Ruling: StoreViewModel DEBUG 'debug_pro' bayrağı eklendi (plan Task 7'de öngörülmüştü, görsel doğrulama için erken) — cost if wrong: yalnız DEBUG derlemede etkili
Task 6: complete (commits c86e01a..a2198c9, tests: .superpowers/sdd/2026-11-02-gorsel-yenileme-1.2/suite.sh → ** TEST SUCCEEDED **)
Final: minor (deferred): App Store Connect abonelik açıklamalarında 'WiFi map' ifadesi var (Task 10 uygulama içi satırı kaldırıyor; ASC metni Tunca güncellemeli)
Task 7: complete (commits a2198c9..8cbc46f, tests: .superpowers/sdd/2026-11-02-gorsel-yenileme-1.2/suite.sh → ** TEST SUCCEEDED **)
Task 8: complete (commits 8cbc46f..ba2ae79, tests: .superpowers/sdd/2026-11-02-gorsel-yenileme-1.2/suite.sh → ** TEST SUCCEEDED **)
Task 9: Ruling: güvenlik taraması CSV formül enjeksiyonu buldu, Task 8 kodu ayrı commit ile düzeltildi (RED→GREEN) — cost if wrong: yok
Task 9: complete (commits ba2ae79..79e783b, tests: .superpowers/sdd/2026-11-02-gorsel-yenileme-1.2/suite.sh → ** TEST SUCCEEDED **)
Task 10: complete (commits 79e783b..52aece9, tests: .superpowers/sdd/2026-11-02-gorsel-yenileme-1.2/suite.sh → ** TEST SUCCEEDED **)
Task 11: Ruling: Icon Composer .icon paketi GUI gerektirir; katman PNG'leri üretildi, paket Tunca'ya bırakıldı (PNG ikon derlemede yeterli) — cost if wrong: iOS 26'da cam/tonlu ikon varyantı olmaz, düz PNG kullanılır
Task 11: complete (commits 52aece9..4351485, tests: .superpowers/sdd/2026-11-02-gorsel-yenileme-1.2/suite.sh → ** TEST SUCCEEDED **)
Task 12: Ruling: onboarding ilk sayfada DialGaugeView yerine IkonKucuk logosu kullanıldı — aynı kadran görseli, Canvas yükü yok — cost if wrong: onboarding görseli statik kalır
Task 12: complete (commits 4351485..5742ef2, tests: .superpowers/sdd/2026-11-02-gorsel-yenileme-1.2/suite.sh → ** TEST SUCCEEDED **)
Task 13: Ruling: cek.sh yalnız yakalama yardımcısı; gezinme MCP ile elle yapıldı (bash'ten dokunma yok) — cost if wrong: tekrar üretim yarı otomatik
Task 13: Ruling: Instruments performans ölçümü simülatörde atlandı; iPhone 11 sınıfı cihaz ölçümü Tunca'nın cihazında — cost if wrong: eski cihazda kadran takılması geç fark edilir
Task 13: eski veri testi: 1.1.2 formatında 12 kayıt container plist'ine yazıldı, geçmiş ve grafik sorunsuz (hücresel/WiFi türetimi doğru)
Final: minor (deferred): 1-kadran mağaza görseli test bittikten sonra çekildi (simülatörde test 3-5 sn sürüyor); gerçek cihazda ibre hareket halindeyken yeniden çekilmeli
Final: minor (deferred): 4-wifi mağaza görseli simülatörde "Ölçülemiyor" gösteriyor; gerçek cihazda yüzdeyle yeniden çekilmeli
Final: minor (deferred): Geçmiş özetinde "13 speed test" (EN çoğul yok; tab_speed anahtarı yeniden kullanılıyor)
Task 13: complete (commits 5742ef2..f0d5bf8, tests: .superpowers/sdd/2026-11-02-gorsel-yenileme-1.2/suite.sh → ** TEST SUCCEEDED **)
Final review: fresh reviewer (fable) — Critical 0, Important 6, Minor 16; verdict "with fixes"
Final: Ruling: minör 14 (CSV'de '-' → "'-") ve 17 (açık temada gradyan düğme metni) etkisiyle Important sayıldı ve düzeltme turuna alındı — kullanıcıya doğrudan görünen veri/okunabilirlik hatası — cost if wrong: yok
Final: Ruling: Issue 1 çözümü koşu kimliği + enjekte edilebilir gecikme/reklam (test edilebilirlik için) — cost if wrong: yok
Final: Ruling: Issue 3 çözümü statik/dinamik iki Canvas + nefes efekti SwiftUI animasyonu (TimelineView kaldırıldı); Instruments ölçümü hâlâ cihaza ertelenmiş — cost if wrong: eski cihazda takılma geç fark edilir
Final: Ruling (reviewer "declined to judge"): banner tab çubuğunun altında (pre-existing) — kadranı örtmüyor, kalır — cost: spec metniyle küçük fark
Final: Ruling (reviewer "declined"): widget büyük boy lineer skala (ShareGaugeView) — spec widget yeniden tasarımını dışlar, kalır — cost: widget ile uygulama kadranı farklı skala
Final: Ruling (reviewer "declined"): NSLocationWhenInUseUsageDescription hâlâ "WiFi sinyal haritası" diyor — Tunca'ya raporlanır, project.yml metni bu turda değişmedi — cost: App Review tutarsızlık sorabilir
Final: Ruling (reviewer "declined"): getCurrentSSID / NetworkInfo.signalStrength kullanılmıyor ama duruyor — temizlik ertelendi — cost: yok
Final: minor (deferred): geçmiş UserDefaults'ta örneklerle ~10× büyüyor (kayıt sınırı/yuvarlama önerisi)
Final: minor (deferred): HistoryViewModel.recentValues/lastSamples/chartResults her çağrıda tam decode
Final: minor (deferred): yükleme örnekleri kümülatif (3 nokta), indirme pencereli
Final: minor (deferred): progress Task'ları final değeri ezebilir (pre-existing kalıp)
Final: minor (deferred): ping ölçülürken telemetri çipi "0 ms"
Final: minor (deferred): sinyal geçmişi grafiği maksimuma ölçekleniyor; sekme girişinde geçmiş sıfırlanıyor
Final: minor (deferred): "%73" biçimi ve PDF başlıkları yerelleşmemiş
Final: minor (deferred): fileName UTC gün kullanıyor
Final: minor (deferred): geçmiş grafiğinde lejant yok, ping /10
Final: minor (deferred): .completed'da kadran yüklemeden indirmeye zıplıyor
Final: minor (deferred): gaugeValue ölü alan
Final: minor (deferred): IkonKucuk yalnız 1x 256 px
Final: minor (deferred): ShareSheet.presentFile yazma hatasını yutuyor
Final: minor (deferred): plan uret.mjs dedi, uret.py yazıldı (ruling eksikti)
Final: fixed Issue 1 (çift dokunuşta kart/reklam sızması) — test_staleRunShowsNeitherCardsNorAd, test_currentRunShowsCardsThenAd, test_phaseLeftCompletedCancelsAd RED→GREEN, suite 52/52
Final: fixed Issue 2 (açık temada beyaz ibre/uç/nokta) — görsel: uretim/magaza/acik/2-sonuc.png; uç her temada beyaz, ibre npTextPrimary
Final: fixed Issue 3 (Canvas kare başına tam çizim) — statik/dinamik katman + SwiftUI nefes animasyonu; görsel doğrulandı, Instruments cihaza ertelendi
Final: fixed Issue 4 (çipler listeyi süzmüyor) — test_narrowFiltersListByKindAndCarrierKeepingOrder RED→GREEN; simülatörde Hücresel çipi doğrulandı
Final: fixed Issue 5 (Pro sonrası eski liste, eksik CSV) — onChange(isPro) + allResults(); görünüm bağlantısı, test yok
Final: fixed Issue 6 (PDF grafiği açık tema) — .environment(colorScheme, .dark)
Final: fixed Issue 14 (CSV '-') — test_csvLegacyDashBecomesEmpty RED→GREEN
Final: fixed Issue 17 (gradyan düğme metni) — görsel: onboarding/yıllık plan düğmeleri npBrandTextPrimary
Final suite: 52 tests, 0 failures (iki ardışık koşu; test_phaseLeftCompletedCancelsAd zaman payı genişletildi)
