import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/onboarding/domain/college_setup_validator.dart';
import 'package:college_os/features/onboarding/presentation/widgets/setup_date_field.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/settings/application/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CollegeInformationScreen extends ConsumerStatefulWidget {
  const CollegeInformationScreen({super.key});

  @override
  ConsumerState<CollegeInformationScreen> createState() =>
      _CollegeInformationScreenState();
}

class _CollegeInformationScreenState
    extends ConsumerState<CollegeInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentNameController = TextEditingController();
  final _collegeController = TextEditingController();
  final _courseController = TextEditingController();
  final _branchController = TextEditingController();
  final _targetController = TextEditingController();
  bool _initialized = false;
  bool _submitted = false;
  late DateTime _academicStartDate;
  late DateTime _academicEndDate;

  @override
  void dispose() {
    _studentNameController.dispose();
    _collegeController.dispose();
    _courseController.dispose();
    _branchController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(collegeSettingsProvider);
    final submission = ref.watch(collegeInformationControllerProvider);
    final activeSemester = ref.watch(activeSemesterProvider).value;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('College Information')),
      body: SafeArea(
        child: settings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'CollegeOS could not load your local college information.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.error),
              ),
            ),
          ),
          data: (value) {
            if (!_initialized) {
              _initialized = true;
              _studentNameController.text = value.studentName;
              _collegeController.text = value.collegeName;
              _courseController.text = value.course;
              _branchController.text = value.branch;
              _targetController.text = _formatPercent(
                value.defaultAttendanceTarget * 100,
              );
              _academicStartDate =
                  value.academicYearStartDate ??
                  activeSemester?.startDate ??
                  DateUtils.dateOnly(DateTime.now());
              _academicEndDate =
                  value.academicYearEndDate ??
                  activeSemester?.endDate ??
                  DateUtils.dateOnly(
                    DateTime.now().add(const Duration(days: 365)),
                  );
            }
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppLayout.floatingDockContentInset +
                    AppSpacing.lg +
                    MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _submitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              children: [
                                TextFormField(
                                  key: const Key('edit_student_name_field'),
                                  controller: _studentNameController,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  autofillHints: const [AutofillHints.name],
                                  decoration: const InputDecoration(
                                    labelText: 'Your Name',
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                    ),
                                  ),
                                  validator: (text) =>
                                      CollegeSetupValidator.requiredText(
                                        text,
                                        fieldName: 'Your name',
                                        maxLength: 80,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextFormField(
                                  key: const Key('edit_college_name_field'),
                                  controller: _collegeController,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'College Name',
                                    prefixIcon: Icon(Icons.school_outlined),
                                  ),
                                  validator: (text) =>
                                      CollegeSetupValidator.requiredText(
                                        text,
                                        fieldName: 'College name',
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextFormField(
                                  controller: _courseController,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Course',
                                    prefixIcon: Icon(Icons.menu_book_outlined),
                                  ),
                                  validator: (text) =>
                                      CollegeSetupValidator.requiredText(
                                        text,
                                        fieldName: 'Course',
                                        maxLength: 80,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextFormField(
                                  controller: _branchController,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Branch',
                                    prefixIcon: Icon(Icons.alt_route_rounded),
                                  ),
                                  validator: (text) =>
                                      CollegeSetupValidator.requiredText(
                                        text,
                                        fieldName: 'Branch',
                                        maxLength: 80,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextFormField(
                                  controller: _targetController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d{0,3}(\.\d{0,1})?'),
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Default Attendance Target',
                                    prefixIcon: Icon(Icons.percent_rounded),
                                    suffixText: '%',
                                  ),
                                  validator:
                                      CollegeSetupValidator.attendanceTarget,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Academic year dates',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                SetupDateField(
                                  label: 'Academic Year Start Date',
                                  value: _academicStartDate,
                                  onChanged: (date) =>
                                      setState(() => _academicStartDate = date),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                SetupDateField(
                                  label: 'Academic Year End Date',
                                  value: _academicEndDate,
                                  errorText: _academicDateError(activeSemester),
                                  onChanged: (date) =>
                                      setState(() => _academicEndDate = date),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (submission.hasError) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Changes could not be saved. Your existing data is unchanged.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.error),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          key: const Key('save_college_information_button'),
                          onPressed: submission.isLoading ? null : _save,
                          icon: submission.isLoading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            submission.isLoading ? 'Saving…' : 'Save Changes',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _submitted = true);
    final activeSemester = ref.read(activeSemesterProvider).value;
    if (!(_formKey.currentState?.validate() ?? false) ||
        _academicDateError(activeSemester) != null) {
      return;
    }

    final saved = await ref
        .read(collegeInformationControllerProvider.notifier)
        .save(
          studentName: _studentNameController.text,
          collegeName: _collegeController.text,
          course: _courseController.text,
          branch: _branchController.text,
          defaultAttendanceTarget: double.parse(_targetController.text) / 100,
          academicYearStartDate: _academicStartDate,
          academicYearEndDate: _academicEndDate,
        );
    if (saved && mounted) context.pop();
  }

  String _formatPercent(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  String? _academicDateError(Semester? activeSemester) {
    if (!_academicStartDate.isBefore(_academicEndDate)) {
      return 'Academic year start must be before its end.';
    }
    if (activeSemester != null &&
        (activeSemester.startDate.isBefore(_academicStartDate) ||
            activeSemester.endDate.isAfter(_academicEndDate))) {
      return 'The active semester must fit inside the academic year.';
    }
    return null;
  }
}
