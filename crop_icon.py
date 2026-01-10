from PIL import Image

def crop_center(image_path, output_path):
    img = Image.open(image_path)
    width, height = img.size
    
    # Calculate crop dimensions (assuming the icon is roughly 80% of the image)
    # The generation usually puts the rounded square in the center with some padding.
    # Let's crop to the central 85% to be safe and fill the frame.
    
    new_width = width * 0.6
    new_height = height * 0.6
    
    left = (width - new_width) / 2
    top = (height - new_height) / 2
    right = (width + new_width) / 2
    bottom = (height + new_height) / 2
    
    img_cropped = img.crop((left, top, right, bottom))
    img_cropped.save(output_path)
    print(f"Cropped {image_path} to {output_path}")

crop_center('assets/icons/app_icon.png', 'assets/icons/app_icon_cropped.png')
