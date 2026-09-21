import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/onboarding/application/onboarding_providers.dart';
import 'package:college_os/features/onboarding/domain/college_setup.dart';
import 'package:college_os/features/onboarding/domain/college_setup_validator.dart';
import 'package:college_os/features/onboarding/presentation/widgets/setup_date_field.dart';
import 'package:college_os/features/onboarding/presentation/widgets/setup_form_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CollegeSetupScreen extends ConsumerStatefulWidget {
  const CollegeSetupScreen({super.key});

  @override
  ConsumerState<CollegeSetupScreen> createState() => _CollegeSetupScreenState();
}

class _CollegeSetupScreenState extends ConsumerState<CollegeSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentNameController = TextEditingController();
  final _collegeController = TextEditingController();
  final _courseController = TextEditingController();
  final _branchController = TextEditingController();
  final _semesterController = TextEditingController(text: '1');
  final _academicYearController = TextEditingController();
  final _targetController = TextEditingController(text: '75');

  late DateTime _academicStartDate;
  late DateTime _academicEndDate;
  late DateTime _semesterStartDate;
  late DateTime _semesterEndDate;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _academicStartDate = today;
    _academicEndDate = DateUtils.dateOnly(
      DateTime(today.year + 1, today.month, today.day - 1),
    );
    _semesterStartDate = today;
    final suggestedSemesterEnd = DateUtils.dateOnly(
      DateTime(today.year, today.month + 4, today.day),
    );
    _semesterEndDate = suggestedSemesterEnd.isAfter(_academicEndDate)
        ? _academicEndDate
        : suggestedSemesterEnd;
    final academicStart = today.month >= 6 ? today.year : today.year - 1;
    _academicYearController.text = '$academicStart-${academicStart + 1}';
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _collegeController.dispose();
    _courseController.dispose();
    _branchController.dispose();
    _semesterController.dispose();
    _academicYearController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submission = ref.watch(onboardingControllerProvider);
    final dateError = _submitted
        ? CollegeSetupValidator.dateRange(
            _semesterStartDate,
            _semesterEndDate,
            academicStart: _academicStartDate,
            academicEnd: _academicEndDate,
          )
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('College Setup')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _submitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SetupFormSection(
                          icon: Icons.account_balance_outlined,
                          title: 'College information',
                          description: 'Used only to personalize this device.',
                          children: [
                            TextFormField(
                              key: const Key('student_name_field'),
                              controller: _studentNameController,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.name],
                              decoration: const InputDecoration(
                                labelText: 'Your Name',
                                hintText: 'e.g. Tsp',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (value) =>
                                  CollegeSetupValidator.requiredText(
                                    value,
                                    fieldName: 'Your name',
                                    maxLength: 80,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              key: const Key('college_name_field'),
                              controller: _collegeController,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [
                                AutofillHints.organizationName,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'College Name',
                                prefixIcon: Icon(Icons.school_outlined),
                              ),
                              validator: (value) =>
                                  CollegeSetupValidator.requiredText(
                                    value,
                                    fieldName: 'College name',
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _responsivePair(
                              constraints.maxWidth,
                              TextFormField(
                                key: const Key('course_field'),
                                controller: _courseController,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Course',
                                  hintText: 'e.g. B.Tech',
                                  prefixIcon: Icon(Icons.menu_book_outlined),
                                ),
                                validator: (value) =>
                                    CollegeSetupValidator.requiredText(
                                      value,
                                      fieldName: 'Course',
                                      maxLength: 80,
                                    ),
                              ),
                              TextFormField(
                                key: const Key('branch_field'),
                                controller: _branchController,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Branch',
                                  hintText: 'e.g. Computer Science',
                                  prefixIcon: Icon(Icons.alt_route_rounded),
                                ),
                                validator: (value) =>
                                    CollegeSetupValidator.requiredText(
                                      value,
                                      fieldName: 'Branch',
                                      maxLength: 80,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SetupFormSection(
                          icon: Icons.calendar_month_outlined,
                          title: 'Current academic details',
                          description:
                              'Tell CollegeOS which semester you are studying now.',
                          children: [
                            _responsivePair(
                              constraints.maxWidth,
                              TextFormField(
                                key: const Key('semester_number_field'),
                                controller: _semesterController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Current Semester',
                                  prefixIcon: Icon(Icons.numbers_rounded),
                                ),
                                validator: CollegeSetupValidator.semesterNumber,
                              ),
                              TextFormField(
                                key: const Key('academic_year_field'),
                                controller: _academicYearController,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.datetime,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(9),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Academic Year',
                                  hintText: '2026-2027',
                                  prefixIcon: Icon(Icons.date_range_outlined),
                                ),
                                validator: CollegeSetupValidator.academicYear,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _responsivePair(
                              constraints.maxWidth,
                              SetupDateField(
                                label: 'Academic Year Start Date',
                                value: _academicStartDate,
                                onChanged: (date) =>
                                    setState(() => _academicStartDate = date),
                              ),
                              SetupDateField(
                                label: 'Academic Year End Date',
                                value: _academicEndDate,
                                errorText: dateError,
                                onChanged: (date) =>
                                    setState(() => _academicEndDate = date),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _responsivePair(
                              constraints.maxWidth,
                              SetupDateField(
                                label: 'Current Semester Start Date',
                                value: _semesterStartDate,
                                onChanged: (date) =>
                                    setState(() => _semesterStartDate = date),
                              ),
                              SetupDateField(
                                label: 'Current Semester End Date',
                                value: _semesterEndDate,
                                errorText: dateError,
                                onChanged: (date) =>
                                    setState(() => _semesterEndDate = date),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SetupFormSection(
                          icon: Icons.track_changes_rounded,
                          title: 'Attendance preference',
                          description:
                              'New subjects start with this target. You can change each subject later.',
                          children: [
                            TextFormField(
                              key: const Key('attendance_target_field'),
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
                                helperText: 'CollegeOS recommends 75%.',
                              ),
                              validator: CollegeSetupValidator.attendanceTarget,
                            ),
                          ],
                        ),
                        if (submission.hasError) ...[
                          const SizedBox(height: AppSpacing.md),
                          _SubmissionError(
                            message:
                                'Setup could not be saved. Your existing local data was not changed.',
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          key: const Key('complete_setup_button'),
                          onPressed: submission.isLoading ? null : _submit,
                          icon: submission.isLoading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                          ),
                          label: Text(
                            submission.isLoading
                                ? 'Saving on this device…'
                                : 'Complete Setup',
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

  Widget _responsivePair(double width, Widget first, Widget second) {
    if (width < 600) {
      return Column(
        children: [
          first,
          const SizedBox(height: AppSpacing.md),
          second,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: second),
      ],
    );
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _submitted = true);
    final validForm = _formKey.currentState?.validate() ?? false;
    final dateError = CollegeSetupValidator.dateRange(
      _semesterStartDate,
      _semesterEndDate,
      academicStart: _academicStartDate,
      academicEnd: _academicEndDate,
    );
    if (!validForm || dateError != null) return;

    final completed = await ref
        .read(onboardingControllerProvider.notifier)
        .complete(
          CollegeSetup(
            studentName: _studentNameController.text.trim(),
            collegeName: _collegeController.text.trim(),
            course: _courseController.text.trim(),
            branch: _branchController.text.trim(),
            semesterNumber: int.parse(_semesterController.text),
            academicYear: _academicYearController.text.trim(),
            academicYearStartDate: _academicStartDate,
            academicYearEndDate: _academicEndDate,
            semesterStartDate: _semesterStartDate,
            semesterEndDate: _semesterEndDate,
            defaultAttendanceTarget: double.parse(_targetController.text) / 100,
          ),
        );
    if (completed && mounted) context.go(RoutePaths.gettingStarted);
  }
}

class _SubmissionError extends StatelessWidget {
  const _SubmissionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
