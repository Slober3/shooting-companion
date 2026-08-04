import 'package:flutter/material.dart';

abstract final class AppFormSpacing {
  static const horizontal = 16.0;
  static const field = 16.0;
  static const related = 12.0;
  static const section = 24.0;
  static const top = 16.0;
  static const bottom = 24.0;
}

class AppFormGroup extends StatelessWidget {
  const AppFormGroup({
    required this.children,
    this.title,
    this.description,
    this.spacing = AppFormSpacing.field,
    super.key,
  });

  final String? title;
  final String? description;
  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (title != null) ...[
        Text(title!, style: Theme.of(context).textTheme.titleMedium),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppFormSpacing.related),
      ],
      for (var index = 0; index < children.length; index++) ...[
        children[index],
        if (index != children.length - 1) SizedBox(height: spacing),
      ],
    ],
  );
}
