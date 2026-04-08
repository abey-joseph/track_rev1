import 'package:flutter/material.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/money/domain/entities/account_entity.dart';
import 'package:track/features/money/presentation/utils/money_icon_resolver.dart';

class AccountPickerGrid extends StatelessWidget {
  const AccountPickerGrid({
    required this.accounts,
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  final List<AccountEntity> accounts;
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
            accounts.map((acct) {
              final isSelected = acct.id == selectedId;
              final color = _parseColor(acct.colorHex);

              return GestureDetector(
                onTap: () => onSelected(acct.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        isSelected
                            ? Border.all(color: colorScheme.primary, width: 1.5)
                            : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isSelected
                                  ? color
                                  : color.withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          resolveMoneyIcon(acct.iconName),
                          size: 13,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        acct.name,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
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
