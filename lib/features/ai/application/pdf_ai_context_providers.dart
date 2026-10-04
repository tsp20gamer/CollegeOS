import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/ai/data/local_pdf_context_repository.dart';
import 'package:college_os/features/ai/domain/pdf_ai_context.dart';
import 'package:college_os/features/ai/domain/pdf_context_repository.dart';
import 'package:college_os/features/notes/application/pdf_search_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [PdfContextRepository] backed by the local SQLite FTS5 index.
///
/// Consumed by AI application code. The concrete type is
/// [LocalPdfContextRepository]; callers should depend on the interface so the
/// implementation can be swapped (e.g. in tests).
///
/// The subject-file repository is injected so context blocks and citations can
/// be attributed to a document the student recognises.
final pdfContextRepositoryProvider = Provider<PdfContextRepository>((ref) {
  return LocalPdfContextRepository(
    ref.watch(pdfSearchDaoProvider),
    ref.watch(subjectFileRepositoryProvider),
  );
});

/// Retrieves PDF pages relevant to [question] for use as AI context.
///
/// Returns an empty list when [question] is blank or nothing matches.
/// The optional [limit] caps the number of pages returned; when omitted the
/// repository applies `AiContextLimits.maxContextPages`.
///
/// Usage:
/// ```dart
/// final pages = await ref.read(
///   pdfAiContextProvider(('What is Newton's law?', limit: 6)).future,
/// );
/// ```
final pdfAiContextProvider =
    FutureProvider.family<List<PdfAiContext>, ({String question, int limit})>((
      ref,
      args,
    ) async {
      if (args.question.trim().isEmpty) return [];
      return ref
          .watch(pdfContextRepositoryProvider)
          .retrieveContext(args.question, limit: args.limit);
    });

/// Convenience provider that applies the configured default page limit.
///
/// Prefer this over [pdfAiContextProvider] unless you need a custom limit.
final pdfAiContextDefaultProvider =
    FutureProvider.family<List<PdfAiContext>, String>((ref, question) async {
      if (question.trim().isEmpty) return [];
      return ref.watch(pdfContextRepositoryProvider).retrieveContext(question);
    });
