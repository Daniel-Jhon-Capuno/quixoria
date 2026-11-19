import os
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, hex_color):
    shading_elm = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{hex_color}"/>')
    cell._tc.get_or_add_tcPr().append(shading_elm)

def set_cell_margins(cell, top=100, bottom=100, left=140, right=140):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{m}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def set_table_borders(table, color="D4AF37", sz="4", val="single"):
    tblPr = table._tbl.tblPr
    borders = parse_xml(
        f'<w:tblBorders {nsdecls("w")}>'
        f'  <w:top w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'  <w:bottom w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'  <w:left w:val="none"/>'
        f'  <w:right w:val="none"/>'
        f'  <w:insideH w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'  <w:insideV w:val="none"/>'
        f'</w:tblBorders>'
    )
    tblPr.append(borders)

def build_quixoria_documentation():
    doc = docx.Document()

    # Configure Margins (Standard 1 inch all around)
    for section in doc.sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)

    # Color Palette: Clean, professional, college-friendly
    C_NAVY = RGBColor(0x1B, 0x2A, 0x4A)      # Main headings
    C_GOLD = RGBColor(0xC4, 0x82, 0x0A)      # Subheadings & accents
    C_BODY = RGBColor(0x22, 0x22, 0x22)      # Body text
    C_MUTED = RGBColor(0x55, 0x55, 0x55)     # Captions / Secondary text

    # Helper text formatting functions
    def add_chapter_title(ch_num, ch_title):
        p1 = doc.add_paragraph()
        p1.paragraph_format.space_before = Pt(14)
        p1.paragraph_format.space_after = Pt(2)
        r1 = p1.add_run(ch_num)
        r1.font.name = 'Arial'
        r1.font.size = Pt(18)
        r1.font.bold = True
        r1.font.color.rgb = C_NAVY

        p2 = doc.add_paragraph()
        p2.paragraph_format.space_before = Pt(0)
        p2.paragraph_format.space_after = Pt(14)
        r2 = p2.add_run(ch_title)
        r2.font.name = 'Arial'
        r2.font.size = Pt(14)
        r2.font.bold = True
        r2.font.color.rgb = C_GOLD

    def add_section_heading(title):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(14)
        p.paragraph_format.space_after = Pt(6)
        r = p.add_run(title)
        r.font.name = 'Arial'
        r.font.size = Pt(12)
        r.font.bold = True
        r.font.color.rgb = C_NAVY

    def add_body_p(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.line_spacing = 1.15
        r = p.add_run(text)
        r.font.name = 'Arial'
        r.font.size = Pt(10)
        r.font.color.rgb = C_BODY
        return p

    def add_bold_body_p(lead_in, text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(2)
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.line_spacing = 1.15
        r_lead = p.add_run(lead_in)
        r_lead.font.name = 'Arial'
        r_lead.font.size = Pt(10)
        r_lead.font.bold = True
        r_lead.font.color.rgb = C_NAVY
        r_text = p.add_run(text)
        r_text.font.name = 'Arial'
        r_text.font.size = Pt(10)
        r_text.font.color.rgb = C_BODY
        return p

    def add_figure(img_path, caption_title, description):
        p_img = doc.add_paragraph()
        p_img.paragraph_format.space_before = Pt(12)
        p_img.paragraph_format.space_after = Pt(4)
        p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
        if os.path.exists(img_path):
            p_img.add_run().add_picture(img_path, width=Inches(3.3))
        
        p_cap = doc.add_paragraph()
        p_cap.paragraph_format.space_before = Pt(2)
        p_cap.paragraph_format.space_after = Pt(4)
        p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r_cap = p_cap.add_run(caption_title)
        r_cap.font.name = 'Arial'
        r_cap.font.size = Pt(10)
        r_cap.font.bold = True
        r_cap.font.color.rgb = C_NAVY

        p_desc = doc.add_paragraph()
        p_desc.paragraph_format.space_before = Pt(0)
        p_desc.paragraph_format.space_after = Pt(12)
        p_desc.paragraph_format.line_spacing = 1.15
        r_desc = p_desc.add_run(description)
        r_desc.font.name = 'Arial'
        r_desc.font.size = Pt(9.5)
        r_desc.font.color.rgb = C_MUTED

    # =========================================================================
    # CHAPTER 1: CONCEPTUALIZING THE MOBILE APPLICATION
    # =========================================================================
    add_chapter_title("Chapter 1", "Conceptualizing the Mobile Application")

    add_section_heading("Introduction")
    add_body_p(
        "Quixoria is a gamified mobile reading application designed to help college students and modern readers rediscover the joy, depth, "
        "and excitement of classic literature. It combines reading with interactive game mechanics—such as a visual chapter quest map, daily reading streaks, "
        "experience points (XP), gems, and a vocabulary word bank—alongside a built-in literary companion inspired by Miguel de Cervantes' Don Quixote."
    )
    add_body_p(
        "In today's digital world, many students struggle with reading classic books because of the constant habit of doom scrolling on social media feeds "
        "like TikTok and Instagram. Endless scrolling through short-form videos has shortened attention spans, leading to mental fatigue and what many young people "
        "call 'brain rot.' As a result, sitting down to read a 500-page classic novel feels overwhelming, boring, or nearly impossible. Classic books often contain "
        "unfamiliar old words, long complex sentences, and historical references that cause readers to lose interest quickly."
    )
    add_body_p(
        "Quixoria directly solves these modern reading challenges. Instead of letting students get lost in mindless scrolling, Quixoria redirects mobile phone habits "
        "into a fun and rewarding reading quest. By breaking books down into bite-sized 10-to-15 minute chapters, providing instant tap-to-define definitions for old words, "
        "offering guided Socratic reflections, and playing soothing acoustic background music, Quixoria makes reading classic books exciting, refreshing, and deeply satisfying."
    )

    add_section_heading("Purpose and Value Proposition")
    add_body_p(
        "The primary purpose of Quixoria is to bring people back to reading, rebuild healthy attention spans, and help students overcome the intimidation of classic literature. "
        "Many college students have required reading assignments for their English, literature, and humanities courses, but they find it hard to disconnect from social media "
        "and focus on difficult texts. While websites like SparkNotes give quick plot summaries, they do not help students actually read the original stories or improve their vocabulary."
    )
    add_body_p(
        "What makes Quixoria uniquely valuable is that it turns classic reading into an engaging and achievable daily habit. By borrowing the motivating elements of popular apps—such as "
        "Duolingo-style chapter paths, daily streaks, and reward gems—it gives readers the immediate positive feedback they are used to getting on their phones, but applies it toward personal "
        "growth and great books. The app includes 'The Scriptorium,' a personal vocabulary word bank that lets students save difficult words and practice them with flashcards. Readers can also "
        "customize text size, switch to a dyslexia-friendly font (OpenDyslexic), choose gentle reading themes, and listen to relaxing lute music. Best of all, Quixoria works 100% offline, allowing "
        "students to read peacefully anywhere without internet distractions."
    )

    add_section_heading("Target Audience")
    add_body_p(
        "The primary target audience for Quixoria is college and high school students who have required literature readings or who want to read more books, but find themselves losing hours "
        "every day to doom scrolling on their smartphones. It is also designed for young adults and book club members who used to love reading when they were younger, but lost the habit due to "
        "digital overload, as well as ESL (English as a Second Language) learners who want to expand their advanced English vocabulary through classic stories."
    )
    add_body_p(
        "These users often lead busy, stressful academic lives and have fragmented attention spans. Quixoria meets their needs by turning thick, intimidating books into bite-sized chapter quests "
        "that can be completed in short study breaks. The instant word lookup feature removes the friction of stopping to search a dictionary, while the daily streak counter and gem rewards give students "
        "a healthy, satisfying reason to open the app every single day instead of scrolling through social media."
    )

    add_section_heading("Core Functionalities")
    add_bold_body_p("1. Chapter Quest Map: ", 
        "Displays each classic book as a visual zigzag learning journey. Chapters are presented as interactive circles that clearly show which chapters are completed, which chapter is currently active, "
        "and which ones are locked. Completing a chapter awards XP and gems and increases the user's daily reading streak."
    )
    add_bold_body_p("2. Interactive Book Reader: ",
        "A clean and comfortable reading screen with customizable text size, dyslexia-friendly font options (OpenDyslexic), different parchment background color themes (Warm Parchment, Midnight Manor, Sepia Script), "
        "and an instant tap-to-define feature that explains difficult words immediately on screen."
    )
    add_bold_body_p("3. Don Quixote's Socratic Counsel (Literary Guide): ",
        "A built-in interactive reading companion that offers curated discussion prompts, historical context, and guided reflection questions (such as 'What does this mean?' and 'Explain tricky words') "
        "to help students understand confusing paragraphs without spoiling the story."
    )
    add_bold_body_p("4. The Scriptorium (Word Bank & Flashcards): ",
        "Automatically saves every difficult word the student looks up while reading. It organizes words into mastery levels (Novice, Hidalgo, and Master) and provides digital flashcard practice "
        "to help students remember new vocabulary words for class and everyday life."
    )
    add_bold_body_p("5. Acoustic Background Music & Soundscapes: ",
        "Provides calming instrumental music, including gentle classical lute melodies and soft ambient atmospheres, with play, pause, volume, and looping controls to help students focus and block out distracting noises."
    )
    add_bold_body_p("6. Chivalric Bazaar (Rewards Shop): ",
        "A motivating in-app store where students spend their earned reading gems on helpful perks, like Streak Shields (to protect their daily streak if they miss a busy study day), Streak Rekindles, "
        "and special reader themes."
    )

    add_section_heading("Technical Feasibility & Flutter Elements")
    add_body_p(
        "Quixoria is built using the Flutter framework and Dart programming language, allowing the application to run smoothly and responsively across Android, iOS, and web browsers from a single codebase. "
        "Common Flutter widgets such as Scaffold, Column, Row, ListView, and CustomPainter are used to build the interface, including the animated chapter quest map and reading canvases."
    )
    add_body_p(
        "The application uses the Provider state management pattern to organize user data cleanly between screens. Supabase Auth and database services handle user authentication "
        "(including email, Google, and Facebook sign-in) and real-time cloud synchronization of user profiles, reading streaks, and Scriptorium vocabulary words using its PostgreSQL relational backend. "
        "All book chapters, vocabulary definitions, and Socratic reflection prompts are curated directly within the application's pedagogical engine for instant, zero-latency learning. "
        "To ensure students can read anywhere—even on airplane mode or without mobile data—all reading progress, books, and saved flashcards are cached locally on the device using SQLite and SharedPreferences. "
        "When an internet connection is available, local data seamlessly syncs with Supabase. The just_audio package manages continuous background music playback, while flutter_local_notifications delivers offline daily streak reminders."
    )
    add_body_p(
        "Technical challenges encountered during development included ensuring smooth text reflow when resizing fonts, designing responsive layouts that do not overflow on small phone screens, and handling offline-to-cloud data synchronization. "
        "These were resolved using flexible layout constraints (such as Wrap and Expanded), defensive margin sizing, conflict-free local caching, and a complete suite of 77 automated tests to ensure the application is robust, accessible, and completely error-free."
    )

    # =========================================================================
    # CHAPTER 2: WIREFRAMES & DESCRIPTIONS
    # =========================================================================
    doc.add_page_break()
    add_chapter_title("Chapter 2", "Wireframes")

    add_figure(
        "wireframe_images/fig1_login.png",
        "Figure 1 Welcome & Onboarding Screen",
        "Greets users with an inspiring Duolingo-style welcome screen featuring the vintage windmill hero artwork, anti-doom scrolling motivation, "
        "and clear entry actions: 'GET STARTED' to create a profile, 'I ALREADY HAVE AN ACCOUNT' to log in (with support for Google and Facebook sign-in), "
        "and 'Quick Guest Scholar Enlistment' to begin reading immediately without friction."
    )

    add_figure(
        "wireframe_images/fig2_quest_map.png",
        "Figure 2 Quest Map & Learning Path",
        "Shows the user's reading progress through the book as an interactive zigzag path. It highlights completed chapters with checkmarks, the current active chapter with a bouncing icon, "
        "and locked upcoming chapters. The top bar displays total gems, daily streak count, and encouraging notes from Don Quixote."
    )

    add_figure(
        "wireframe_images/fig3_reader.png",
        "Figure 3 Literary Reader & Tap-to-Define Glossary",
        "The main reading screen showing the classic book text with clean formatting. Tapping any difficult word (like 'Buckler') opens a simple definition card with its meaning, pronunciation, "
        "and an 'Add to Word Bank' button, along with controls for background music at the bottom."
    )

    add_figure(
        "wireframe_images/fig4_counsel.png",
        "Figure 4 Socratic Counsel Modal (Don Quixote Literary Guide)",
        "The interactive reflection sheet where students can explore any paragraph they highlight. It offers quick question buttons ('What does this mean?' and 'Explain tricky words') "
        "and displays curated Socratic advice from Don Quixote to guide the student's understanding without spoilers."
    )

    add_figure(
        "wireframe_images/fig5_scriptorium.png",
        "Figure 5 The Scriptorium (Spaced Repetition Word Bank)",
        "The vocabulary study center that shows all saved words organized by mastery level (Novice, Hidalgo, and Master). It tracks how many words are due for daily review and lets students start "
        "quick flashcard practice sessions."
    )

    add_figure(
        "wireframe_images/fig6_profile_bazaar.png",
        "Figure 6 Profile & Chivalric Bazaar",
        "Displays the student's reading profile, level, daily streak, and earned gems. It includes a rewards shop where users can spend their gems to buy Streak Shields and custom parchment reader themes."
    )

    # =========================================================================
    # TASK ANALYSIS
    # =========================================================================
    doc.add_page_break()
    add_section_heading("Task Analysis")
    add_bold_body_p("Main Transaction Process: ", "Starting and Completing a Chapter Reading Session")
    add_body_p(
        "This task analysis describes the step-by-step journey of a student using Quixoria, replacing 15 minutes of mindless doom scrolling with an engaging chapter quest. "
        "It traces how a reader opens the app, chooses a chapter on the quest map, reads with relaxing music, looks up unfamiliar words, reflects on key scenes, and earns daily rewards."
    )

    add_section_heading("User Goal")
    add_body_p(
        "Read an assigned book chapter, look up difficult vocabulary words, reflect on key story scenes using Don Quixote's guide, practice words with flashcards, and earn gems to maintain a daily reading streak."
    )

    add_section_heading("Step-by-Step User Journey")

    add_bold_body_p("1. Welcome & Authentication (Welcome Screen to Sign Up / Log In)", "")
    add_body_p("Action: The student opens Quixoria and is warmly greeted by the Duolingo-style welcome screen with the vintage windmill artwork and inspiring reading mission. The student taps 'GET STARTED' to create a new profile or 'I ALREADY HAVE AN ACCOUNT' to log in (using email, Google, or Facebook), or chooses 'Quick Guest Scholar Enlistment' to jump in immediately.")
    add_body_p("Outcome: The student enters the realm comfortably without feeling pressured by an immediate email form, and their profile, gems, and reading progress are initialized or restored.")

    add_bold_body_p("2. Choose a Chapter on the Quest Map (Quest Map)", "")
    add_body_p("Action: On the quest map, the student checks their current streak and gems, then taps the active chapter circle (such as Chapter 1).")
    add_body_p("Outcome: The chapter opens up in the clean reader view ready for study.")

    add_bold_body_p("3. Read with Relaxing Background Music (Literary Reader)", "")
    add_body_p("Action: The student begins reading the book. To help block out phone notifications and distractions, they tap the music icon at the top and select soft classical lute music.")
    add_body_p("Outcome: Calming background music loops quietly, creating a peaceful reading environment that helps rebuild deep concentration.")

    add_bold_body_p("4. Look Up Unfamiliar Words (Tap-to-Define Glossary)", "")
    add_body_p("Action: When coming across an unfamiliar or archaic word (such as 'Buckler'), the student taps on it directly on the screen.")
    add_body_p("Outcome: A small card slides up from the bottom showing the definition in simple terms. The student taps 'Add to Word Bank' to save it for later review.")

    add_bold_body_p("5. Explore Key Scenes with Socratic Counsel (Socratic Counsel Sheet)", "")
    add_body_p("Action: The student highlights a confusing paragraph, taps the chat icon, and selects the button '💡 What does this mean?'.")
    add_body_p("Outcome: Don Quixote's literary guide provides an insightful explanation and poses a guided question to help the student understand what the character is doing.")

    add_bold_body_p("6. Finish the Chapter and Collect Rewards (Reader to Quest Map)", "")
    add_body_p("Action: The student reaches the end of the chapter and taps 'Complete Quest' at the bottom.")
    add_body_p("Outcome: A reward popup awards +50 XP and +20 Gems. The chapter circle turns gold with a checkmark, the next chapter unlocks, and the student's daily streak increases by 1.")

    add_bold_body_p("7. Practice Words in the Word Bank (The Scriptorium)", "")
    add_body_p("Action: The student navigates to the Scriptorium tab and completes a quick 5-card flashcard review of the words they saved during reading.")
    add_body_p("Outcome: The app tracks how well the student remembered each word, upgrades their word rank, and schedules the next review date.")

    # =========================================================================
    # USE CASE SPECIFICATION
    # =========================================================================
    doc.add_page_break()
    add_section_heading("Use Case")
    add_body_p(
        "This section outlines the primary actors and system roles in Quixoria, followed by a summary table of the key use cases supported by the app."
    )
    add_bold_body_p("System Actors:", "")
    add_body_p("1. Student / Reader (Primary User): The person reading books, tapping words, exploring chapter reflections, and practicing flashcards.")
    add_body_p("2. Cloud Backend / Supabase (Cloud Service): Manages user authentication (email, Google, Facebook) and synchronizes user profiles, reading streaks, and saved vocabulary.")
    add_body_p("3. Local Storage / SQLite Database (Internal System): The on-device database that stores books, user progress, and vocabulary words so the app works reliably offline.")

    # Table of Use Cases
    uc_table = doc.add_table(rows=1, cols=4)
    uc_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(uc_table, color="B8860B", sz="4")

    headers = ["Use Case ID", "Use Case Name", "Actor", "Description"]
    hdr_cells = uc_table.rows[0].cells
    for i, h in enumerate(headers):
        hdr_cells[i].text = h
        set_cell_background(hdr_cells[i], "1B2A4A")
        set_cell_margins(hdr_cells[i], top=90, bottom=90, left=120, right=120)
        p = hdr_cells[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        for r in p.runs:
            r.font.name = 'Arial'
            r.font.size = Pt(9)
            r.font.bold = True
            r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)

    use_cases = [
        ("UC-01", "Sign In & Profile Setup", "Student, Supabase", "Sign in with email, Google, or Facebook via Supabase Auth, or enter immediately as a guest."),
        ("UC-02", "Navigate Quest Map", "Student / Reader", "View reading progress on the chapter path, check streak and gem counts, and open active chapters."),
        ("UC-03", "Read Classic Books", "Student / Reader", "Read book chapters with adjustable text size, dyslexia-friendly font options, and different background colors."),
        ("UC-04", "Tap-to-Define Words", "Student / Reader", "Tap any difficult word to see its definition instantly and save it to the personal word bank."),
        ("UC-05", "Consult Socratic Counsel", "Student / Reader", "Highlight confusing passages and view curated Socratic guide questions and historical notes from Don Quixote."),
        ("UC-06", "Review Flashcards", "Reader, Supabase / SQLite", "Practice saved vocabulary words with digital flashcards, tracking word mastery locally and syncing with the cloud."),
        ("UC-07", "Buy Rewards in Bazaar", "Student, Supabase", "Spend earned gems to buy Streak Shields (to save streaks during busy days) and custom app themes."),
    ]

    for row_idx, (ucid, name, actor, desc) in enumerate(use_cases):
        row = uc_table.add_row()
        cells = row.cells
        cells[0].text = ucid
        cells[1].text = name
        cells[2].text = actor
        cells[3].text = desc

        bg_hex = "FDFBF7" if row_idx % 2 == 0 else "F4ECE1"
        for i, cell in enumerate(cells):
            set_cell_background(cell, bg_hex)
            set_cell_margins(cell, top=70, bottom=70, left=120, right=120)
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT if i > 0 else WD_ALIGN_PARAGRAPH.CENTER
            for r in p.runs:
                r.font.name = 'Arial'
                r.font.size = Pt(8.5)
                r.font.color.rgb = C_BODY
                if i == 0:
                    r.font.bold = True
                    r.font.color.rgb = C_NAVY

    # =========================================================================
    # CONCEPTUAL FRAMEWORK
    # =========================================================================
    doc.add_page_break()
    add_section_heading("Conceptual Framework")
    add_body_p(
        "Quixoria is based on the idea that students can overcome doom scrolling and rebuild a love for reading when literature is interactive, bite-sized, and rewarding. "
        "Instead of struggling through long text alone, students stay engaged when they can easily look up words they do not know, reflect on key scenes with guided questions, "
        "and feel a sense of achievement through visual levels and streaks."
    )
    add_body_p(
        "The overall workflow of the application is shown below using the Input-Process-Output (IPO) model:"
    )

    ipo_table = doc.add_table(rows=1, cols=3)
    ipo_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(ipo_table, color="B8860B", sz="4")

    ipo_hdrs = ["Input (User Actions)", "Process (What the App Does)", "Output (Results & Features)"]
    hdr_cells = ipo_table.rows[0].cells
    for i, h in enumerate(ipo_hdrs):
        hdr_cells[i].text = h
        set_cell_background(hdr_cells[i], "1B2A4A")
        set_cell_margins(hdr_cells[i], top=90, bottom=90, left=120, right=120)
        p = hdr_cells[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        for r in p.runs:
            r.font.name = 'Arial'
            r.font.size = Pt(9)
            r.font.bold = True
            r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)

    ipo_data = [
        (
            "• User sign-in info (email, Google, Facebook) or guest choice\n"
            "• Tapping a chapter node on the map\n"
            "• Tapping a difficult word in the text\n"
            "• Highlighting text and choosing a Socratic reflection prompt\n"
            "• Grading flashcard answers (Easy, Good, Hard)\n"
            "• Selecting background music\n"
            "• Buying items in the shop",
            
            "• Managing app state with Provider\n"
            "• Supabase Auth & PostgreSQL cloud database synchronization\n"
            "• Formatting text and applying custom fonts\n"
            "• Looking up definitions in the built-in glossary\n"
            "• Loading curated Socratic reflection notes from Don Quixote\n"
            "• Calculating flashcard review schedules\n"
            "• Saving progress locally using SQLite and sync to cloud\n"
            "• Playing background music via just_audio\n"
            "• Updating XP, gems, and daily streak counts",
            
            "• Visual chapter quest map\n"
            "• Clean, customizable reading screen\n"
            "• Pop-up word definition card\n"
            "• Guided Socratic commentary and questions\n"
            "• Updated flashcard levels in the Word Bank\n"
            "• Cloud-synced profile, gems, and reading streak count\n"
            "• Calming acoustic background music"
        )
    ]

    for inputs, processes, outputs in ipo_data:
        row = ipo_table.add_row()
        for i, text in enumerate([inputs, processes, outputs]):
            cell = row.cells[i]
            cell.text = text
            set_cell_background(cell, "FDFBF7")
            set_cell_margins(cell, top=90, bottom=90, left=120, right=120)
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT
            for r in p.runs:
                r.font.name = 'Arial'
                r.font.size = Pt(8.5)
                r.font.color.rgb = C_BODY

    add_body_p(
        "\nAs shown in the table above, the student's actions are processed by the app's internal engines to produce helpful reading assistance, "
        "manageable vocabulary tracking, and rewarding game progress that replaces mindless screen time with productive, joyful reading habits."
    )

    # =========================================================================
    # GANTT CHART
    # =========================================================================
    doc.add_page_break()
    add_section_heading("Gantt Chart")
    add_body_p(
        "Quixoria was developed over a 14-week period following an Agile software development plan. The work was divided into six clear phases, "
        "focusing on tackling doom scrolling and reading fatigue through gamified book design and multi-platform testing."
    )

    gantt_table = doc.add_table(rows=1, cols=5)
    gantt_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(gantt_table, color="B8860B", sz="4")

    g_hdrs = ["Phase", "Milestone / Task Name", "Time Period", "Duration", "Key Output"]
    for i, h in enumerate(g_hdrs):
        c = gantt_table.rows[0].cells[i]
        c.text = h
        set_cell_background(c, "1B2A4A")
        set_cell_margins(c, top=90, bottom=90, left=100, right=100)
        p = c.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        for r in p.runs:
            r.font.name = 'Arial'
            r.font.size = Pt(9)
            r.font.bold = True
            r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)

    schedule = [
        ("Phase 1", "Problem Research & Book Curation", "Weeks 1 - 2", "2 Weeks", "Surveyed student screen habits (doom scrolling) and selected initial classic literature."),
        ("Phase 2", "UI/UX & Wireframe Design", "Weeks 3 - 4", "2 Weeks", "Created screen mockups, parchment color schemes, and quest map layouts."),
        ("Phase 3", "Building the Core Reader & Glossary", "Weeks 5 - 7", "3 Weeks", "Programmed the reading screen, tap-to-define glossary, and local SQLite storage."),
        ("Phase 4", "Socratic Guide & Scriptorium Flashcards", "Weeks 8 - 10", "3 Weeks", "Authored Don Quixote's reflection notes and built the Scriptorium flashcard system."),
        ("Phase 5", "Adding Rewards & Soundscapes", "Weeks 11 - 12", "2 Weeks", "Built the Bazaar shop, daily streak counter, and acoustic lute background audio."),
        ("Phase 6", "Testing & Final Polishing", "Weeks 13 - 14", "2 Weeks", "Fixed screen layout issues and confirmed all 77 automated tests pass successfully."),
    ]

    for row_idx, (p_id, t_name, period, dur, deliv) in enumerate(schedule):
        row = gantt_table.add_row()
        cells = row.cells
        cells[0].text = p_id
        cells[1].text = t_name
        cells[2].text = period
        cells[3].text = dur
        cells[4].text = deliv

        bg_hex = "FDFBF7" if row_idx % 2 == 0 else "F4ECE1"
        for i, cell in enumerate(cells):
            set_cell_background(cell, bg_hex)
            set_cell_margins(cell, top=70, bottom=70, left=100, right=100)
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT if i != 0 and i != 3 else WD_ALIGN_PARAGRAPH.CENTER
            for r in p.runs:
                r.font.name = 'Arial'
                r.font.size = Pt(8.5)
                r.font.color.rgb = C_BODY
                if i == 0:
                    r.font.bold = True
                    r.font.color.rgb = C_NAVY

    # =========================================================================
    # TEST CASES
    # =========================================================================
    doc.add_page_break()
    add_section_heading("Test Cases")
    add_body_p(
        "To ensure Quixoria runs reliably and is easy to use for college students, automated and manual test cases were performed across Android, "
        "iOS, and web browsers. These tests verify login, reading, word lookup, Socratic reflection prompts, flashcard reviews, and screen responsiveness."
    )

    test_table = doc.add_table(rows=1, cols=5)
    test_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(test_table, color="B8860B", sz="4")

    t_hdrs = ["Test ID", "Test Scenario", "Steps to Test", "Expected Result", "Status"]
    for i, h in enumerate(t_hdrs):
        c = test_table.rows[0].cells[i]
        c.text = h
        set_cell_background(c, "1B2A4A")
        set_cell_margins(c, top=90, bottom=90, left=100, right=100)
        p = c.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        for r in p.runs:
            r.font.name = 'Arial'
            r.font.size = Pt(9)
            r.font.bold = True
            r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)

    test_cases = [
        ("TC-001", "Guest Login Flow", "1. Open app.\n2. Tap 'Embark as Guest'.", "Opens the Quest Map with a new local profile and initial 0-day streak.", "Pass"),
        ("TC-002", "Chapter Completion & Unlock", "1. Open Chapter 1.\n2. Scroll to bottom.\n3. Tap 'Complete Quest'.", "Awards +50 XP and +20 Gems; Chapter 1 shows gold checkmark; Chapter 2 unlocks.", "Pass"),
        ("TC-003", "Tap-to-Define Word Lookup", "1. While reading, tap the word 'Buckler'.", "Definition card pops up with clear explanation and an 'Add to Word Bank' button.", "Pass"),
        ("TC-004", "Socratic Literary Guide", "1. Highlight a paragraph.\n2. Tap 'Ask Don Quixote'.\n3. Tap 'What does this mean?'.", "Don Quixote displays a curated reflection note and guiding questions to help the student understand the scene.", "Pass"),
        ("TC-005", "Flashcard Review Scheduling", "1. Open Scriptorium.\n2. Review card 'Buckler'.\n3. Tap 'Good'.", "Word mastery rank increases and next review date is scheduled for tomorrow.", "Pass"),
        ("TC-006", "Dyslexia Font Switch", "1. Open reader settings.\n2. Turn on 'Dyslexic Font'.", "Text immediately re-renders using the OpenDyslexic font without any layout glitch.", "Pass"),
        ("TC-007", "Buying a Streak Shield", "1. Open shop with 480 Gems.\n2. Buy 'Streak Shield' (100 Gems).", "Gems balance updates to 380; Streak Shield count increases by 1.", "Pass"),
        ("TC-008", "Background Music Playback", "1. Open Ambience menu.\n2. Tap 'Classical Lute'.", "Lute music plays quietly and loops continuously while reading.", "Pass"),
        ("TC-009", "Offline Reading & Cloud Sync", "1. Turn off Wi-Fi/data.\n2. Read Chapter 1.\n3. Reconnect to internet.", "Book opens and reads normally offline; progress synchronizes seamlessly with Supabase upon reconnection.", "Pass"),
        ("TC-010", "Screen Layout & Overflow Check", "1. Open app and modals on different phone screen sizes.", "All text, buttons, and cards adjust cleanly without any overflow error stripes.", "Pass"),
    ]

    for row_idx, (t_id, scenario, steps, exp, status) in enumerate(test_cases):
        row = test_table.add_row()
        cells = row.cells
        cells[0].text = t_id
        cells[1].text = scenario
        cells[2].text = steps
        cells[3].text = exp
        cells[4].text = status

        bg_hex = "FDFBF7" if row_idx % 2 == 0 else "F4ECE1"
        for i, cell in enumerate(cells):
            set_cell_background(cell, bg_hex)
            set_cell_margins(cell, top=65, bottom=65, left=90, right=90)
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT if i != 0 and i != 4 else WD_ALIGN_PARAGRAPH.CENTER
            for r in p.runs:
                r.font.name = 'Arial'
                r.font.size = Pt(8.2)
                r.font.color.rgb = C_BODY
                if i == 0:
                    r.font.bold = True
                    r.font.color.rgb = C_NAVY
                if i == 4:
                    r.font.bold = True
                    r.font.color.rgb = RGBColor(0x2E, 0x7D, 0x32) # Green

    output_path = r"c:\Users\User\Desktop\QuixoriaV2\quixoria\Quixoria_Project_Documentation.docx"
    doc.save(output_path)
    print(f"DOCUMENT_SAVED_SUCCESSFULLY: {output_path}")

if __name__ == '__main__':
    build_quixoria_documentation()
