from PIL import Image

png_file = "icon_sq1_nobg.png"

logo = Image.open(png_file)
logo.save("app_icon.ico", format="ICO", sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256), (512, 512), (1024, 1024)])