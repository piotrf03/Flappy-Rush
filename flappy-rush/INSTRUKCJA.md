# Flappy Rush — instrukcja

## Co to za gra
Plansza jak we Flappy Bird, ale skaczesz jak w Angry Birds: **przeciągasz i puszczasz** kulkę (proca).
Ekran cały czas przesuwa się w prawo i **przyspiesza**. Przegrywasz, gdy kulka wypadnie poza ekran
albo gdy trafi ją spadający kolczasty blok.

---

## 1. Uruchomienie na komputerze
1. Otwórz **Godot 4.6** i wczytaj ten projekt (wskaż plik `project.godot`).
2. Przy pierwszym otwarciu Godot zaimportuje grafiki i **dźwięki** (pliki z folderu `sfx/`) — to potrwa kilka sekund.
3. Naciśnij **F5** (lub przycisk ▶ w prawym górnym rogu), aby zagrać.

Sterowanie na PC: przytrzymaj **lewy przycisk myszy** na kulce, odciągnij w przeciwną stronę
(zobaczysz linię procy i kropki przewidywanego lotu) i puść.

---

## 2. Eksport na telefon (Android / plik APK)

**APK** to plik instalacyjny aplikacji na Androida — to jego kopiujesz na telefon, żeby zagrać.

### Krok A — Zainstaluj szablony eksportu (jednorazowo)
W Godot: menu **Editor → Manage Export Templates… → Download and Install**.
To pobiera komponenty potrzebne do budowania gier na telefon (~700 MB).

### Krok B — Przygotuj klucz podpisu (jednorazowo)
Android wymaga, by każda aplikacja była „podpisana". Do testów wystarczy klucz debug:
1. Zainstaluj **Java JDK** (np. Temurin/Adoptium), jeśli go nie masz.
2. W Godot: **Editor → Editor Settings → Export → Android**.
3. W polu **Debug Keystore** wskaż plik `debug.keystore`. Jeśli go nie masz, utwórz go raz w terminalu:
   ```
   keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
   ```
4. Uzupełnij `User`: `androiddebugkey`, `Password`: `android`.

### Krok C — Zbuduj APK
1. Menu **Project → Export…**.
2. Na liście jest już gotowy preset **„Android"** (skonfigurowałem go: orientacja pozioma, nazwa „Flappy Rush").
3. Kliknij **Export Project**, wybierz miejsce zapisu (np. `build/FlappyRush.apk`), odznacz „Export With Debug" jeśli chcesz wersję release — do testów zostaw zaznaczone.
4. Godot wygeneruje plik **`FlappyRush.apk`**.

### Krok D — Zainstaluj na telefonie
**Najprościej (przez kabel USB):**
1. W telefonie włącz **Opcje programisty** i **Debugowanie USB**.
2. Podłącz telefon kablem do komputera.
3. W Godot, w prawym górnym rogu, pojawi się ikona telefonu **One-click deploy** — kliknij, a gra sama zainstaluje się i uruchomi.

**Albo ręcznie:**
1. Skopiuj plik `FlappyRush.apk` na telefon (kabel, e-mail, dysk).
2. Otwórz go w telefonie i potwierdź instalację (zezwól na „instalację z nieznanych źródeł").

Sterowanie na telefonie: dotknij kulki, przeciągnij palcem i puść. Po przegranej dotknij ekranu, by zagrać ponownie.

---

## 3. Co zostało zmienione / dodane

**Dźwięki** (folder `sfx/`, podpięte przez autoload `Audio`):
- `launch` — wystrzał z procy (wysokość tonu zależy od siły),
- `bounce` — odbicie kulki od ziemi/rur,
- `score` — zdobycie punktu,
- `gameover` — przegrana,
- `whoosh` — nadlatujący deszcz bloków.

**Wersja mobilna:**
- orientacja pozioma, skalowanie do każdego ekranu (`stretch = canvas_items / expand`),
- obsługa dotyku (proca i restart działają palcem),
- gotowy preset eksportu Android (`export_presets.cfg`).

**Wygląd:**
- gradientowe niebo (shader) + przesuwające się chmury z parallaxem,
- kulka z oczami patrzącymi w stronę lotu, cieniem, obrysem i efektem „squash" przy odbiciu,
- celownik: linia procy + kropki przewidywanej trajektorii,
- cząsteczki (ślad lotu, błysk przy wystrzale, eksplozja przy śmierci),
- ładniejsze rury (obrys + cieniowanie) i groźne kolczaste, obracające się bloki,
- czytelniejsze UI z obrysem tekstu, rekordem **Best** i podpowiedzią na start.

**Rozgrywka:**
- zapisywany **najlepszy wynik** (plik `user://highscore.save`),
- ograniczenie maksymalnej prędkości przewijania (żeby na szybkich telefonach było grywalnie).
