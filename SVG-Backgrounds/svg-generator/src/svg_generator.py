def generate_svg(r=0, g=0, b=0):
    svg_template = f'''<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">
        <rect width="100%" height="100%" fill="rgb({r},{g},{b})" />
        Sorry, your browser does not support inline SVG.
        <!--
            by: @drgfragkos
        -->
    </svg>'''
    return svg_template