import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

void main() {
  renderComponent(Chat());
}

class Chat extends Component {
  final messages = <String>[];

  @override
  RenderComponent build() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        gap: 20,
        crossAxisAlignment: FlexAlignment.stretch,
        children: [
          for (final message in messages)
            Column(
              gap: 5,
              children: [
                Container(
                  child: Text('You'),
                  opacity: 0.5,
                ),
                Text(message),
              ],
            ),
          MessageField(
            onSent: (text) async {
              messages.add(text);
              setState(() {});
            },
          )
        ],
      ),
    );
  }
}

class MessageField extends Component {
  final Function(String message) onSent;

  MessageField({required this.onSent});

  var message = '';

  @override
  RenderComponent build() {
    return Row(
      gap: 10,
      mainAxisAlignment: FlexAlignment.center,
      children: [
        Text('Your message:'),
        TextField(
          value: message,
          placeholderText: 'How many r\'s in "strawberry"?',
          onChanged: (value) => message = value,
        ),
        Button(
          child: Text('Send'),
          onClick: () {
            onSent(message);
            setState(() => message = '');
          },
        ),
      ],
    );
  }
}

abstract class RenderComponent {
  web.Element render();

  String get selector => 'component-$hashCode';
}

abstract class Component extends RenderComponent {
  RenderComponent build() =>
      throw UnimplementedError('Component must implement the `build` method.');

  @override
  web.Element render() => build().render()..id = selector;

  setState(void Function() callback) {
    callback();
    renderComponent(this, selector: '#$selector', root: false);
  }
}

enum FlexDirection { row, column }

class EdgeInsets {
  final double top;
  final double right;
  final double bottom;
  final double left;

  EdgeInsets.all(double value)
      : top = value,
        right = value,
        bottom = value,
        left = value;

  EdgeInsets.only({
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.left = 0,
  });

  EdgeInsets.symmetric({
    double vertical = 0,
    double horizontal = 0,
  })  : top = vertical,
        right = horizontal,
        bottom = vertical,
        left = horizontal;

  String toCSS() {
    return '${top}px ${right}px ${bottom}px ${left}px';
  }
}

class Container extends RenderComponent {
  final RenderComponent child;
  final double? opacity;
  final double? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final String? border;
  final String? backgroundColor;

  Container({
    required this.child,
    this.opacity,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
    this.backgroundColor,
  });

  @override
  web.Element render() {
    return web.HTMLDivElement()
      ..style.opacity = opacity?.toString() ?? ''
      ..style.borderRadius = borderRadius?.toString() ?? ''
      ..style.padding = padding?.toCSS() ?? ''
      ..style.margin = margin?.toCSS() ?? ''
      ..style.border = border ?? ''
      ..style.backgroundColor = backgroundColor ?? ''
      ..append(child.render());
  }
}

class FlexAlignment {
  final String _css;

  const FlexAlignment._(this._css);

  static const start = FlexAlignment._('flex-start');
  static const center = FlexAlignment._('center');
  static const end = FlexAlignment._('flex-end');
  static const stretch = FlexAlignment._('stretch');

  String toCSS() => _css;
}

class Row extends Flex {
  Row({
    required super.children,
    super.crossAxisAlignment,
    super.mainAxisAlignment,
    super.gap,
  }) : super(direction: FlexDirection.row);
}

class Column extends Flex {
  Column({
    required super.children,
    super.crossAxisAlignment,
    super.mainAxisAlignment,
    super.gap,
  }) : super(direction: FlexDirection.column);
}

class Flex extends RenderComponent {
  final List<RenderComponent> children;
  final FlexDirection direction;
  final FlexAlignment crossAxisAlignment;
  final FlexAlignment mainAxisAlignment;
  final double? gap;

  Flex({
    required this.children,
    required this.direction,
    this.crossAxisAlignment = FlexAlignment.start,
    this.mainAxisAlignment = FlexAlignment.start,
    this.gap = 0,
  });

  @override
  web.Element render() {
    final div = web.HTMLDivElement()
      ..style.display = 'flex'
      ..style.flexDirection = direction == FlexDirection.row ? 'row' : 'column'
      ..style.gap = '${gap}px'
      ..style.justifyContent = mainAxisAlignment.toCSS()
      ..style.alignItems = crossAxisAlignment.toCSS();

    for (final child in children) {
      div.appendChild(child.render());
    }

    return div;
  }
}

class Button extends RenderComponent {
  final RenderComponent child;
  final void Function() onClick;

  Button({required this.child, required this.onClick});

  @override
  web.Element render() {
    final button = web.HTMLButtonElement()
      ..appendChild(child.render())
      ..onClick.listen((_) => onClick());

    return button;
  }
}

class Text extends RenderComponent {
  final String text;

  Text(this.text);

  @override
  web.Element render() {
    return web.HTMLOutputElement()..text = text;
  }
}

enum TextInputType { text, number, email, password, multiline }

class TextField extends RenderComponent {
  final String? placeholderText;
  final void Function(String) onChanged;
  final TextInputType keyboardType;
  final String value; // Add value parameter

  TextField({
    required this.onChanged,
    required this.value, // Make value required
    this.placeholderText,
    this.keyboardType = TextInputType.text,
  });

  @override
  web.Element render() {
    final input = web.HTMLInputElement()
      ..type = keyboardType.name
      ..placeholder = placeholderText ?? ''
      ..value = value // Set the current value
      ..onInput.listen((event) {
        final data = (event.dartify() as web.InputEvent)
            .target!
            .getProperty('value'.toJS)
            .dartify();

        if (data is String) onChanged(data);
      });

    return input;
  }
}

void renderComponent(RenderComponent component,
    {String selector = '#root', bool root = true}) {
  final element = web.document.querySelector(selector);
  assert(element != null, 'Element with selector `$selector` not found.');

  if (root) {
    return element?.replaceChildren(component.render());
  }

  return element?.replaceWith(component.render());
}
