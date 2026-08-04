import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../data/app_database.dart';

typedef ExportDirectoryProvider = Future<Directory> Function();
typedef PdfFontLoader = Future<PdfFontBundle> Function();

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

class PdfFontBundle {
  const PdfFontBundle({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;

  static Future<PdfFontBundle> loadFromAssets() async {
    final regular = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    return PdfFontBundle(
      regular: pw.Font.ttf(regular),
      bold: pw.Font.ttf(bold),
    );
  }
}

class PdfReportData {
  const PdfReportData({required this.seriesRows, required this.generatedAt});

  final List<ExportSeriesRow> seriesRows;
  final DateTime generatedAt;

  int get sessionCount => seriesRows.map((row) => row.sessionId).toSet().length;
  int get seriesCount => seriesRows.length;
  int get shotCount => seriesRows.fold(0, (sum, row) => sum + row.shotCount);
  int get totalScore => seriesRows.fold(0, (sum, row) => sum + row.totalScore);
  int get maximumPossibleScore =>
      seriesRows.fold(0, (sum, row) => sum + row.maximumPossibleScore);
}

class PdfReportBuilder {
  const PdfReportBuilder._();

  static Future<Uint8List> build(
    PdfReportData data,
    PdfFontBundle fonts,
  ) async {
    final document = pw.Document(
      title: 'Shooting Companion trainingsrapport',
      author: 'Shooting Companion',
    );
    final formatter = DateFormat('dd/MM/yyyy HH:mm', 'nl_BE');
    final theme = pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(30, 28, 30, 30),
        theme: theme,
        maxPages: data.seriesRows.length + 20,
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Trainingsregistratie - geen gecertificeerde wedstrijdscore.',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.Text(
                'Pagina ${context.pageNumber} van ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.Text(
            'Shooting Companion',
            style: pw.TextStyle(fontSize: 25, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Offline trainingsrapport • gegenereerd ${formatter.format(data.generatedAt)}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _metric('Sessies', '${data.sessionCount}'),
              _metric('Reeksen', '${data.seriesCount}'),
              _metric('Schoten', '${data.shotCount}'),
              _metric(
                'Score',
                '${data.totalScore}/${data.maximumPossibleScore}',
              ),
            ],
          ),
          pw.SizedBox(height: 20),
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
            data: data.seriesRows
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
            headerCount: 1,
            columnWidths: const {
              0: pw.FixedColumnWidth(105),
              1: pw.FlexColumnWidth(2.8),
              2: pw.FixedColumnWidth(45),
              3: pw.FixedColumnWidth(58),
              4: pw.FixedColumnWidth(58),
              5: pw.FixedColumnWidth(70),
              6: pw.FixedColumnWidth(45),
              7: pw.FixedColumnWidth(35),
            },
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 4,
            ),
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
    return document.save();
  }

  static pw.Widget _metric(String label, String value) => pw.Column(
    children: [
      pw.Text(
        value,
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
      pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
    ],
  );
}

class ExportService {
  ExportService(
    this.database, {
    ExportDirectoryProvider? temporaryDirectory,
    DateTime Function()? now,
    PdfFontLoader? pdfFonts,
  }) : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _now = now ?? DateTime.now,
       _pdfFonts = pdfFonts ?? PdfFontBundle.loadFromAssets;

  final AppDatabase database;
  final ExportDirectoryProvider _temporaryDirectory;
  final DateTime Function() _now;
  final PdfFontLoader _pdfFonts;

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
    final rows = await _reportRows();
    final bytes = await PdfReportBuilder.build(
      PdfReportData(seriesRows: rows, generatedAt: _now()),
      await _pdfFonts(),
    );
    final file = await _exportFile('shooting-companion-${_stamp()}.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> shareFile(File file, {required String label}) => SharePlus
      .instance
      .share(ShareParams(files: [XFile(file.path)], text: label));

  Future<List<ExportSeriesRow>> _reportRows() async {
    final queryRows = await database
        .customSelect(
          '''
        SELECT
          series.session_id,
          session.started_at_utc,
          session.status AS session_status,
          series.sequence_number,
          series.target_profile_json,
          series.target_profile_versioned_id,
          series.distance_meters,
          series.shot_count,
          series.total_score,
          series.maximum_possible_score,
          series.inner_ten_count,
          series.miss_count,
          series.projectile_diameter_mm,
          series.notes,
          COUNT(image.id) AS photo_count
        FROM shooting_series AS series
        INNER JOIN training_sessions AS session
          ON session.id = series.session_id
        LEFT JOIN image_assets AS image
          ON image.series_id = series.id
        WHERE series.status = 'confirmed'
        GROUP BY series.id
        ORDER BY session.started_at_utc, series.sequence_number
      ''',
          readsFrom: {
            database.trainingSessions,
            database.shootingSeries,
            database.imageAssets,
          },
        )
        .get();
    return [
      for (final row in queryRows)
        ExportSeriesRow(
          sessionId: row.read<String>('session_id'),
          sessionStartedAtUtc: row.read<DateTime>('started_at_utc'),
          sessionStatus: row.read<String>('session_status'),
          sequenceNumber: row.read<int>('sequence_number'),
          targetName: ExportFormatter.targetDisplayName(
            row.read<String>('target_profile_json'),
            row.read<String>('target_profile_versioned_id'),
          ),
          distanceMeters: row.read<double>('distance_meters'),
          shotCount: row.read<int>('shot_count'),
          totalScore: row.read<int>('total_score'),
          maximumPossibleScore: row.read<int>('maximum_possible_score'),
          innerTenCount: row.read<int>('inner_ten_count'),
          missCount: row.read<int>('miss_count'),
          projectileDiameterMm: row.read<double>('projectile_diameter_mm'),
          photoCount: row.read<int>('photo_count'),
          notes: row.readNullable<String>('notes'),
        ),
    ];
  }

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
