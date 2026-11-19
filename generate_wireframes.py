import os
from PIL import Image, ImageDraw, ImageFont

os.makedirs('wireframe_images', exist_ok=True)

# Dimensions for clean mobile wireframe (width: 480, height: 780)
W, H = 480, 780

# Colors matching Quixoria's palette
BG_WARM = (248, 244, 235)       # Parchment cream
BG_CARD = (255, 255, 255)       # Crisp white card
GOLD_PRIMARY = (212, 160, 23)   # Antique Gold
GOLD_DARK = (168, 122, 10)
GOLD_LIGHT = (250, 240, 215)
TEXT_DARK = (38, 38, 48)        # Ink Dark
TEXT_MUTED = (120, 115, 105)
TERRACOTTA = (194, 89, 58)      # La Mancha Terracotta
BORDER_COLOR = (225, 218, 202)
NAV_BG = (255, 253, 248)

def get_font(size, bold=False):
    # Try common Windows TrueType fonts, fallback to default
    candidates = ["arialbd.ttf" if bold else "arial.ttf", "segoeuib.ttf" if bold else "segoeui.ttf", "calibrib.ttf" if bold else "calibri.ttf"]
    for c in candidates:
        try:
            return ImageFont.truetype(c, size)
        except Exception:
            continue
    return ImageFont.load_default()

font_title = get_font(22, bold=True)
font_subtitle = get_font(13, bold=False)
font_header = get_font(16, bold=True)
font_body = get_font(13, bold=False)
font_body_bold = get_font(13, bold=True)
font_small = get_font(11, bold=False)
font_small_bold = get_font(11, bold=True)
font_tiny = get_font(10, bold=False)

def draw_phone_frame(draw):
    # Background
    draw.rectangle([0, 0, W, H], fill=BG_WARM)
    # Phone border
    draw.rounded_rectangle([6, 6, W-7, H-7], radius=32, outline=(180, 170, 155), width=3)
    # Status bar
    draw.text((36, 16), "9:41", fill=TEXT_DARK, font=font_small_bold)
    # Battery & wifi symbols mockup
    draw.rectangle([W-60, 18, W-40, 28], outline=TEXT_DARK, width=1)
    draw.rectangle([W-58, 20, W-44, 26], fill=TEXT_DARK)
    draw.rectangle([W-39, 21, W-37, 25], fill=TEXT_DARK)

def draw_bottom_nav(draw, active_index=0):
    nav_y = H - 65
    draw.rectangle([6, nav_y, W-7, H-7], fill=NAV_BG)
    draw.line([6, nav_y, W-7, nav_y], fill=BORDER_COLOR, width=1)
    
    tabs = ["Quest", "Library", "Notes", "Bazaar", "Profile"]
    icons = ["⚔️", "📖", "📜", "🪙", "👤"]
    tab_w = (W - 14) / 5
    
    for i, (tab, icon) in enumerate(zip(tabs, icons)):
        tx = 7 + i * tab_w + tab_w / 2
        is_active = (i == active_index)
        col = GOLD_PRIMARY if is_active else TEXT_MUTED
        
        # Icon
        draw.text((tx - 8, nav_y + 8), icon, font=font_header)
        # Label
        f = font_tiny
        bbox = draw.textbbox((0, 0), tab, font=f)
        tw = bbox[2] - bbox[0]
        draw.text((tx - tw / 2, nav_y + 36), tab, fill=col, font=f)
        if is_active:
            draw.line([tx - 12, nav_y + 50, tx + 12, nav_y + 50], fill=GOLD_PRIMARY, width=2)

# ==========================================
# 1. Figure 1: Login / Sign Up Screen
# ==========================================
def make_fig1():
    img = Image.new('RGB', (W, H), color=BG_WARM)
    draw = ImageDraw.Draw(img)
    draw_phone_frame(draw)
    
    # Top Logo
    draw.text((W/2 - 65, 80), "🛡️ QUIXORIA", fill=GOLD_PRIMARY, font=get_font(22, bold=True))
    
    # Hero Windmill Artwork
    try:
        wm = Image.open('assets/images/vintage_windmill.jpg').convert('RGB')
        wm = wm.resize((W - 80, 220))
        img.paste(wm, (40, 125))
        draw.rounded_rectangle([40, 125, W - 40, 345], radius=16, outline=GOLD_PRIMARY, width=2)
    except Exception as e:
        draw.rounded_rectangle([40, 125, W - 40, 345], radius=16, fill=BG_CARD, outline=GOLD_PRIMARY, width=2)
        draw.text((W/2 - 60, 220), "[Windmill Art]", fill=TEXT_MUTED, font=font_body)
        
    # Badge on Artwork
    draw.rounded_rectangle([52, 305, 200, 335], radius=8, fill=(255, 255, 255), outline=GOLD_PRIMARY, width=1)
    draw.text((62, 314), "🏰 Realm of La Mancha", fill=TEXT_DARK, font=font_tiny)
    
    # Headline (Duolingo Style)
    draw.text((W/2 - 165, 370), "The most fun way to conquer", fill=TEXT_DARK, font=get_font(19, bold=True))
    draw.text((W/2 - 70, 396), "classic books!", fill=TEXT_DARK, font=get_font(19, bold=True))
    
    # Anti-Doom Scrolling Subtitle
    draw.text((W/2 - 160, 435), "Ditch the doom scroll. Level up thy mind,", fill=TEXT_MUTED, font=font_small)
    draw.text((W/2 - 150, 455), "vocabulary, and daily chivalric streak.", fill=TEXT_MUTED, font=font_small)
    
    # Button 1: GET STARTED (Duolingo 3D Button)
    by1 = 505
    draw.rounded_rectangle([40, by1 + 4, W - 40, by1 + 52], radius=14, fill=(30, 91, 34))
    draw.rounded_rectangle([40, by1, W - 40, by1 + 48], radius=14, fill=(46, 125, 50))
    draw.text((W/2 - 58, by1 + 14), "GET STARTED", fill=(255, 255, 255), font=font_body_bold)
    
    # Button 2: I ALREADY HAVE AN ACCOUNT (Duolingo Outlined Button)
    by2 = 575
    draw.rounded_rectangle([40, by2 + 4, W - 40, by2 + 52], radius=14, fill=(215, 208, 195))
    draw.rounded_rectangle([40, by2, W - 40, by2 + 48], radius=14, fill=(255, 255, 255), outline=GOLD_PRIMARY, width=2)
    draw.text((W/2 - 120, by2 + 14), "I ALREADY HAVE AN ACCOUNT", fill=GOLD_PRIMARY, font=font_body_bold)
    
    # Guest Skip Link
    draw.text((W/2 - 110, 650), "🛡️ Quick Guest Scholar Enlistment (Skip)", fill=GOLD_PRIMARY, font=font_small)
    
    img.save('wireframe_images/fig1_login.png')

def make_fig2():
    img = Image.new('RGB', (W, H), color=BG_WARM)
    draw = ImageDraw.Draw(img)
    draw_phone_frame(draw)
    
    # Top Bar: Literature title & Stats Header
    draw.rectangle([6, 38, W-7, 100], fill=BG_CARD)
    draw.line([6, 100, W-7, 100], fill=BORDER_COLOR, width=1)
    
    draw.text((24, 46), "Don Quixote de la Mancha", fill=TEXT_DARK, font=font_header)
    draw.text((24, 68), "Book I • The Renowned Hidalgo", fill=TEXT_MUTED, font=font_tiny)
    
    # Gems, Streak & Energy stats pills
    draw.rounded_rectangle([W - 190, 52, W - 130, 80], radius=8, fill=GOLD_LIGHT, outline=GOLD_PRIMARY)
    draw.text((W - 182, 58), "💎 480", fill=GOLD_DARK, font=font_small_bold)
    
    draw.rounded_rectangle([W - 120, 52, W - 60, 80], radius=8, fill=(255, 235, 230), outline=TERRACOTTA)
    draw.text((W - 114, 58), "🔥 14", fill=TERRACOTTA, font=font_small_bold)
    
    draw.rounded_rectangle([W - 50, 52, W - 14, 80], radius=8, fill=(230, 245, 230), outline=(76, 175, 80))
    draw.text((W - 46, 58), "⚡ 5", fill=(46, 125, 50), font=font_small_bold)
    
    # Quest Header / Active Milestone Banner
    draw.rounded_rectangle([20, 115, W - 20, 180], radius=16, fill=GOLD_PRIMARY)
    draw.text((36, 126), "CHAPTER 1: THE KNIGHT AWAKENS", fill=(255, 255, 255), font=font_small_bold)
    draw.text((36, 146), "Level 1 of 5 • Reading & Vocabulary Mastery", fill=GOLD_LIGHT, font=font_tiny)
    draw.rounded_rectangle([36, 162, W - 100, 168], radius=3, fill=(255, 255, 255, 120))
    draw.rounded_rectangle([36, 162, 36 + (W - 136)*0.4, 168], radius=3, fill=(255, 255, 255))
    
    # Zigzag Pathway Nodes
    nodes = [
        (W/2, 235, "1", "Completed", True),
        (W/2 + 80, 315, "2", "Active (Current)", True),
        (W/2 - 60, 395, "3", "Locked", False),
        (W/2 + 50, 475, "4", "Locked", False),
        (W/2, 555, "5", "Boss Level", False),
    ]
    
    # Draw curved dotted path
    for i in range(len(nodes) - 1):
        x1, y1 = nodes[i][0], nodes[i][1]
        x2, y2 = nodes[i+1][0], nodes[i+1][1]
        draw.line([x1, y1, x2, y2], fill=(205, 195, 180), width=4)
        
    for x, y, num, status, unlocked in nodes:
        if status == "Completed":
            draw.ellipse([x - 26, y - 26, x + 26, y + 26], fill=(76, 175, 80), outline=(56, 142, 60), width=3)
            draw.text((x - 8, y - 10), "✓", fill=(255, 255, 255), font=font_header)
        elif "Active" in status:
            # Bouncing current node with gold halo
            draw.ellipse([x - 34, y - 34, x + 34, y + 34], fill=GOLD_LIGHT)
            draw.ellipse([x - 28, y - 28, x + 28, y + 28], fill=GOLD_PRIMARY, outline=GOLD_DARK, width=3)
            draw.text((x - 6, y - 10), num, fill=(255, 255, 255), font=font_header)
            # Floating banner
            draw.rounded_rectangle([x - 48, y + 32, x + 48, y + 50], radius=6, fill=GOLD_DARK)
            draw.text((x - 32, y + 35), "START ⚔️", fill=(255, 255, 255), font=font_tiny)
        elif status == "Boss Level":
            draw.ellipse([x - 26, y - 26, x + 26, y + 26], fill=(230, 220, 205), outline=(170, 160, 145), width=2)
            draw.text((x - 8, y - 10), "👑", font=font_body)
        else:
            draw.ellipse([x - 24, y - 24, x + 24, y + 24], fill=(235, 228, 218), outline=(190, 180, 170), width=2)
            draw.text((x - 6, y - 8), "🔒", font=font_small)
            
    # Floating Companion Dialog / Tip
    draw.rounded_rectangle([30, 625, W - 30, 695], radius=14, fill=BG_CARD, outline=GOLD_PRIMARY, width=1)
    draw.text((44, 634), "🛡️ Sir Quixote's Advice:", fill=GOLD_DARK, font=font_small_bold)
    draw.text((44, 654), "“Press onward, scholar! Each chapter conquered", fill=TEXT_DARK, font=font_tiny)
    draw.text((44, 670), "sharpens thy intellect like fine Toledo steel!”", fill=TEXT_DARK, font=font_tiny)
    
    draw_bottom_nav(draw, active_index=0)
    img.save('wireframe_images/fig2_quest_map.png')

# ==========================================
# 3. Figure 3: Literary Reader Screen
# ==========================================
def make_fig3():
    img = Image.new('RGB', (W, H), color=BG_WARM)
    draw = ImageDraw.Draw(img)
    draw_phone_frame(draw)
    
    # Reader AppBar
    draw.rectangle([6, 38, W-7, 95], fill=BG_WARM)
    draw.line([6, 95, W-7, 95], fill=BORDER_COLOR, width=1)
    
    draw.text((20, 52), "‹ Back", fill=GOLD_DARK, font=font_small_bold)
    draw.text((W/2 - 60, 48), "Don Quixote", fill=TEXT_DARK, font=font_header)
    draw.text((W/2 - 75, 70), "Chapter 1 • Mr. Quixana", fill=TEXT_MUTED, font=font_tiny)
    
    # Reader Tool Icons (Ambience, Ask Don Quixote, More)
    draw.text((W - 120, 52), "🎵", font=font_body)
    draw.text((W - 80, 52), "💬", font=font_body)
    draw.text((W - 40, 52), "⋮", font=font_header)
    
    # Reading Progress Bar
    draw.rectangle([6, 96, W-7, 99], fill=BORDER_COLOR)
    draw.rectangle([6, 96, W * 0.45, 99], fill=GOLD_PRIMARY)
    
    # Parchment Reading Body
    ry = 115
    # Drop-cap "I"
    draw.rounded_rectangle([25, ry, 65, ry + 46], radius=6, fill=GOLD_PRIMARY)
    draw.text((37, ry + 6), "I", fill=(255, 255, 255), font=get_font(30, bold=True))
    
    p1 = "N A VILLAGE of La Mancha, the"
    p2 = "name of which I have no desire to call"
    p3 = "to mind, there lived not long since one of"
    p4 = "those gentlemen that keep a lance in the lance-rack, an ancient"
    p5 = "buckler, a lean hack, and a greyhound for coursing."
    
    draw.text((75, ry + 4), p1, fill=TEXT_DARK, font=font_body_bold)
    draw.text((75, ry + 24), p2, fill=TEXT_DARK, font=font_body)
    draw.text((25, ry + 54), p3, fill=TEXT_DARK, font=font_body)
    draw.text((25, ry + 74), p4, fill=TEXT_DARK, font=font_body)
    draw.text((25, ry + 94), p5, fill=TEXT_DARK, font=font_body)
    
    # Tap-to-define word highlighted ("buckler" or "hidalgo")
    hy = ry + 94
    # Underline "buckler"
    draw.rectangle([78, hy + 14, 126, hy + 16], fill=GOLD_PRIMARY)
    
    # Second paragraph
    p6_y = ry + 130
    draw.text((25, p6_y), "An olla of rather more beef than mutton, a salad on most", fill=TEXT_DARK, font=font_body)
    draw.text((25, p6_y + 20), "nights, scraps on Saturdays, lentils on Fridays, and a pigeon", fill=TEXT_DARK, font=font_body)
    draw.text((25, p6_y + 40), "or so extra on Sundays, made away with three-quarters", fill=TEXT_DARK, font=font_body)
    draw.text((25, p6_y + 60), "of his income. The rest of it went in a coat of fine cloth...", fill=TEXT_DARK, font=font_body)
    
    # Interactive Vocabulary Inspection Overlay (Simulated tap on "buckler")
    toy = 350
    draw.rounded_rectangle([25, toy, W - 25, toy + 145], radius=16, fill=BG_CARD, outline=GOLD_PRIMARY, width=2)
    # Header of gloss
    draw.text((40, toy + 14), "🛡️ Buckler", fill=GOLD_DARK, font=font_header)
    draw.text((130, toy + 18), "noun • /ˈbʌk.lər/", fill=TEXT_MUTED, font=font_tiny)
    draw.text((40, toy + 42), "A small, round shield held in the fist, used in medieval", fill=TEXT_DARK, font=font_small)
    draw.text((40, toy + 58), "and renaissance combat for parrying sword strikes.", fill=TEXT_DARK, font=font_small)
    
    # Context quote
    draw.text((40, toy + 82), "“an ancient buckler, a lean hack...”", fill=TEXT_MUTED, font=font_tiny)
    
    # Action buttons
    draw.rounded_rectangle([40, toy + 104, 180, toy + 132], radius=8, fill=GOLD_PRIMARY)
    draw.text((54, toy + 110), "+ Add to Word Bank", fill=(255, 255, 255), font=font_tiny)
    
    draw.rounded_rectangle([195, toy + 104, 305, toy + 132], radius=8, fill=GOLD_LIGHT, outline=GOLD_PRIMARY)
    draw.text((208, toy + 110), "Ask Sir Quixote", fill=GOLD_DARK, font=font_tiny)
    
    # Ambience floating bar
    ay = H - 85
    draw.rounded_rectangle([30, ay, W - 30, ay + 48], radius=24, fill=(40, 36, 32))
    draw.text((46, ay + 14), "🎵 Ambience: Classical Lute (Gentle Ballad)", fill=GOLD_LIGHT, font=font_small)
    draw.text((W - 65, ay + 14), "❚❚ 45%", fill=GOLD_PRIMARY, font=font_small_bold)
    
    img.save('wireframe_images/fig3_reader.png')

# ==========================================
# 4. Figure 4: Socratic Counsel Sheet
# ==========================================
def make_fig4():
    img = Image.new('RGB', (W, H), color=BG_WARM)
    draw = ImageDraw.Draw(img)
    draw_phone_frame(draw)
    
    # Dimmed reader background underneath
    draw.text((25, 60), "In a village of La Mancha, the name of which I have no desire...", fill=(180, 175, 165), font=font_small)
    draw.rectangle([6, 95, W-7, H-7], fill=(0, 0, 0, 110)) # Modal scrim
    
    # Socratic Bottom Sheet
    sy = 140
    draw.rounded_rectangle([16, sy, W - 16, H - 16], radius=24, fill=BG_CARD, outline=GOLD_PRIMARY, width=2)
    
    # Drag notch
    draw.rounded_rectangle([W/2 - 20, sy + 10, W/2 + 20, sy + 14], radius=2, fill=BORDER_COLOR)
    
    # Header: Mascot avatar & Title
    draw.ellipse([36, sy + 25, 78, sy + 67], fill=GOLD_LIGHT, outline=GOLD_PRIMARY)
    draw.text((46, sy + 34), "🛡️", font=get_font(20))
    
    draw.text((90, sy + 26), "Ask Don Quixote", fill=TEXT_DARK, font=font_header)
    draw.text((90, sy + 48), "Thy Knightly Reading Friend • Don Quixote Book I", fill=TEXT_MUTED, font=font_tiny)
    draw.text((W - 50, sy + 32), "✕", fill=TEXT_MUTED, font=font_header)
    
    draw.line([16, sy + 80, W - 16, sy + 80], fill=BORDER_COLOR, width=1)
    
    # Selected Passage Box
    py = sy + 95
    draw.rounded_rectangle([32, py, W - 32, py + 54], radius=10, fill=BG_WARM, outline=BORDER_COLOR)
    draw.text((44, py + 8), "“You have been in Afghanistan, I perceive...”", fill=TEXT_DARK, font=font_tiny)
    draw.text((44, py + 28), "Passage from A Study in Scarlet • Chapter 1", fill=GOLD_DARK, font=font_tiny)
    
    # Quick Prompt Chips
    qy = py + 68
    draw.text((32, qy), "Ask Sir Quixote:", fill=TEXT_MUTED, font=font_small_bold)
    
    chips = [
        ("💡 What does this mean?", True),
        ("🔍 Explain tricky words", False),
        ("⚔️ What would Don Quixote do?", False),
        ("📖 Tell me what happens next!", False),
    ]
    cy = qy + 22
    for label, is_sel in chips:
        bg = GOLD_LIGHT if is_sel else (245, 242, 235)
        border = GOLD_PRIMARY if is_sel else BORDER_COLOR
        txt_col = GOLD_DARK if is_sel else TEXT_DARK
        draw.rounded_rectangle([32, cy, W - 32, cy + 32], radius=8, fill=bg, outline=border, width=1)
        draw.text((44, cy + 8), label, fill=txt_col, font=font_small_bold if is_sel else font_small)
        if is_sel:
            draw.text((W - 60, cy + 8), "✓ Active", fill=GOLD_DARK, font=font_tiny)
        cy += 40
        
    # Don Quixote's Socratic Wisdom Card
    wy = cy + 10
    draw.rounded_rectangle([32, wy, W - 32, wy + 115], radius=14, fill=GOLD_LIGHT, outline=GOLD_PRIMARY, width=1)
    draw.text((46, wy + 12), "🛡️ Sir Quixote's Advice  •  Socratic Guide", fill=GOLD_DARK, font=font_small_bold)
    
    wisdom = [
        "“Hearken, noble student! Sherlock Holmes deduced",
        "right away that Watson had been in the army because",
        "of his sunburnt face, stiff arm, and tired look. Even",
        "without a sword, Holmes observes like a vigilant knight!”"
    ]
    for idx, line in enumerate(wisdom):
        draw.text((46, wy + 34 + idx * 17), line, fill=TEXT_DARK, font=font_tiny)
        
    # Action button: Save Advice to Notes
    draw.rounded_rectangle([32, wy + 130, W - 32, wy + 168], radius=10, fill=GOLD_PRIMARY)
    draw.text((W/2 - 70, wy + 142), "Inscribe Advice to Notes 🔖", fill=(255, 255, 255), font=font_small_bold)
    
    img.save('wireframe_images/fig4_counsel.png')

# ==========================================
# 5. Figure 5: Scriptorium & Word Bank Screen
# ==========================================
def make_fig5():
    img = Image.new('RGB', (W, H), color=BG_WARM)
    draw = ImageDraw.Draw(img)
    draw_phone_frame(draw)
    
    # Header
    draw.rectangle([6, 38, W-7, 95], fill=BG_CARD)
    draw.text((24, 48), "The Scriptorium", fill=TEXT_DARK, font=font_title)
    draw.text((24, 74), "Thy Literary Notes & Spaced Repetition Vocabulary", fill=TEXT_MUTED, font=font_tiny)
    
    # Segmented Tabs: Notes / Word Bank / Flashcards
    ty = 110
    draw.rounded_rectangle([30, ty, W - 30, ty + 38], radius=10, fill=(235, 230, 220))
    draw.rounded_rectangle([33, ty + 3, W/3 - 4, ty + 35], radius=8, fill=GOLD_PRIMARY)
    draw.text((W/6 - 15, ty + 10), "Word Bank", fill=(255, 255, 255), font=font_small_bold)
    draw.text((W/2 - 15, ty + 10), "Notes", fill=TEXT_MUTED, font=font_small)
    draw.text((5*W/6 - 20, ty + 10), "Review (8)", fill=TEXT_MUTED, font=font_small)
    
    # Spaced Repetition Stats Card
    sy = 165
    draw.rounded_rectangle([30, sy, W - 30, sy + 65], radius=12, fill=BG_CARD, outline=BORDER_COLOR)
    draw.text((46, sy + 12), "📚 42 Words Mastered", fill=GOLD_DARK, font=font_small_bold)
    draw.text((46, sy + 32), "8 words scheduled for spaced repetition review today", fill=TEXT_MUTED, font=font_tiny)
    draw.rounded_rectangle([W - 120, sy + 16, W - 44, sy + 48], radius=8, fill=GOLD_PRIMARY)
    draw.text((W - 108, sy + 24), "Practice Now", fill=(255, 255, 255), font=font_tiny)
    
    # Vocabulary Flashcard Item 1
    cy1 = 245
    draw.rounded_rectangle([30, cy1, W - 30, cy1 + 105], radius=12, fill=BG_CARD, outline=BORDER_COLOR)
    draw.text((46, cy1 + 12), "Hidalgo", fill=TEXT_DARK, font=font_header)
    draw.text((120, cy1 + 16), "noun  •  Don Quixote Book I", fill=TEXT_MUTED, font=font_tiny)
    draw.text((46, cy1 + 38), "An honorable Spanish gentleman or knight without a hereditary title.", fill=TEXT_DARK, font=font_small)
    draw.text((46, cy1 + 58), "“lived not long since one of those hidalgos that keep a lance...”", fill=TEXT_MUTED, font=font_tiny)
    # Mastery bar
    draw.rectangle([46, cy1 + 84, 180, cy1 + 88], fill=BORDER_COLOR)
    draw.rectangle([46, cy1 + 84, 150, cy1 + 88], fill=(76, 175, 80))
    draw.text((190, cy1 + 80), "Level 4 (Strong)", fill=(76, 175, 80), font=font_tiny)
    
    # Vocabulary Flashcard Item 2
    cy2 = 365
    draw.rounded_rectangle([30, cy2, W - 30, cy2 + 105], radius=12, fill=BG_CARD, outline=BORDER_COLOR)
    draw.text((46, cy2 + 12), "Buckler", fill=TEXT_DARK, font=font_header)
    draw.text((120, cy2 + 16), "noun  •  Don Quixote Book I", fill=TEXT_MUTED, font=font_tiny)
    draw.text((46, cy2 + 38), "A small, round shield held in the hand to block sword strikes.", fill=TEXT_DARK, font=font_small)
    draw.text((46, cy2 + 58), "“an ancient buckler, a lean hack, and a greyhound...”", fill=TEXT_MUTED, font=font_tiny)
    draw.rectangle([46, cy2 + 84, 180, cy2 + 88], fill=BORDER_COLOR)
    draw.rectangle([46, cy2 + 84, 90, cy2 + 88], fill=GOLD_PRIMARY)
    draw.text((190, cy2 + 80), "Level 2 (Learning)", fill=GOLD_DARK, font=font_tiny)
    
    # Vocabulary Flashcard Item 3
    cy3 = 485
    draw.rounded_rectangle([30, cy3, W - 30, cy3 + 105], radius=12, fill=BG_CARD, outline=BORDER_COLOR)
    draw.text((46, cy3 + 12), "Ineffable", fill=TEXT_DARK, font=font_header)
    draw.text((130, cy3 + 16), "adj  •  The Great Gatsby", fill=TEXT_MUTED, font=font_tiny)
    draw.text((46, cy3 + 38), "Too great or beautiful to be expressed or described in words.", fill=TEXT_DARK, font=font_small)
    draw.text((46, cy3 + 58), "“an ineffable romance that hovered over the summer night...”", fill=TEXT_MUTED, font=font_tiny)
    draw.rectangle([46, cy3 + 84, 180, cy3 + 88], fill=BORDER_COLOR)
    draw.rectangle([46, cy3 + 84, 170, cy3 + 88], fill=(76, 175, 80))
    draw.text((190, cy3 + 80), "Level 5 (Mastered)", fill=(76, 175, 80), font=font_tiny)
    
    draw_bottom_nav(draw, active_index=2)
    img.save('wireframe_images/fig5_scriptorium.png')

# ==========================================
# 6. Figure 6: Profile & Bazaar Shop Screen
# ==========================================
def make_fig6():
    img = Image.new('RGB', (W, H), color=BG_WARM)
    draw = ImageDraw.Draw(img)
    draw_phone_frame(draw)
    
    # Header
    draw.rectangle([6, 38, W-7, 125], fill=BG_CARD)
    # Profile avatar
    draw.ellipse([24, 48, 80, 104], fill=GOLD_LIGHT, outline=GOLD_PRIMARY, width=2)
    draw.text((36, 60), "⚔️", font=get_font(26))
    
    draw.text((95, 52), "Knight Alonzo", fill=TEXT_DARK, font=font_header)
    draw.text((95, 74), "Level 7 • Gallant Champion of La Mancha", fill=GOLD_DARK, font=font_tiny)
    draw.text((95, 92), "alonzo@quixoria.realm • Signed In", fill=TEXT_MUTED, font=font_tiny)
    
    # Gems & Points Balance Banner
    by = 140
    draw.rounded_rectangle([30, by, W - 30, by + 65], radius=14, fill=(40, 36, 32))
    draw.text((48, by + 14), "THE CHIVALRIC BAZAAR", fill=GOLD_PRIMARY, font=font_small_bold)
    draw.text((48, by + 34), "Treasury: 480 Knightly Gems", fill=(255, 255, 255), font=font_body_bold)
    draw.text((W - 110, by + 34), "🔥 14-Day Streak", fill=TERRACOTTA, font=font_small_bold)
    
    # Streak Essentials Category
    sy = by + 80
    draw.text((30, sy), "Streak Protection Essentials", fill=TEXT_DARK, font=font_small_bold)
    
    # Item 1: Streak Shield / Freeze
    card_w = (W - 75) / 2
    draw.rounded_rectangle([30, sy + 20, 30 + card_w, sy + 155], radius=12, fill=BG_CARD, outline=BORDER_COLOR)
    draw.ellipse([30 + card_w/2 - 22, sy + 32, 30 + card_w/2 + 22, sy + 76], fill=GOLD_LIGHT)
    draw.text((30 + card_w/2 - 12, sy + 42), "🛡️", font=font_header)
    draw.text((42, sy + 84), "Streak Shield", fill=TEXT_DARK, font=font_small_bold)
    draw.text((42, sy + 102), "Protects 1 missed day", fill=TEXT_MUTED, font=font_tiny)
    draw.rounded_rectangle([42, sy + 120, 30 + card_w - 12, sy + 144], radius=6, fill=GOLD_PRIMARY)
    draw.text((62, sy + 125), "💎 60 Gems", fill=(255, 255, 255), font=font_tiny)
    
    # Item 2: Streak Rekindle
    draw.rounded_rectangle([45 + card_w, sy + 20, W - 30, sy + 155], radius=12, fill=BG_CARD, outline=BORDER_COLOR)
    draw.ellipse([45 + card_w + card_w/2 - 22, sy + 32, 45 + card_w + card_w/2 + 22, sy + 76], fill=(255, 235, 230))
    draw.text((45 + card_w + card_w/2 - 12, sy + 42), "🔥", font=font_header)
    draw.text((57 + card_w, sy + 84), "Streak Rekindle", fill=TEXT_DARK, font=font_small_bold)
    draw.text((57 + card_w, sy + 102), "Repair broken streak", fill=TEXT_MUTED, font=font_tiny)
    draw.rounded_rectangle([57 + card_w, sy + 120, W - 42, sy + 144], radius=6, fill=TERRACOTTA)
    draw.text((77 + card_w, sy + 125), "💎 90 Gems", fill=(255, 255, 255), font=font_tiny)
    
    # Reader Themes & Parchment Styles
    py = sy + 175
    draw.text((30, py), "Parchment Aesthetics & Themes", fill=TEXT_DARK, font=font_small_bold)
    
    themes = [
        ("Classic Parchment", "Warm Renaissance scroll", "Equipped ✓", True),
        ("Black Plague Dark", "High contrast night reading", "Equip", False),
        ("Cozy Hearthstone", "Warm ember firelight", "💎 120 Gems", False),
    ]
    ty = py + 20
    for name, desc, btn, is_eq in themes:
        draw.rounded_rectangle([30, ty, W - 30, ty + 46], radius=10, fill=BG_CARD, outline=GOLD_PRIMARY if is_eq else BORDER_COLOR)
        draw.text((44, ty + 8), name, fill=TEXT_DARK, font=font_small_bold)
        draw.text((44, ty + 26), desc, fill=TEXT_MUTED, font=font_tiny)
        
        btn_bg = (76, 175, 80) if is_eq else (GOLD_PRIMARY if "Gems" in btn else GOLD_LIGHT)
        btn_col = (255, 255, 255) if is_eq or "Gems" in btn else GOLD_DARK
        draw.rounded_rectangle([W - 125, ty + 10, W - 42, ty + 36], radius=6, fill=btn_bg)
        draw.text((W - 115, ty + 16), btn, fill=btn_col, font=font_tiny)
        ty += 54
        
    draw_bottom_nav(draw, active_index=3)
    img.save('wireframe_images/fig6_profile_bazaar.png')

print('Generating 6 wireframes...')
make_fig1()
make_fig2()
make_fig3()
make_fig4()
make_fig5()
make_fig6()
print('ALL_WIREFRAMES_GENERATED_SUCCESSFULLY')
