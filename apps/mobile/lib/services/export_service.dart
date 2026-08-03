import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../data/app_database.dart';

typedef ExportDirectoryProvider = Future<Directory> Function();

class ExportSeriesRow {
  const ExportSeriesRow({
    required this.sessionId,
    required this.sessionStartedAtUtc,
    required this.sessionStatus,
    required this.sequenceNumber,
    required this.targetName,
    required this.distanceMeters,
    required this.shotCount,
    required this.totalScore,
    required this.maximumPossibleScore,
    required this.innerTenCount,
    required this.missCount,
    required this.projectileDiameterMm,
    required this.photoCount,
    this.notes,
  });

  final String sessionId;
  final DateTime sessionStartedAtUtc;
  final String sessionStatus;
  final int sequenceNumber;
  final String targetName;
  final double distanceMeters;
  final int shotCount;
  final int totalScore;
  final int maximumPossibleScore;
  final int innerTenCount;
  final int missCount;
  final double projectileDiameterMm;
  final int photoCount;
  final String? notes;

  double get percentage =>
      maximumPossibleScore == 0 ? 0 : totalScore * 100 / maximumPossibleScore;
}

/// Pure formatting helpers used by CSV, PDF and regression tests.
class ExportFormatter {
  const ExportFormatter._();

  static String buildCsv(List<ExportSeriesRow> rows) {
    final lines = <String>[
      'session_id,datum,status,reeks,doelprofiel,afstand_m,'
          'geregistreerde_schoten,score,maximum,percentage,x,missers,'
          'projectieldiameter_mm,reeksnotitie,foto_aantal',
    ];
    for (final row in rows) {
      lines.add(
        [
          row.sessionId,
          row.sessionStartedAtUtc.toUtc().toIso8601String(),
          row.sessionStatus,
          '${row.sequenceNumber}',
          row.targetName,
          _decimal(row.distanceMeters),
          '${row.shotCount}',
          '${row.totalScore}',
          '${row.maximumPossibleScore}',
          row.percentage.toStringAsFixed(2),
          '${row.innerTenCount}',
          '${row.missCount}',
          _decimal(row.projectileDiameterMm),
          row.notes ?? '',
          '${row.photoCount}',
        ].map(_csv).join(','),
      );
    }
    return lines.join('\r\n');
  }

  static String targetDisplayName(String snapshot, String fallback) {
    try {
      final decoded = jsonDecode(snapshot);
      if (decoded is Map) {
        final name = decoded['displayName'];
        if (name is String && name.trim().isNotEmpty) return name.trim();
      }
    } on FormatException {
      // A historical snapshot can still be exported using its versioned id.
    }
    return fallback;
  }

  static String _csv(String value) => '"${value.replaceAll('"', '""')}"';

  static String _decimal(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toString();
  }
}

class ExportService {
  ExportService(
    this.database, {
    ExportDirectoryProvider? temporaryDirectory,
    DateTime Function()? now,
  }) : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _now = now ?? DateTime.now;

  final AppDatabase database;
  final ExportDirectoryProvider _temporaryDirectory;
  final DateTime Function() _now;

  Future<File> createCsv() async {
    final rows = await _reportRows();
    final file = await _exportFile('shooting-companion-${_stamp()}.csv');
    return file.writeAsString(
      ExportFormatter.buildCsv(rows),
      encoding: utf8,
      flush: true,
    );
  }

  Future<File> createPdfReport() async {
    final sessions = await database.select(database.trainingSessions).get();
    final rows = await _reportRows();
    final document = pw.Document(
      title: 'Shooting Companion trainingsrapport',
      author: 'Shooting Companion',
    );
    final totalScore = rows.fold(0, (sum, item) => sum + item.totalScore);
    final maximum = rows.fold(
      0,
      (sum, item) => sum + item.maximumPossibleScore,
    );
    final shotCount = rows.fold(0, (sum, item) => sum + item.shotCount);
    final formatter = DateFormat('dd/MM/yyyy HH:mm', 'nl_BE');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Shooting Companion',
            style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Offline trainingsrapport • gegenereerd ${formatter.format(_now())}',
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _pdfMetric('Sessies', '${sessions.length}'),
              _pdfMetric('Reeksen', '${rows.length}'),
              _pdfMetric('Schoten', '$shotCount'),
              _pdfMetric('Score', '$totalScore/$maximum'),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Datum',
              'Doelkaart',
              'Reeks',
              'Afstand',
              'Schoten',
              'Score',
              '%',
              'X',
            ],
            data: rows
                .map(
                  (item) => [
                    formatter.format(item.sessionStartedAtUtc.toLocal()),
                    item.targetName,
                    '${item.sequenceNumber}',
                    '${item.distanceMeters.toStringAsFixed(0)} m',
                    '${item.shotCount}',
                    '${item.totalScore}/${item.maximumPossibleScore}',
                    item.percentage.toStringAsFixed(1),
                    '${item.innerTenCount}',
                  ],
                )
                .toList(),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Dit rapport is een trainingsregistratie en geen gecertificeerde wedstrijdscore.',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
    final file = await _exportFile('shooting-companion-${_stamp()}.pdf');
    await file.writeAsBytes(await document.save(), flush: true);
    return file;
  }

  Future<void> shareFile(File file, {required String label}) => SharePlus
      .instance
      .share(ShareParams(files: [XFile(file.path)], text: label));

  Future<List<ExportSeriesRow>> _reportRows() async {
    final sessions = await database.select(database.trainingSessions).get();
    final allSeries = await database.select(database.shootingSeries).get();
    final images = await database.select(database.imageAssets).get();
    final sessionById = {for (final item in sessions) item.id: item};
    final photoCountBySeries = <String, int>{};
    for (final image in images) {
      final seriesId = image.seriesId;
      if (seriesId != null) {
        photoCountBySeries.update(
          seriesId,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final rows = <ExportSeriesRow>[];
    for (final item in allSeries) {
      if (item.status != 'confirmed') continue;
      final session = sessionById[item.sessionId];
      if (session == null) continue;
      rows.add(
        ExportSeriesRow(
          sessionId: item.sessionId,
          sessionStartedAtUtc: session.startedAtUtc,
          sessionStatus: session.status,
          sequenceNumber: item.sequenceNumber,
          targetName: ExportFormatter.targetDisplayName(
            item.targetProfileJson,
            item.targetProfileVersionedId,
          ),
          distanceMeters: item.distanceMeters,
          shotCount: item.shotCount,
          totalScore: item.totalScore,
          maximumPossibleScore: item.maximumPossibleScore,
          innerTenCount: item.innerTenCount,
          missCount: item.missCount,
          projectileDiameterMm: item.projectileDiameterMm,
          photoCount: photoCountBySeries[item.id] ?? 0,
          notes: item.notes,
        ),
      );
    }
    rows.sort((first, second) {
      final date = first.sessionStartedAtUtc.compareTo(
        second.sessionStartedAtUtc,
      );
      return date != 0
          ? date
          : first.sequenceNumber.compareTo(second.sequenceNumber);
    });
    return rows;
  }

  pw.Widget _pdfMetric(String label, String value) => pw.Column(
    children: [
      pw.Text(
        value,
        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
      ),
      pw.Text(label),
    ],
  );

  String _stamp() => DateFormat('yyyyMMdd-HHmmss').format(_now());

  Future<File> _exportFile(String name) async {
    final directory = Directory(
      path.join(
        (await _temporaryDirectory()).path,
        'shooting_companion_exports',
      ),
    );
    await directory.create(recursive: true);
    return File(path.join(directory.path, name));
  }
}
