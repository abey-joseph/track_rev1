import 'package:flutter/material.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/presentation/utils/money_icon_resolver.dart';

class CategoryPickerGrid extends StatelessWidget {
  const CategoryPickerGrid({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CategoryEntity> categories;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 8,
        children:
            categories.map((cat) {
              final isSelected = cat.id == selectedId;
              final color = _parseColor(cat.colorHex);

              return GestureDetector(
                onTap: () => onSelected(cat.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        isSelected
                            ? Border.all(color: colorScheme.primary, width: 1.5)
                            : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isSelected
                                  ? color
                                  : color.withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          resolveMoneyIcon(cat.iconName),
                          size: 14,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat.name,
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

Color _parseColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
