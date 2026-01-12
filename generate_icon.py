"""
하이노밸런스 앱 아이콘 생성 스크립트
임시 아이콘 - 간단한 디자인
"""
from PIL import Image, ImageDraw, ImageFont
import os

def generate_app_icon():
    # 1024x1024 기본 이미지 (Android/iOS 모두 사용)
    size = 1024
    img = Image.new('RGB', (size, size), color='#667eea')
    draw = ImageDraw.Draw(img)
    
    # 그라데이션 효과 (간단히 원으로 표현)
    center_x, center_y = size // 2, size // 2
    radius = size // 2
    
    # 원형 배경
    draw.ellipse([center_x - radius, center_y - radius, 
                  center_x + radius, center_y + radius], 
                 fill='#764ba2', outline='#667eea', width=20)
    
    # 'H' 텍스트 (하이노밸런스)
    try:
        # Windows 기본 폰트
        font = ImageFont.truetype("arial.ttf", 600)
    except:
        font = ImageFont.load_default()
    
    text = "H"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    x = (size - text_width) // 2
    y = (size - text_height) // 2 - 50
    
    # 텍스트 그리기 (흰색)
    draw.text((x, y), text, fill='white', font=font)
    
    # Android용 다양한 크기 생성
    android_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    
    android_path = 'android/app/src/main/res'
    
    for folder, px_size in android_sizes.items():
        folder_path = os.path.join(android_path, folder)
        os.makedirs(folder_path, exist_ok=True)
        
        resized = img.resize((px_size, px_size), Image.Resampling.LANCZOS)
        resized.save(os.path.join(folder_path, 'ic_launcher.png'))
        print(f'✅ {folder}/ic_launcher.png ({px_size}x{px_size}) 생성')
    
    # iOS용 (기본 1024x1024)
    ios_path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    os.makedirs(ios_path, exist_ok=True)
    img.save(os.path.join(ios_path, 'Icon-App-1024x1024@1x.png'))
    print(f'✅ iOS AppIcon (1024x1024) 생성')
    
    # Web용
    web_path = 'web/icons'
    os.makedirs(web_path, exist_ok=True)
    img.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_path, 'Icon-192.png'))
    img.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_path, 'Icon-512.png'))
    print(f'✅ Web Icons (192, 512) 생성')
    
    print('\n🎉 앱 아이콘 생성 완료!')

if __name__ == '__main__':
    generate_app_icon()
