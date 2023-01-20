from PIL import Image
import random

# Create a new image with the size 16x16
img = Image.new('RGB', (16, 16), color = (random.randint(0, 255), random.randint(0, 255), random.randint(0, 255)))

# Loop through each pixel and generate a random RGB value
for x in range(img.size[0]):
    for y in range(img.size[1]):
        img.putpixel((x, y), (random.randint(0, 255), random.randint(0, 255), random.randint(0, 255))) ## Random Colors
        #img.putpixel((x, y), (random.randint(100, 255), random.randint(100, 255), random.randint(100, 255))) ## Random Pastel Colors
        #img.putpixel((x, y), (random.randint(0, 3), random.randint(0, 3), random.randint(0, 3))) ## Black Colors
        #img.putpixel((x, y), (random.randint(250, 255), random.randint(250, 255), random.randint(250, 255))) ## White Colors
        #img.putpixel((x, y), (random.randint(0, 255), random.randint(0, 0), random.randint(0, 0))) ## Red Shades
        #img.putpixel((x, y), (random.randint(0, 0), random.randint(0, 255), random.randint(0, 0))) ## Green Shades
        #img.putpixel((x, y), (random.randint(0, 0), random.randint(0, 0), random.randint(0, 255))) ## Blue Shades

# Save the image as an .ico file
img.save("random-ico-" + str(random.randint(100, 999)) + ".ico", "ico")
