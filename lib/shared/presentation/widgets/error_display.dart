import 'package:flutter/material.dart';
import 'package:shoothelper/core/errors/failures.dart';

class ErrorDisplay extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onAction;

  const ErrorDisplay({super.key, required this.failure, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconFor(failure),
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              failure.userMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (failure.actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAction,
                child: Text(failure.actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(Failure failure) => switch (failure) {
        NetworkFailure() => Icons.wifi_off_rounded,
        DataNotReadyFailure() => Icons.download_rounded,
        CorruptedDataFailure() => Icons.warning_rounded,
        GearMissingFailure() => Icons.camera_alt_outlined,
        AppUpdateRequiredFailure() => Icons.system_update_rounded,
        UnknownFailure() => Icons.error_outline_rounded,
      };
}
