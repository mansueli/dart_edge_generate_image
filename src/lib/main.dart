import 'dart:convert';
import 'package:edge/edge.dart';
import 'package:supabase_functions/supabase_functions.dart';
import 'package:xml/xml.dart' as xml;

void main() {
    SupabaseFunctions(fetch: (request) async {
        // Get the text parameter from the request
        final text = request.url.queryParameters['text'] ?? 'Hello, world!';
        // Height & length of the final image
        final height = request.url.queryParameters['height'] ?? '630';
        final length = request.url.queryParameters['length'] ?? '1200';
        // Patern to be used (more on this later)
        final pattern = request.url.queryParameters['p'] ?? '';
        // Main, secondary & text colors to be used
        final pcolor = '#' + (request.url.queryParameters['pcolor'] ?? '040703');
        final scolor = '#' + (request.url.queryParameters['scolor'] ?? '055C13');
        final text_color = '#' + (request.url.queryParameters['text_color'] ?? 'FFFFFF');
        // Returns the image with the proper headers:
        final svg = generateOGImage(text, int.parse(height), int.parse(length), pattern, pcolor, scolor, text_color);
        final headers = Headers({'Content-Type': 'image/svg+xml', 'Cache-Control': 'public, max-age=3600'});
        return Response(utf8.encode(svg),
        status: 200,
        headers: headers
                       );
    });
}

String generateOGImage(String text, int height, int length, String pattern, String pcolor, String scolor, String text_color) {
    String selectedPattern = getPatternFunction(pattern, length, height);
    List<String> pattern_values = ['motif','surf','coil','scribble','radial','linear'];
    final int text_length = text.length;
    //Checks if the pattern actually exists, if not pick the default
    final actual_pattern = pattern_values.contains(pattern) ? pattern : 'linear';
    final svg = xml.XmlBuilder();
    //Check if the patterns uses more fancy elements or set the default one
    if (selectedPattern.isEmpty) {
        selectedPattern = '<rect x="0" y="0" width="$length" height="$height" fill="url(#$actual_pattern)" />';
    }
    svg.processing('xml', 'version="1.0" encoding="UTF-8"');
    svg.element('svg', nest: () {
        // Set the viewBox attribute to ensure the image scales properly
        svg.attribute('viewBox', '0 0 $length $height');
        svg.attribute('xmlns', 'http://www.w3.org/2000/svg');
        svg.attribute('xmlns:xlink', 'http://www.w3.org/1999/xlink');
        //The SVG patterns used: 
        svg.element('defs', nest: () {
            svg.element('pattern', attributes: {
                            'id': 'motif',
                            'width': '40',
                            'height': '40',
                            'fill': '$pcolor',
                            'patternUnits': 'userSpaceOnUse',
                            'patternTransform': 'translate(19 0) scale(1.4) rotate(55) skewX(0) skewY(0)',
            }, nest: () {
                svg.xml('<rect width="100%" height="100%" fill="url(#linear)"/>');
                svg.xml('<path d="M9.39371 2.87681L34.4892 6.75876L16.118 17.3644L9.39371 2.87681Z" opacity="0.3" fill="$pcolor"></path>');
                svg.xml('<path d="M9.39711 22.8738L9.39697 2.87378L16.1171 17.3638V37.3638L9.39711 22.8738Z" opacity="0.3" fill="$scolor"></path>');
                svg.xml('<path d="M34.4871 26.7538L34.4872 6.75391L16.1173 17.3439L16.1172 37.3638L34.4871 26.7538Z" opacity="0.3" fill="#333333"></path>');
            });
            svg.element('linearGradient', attributes: {
                            'id': 'linear',
                            'gradientTransform': 'rotate(214 .5 .5)',
            }, nest: () {
                svg.element('stop', attributes: {
                                'offset': '0.15',
                                'stop-color': '$pcolor',
                            });
                svg.element('stop', attributes: {
                                'offset': '1',
                                'stop-color': '$scolor',
                            });
            });

            svg.element('radialGradient', attributes: {
                            'id': 'radial',
                            'r': '0.75',
                            'cx': '0.5',
                            'cy': '0.5',
            }, nest: () {
                svg.element('stop', attributes: {
                                'offset': '0',
                                'stop-color': '$pcolor',
                            });
                svg.element('stop', attributes: {
                                'offset': '1',
                                'stop-color': '$scolor',
                            });
            });

            svg.element('linearGradient', attributes: {
                            'id': 'scribble',
                            'x1': '50%',
                            'y1': '0%',
                            'x2': '50%',
                            'y2': '100%',
            }, nest: () {
                svg.element('stop', attributes: {
                                'stop-color': '$pcolor',
                                'stop-opacity': '1',
                                'offset': '0%',
                            });
                svg.element('stop', attributes: {
                                'stop-color': '$scolor',
                                'stop-opacity': '1',
                                'offset': '100%',
                            });
            });
            svg.element('linearGradient', attributes: {
                            'id': 'surf',
                            'x1': '50%',
                            'y1': '0%',
                            'x2': '50%',
                            'y2': '100%',
            }, nest: () {
                svg.element('stop', attributes: {
                                'stop-color': '$pcolor',
                                'stop-opacity': '1',
                                'offset': '0%',
                            });
                svg.element('stop', attributes: {
                                'stop-color': '$scolor',
                                'stop-opacity': '1',
                                'offset': '100%',
                            });
            });

        });
        //Applies the selected Pattern
        svg.xml(selectedPattern);
        int font_size = scaleFontSize(text_length, length);
        svg.element('text', nest: () {
            svg.attribute('x', '50%');
            svg.attribute('y', '50%');
            svg.attribute('fill', '$text_color');
            svg.attribute('font-size', '$font_size');
            svg.attribute('font-family', 'Helvetica');
            svg.attribute('font-weight', 'bold');
            svg.attribute('text-anchor', 'middle');
            //You can include the pattern here to help debugging
            svg.text(text);
        });
    });
    return svg.build().toString();
}

// This function returns the SVG pattern corresponding to the given pattern name
String getPatternFunction(String pattern, int length, int height) {
  switch (pattern) {
    case 'surf':
      return generateSurfPattern(length, height);
    case 'coil':
      return generateCoilPattern(length, height);
    default:
      return '';
  }
}
// This function calculates the optimal font size for the given text length and image width
int scaleFontSize(int textLength, int imgWidth) {
  double ratio = imgWidth / (textLength * 10);
  int fontSize = (ratio * 18).round();
  return fontSize;
}

String generateSurfPattern(int length, int height) {
    List<String> transforms = [
                                  'matrix(1,0,0,1,0,35)',
                                  'matrix(1,0,0,1,0,70)',
                                  'matrix(1,0,0,1,0,105)',
                                  'matrix(1,0,0,1,0,140)',
                                  'matrix(1,0,0,1,0,175)',
                                  'matrix(1,0,0,1,0,210)',
                                  'matrix(1,0,0,1,0,245)',
                              ];
    List<double> opacities = [0.05, 0.21, 0.37, 0.53, 0.68, 0.84, 1.0];
    StringBuffer svg = StringBuffer('<g fill="url(#surf)" transform="matrix(1,0,0,1,0,-90.39413452148438)">');
    svg.write('<rect x="0" y="0" width="$length" height="$height" fill="url(#linear)" />');
    for (int i = 0; i < transforms.length; i++) {
        svg.write('<path d="M 0 342.29282328600317 Q ${length * 450 / 2400} 504.6117272258968 ${length * 600 / 2400} 305.7384012795945 ');
        svg.write('Q ${length * 1050 / 2400} 515.5586511543015 ${length * 1200 / 2400} 304.8942027727378 ');
        svg.write('Q ${length * 1650 / 2400} 588.4072802827825 ${length * 1800 / 2400} 305.3095324794213 ');
        svg.write('Q ${length * 2250 / 2400} 543.4292723926144 $length 300.78824070147607 ');
        svg.write('L $length $height L 0 $height L 0 344.59037112525715 Z" ');
        svg.write('transform="${transforms[i]}" ');
        svg.write('opacity="${opacities[i]}"></path>');
    }
    svg.write('</g>');
    return svg.toString();
}

String generateCoilPattern(int length, int height) {
    final int centerX = length ~/ 2;
    final int centerY = height ~/ 2;
    final int strokeWidth = 9;
    final int numCircles = 8;
    final double opacityStep = 0.05;
    final double rotationStep = 360 / numCircles;
    final double radiusStep = (385 - 245) / (numCircles - 1);
    final List<String> circles = [];

    for (int i = 0; i < numCircles; i++) {
        double radius = 385 - (radiusStep * i);
        double rotation = rotationStep * i;
        double opacity = 0.05 + (opacityStep * i);
        double strokeDashArray1 = 2056.0 - (187.0 * i.toDouble());
        double strokeDashArray2 = 2419.0 - (170.0 * i.toDouble());

        circles.add('''
                    <circle
                    r="$radius"
                    cx="$centerX"
                    cy="$centerY"
                    stroke-width="$strokeWidth"
                    stroke-dasharray="$strokeDashArray1 $strokeDashArray2"
                    transform="rotate($rotation, $centerX, $centerY)"
                    opacity="$opacity">
                    </circle>
                    ''');
    }
    return '''
           <g stroke="url(#coil)" fill="#111111" opacity="0.93" stroke-linecap="round">
           <rect x="0" y="0" width="$length" height="$height" fill="url(#linear)"/>
           ${circles.join('\n')}
           </g>
           ''';
}
