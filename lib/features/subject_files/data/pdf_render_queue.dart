import 'dart:async';
import 'dart:collection';

/// A handle on one scheduled page render.
class PdfRenderTicket<T> {
  PdfRenderTicket._(this._queue);

  final PdfRenderQueue _queue;
  final Completer<T?> _completer = Completer<T?>();
  bool _cancelled = false;
  bool _started = false;

  /// Completes with the job's result, or with null when the ticket was
  /// cancelled before its result was delivered.
  Future<T?> get future => _completer.future;

  bool get isCancelled => _cancelled;
  bool get isStarted => _started;

  /// Drops the render. A job that has not started never runs; a running job
  /// finishes on the renderer but its result is discarded (through
  /// [PdfRenderQueue]'s `onDiscard`, so an image it made is disposed).
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _queue._cancel(this);
    if (!_completer.isCompleted) _completer.complete(null);
  }
}

class _QueuedJob<T> {
  _QueuedJob(this.ticket, this.job);

  final PdfRenderTicket<T> ticket;
  final Future<T> Function() job;
}

/// Runs page renders a few at a time, newest request first.
///
/// While the student flings through a long document, page widgets ask for
/// renders far faster than the renderer can draw them. Running them all at
/// once is what piles up bitmaps (and the platform renderer can only draw one
/// page of a document at a time anyway), so here at most [maxConcurrent] run,
/// the most recent request goes next (the page now on screen, not the one
/// flung past a second ago), and a page that scrolls away cancels its request
/// before it ever reaches the renderer.
class PdfRenderQueue {
  PdfRenderQueue({this.maxConcurrent = 1, this.onDiscard})
    : assert(maxConcurrent > 0);

  final int maxConcurrent;

  /// Receives the result of a job whose ticket was cancelled while it ran.
  final void Function(Object? result)? onDiscard;

  final ListQueue<_QueuedJob<Object?>> _pending = ListQueue();
  int _running = 0;
  bool _closed = false;

  int get pendingCount => _pending.length;
  int get runningCount => _running;

  PdfRenderTicket<T> schedule<T>(Future<T> Function() job) {
    final ticket = PdfRenderTicket<T>._(this);
    if (_closed) {
      ticket._cancelled = true;
      ticket._completer.complete(null);
      return ticket;
    }
    _pending.addLast(_QueuedJob<Object?>(ticket, () => job()));
    _pump();
    return ticket;
  }

  /// Cancels everything and refuses new work.
  void close() {
    _closed = true;
    final pending = _pending.toList();
    _pending.clear();
    for (final job in pending) {
      job.ticket.cancel();
    }
  }

  void _cancel(PdfRenderTicket<Object?> ticket) {
    if (!ticket._started) {
      _pending.removeWhere((job) => identical(job.ticket, ticket));
    }
  }

  void _pump() {
    while (_running < maxConcurrent && _pending.isNotEmpty) {
      // Newest first: the page the student is looking at now.
      final next = _pending.removeLast();
      if (next.ticket._cancelled) continue;
      next.ticket._started = true;
      _running++;
      unawaited(_run(next));
    }
  }

  Future<void> _run(_QueuedJob<Object?> queued) async {
    final ticket = queued.ticket;
    try {
      final result = await queued.job();
      if (ticket._cancelled || ticket._completer.isCompleted) {
        onDiscard?.call(result);
      } else {
        ticket._completer.complete(result);
      }
    } catch (error, stackTrace) {
      if (!ticket._completer.isCompleted) {
        ticket._completer.completeError(error, stackTrace);
      }
    } finally {
      _running--;
      if (!_closed) _pump();
    }
  }
}
