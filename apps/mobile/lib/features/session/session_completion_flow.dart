import 'package:flutter/material.dart';

import '../../data/shooting_repository.dart';

enum SessionEndDecision {
  cancel,
  openDraft,
  confirmDraft,
  discardDraft,
  complete,
}

enum SessionCompletionUiOutcome {
  canceled,
  openedDraft,
  completed,
  deleted,
  alreadyCompleted,
  notFound,
  failed,
  busy,
}

class SessionCompletionCoordinator {
  const SessionCompletionCoordinator._();

  static final Set<String> _inFlightSessionIds = <String>{};

  static Future<SessionCompletionUiOutcome> run({
    required BuildContext context,
    required ShootingRepository repository,
    required String sessionId,
    required SessionEndPromptData promptData,
    required Future<void> Function(String draftSeriesId) openDraft,
  }) async {
    if (!_inFlightSessionIds.add(sessionId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deze sessie wordt al beëindigd.')),
        );
      }
      return SessionCompletionUiOutcome.busy;
    }

    try {
      final decision = await showSessionEndDialog(
        context: context,
        data: promptData,
      );
      if (!context.mounted || decision == SessionEndDecision.cancel) {
        return SessionCompletionUiOutcome.canceled;
      }
      if (decision == SessionEndDecision.openDraft) {
        final draftId = promptData.draftSeriesId;
        if (draftId != null) await openDraft(draftId);
        return SessionCompletionUiOutcome.openedDraft;
      }

      final result = switch (decision) {
        SessionEndDecision.confirmDraft =>
          await repository.confirmDraftAndCompleteSession(sessionId),
        SessionEndDecision.discardDraft =>
          await repository.discardDraftAndCompleteSession(sessionId),
        SessionEndDecision.complete => await repository.completeSession(
          sessionId,
        ),
        SessionEndDecision.cancel || SessionEndDecision.openDraft =>
          throw StateError('Onbereikbare sessieactie'),
      };
      final outcome = switch (result.outcome) {
        SessionCompletionOutcome.completed =>
          SessionCompletionUiOutcome.completed,
        SessionCompletionOutcome.deletedEmpty =>
          SessionCompletionUiOutcome.deleted,
        SessionCompletionOutcome.alreadyCompleted =>
          SessionCompletionUiOutcome.alreadyCompleted,
        SessionCompletionOutcome.notFound =>
          SessionCompletionUiOutcome.notFound,
      };
      if (context.mounted) {
        final message = switch (outcome) {
          SessionCompletionUiOutcome.completed => 'Sessie beëindigd',
          SessionCompletionUiOutcome.deleted => 'Lege sessie verwijderd',
          SessionCompletionUiOutcome.alreadyCompleted =>
            'Sessie was al beëindigd',
          SessionCompletionUiOutcome.notFound => 'Sessie bestaat niet meer',
          _ => null,
        };
        if (message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      }
      return outcome;
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sessie beëindigen mislukt: $error')),
        );
      }
      return SessionCompletionUiOutcome.failed;
    } finally {
      _inFlightSessionIds.remove(sessionId);
    }
  }
}

class SessionEndPromptData {
  const SessionEndPromptData({
    required this.confirmedSeriesCount,
    required this.draftSeriesId,
    required this.draftShotCount,
    required this.draftPhotoCount,
    required this.draftHasNotes,
    required this.draftWasEdited,
    required this.sessionPhotoCount,
    required this.hasSessionDetails,
  });

  final int confirmedSeriesCount;
  final String? draftSeriesId;
  final int draftShotCount;
  final int draftPhotoCount;
  final bool draftHasNotes;
  final bool draftWasEdited;
  final int sessionPhotoCount;
  final bool hasSessionDetails;

  bool get hasMeaningfulDraft =>
      draftSeriesId != null &&
      (draftShotCount > 0 ||
          draftPhotoCount > 0 ||
          draftHasNotes ||
          draftWasEdited);

  bool get wouldDeleteWithoutDraft =>
      confirmedSeriesCount == 0 && sessionPhotoCount == 0 && !hasSessionDetails;
}

Future<SessionEndDecision> showSessionEndDialog({
  required BuildContext context,
  required SessionEndPromptData data,
}) async {
  final decision = await showDialog<SessionEndDecision>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sessie beëindigen?'),
      content: Text(_message(data)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, SessionEndDecision.cancel),
          child: const Text('Annuleren'),
        ),
        if (data.hasMeaningfulDraft) ...[
          TextButton(
            onPressed: () =>
                Navigator.pop(context, SessionEndDecision.openDraft),
            child: const Text('Reeks openen'),
          ),
          OutlinedButton(
            onPressed: () =>
                Navigator.pop(context, SessionEndDecision.discardDraft),
            child: const Text('Concept verwijderen'),
          ),
          if (data.draftShotCount > 0)
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, SessionEndDecision.confirmDraft),
              child: const Text('Reeks bewaren en beëindigen'),
            ),
        ] else
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, SessionEndDecision.complete),
            child: const Text('Beëindigen'),
          ),
      ],
    ),
  );
  return decision ?? SessionEndDecision.cancel;
}

String _message(SessionEndPromptData data) {
  if (!data.hasMeaningfulDraft) {
    if (data.wouldDeleteWithoutDraft) {
      return 'Deze sessie bevat nog geen bewaarde reeks. Een volledig lege sessie wordt verwijderd.';
    }
    if (data.confirmedSeriesCount == 0) {
      if (data.sessionPhotoCount == 0) {
        return 'De ingevulde sessiedetails blijven lokaal bewaard.';
      }
      if (!data.hasSessionDetails) {
        return '${data.sessionPhotoCount} '
            '${data.sessionPhotoCount == 1 ? 'sessiefoto blijft' : 'sessiefoto’s blijven'} lokaal bewaard.';
      }
      return 'De ingevulde sessiedetails en ${data.sessionPhotoCount} '
          '${data.sessionPhotoCount == 1 ? 'sessiefoto blijven' : 'sessiefoto’s blijven'} lokaal bewaard.';
    }
    return 'Alle ${data.confirmedSeriesCount} bevestigde ${data.confirmedSeriesCount == 1 ? 'reeks blijft' : 'reeksen blijven'} lokaal bewaard.';
  }

  final parts = <String>[];
  if (data.draftShotCount > 0) {
    parts.add(
      '${data.draftShotCount} ${data.draftShotCount == 1 ? 'schot' : 'schoten'}',
    );
  }
  if (data.draftPhotoCount > 0) {
    parts.add(
      '${data.draftPhotoCount} ${data.draftPhotoCount == 1 ? 'foto' : 'foto’s'}',
    );
  }
  if (data.draftHasNotes) parts.add('een notitie');
  if (parts.isEmpty && data.draftWasEdited) {
    parts.add('gewijzigde instellingen');
  }
  return 'De conceptreeks bevat ${parts.join(' en ')}. Kies of je ze opent, bewaart of verwijdert.';
}
