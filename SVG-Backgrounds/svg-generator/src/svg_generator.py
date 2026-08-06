def generate_svg(r=0, g=0, b=0):
    """Generate an SVG string with a solid background color.

    Raises ValueError if any component is not an int in the 0-255 range.
    """
    for name, value in (("R", r), ("G", g), ("B", b)):
        if not isinstance(value, int) or isinstance(value, bool):
            raise ValueError(f"{name} must be an integer, got {value!r}")
        if not 0 <= value <= 255:
            raise ValueError(f"{name} must be between 0 and 255, got {value}")

    svg_template = f'''<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">
    <rect width="100%" height="100%" fill="rgb({r},{g},{b})" />
    <!--
        by: @drgfragkos
    -->
</svg>'''
    return svg_template
