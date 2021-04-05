import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';

typedef AutoSuggestBoxItemBuilder<T> = Widget Function(BuildContext, T);
typedef AutoSuggestBoxItemSorter<T> = List<T> Function(String, List<T>);
typedef AutoSuggestBoxTextBoxBuilder<T> = Widget Function(
  BuildContext context,
  TextEditingController controller,
  FocusNode focusNode,
  GlobalKey key,
);

class AutoSuggestBox<T> extends StatefulWidget {
  const AutoSuggestBox({
    Key? key,
    required this.controller,
    required this.items,
    this.itemBuilder,
    this.sorter = defaultItemSorter,
    this.noResultsFound = defaultNoResultsFound,
    this.textBoxBuilder = defaultTextBoxBuilder,
    this.onSelected,
  }) : super(key: key);

  final TextEditingController controller;
  final List<T> items;
  final AutoSuggestBoxItemBuilder<T>? itemBuilder;
  final AutoSuggestBoxItemSorter sorter;
  final AutoSuggestBoxTextBoxBuilder<T> textBoxBuilder;
  final WidgetBuilder noResultsFound;

  final ValueChanged<T>? onSelected;

  @override
  _AutoSuggestBoxState<T> createState() => _AutoSuggestBoxState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty('items', items));
    properties.add(ObjectFlagProperty(
      'onSelected',
      onSelected,
      ifNull: 'disabled',
    ));
  }

  static List defaultItemSorter<T>(String text, List items) {
    return items.where((element) {
      return element.toString().toLowerCase().contains(text.toLowerCase());
    }).toList();
  }

  static Widget defaultNoResultsFound(context) {
    debugCheckHasFluentTheme(context);
    return ListTile(
      title: DefaultTextStyle(
        style: TextStyle(fontWeight: FontWeight.normal),
        child: Text('No results found'),
      ),
    );
  }

  static Widget defaultTextBoxBuilder(
    BuildContext context,
    TextEditingController controller,
    FocusNode focusNode,
    GlobalKey key,
  ) {
    debugCheckHasFluentTheme(context);
    const BorderSide _kDefaultRoundedBorderSide = BorderSide(
      style: BorderStyle.solid,
      width: 0.8,
    );
    return TextBox(
      key: key,
      controller: controller,
      focusNode: focusNode,
      decoration: BoxDecoration(
        border: Border(
          top: _kDefaultRoundedBorderSide,
          bottom: _kDefaultRoundedBorderSide,
          left: _kDefaultRoundedBorderSide,
          right: _kDefaultRoundedBorderSide,
        ),
        borderRadius: focusNode.hasFocus
            ? BorderRadius.vertical(top: Radius.circular(3.0))
            : BorderRadius.all(Radius.circular(3.0)),
      ),
    );
  }
}

class _AutoSuggestBoxState<T> extends State<AutoSuggestBox<T>> {
  final FocusNode focusNode = FocusNode();
  OverlayEntry? _entry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _textBoxKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  void _handleFocusChanged() {
    final hasFocus = focusNode.hasFocus;
    if (hasFocus) {
      if (_entry == null && !(_entry?.mounted ?? false)) {
        _insertOverlay();
      }
    } else {
      _dismissOverlay();
    }
    setState(() {});
  }

  AutoSuggestBoxItemBuilder<T> get itemBuilder =>
      widget.itemBuilder ?? _defaultItemBuilder;

  Widget _defaultItemBuilder(BuildContext context, T value) {
    debugCheckHasFluentTheme(context);
    return TappableListTile(
      onTap: () {
        widget.controller.text = '$value';
        widget.onSelected?.call(value);
        focusNode.unfocus();
      },
      title: Text(
        '$value',
        style: context.theme.typography?.body,
      ),
    );
  }

  void _insertOverlay() {
    _entry = OverlayEntry(builder: (context) {
      final box = _textBoxKey.currentContext!.findRenderObject() as RenderBox;
      return Positioned(
        width: box.size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, box.size.height + 0.8),
          child: Acrylic(
            elevation: 6,
            width: box.size.width,
            decoration: BoxDecoration(
                color: context.theme.navigationPanelBackgroundColor,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(4.0),
                ),
                border: Border.all(
                  color: context.theme.scaffoldBackgroundColor ??
                      Colors.transparent,
                  width: 0.8,
                )),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, _) {
                final items = widget.sorter(value.text, widget.items);
                late Widget result;
                if (items.isEmpty) {
                  result = widget.noResultsFound(context);
                } else {
                  result = ListView(
                    shrinkWrap: true,
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      return itemBuilder(context, item);
                    }),
                  );
                }
                return AnimatedSwitcher(
                  duration:
                      context.theme.fastAnimationDuration ?? Duration.zero,
                  switchInCurve: context.theme.animationCurve ?? Curves.linear,
                  transitionBuilder: (child, animation) {
                    if (child is ListView) {
                      return child;
                    }
                    return EntrancePageTransition(
                      child: child,
                      animation: animation,
                      vertical: true,
                    );
                  },
                  layoutBuilder: (child, children) => child ?? SizedBox(),
                  child: result,
                );
              },
            ),
          ),
        ),
      );
    });

    if (_textBoxKey.currentContext != null)
      Overlay.of(context)?.insert(_entry!);
  }

  void _dismissOverlay() {
    _entry?.remove();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) {
    debugCheckHasFluentTheme(context);
    return CompositedTransformTarget(
      link: _layerLink,
      child: widget.textBoxBuilder(
        context,
        widget.controller,
        focusNode,
        _textBoxKey,
      ),
    );
  }
}