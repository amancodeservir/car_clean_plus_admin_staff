import os
from PIL import Image, ImageDraw, ImageFont

W, H = 1080, 1920

# Fonts
font_bold = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 42)
font_title = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 56)
font_sub = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 26)
font_card_title = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 32)
font_body = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 24)
font_small = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 20)
font_stat_num = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 44)
font_pill = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 18)
font_avatar = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 38)

logo_path = '/Users/rajesh/Documents/car_clean_plus/admin/assets/logo.png'
wash_path = '/Users/rajesh/Documents/car_clean_plus/admin/assets/basic_wash.png'
interior_path = '/Users/rajesh/Documents/car_clean_plus/admin/assets/interior_cleaning.png'

logo_img = Image.open(logo_path).convert("RGBA").resize((84, 84), Image.Resampling.LANCZOS)
wash_img = Image.open(wash_path).convert("RGBA").resize((410, 240), Image.Resampling.LANCZOS)
interior_img = Image.open(interior_path).convert("RGBA").resize((410, 240), Image.Resampling.LANCZOS)

def create_base(title, subtitle, badge_text, active_tab=0):
    img = Image.new("RGBA", (W, H), (15, 23, 42, 255))
    draw = ImageDraw.Draw(img)
    
    # Gradient glow at top
    for i in range(400):
        alpha = int(80 * (1 - i / 400))
        draw.line([(0, i), (W, i)], fill=(37, 99, 235, alpha))
        
    # Top badge
    badge_w, badge_h = 360, 46
    badge_x = (W - badge_w) // 2
    draw.rounded_rectangle([badge_x, 70, badge_x + badge_w, 70 + badge_h], radius=23, fill=(30, 58, 138, 240), outline=(59, 130, 246, 220), width=2)
    bbox = font_pill.getbbox(badge_text)
    bw = bbox[2] - bbox[0]
    draw.text((badge_x + (badge_w - bw) // 2, 82), badge_text, fill=(147, 197, 253), font=font_pill)
    
    # Headline & Subtitle
    t_box = font_title.getbbox(title)
    tw = t_box[2] - t_box[0]
    draw.text(((W - tw) // 2, 140), title, fill=(255, 255, 255), font=font_title)
    
    s_box = font_sub.getbbox(subtitle)
    sw = s_box[2] - s_box[0]
    draw.text(((W - sw) // 2, 215), subtitle, fill=(148, 163, 184), font=font_sub)
    
    # Phone frame coordinates
    phone_x1, phone_y1 = 80, 280
    phone_x2, phone_y2 = W - 80, H - 35
    
    # Outer device bezel
    draw.rounded_rectangle([phone_x1, phone_y1, phone_x2, phone_y2], radius=48, fill=(15, 23, 42), outline=(51, 65, 85), width=5)
    
    # Inner screen
    screen_x1, screen_y1 = phone_x1 + 12, phone_y1 + 12
    screen_x2, screen_y2 = phone_x2 - 12, phone_y2 - 12
    draw.rounded_rectangle([screen_x1, screen_y1, screen_x2, screen_y2], radius=38, fill=(248, 250, 252))
    
    # Status bar
    draw.text((screen_x1 + 32, screen_y1 + 18), "09:41", fill=(15, 23, 42), font=font_small)
    draw.text((screen_x2 - 105, screen_y1 + 18), "5G  100%", fill=(15, 23, 42), font=font_small)
    
    # App Bar
    app_bar_y = screen_y1 + 52
    draw.rectangle([screen_x1, app_bar_y, screen_x2, app_bar_y + 85], fill=(15, 23, 42))
    img.paste(logo_img, (screen_x1 + 22, app_bar_y + 1), logo_img)
    draw.text((screen_x1 + 120, app_bar_y + 14), "Car Clean Plus", fill=(255, 255, 255), font=font_bold)
    draw.text((screen_x1 + 122, app_bar_y + 52), "PARTNER & CREW PORTAL", fill=(59, 130, 246), font=font_small)
    
    # Bottom Tab Navigation Bar
    tab_y1 = screen_y2 - 80
    draw.rectangle([screen_x1, tab_y1, screen_x2, screen_y2], fill=(255, 255, 255))
    draw.line([(screen_x1, tab_y1), (screen_x2, tab_y1)], fill=(226, 232, 240), width=2)
    
    tab_w = (screen_x2 - screen_x1) // 3
    # Tab 1: Jobs
    col1 = (37, 99, 235) if active_tab == 0 else (100, 116, 139)
    draw.text((screen_x1 + tab_w // 2 - 25, tab_y1 + 26), "Jobs", fill=col1, font=font_body)
    if active_tab == 0:
        draw.line([(screen_x1 + tab_w // 2 - 25, tab_y1 + 58), (screen_x1 + tab_w // 2 + 25, tab_y1 + 58)], fill=col1, width=3)
        
    # Tab 2: Alerts
    col2 = (37, 99, 235) if active_tab == 1 else (100, 116, 139)
    draw.text((screen_x1 + tab_w + tab_w // 2 - 28, tab_y1 + 26), "Alerts", fill=col2, font=font_body)
    # Alerts badge count "2"
    badge_ax = screen_x1 + tab_w + tab_w // 2 + 32
    draw.rounded_rectangle([badge_ax, tab_y1 + 22, badge_ax + 22, tab_y1 + 42], radius=10, fill=(239, 68, 68))
    draw.text((badge_ax + 6, tab_y1 + 24), "2", fill=(255, 255, 255), font=font_small)
    
    # Tab 3: Profile
    col3 = (37, 99, 235) if active_tab == 2 else (100, 116, 139)
    draw.text((screen_x1 + tab_w * 2 + tab_w // 2 - 32, tab_y1 + 26), "Profile", fill=col3, font=font_body)
    if active_tab == 2:
        draw.line([(screen_x1 + tab_w * 2 + tab_w // 2 - 32, tab_y1 + 58), (screen_x1 + tab_w * 2 + tab_w // 2 + 32, tab_y1 + 58)], fill=col3, width=3)
    
    content_y1 = app_bar_y + 85
    content_y2 = tab_y1
    return img, draw, screen_x1, content_y1, screen_x2, content_y2

# 1. SCREEN 1: Today's Wash Jobs & Shift Toggle
def make_screen_1():
    img, draw, sx1, sy1, sx2, sy2 = create_base(
        "Today’s Doorstep Wash Jobs",
        "Assigned wash queue, shift controls & real-time dispatch",
        "DOORSTEP JOBS QUEUE",
        active_tab=0
    )
    
    y = sy1 + 16
    # Segmented Tab: [ Today ] | [ Tomorrow ]
    seg_w = sx2 - sx1 - 40
    seg_x = sx1 + 20
    draw.rounded_rectangle([seg_x, y, seg_x + seg_w, y + 54], radius=12, fill=(226, 232, 240))
    # Selected: Today
    draw.rounded_rectangle([seg_x + 4, y + 4, seg_x + seg_w // 2 - 4, y + 50], radius=10, fill=(37, 99, 235))
    draw.text((seg_x + seg_w // 4 - 35, y + 14), "Today (2)", fill=(255, 255, 255), font=font_body)
    draw.text((seg_x + 3 * seg_w // 4 - 45, y + 14), "Tomorrow (0)", fill=(100, 116, 139), font=font_body)
    
    # On Shift Switch Card
    y += 72
    draw.rounded_rectangle([sx1 + 20, y, sx2 - 20, y + 90], radius=16, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
    draw.text((sx1 + 40, y + 18), "On Shift Duty", fill=(15, 23, 42), font=font_card_title)
    draw.text((sx1 + 40, y + 54), "Active & receiving assigned doorstep jobs", fill=(100, 116, 139), font=font_small)
    # Green switch
    sw_x = sx2 - 100
    draw.rounded_rectangle([sw_x, y + 26, sw_x + 64, y + 62], radius=18, fill=(16, 185, 129))
    draw.ellipse([sw_x + 30, y + 28, sw_x + 62, y + 60], fill=(255, 255, 255))
    
    # Job Card 1 (In Progress)
    y += 110
    draw.rounded_rectangle([sx1 + 20, y, sx2 - 20, y + 440], radius=20, fill=(255, 255, 255), outline=(59, 130, 246), width=3)
    
    # Badge + Slot
    draw.rounded_rectangle([sx1 + 36, y + 20, sx1 + 200, y + 58], radius=8, fill=(239, 246, 255))
    draw.text((sx1 + 48, y + 26), "IN PROGRESS", fill=(37, 99, 235), font=font_small)
    draw.text((sx2 - 230, y + 26), "Slot: 10:00 - 11:30 AM", fill=(100, 116, 139), font=font_small)
    
    # Service Title + Price
    draw.text((sx1 + 36, y + 74), "Full Foam Wash & Interior Polish", fill=(15, 23, 42), font=font_card_title)
    draw.text((sx1 + 36, y + 120), "₹699 • Cash on Delivery", fill=(16, 185, 129), font=font_body)
    
    draw.line([(sx1 + 36, y + 160), (sx2 - 36, y + 160)], fill=(241, 245, 249), width=2)
    
    # Customer Details
    draw.text((sx1 + 36, y + 180), "Customer: Priya Nair • +91 90000 00001", fill=(15, 23, 42), font=font_body)
    draw.text((sx1 + 36, y + 218), "Vehicle: Hyundai Creta (White) • SUV", fill=(71, 85, 105), font=font_body)
    draw.text((sx1 + 36, y + 256), "Address: House 42, Sector 4, Gomti Nagar, Lucknow", fill=(71, 85, 105), font=font_body)
    draw.text((sx1 + 36, y + 294), "Photo Proof: Before Uploaded [Yes] | After [Pending]", fill=(217, 119, 6), font=font_small)
    
    # Action buttons
    draw.rounded_rectangle([sx1 + 36, y + 345, sx1 + 410, y + 415], radius=12, fill=(37, 99, 235))
    draw.text((sx1 + 105, y + 365), "Open in Maps", fill=(255, 255, 255), font=font_body)
    
    draw.rounded_rectangle([sx1 + 430, y + 345, sx2 - 36, y + 415], radius=12, fill=(241, 245, 249))
    draw.text((sx1 + 510, y + 365), "Call Customer", fill=(15, 23, 42), font=font_body)
    
    # Job Card 2 (Accepted)
    y += 460
    draw.rounded_rectangle([sx1 + 20, y, sx2 - 20, y + 370], radius=20, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
    draw.rounded_rectangle([sx1 + 36, y + 20, sx1 + 175, y + 58], radius=8, fill=(240, 253, 244))
    draw.text((sx1 + 52, y + 26), "ACCEPTED", fill=(22, 163, 74), font=font_small)
    draw.text((sx2 - 230, y + 26), "Slot: 02:00 - 03:00 PM", fill=(100, 116, 139), font=font_small)
    
    draw.text((sx1 + 36, y + 74), "Exterior Waterless Foam Wash", fill=(15, 23, 42), font=font_card_title)
    draw.text((sx1 + 36, y + 120), "₹499 • Online Paid (Verified)", fill=(16, 185, 129), font=font_body)
    draw.text((sx1 + 36, y + 170), "Customer: Rahul Verma • Honda City (Silver)", fill=(71, 85, 105), font=font_body)
    draw.text((sx1 + 36, y + 210), "Address: Flat 204, Royal Apartments, Aliganj", fill=(71, 85, 105), font=font_body)
    
    draw.rounded_rectangle([sx1 + 36, y + 270, sx2 - 36, y + 340], radius=12, fill=(16, 185, 129))
    draw.text((sx1 + 310, y + 290), "MARK ON THE WAY >", fill=(255, 255, 255), font=font_body)
    
    return img

# 2. SCREEN 2: Booking Details & GPS Turn-by-Turn
def make_screen_2():
    img, draw, sx1, sy1, sx2, sy2 = create_base(
        "Booking Details & Navigation",
        "Customer location, vehicle specs & one-tap Google Maps",
        "DOORSTEP DISPATCH",
        active_tab=0
    )
    
    y = sy1 + 20
    # Booking Header Banner
    draw.rounded_rectangle([sx1 + 20, y, sx2 - 20, y + 120], radius=18, fill=(15, 23, 42))
    draw.text((sx1 + 40, y + 24), "Booking #CCP-8492", fill=(255, 255, 255), font=font_card_title)
    draw.text((sx1 + 40, y + 68), "Full Foam Body Wash & Interior Polish", fill=(147, 197, 253), font=font_body)
    draw.rounded_rectangle([sx2 - 200, y + 36, sx2 - 40, y + 84], radius=8, fill=(37, 99, 235))
    draw.text((sx2 - 185, y + 46), "IN PROGRESS", fill=(255, 255, 255), font=font_small)
    
    # Customer Details Card
    y += 140
    draw.rounded_rectangle([sx1 + 20, y, sx2 - 20, y + 200], radius=18, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
    draw.text((sx1 + 40, y + 22), "Customer Information", fill=(100, 116, 139), font=font_small)
    draw.text((sx1 + 40, y + 58), "Priya Nair", fill=(15, 23, 42), font=font_card_title)
    draw.text((sx1 + 40, y + 102), "Contact: +91 90000 00001", fill=(71, 85, 105), font=font_body)
    draw.rounded_rectangle([sx2 - 250, y + 60, sx2 - 40, y + 140], radius=12, fill=(240, 253, 244), outline=(187, 247, 208), width=1)
    draw.text((sx2 - 220, y + 84), "Call Customer", fill=(22, 163, 74), font=font_body)
    
    # Doorstep Address Card with Navigation
    y += 220
    draw.rounded_rectangle([sx1 + 20, y, sx2 - 20, y + 260], radius=18, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
    draw.text((sx1 + 40, y + 22), "Service Location", fill=(100, 116, 139), font=font_small)
    draw.text((sx1 + 40, y + 58), "House 42, Sector 4, Gomti Nagar", fill=(15, 23, 42), font=font_card_title)
    draw.text((sx1 + 40, y + 102), "Lucknow, Uttar Pradesh - 226010", fill=(71, 85, 105), font=font_body)
    
    # Google Maps CTA
    draw.rounded_rectangle([sx1 + 40, y + 155, sx2 - 40, y + 230], radius=12, fill=(37, 99, 235))
    draw.text((sx1 + 240, y + 175), "Open in Google Maps", fill=(255, 255, 255), font=font_card_title)
    
    # Vehicle & Special Instructions
    y += 280
    draw.rounded_rectangle([sx1 + 20, y, sx2 - 20, y + 360], radius=18, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
    draw.text((sx1 + 40, y + 22), "Vehicle & Access Instructions", fill=(100, 116, 139), font=font_small)
    draw.text((sx1 + 40, y + 58), "Hyundai Creta (White) • SUV", fill=(15, 23, 42), font=font_card_title)
    
    draw.rounded_rectangle([sx1 + 40, y + 110, sx2 - 40, y + 230], radius=12, fill=(248, 250, 252), outline=(226, 232, 240), width=1)
    draw.text((sx1 + 60, y + 128), "Special Instructions from Customer:", fill=(100, 116, 139), font=font_small)
    draw.text((sx1 + 60, y + 162), "\"Gate key is with building security guard.", fill=(15, 23, 42), font=font_body)
    draw.text((sx1 + 60, y + 194), "Basement water tap located near pillar B4.\"", fill=(15, 23, 42), font=font_body)
    
    draw.text((sx1 + 40, y + 265), "Service Amount:", fill=(100, 116, 139), font=font_body)
    draw.text((sx1 + 220, y + 260), "₹699", fill=(16, 185, 129), font=font_card_title)
    draw.text((sx1 + 40, y + 305), "Payment Status: Cash to be collected at doorstep", fill=(217, 119, 6), font=font_small)
    
    return img

# 3. SCREEN 3: Authentic Before & After Inspection Photo Upload
def make_screen_3():
    img, draw, sx1, sy1, sx2, sy2 = create_base(
        "Before & After Photo Proof",
        "Upload authentic doorstep photos to verify wash quality",
        "INSPECTION PROOF",
        active_tab=0
    )
    
    y = sy1 + 20
    draw.rounded_rectangle([sx1 + 20, y, sx2 - 20, y + 860], radius=22, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
    draw.text((sx1 + 40, y + 24), "Job Quality Photo Verification", fill=(15, 23, 42), font=font_card_title)
    draw.text((sx1 + 40, y + 68), "Booking #CCP-8492 • Hyundai Creta (SUV)", fill=(100, 116, 139), font=font_small)
    
    # Photo 1: Before Wash
    y_p1 = y + 115
    draw.rounded_rectangle([sx1 + 40, y_p1, sx1 + 440, y_p1 + 44], radius=8, fill=(22, 163, 74))
    draw.text((sx1 + 130, y_p1 + 10), "BEFORE WASH [UPLOADED]", fill=(255, 255, 255), font=font_small)
    img.paste(interior_img, (sx1 + 40, y_p1 + 48))
    draw.text((sx1 + 45, y_p1 + 296), "Uploaded: Today 10:05 AM", fill=(100, 116, 139), font=font_small)
    
    # Photo 2: After Wash
    draw.rounded_rectangle([sx2 - 440, y_p1, sx2 - 40, y_p1 + 44], radius=8, fill=(37, 99, 235))
    draw.text((sx2 - 350, y_p1 + 10), "AFTER WASH [CAMERA READY]", fill=(255, 255, 255), font=font_small)
    img.paste(wash_img, (sx2 - 440, y_p1 + 48))
    draw.text((sx2 - 435, y_p1 + 296), "Ready to verify & upload", fill=(100, 116, 139), font=font_small)
    
    # Compliance Notice box
    y_box = y_p1 + 345
    draw.rounded_rectangle([sx1 + 40, y_box, sx2 - 40, y_box + 190], radius=14, fill=(248, 250, 252), outline=(226, 232, 240), width=1)
    draw.text((sx1 + 60, y_box + 22), "Doorstep Inspection Guidelines:", fill=(15, 23, 42), font=font_body)
    
    rules = [
        "• High-resolution camera photos stored directly on server",
        "• Timestamp and booking ID stamped for quality check",
        "• Required to complete before marking wash job completed"
    ]
    for i, r in enumerate(rules):
        draw.text((sx1 + 60, y_box + 65 + i * 36), r, fill=(71, 85, 105), font=font_small)
        
    # Buttons
    y_btn = y_box + 230
    draw.rounded_rectangle([sx1 + 40, y_btn, sx2 - 40, y_btn + 75], radius=14, fill=(16, 185, 129))
    draw.text((sx1 + 230, y_btn + 22), "COMPLETE WASH JOB", fill=(255, 255, 255), font=font_card_title)
    
    return img

# 4. SCREEN 4: Record Doorstep Cash/UPI Collection Modal Dialog
def make_screen_4():
    img, draw, sx1, sy1, sx2, sy2 = create_base(
        "Record Payment Collection",
        "Log collected doorstep cash & UPI payments to ledger",
        "PAYMENT COLLECTION",
        active_tab=0
    )
    
    # Modal Dialog Box
    y_modal = sy1 + 100
    draw.rounded_rectangle([sx1 + 30, y_modal, sx2 - 30, y_modal + 740], radius=24, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
    
    # Dialog Title
    draw.text((sx1 + 60, y_modal + 36), "Record collection", fill=(15, 23, 42), font=font_title)
    draw.text((sx1 + 60, y_modal + 106), "How much did you collect from Priya Nair", fill=(71, 85, 105), font=font_body)
    draw.text((sx1 + 60, y_modal + 142), "for Booking #CCP-8492?", fill=(71, 85, 105), font=font_body)
    
    # Due Amount Card
    draw.rounded_rectangle([sx1 + 60, y_modal + 195, sx2 - 60, y_modal + 295], radius=16, fill=(240, 253, 244), outline=(187, 247, 208), width=1)
    draw.text((sx1 + 85, y_modal + 230), "Service Amount Due", fill=(22, 163, 74), font=font_body)
    draw.text((sx2 - 210, y_modal + 220), "₹699", fill=(22, 163, 74), font=font_stat_num)
    
    # Input Field 1: Cash Collected
    y_f1 = y_modal + 325
    draw.rounded_rectangle([sx1 + 60, y_f1, sx2 - 60, y_f1 + 100], radius=14, fill=(255, 255, 255), outline=(59, 130, 246), width=2)
    draw.text((sx1 + 80, y_f1 + 14), "Cash collected (₹)", fill=(37, 99, 235), font=font_small)
    draw.text((sx1 + 80, y_f1 + 48), "699", fill=(15, 23, 42), font=font_card_title)
    draw.text((sx2 - 120, y_f1 + 48), "(Cash)", fill=(100, 116, 139), font=font_small)
    
    # Input Field 2: UPI Collected
    y_f2 = y_modal + 450
    draw.rounded_rectangle([sx1 + 60, y_f2, sx2 - 60, y_f2 + 100], radius=14, fill=(255, 255, 255), outline=(226, 232, 240), width=1)
    draw.text((sx1 + 80, y_f2 + 14), "UPI collected (₹)", fill=(100, 116, 139), font=font_small)
    draw.text((sx1 + 80, y_f2 + 48), "0", fill=(15, 23, 42), font=font_card_title)
    draw.text((sx2 - 120, y_f2 + 48), "(UPI)", fill=(100, 116, 139), font=font_small)
    
    # Dialog Action Buttons
    y_act = y_modal + 600
    draw.rounded_rectangle([sx1 + 60, y_act, sx1 + 360, y_act + 80], radius=14, fill=(241, 245, 249))
    draw.text((sx1 + 160, y_act + 25), "Cancel", fill=(100, 116, 139), font=font_body)
    
    draw.rounded_rectangle([sx1 + 390, y_act, sx2 - 60, y_act + 80], radius=14, fill=(16, 185, 129))
    draw.text((sx1 + 470, y_act + 25), "Save Collection", fill=(255, 255, 255), font=font_body)
    
    return img

# 5. SCREEN 5: Staff Shift, Crew Profile & Operations Desk Support
def make_screen_5():
    img, draw, sx1, sy1, sx2, sy2 = create_base(
        "Staff Profile & Duty Shift",
        "Active shift duty control & operations desk support hotline",
        "CREW PROFILE & SHIFT",
        active_tab=2
    )
    
    y = sy1 + 20
    # Crew Profile Header Card
    draw.rounded_rectangle([sx1 + 20, y, sx2 - 20, y + 210], radius=20, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
    # Avatar Circle with Initials
    draw.ellipse([sx1 + 45, y + 45, sx1 + 155, y + 155], fill=(239, 246, 255), outline=(191, 219, 254), width=2)
    draw.text((sx1 + 75, y + 78), "DK", fill=(37, 99, 235), font=font_avatar)
    
    draw.text((sx1 + 180, y + 45), "Dinesh Kumar", fill=(15, 23, 42), font=font_card_title)
    draw.text((sx1 + 180, y + 90), "Car Clean Plus Doorstep Staff", fill=(71, 85, 105), font=font_body)
    draw.text((sx1 + 180, y + 130), "Lucknow Central Branch", fill=(100, 116, 139), font=font_small)
    
    draw.rounded_rectangle([sx2 - 170, y + 45, sx2 - 40, y + 90], radius=8, fill=(240, 253, 244))
    draw.text((sx2 - 150, y + 56), "STAFF", fill=(22, 163, 74), font=font_small)
    
    # Duty Shift Switch Card
    y += 235
    draw.rounded_rectangle([sx1 + 20, y, sx2 - 20, y + 135], radius=18, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
    draw.text((sx1 + 40, y + 26), "On Shift Duty", fill=(15, 23, 42), font=font_card_title)
    draw.text((sx1 + 40, y + 75), "Toggle on to receive scheduled wash bookings", fill=(100, 116, 139), font=font_body)
    sw_x = sx2 - 110
    draw.rounded_rectangle([sw_x, y + 36, sw_x + 70, y + 76], radius=20, fill=(16, 185, 129))
    draw.ellipse([sw_x + 32, y + 38, sw_x + 68, y + 74], fill=(255, 255, 255))
    
    # Operations Desk Hotline Card
    y += 160
    draw.rounded_rectangle([sx1 + 20, y, sx2 - 20, y + 220], radius=18, fill=(248, 250, 252), outline=(226, 232, 240), width=2)
    draw.text((sx1 + 40, y + 25), "Operations Desk Hotline", fill=(100, 116, 139), font=font_small)
    draw.text((sx1 + 40, y + 68), "+91 6392 798847", fill=(37, 99, 235), font=font_title)
    draw.text((sx1 + 40, y + 135), "Direct phone support for address verification, customer", fill=(71, 85, 105), font=font_small)
    draw.text((sx1 + 40, y + 168), "contact issues, or equipment assistance in field.", fill=(71, 85, 105), font=font_small)
    
    # App Information & Logout
    y += 245
    draw.rounded_rectangle([sx1 + 20, y, sx2 - 20, y + 180], radius=18, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
    draw.text((sx1 + 40, y + 25), "Account Details", fill=(100, 116, 139), font=font_small)
    draw.text((sx1 + 40, y + 65), "Registered Email: washer@carclean.in", fill=(15, 23, 42), font=font_body)
    draw.text((sx1 + 40, y + 110), "Car Clean Plus Staff App • Version 1.0.0 (13)", fill=(100, 116, 139), font=font_small)
    
    return img

out_dirs = [
    '/Users/rajesh/Documents/car_clean_plus/admin/fastlane/metadata/android/en-GB/images/phoneScreenshots',
    '/Users/rajesh/Documents/car_clean_plus/admin/fastlane/metadata/android/en-US/images/phoneScreenshots'
]

for d in out_dirs:
    os.makedirs(d, exist_ok=True)

screens = [
    ("1_daily_jobs.png", make_screen_1()),
    ("2_job_workflow.png", make_screen_2()),
    ("3_photo_proof.png", make_screen_3()),
    ("4_payment_collection.png", make_screen_4()),
    ("5_operations_hub.png", make_screen_5())
]

for filename, img in screens:
    for d in out_dirs:
        dest = os.path.join(d, filename)
        img.convert("RGB").save(dest, "PNG", quality=95)
        print(f"Saved: {dest}")

print("All 5 authentic staff phone screenshots successfully generated!")
