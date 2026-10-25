"""Render FitLife's existing Android vector geometry as opaque iOS icons.

Requires Pillow. No external artwork is downloaded.
"""
import json
from pathlib import Path
from PIL import Image, ImageDraw


def curve(start, c1, c2, end):
    return [tuple((1-t)**3 * start[k] + 3*(1-t)**2*t*c1[k]
                  + 3*(1-t)*t*t*c2[k] + t**3*end[k] for k in (0, 1))
            for t in (i/80 for i in range(81))]


def main():
    root = Path(__file__).resolve().parents[1]
    directory = root / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    image = Image.new('RGB', (1080, 1080), '#214D3B')
    draw = ImageDraw.Draw(image)
    def polygon(points, color):
        draw.polygon([(round(x*10), round(y*10)) for x, y in points], fill=color)
    polygon([(27,56), (81,56)] + curve((81,56),(79,74),(69,84),(54,84))
            + curve((54,84),(39,84),(29,74),(27,56)), '#D6ECA4')
    polygon([(35,88),(73,88),(73,92),(35,92)], '#D6ECA4')
    polygon(curve((54,51),(52,32),(62,21),(80,21))
            + curve((80,21),(80,39),(70,50),(54,51)), '#F5F5EF')
    polygon(curve((49,50),(33,48),(27,39),(28,27))
            + curve((28,27),(42,28),(51,35),(49,50)), '#F5F5EF')
    manifest = json.loads((directory / 'Contents.json').read_text())
    for entry in manifest['images']:
        size = round(float(entry['size'].split('x')[0]) * float(entry['scale'][:-1]))
        image.resize((size, size), Image.Resampling.LANCZOS).save(directory / entry['filename'])
    print(f"Generated {len(manifest['images'])} opaque FitLife icons")


if __name__ == '__main__':
    main()
