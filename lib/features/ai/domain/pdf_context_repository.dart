import 'package:college_os/features/ai/domain/pdf_ai_context.dart';

/// Contract for the local PDF AI context retrieval layer.
///
/// Implementations query the already-indexed FTS5 data and return the most
/// relevant pages for a given natural-language question.  No network calls are
/// made; all data stays on-device.
abstract interface class PdfContextRepository {
  /// Returns up to [limit] PDF pages whose content is most relevant to
  /// [question].
  ///
  /// - When [limit] is `null` the implementation's configured
  ///   `AiContextLimits.maxContextPages` applies.
  /// - Returns an empty list when [question] is blank or no matches are found.
  /// - Never throws; errors are swallowed and an empty list is returned.
  /// - Does **not** modify or delete any indexed data.
  Future<List<PdfAiContext>> retrieveContext(String question, {int? limit});
}
