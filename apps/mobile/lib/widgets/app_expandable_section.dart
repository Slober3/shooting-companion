import 'package:flutter/material.dart';

/// A divider-free expandable form section with space for floating field labels.
class AppExpandableSection extends StatefulWidget {
  const AppExpandableSection({
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<AppExpandableSection> createState() => _AppExpandableSectionState();
}

class _AppExpandableSectionState extends State<AppExpandableSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Semantics(
        container: true,
        label: '${widget.title}, ${_expanded ? 'uitgevouwen' : 'ingevouwen'}',
        child: ExpansionTile(
          initiallyExpanded: widget.initiallyExpanded,
          maintainState: true,
          minTileHeight: 48,
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          clipBehavior: Clip.none,
          title: Text(widget.title),
          onExpansionChanged: (expanded) {
            setState(() => _expanded = expanded);
            widget.onExpansionChanged?.call(expanded);
          },
          children: widget.children,
        ),
      ),
    );
  }
}
