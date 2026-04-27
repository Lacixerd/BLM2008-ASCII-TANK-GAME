# BLM2008 ASCII Tank Oyunu — 8086 Assembly (emu8086)

Mikroişlemciler dersi için yazılmış, **emu8086** üzerinde doğrudan çalışabilen
bir 8086 Assembly oyunu. Oyuncu tankını yönlendirerek sınırlı mermiyle (20 adet)
haritadaki 8 sabit hedefi vurmaya çalışır.

## Performans Optimizasyonları (emu8086 için)

- **Hızlı string çizimi:** `draw_string` her string için tek bir `MUL` hesaplar,
sonra `STOSW` döngüsüyle video belleğe yazar. Eski versiyonda her karakter
için ayrı MUL yapılıyordu (~700 MUL → ~15 MUL).
- **Seçici güncelleme:** Oyun döngüsünde tüm ekran yeniden çizilMEZ. Kenarlar,
engeller ve etiketler sadece bir kez çizilir. Her karede yalnızca değişen
öğeler (tank, mermiler, skor rakamları) güncellenir.
- **Hızlı border:** `draw_border` önceden hesaplanmış offset'ler ve `REP STOSW`
kullanır — hiç MUL yok.
- **Tek karakter güncellemeleri:** Tank hareketi = 2 `put_char` (eski sil, yeni çiz).
Mermi güncellemesi = mermi sayısı × 2 `put_char`. Skor = ~10 `put_char`.

## Kontroller


| Tuş                  | İşlev                           |
| -------------------- | ------------------------------- |
| Ok tuşları / W A S D | Hareket et ve yönlen            |
| SPACE                | Ateş et                         |
| ESC                  | Menüye dön / oyundan çık        |
| ENTER                | Menüde oyunu başlat             |
| R                    | Oyun sonu ekranında tekrar oyna |
| Q / ESC              | Oyun sonu ekranında çık         |


## Simgeler

```
^ v < >    Tank (baktığı yön)
*          Hedef (kırmızı)
#          Engel (gri)
.          Mermi (beyaz)
```

## Oyun Kuralları

- Maksimum **20 mermi** hakkınız var.
- Haritada **8 sabit hedef** (`*`) bulunur — hepsini vurun.
- **Engeller** (`#`) mermileri durdurur ama vurulmaz.
- Mermiler doğrusal ilerler; kenar/engel/hedef çarpışması kontrol edilir.
- Tüm hedefler vurulursa **kazanırsınız**.
- Mermi biter ve ekranda aktif mermi kalmazsa **kaybedersiniz**.

## Ekranlar

1. **Menü:** Başlık, kurallar, kontroller, en iyi skor, ENTER/ESC seçimi.
2. **Oyun:** Üst durum çubuğu, çerçeveli alan, alt yardım şeridi.
3. **Oyun Sonu:** Kazan/Kaybet/Çık mesajı, yeni rekor bildirimi, skor,
  `R` = tekrar oyna, `Q`/`ESC` = çık.

## En İyi Skor

`TANK.DAT` dosyasında 2-byte word olarak saklanır. Program her açılışta
dosyayı okur, kapanışta (veya oyun bitiminde) günceller.
emu8086'nın sanal dosya sisteminde çalışır.

## Teknik Detaylar

- **Format:** `.MODEL SMALL` (EXE), MASM/TASM uyumlu söz dizimi
- **Ekran:** 80×25 text modu (INT 10h, mode 03h), doğrudan 0B800h video belleği
- **Giriş:** Non-blocking klavye (INT 16h AH=01h/00h)
- **Zamanlama:** BIOS tick sayacı (INT 1Ah), ~9 Hz mermi hareketi
- **Dosya I/O:** DOS INT 21h (3Ch/3Dh/3Eh/3Fh/40h)
- **35 prosedür**, temiz push/pop stack disiplini

