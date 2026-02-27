import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/core/models/employee.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/features/m04_ghp/providers/ghp_provider.dart';

void main() {
  test('GhpFormSubmission returns error when user is missing', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final success = await container
        .read(ghpFormSubmissionProvider.notifier)
        .submitChecklist(
          formId: 'ghp_personnel',
          data: {
            'answers': {'uniform': true},
          },
        );

    expect(success, isFalse);
  });

  test('GhpFormSubmission returns error when zone is missing', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(currentUserProvider.notifier)
        .set(
          Employee(
            id: 'user-1',
            fullName: 'Tester',
            role: 'manager',
            isActive: true,
          ),
        );

    final success = await container
        .read(ghpFormSubmissionProvider.notifier)
        .submitChecklist(
          formId: 'ghp_personnel',
          data: {
            'answers': {'uniform': true},
          },
        );

    expect(success, isFalse);
  });
}
