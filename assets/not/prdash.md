Görseldeki modern ve katmanlı NBA oyuncu profil arayüzünü Claude'un eksiksiz kodlayabilmesi için hazırlanan detaylı Flutter prompt'u:

---

**Prompt:**

Act as a Senior Flutter & UI/UX Developer. Please create a clean, responsive, and pixel-perfect Flutter web/desktop dashboard widget based on the following detailed layout specification:

**1. General Layout & Background Architecture**

* **Container**: Light grey/off-white background (`#F4F5F8`) with rounded outer corners and subtle shadow.
* **Layout Structure**: Use a `Stack` as the main container to layer background typography, the central cutout image, and foreground UI elements smoothly.

**2. Navigation Bar (Top)**

* **Left**: NBA Logo + Top navigation menu (`Row` with `TextButton` items: "SCORES", "SCHEDULE", "NEWS", "STATS", "PLAYERS", "TEAMS").
* **Right**: User profile avatar (`CircleAvatar`) with a small dropdown arrow icon.
* **Left Sidebar**: Ultra-narrow vertical navigation rail (`#0D2240` dark blue background) containing a subtle hamburger menu icon.

**3. Layering & Center Cutout (Hero Area)**

* **Background Layer**:
* Giant watermark typography in faint grey (`#E5E8ED`) spelling "CLIPPERS".
* Oversized bold red text `#13` on the left and position `F` on the right.
* Thin circular vector outline surrounding the hero player.


* **Foreground Layer**:
* High-resolution cutout image of the player (Paul George) overlapping the background text and floating slightly above the bottom boundary.



**4. Left Side Panel (Player Information)**

* **Header**:
* Outlined "Favorite" button (`ElevatedButton.icon` with star icon).
* Main Name: "Paul George" in large, bold typography with a subtle dropdown caret.
* Sub-header: LA Clippers team logo alongside "LA Clippers".


* **Key Specs Grid**: Two columns showing **HEIGHT** (`6 ft 8 in / 2.03m`) and **WEIGHT** (`220 lbs / 99.8kg`).
* **Personal Data Table**: Thin horizontal dividers containing key-value pairs:
* **BORN**: `05/02/1990`
* **AGE**: `29 years`
* **FROM**: `Fresno State`



**5. Right Side Panel (Matches & Media)**

* **Match Score Card**:
* White card (`Card` with rounded corners and light elevation).
* Tab Bar at top: `LAST GAME` (active, dark bold) | `NEXT GAME` (inactive).
* Subtitle: `LEAGUE PASS`.
* Scoreboard Row: Team logos, scores (`101` vs `150`), `FINAL` tag, team records (`4 - 8`, `8 - 5`), and game date (`05/02/2019`).


* **Video Carousel / Highlights**:
* Horizontal scroll/list view containing video thumbnail cards with overlay play icons, video duration badges (e.g., `1:15`), and title captions below.


* **Career Summary Data**:
* **NBA DEBUT**: `2010`
* **YEARS IN NBA**: `9`
* **PREVIOUSLY**: `LAC 2019-20`, `OKC 2017-19`



**6. Bottom Floating Cards (Stat Highlights)**

* **Positioning**: Positioned over the lower portion of the screen using `Positioned` in the `Stack`.
* **Design**: 3 dark royal-blue gradient cards (`#0D3B8E` to `#0A2968`) with drop shadows (`BoxShadow`) and rounded corners.
* **Card Content**:
1. **POINTS PER GAME**: `35.0` (with a small blue up-arrow icon)
2. **REBOUNDS PER GAME**: `6.5` (with a small blue up-arrow icon)
3. **ASSISTS PER GAME**: `3.5` (with a small blue up-arrow icon)



**Code Requirements:**

* Use clean, modular Flutter code (break components into smaller `StatCard`, `InfoRow`, and `MatchScoreCard` widgets).
* Ensure proper use of `GoogleFonts` (e.g., Inter or Montserrat) for modern typography hierarchy.
* Add dummy asset paths (e.g., `assets/player.png`, `assets/clippers.png`) for image references.