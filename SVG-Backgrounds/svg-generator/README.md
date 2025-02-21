# SVG Generator

This project is a simple command-line tool that generates SVG files with a customizable background color. You can specify RGB values directly or use predefined color presets.

## Features

- Generate SVG files with a full black background or specified RGB colors.
- Use command-line flags to set RGB values (-R, -G, -B).
- Choose from predefined color presets using the -c flag.
- List all available color presets with the -l flag.

## Installation

To install the required dependencies, run:

```
pip install -r requirements.txt
```

## Usage

To generate an SVG file with specified RGB values, use the following command:

```
python src/main.py -R <red_value> -G <green_value> -B <blue_value>
```

For example:

```
python src/main.py -R 255 -G 0 -B 0
```

This command generates an SVG file with a red background.

To use a color preset, use the -c flag:

```
python src/main.py -c <preset_name>
```

To list all available color presets, use the -l flag:

```
python src/main.py -l
```

## Color Presets

The following color presets are available:

### Basic Colors

- red: (255, 0, 0)
- green: (0, 255, 0)
- blue: (0, 0, 255)
- yellow: (255, 255, 0)
- cyan: (0, 255, 255)
- magenta: (255, 0, 255)
- white: (255, 255, 255)
- gray: (128, 128, 128)
- orange: (255, 165, 0)
- ChromaKeyGreen: (0, 117, 64)
- dark: (35, 34, 34)
- darker: (13, 17, 23)
- black: (0, 0, 0)

### Pastel Colors (Alphabetical Order)

- PastelAmber: (248, 197, 124)
- PastelAquamarine: (176, 233, 213)
- PastelAqua: (213, 246, 251)
- PastelAvocado: (177, 192, 134)
- PastelBeige: (212, 198, 170)
- PastelBerry: (237, 134, 152)
- PastelBlack: (29, 28, 26)
- PastelBlond: (255, 248, 213)
- PastelBlue: (174, 198, 207)
- PastelBlueGreen: (165, 227, 224)
- PastelBurgundy: (151, 76, 94)
- PastelCaramel: (255, 221, 179)
- PastelCherry: (229, 110, 144)
- PastelChocolate: (167, 121, 109)
- PastelCinnamon: (207, 172, 148)
- PastelCoffee: (208, 164, 141)
- PastelCoral: (255, 163, 140)
- PastelCream: (255, 254, 224)
- PastelDarkBlue: (61, 66, 107)
- PastelDarkGold: (187, 161, 81)
- PastelDeepGold: (229, 199, 104)
- PastelDeepGreen: (47, 76, 57)
- PastelDenim: (175, 192, 234)
- PastelEarth: (215, 202, 183)
- PastelFlesh: (241, 190, 181)
- PastelGrape: (161, 106, 209)
- PastelGold: (231, 210, 124)
- PastelGray: (207, 207, 196)
- PastelGrassGreen: (158, 203, 145)
- PastelIndigo: (134, 134, 175)
- PastelKhaki: (218, 212, 182)
- PastelLemon: (246, 243, 169)
- PastelLime: (209, 254, 184)
- PastelMauve: (235, 204, 255)
- PastelMaroon: (148, 69, 71)
- PastelNavyBlue: (94, 92, 178)
- PastelNude: (231, 215, 202)
- PastelOchre: (214, 151, 89)
- PastelOcean: (110, 205, 219)
- PastelOlive: (188, 188, 130)
- PastelOrange: (255, 179, 71)
- PastelPeach: (247, 223, 194)
- PastelPearl: (240, 235, 216)
- PastelPersimmon: (239, 153, 103)
- PastelPistachio: (208, 233, 192)
- PastelRedRose: (235, 97, 143)
- PastelRose: (246, 184, 208)
- PastelRoseGold: (199, 144, 152)
- PastelRouge: (233, 159, 170)
- PastelSalmon: (246, 193, 178)
- PastelSand: (211, 199, 162)
- PastelSkin: (239, 223, 216)
- PastelSnow: (229, 236, 248)
- PastelTaupe: (117, 101, 90)
- PastelTeal: (99, 183, 183)
- PastelTulip: (255, 164, 169)
- PastelVerde: (157, 214, 173)
- PastelWhite: (250, 248, 246)
- PastelWineRed: (194, 89, 100)
- PastelUltramarine: (128, 125, 219)

## License

This project is licensed under the MIT License.