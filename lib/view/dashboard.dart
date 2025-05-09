import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import '../model/workflow.dart';
import '../viewmodel/workflow_view_model.dart';
import '../viewmodel/process_view_model.dart';
import '../viewmodel/sub_process_view_model.dart';
import 'package:signature/signature.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final WorkflowViewModel _workflowVM = WorkflowViewModel();
  final ProcessViewModel _processVM = ProcessViewModel();
  final SubProcessViewModel _subProcessVM = SubProcessViewModel();
  List<Workflow> _workflows = [];
  bool _isPieChart = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _toggleChartType() {
    setState(() {
      _isPieChart = !_isPieChart;
    });
  }

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );
  Widget _buildDialogActionButtons({
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    Color confirmColor = const Color(0xFF78A190),
    String confirmText = 'Save',
  }) {
    final intl = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancel,
          child: Text(intl.cancel,
              style: TextStyle(
                  color: Color(0xFF28445C), fontFamily: 'BrandonGrotesque')),
        ),
        SizedBox(width: 12),
        ElevatedButton(
          style: _buttonStyle.copyWith(
              backgroundColor: MaterialStatePropertyAll(confirmColor)),
          onPressed: onConfirm,
          child: Text(confirmText,
              style: TextStyle(fontFamily: 'BrandonGrotesque')),
        ),
      ],
    );
  }

  Widget _buildDialogHeader(String title, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF78A190).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: Color(0xFF28445C)),
        ),
        SizedBox(height: 16),
        Text(title, style: _headerStyle),
      ],
    );
  }

  Future<Map<String, Map<int, int>>> _loadWorkflowData(
      Workflow workflow) async {
    try {
      // 1. Get processes for this workflow
      final processes = await _processVM.getByWorkflowId(workflow.id!);

      // 2. Get sub-processes for each process
      final allSubs = await Future.wait(
          processes.map((p) => _subProcessVM.getByProcessId(p.id!)));

      // 3. Combine sub-processes
      final subProcesses = allSubs.expand((s) => s).toList();

      return {
        'process': _getStatusCounts(processes, (p) => p.statusId),
        'subProcess': _getStatusCounts(subProcesses, (sp) => sp.statusId),
      };
    } catch (e) {
      print('Error loading workflow data: $e');
      return {'process': {}, 'subProcess': {}};
    }
  }

  Map<int, int> _getStatusCounts<T>(List<T> items, int? Function(T) getStatus) {
    return {
      1: items.where((i) => getStatus(i) == 1).length,
      2: items.where((i) => getStatus(i) == 2).length,
      3: items.where((i) => getStatus(i) == 3).length,
    };
  }

  Future<void> _loadData() async {
    try {
      final workflows = await _workflowVM.fetchAllWorkflows();
      if (mounted) {
        setState(() {
          _workflows = workflows;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('Error loading data: $e');
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(int status, BuildContext context) {
    final intl = AppLocalizations.of(context)!;
    switch (status) {
      case 1:
        return intl.created;
      case 2:
        return intl.started;
      case 3:
        return intl.finished;
      default:
        return intl.unknown;
    }
  }

  Widget _buildChart(
      Map<int, int> statusCounts, String title, BuildContext context) {
    if (_isPieChart) {
      return _buildPieChart(statusCounts, title, context);
    } else {
      return _buildBarChart(statusCounts, title, context);
    }
  }

  void _showSignatureDialog() async {
    final Uint8List? signature = await showDialog<Uint8List>(
      context: context,
      builder: (context) => Dialog(
        shape: _dialogShape,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildDialogHeader(
                AppLocalizations.of(context)!.signReport,
                Icons.brush,
              ),
              const SizedBox(height: 24),
              // Signature Area
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF78A190).withOpacity(0.2),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Signature(
                    controller: _signatureController,
                    backgroundColor: const Color(0xFFF5F7FA),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
              _buildDialogActionButtons(
                onCancel: () => Navigator.pop(context),
                onConfirm: () async {
                  if (_signatureController.isNotEmpty) {
                    final signatureImage = await _signatureController
                        .toPngBytes(height: 200, width: 400);
                    if (signatureImage != null) {
                      Navigator.pop(context, signatureImage);
                    }
                  }
                },
                confirmText: AppLocalizations.of(context)!.confirm,
              ),
            ],
          ),
        ),
      ),
    );

    if (signature != null && signature.isNotEmpty) {
      await _generateReport(signature);
    }
    _signatureController.clear();
  }

  Future<void> _generateReport(Uint8List signatureImage) async {
    final currentContext = context;
    final intl = AppLocalizations.of(context)!;
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(
                intl.generatingReport,
                Icons.description, // Or choose appropriate icon
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                color: Color(0xFF78A190), // Match accent color
              ),
              const SizedBox(height: 24),
              Text(
                intl.pleaseWaitpdf,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final allData = await Future.wait(
          _workflows.map((workflow) => _loadWorkflowData(workflow)));

      final pdf = await _buildPdf(allData, signatureImage);
      final bytes = await pdf.save();

      if (mounted) {
        Navigator.of(currentContext).pop();

        // Show PDF preview dialog
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(currentContext).pop();
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('${intl.errorGeneratingReport}: $e')),
        );
      }
    }
  }

  Future<pw.Document> _buildPdf(
      List<Map<String, Map<int, int>>> allData, Uint8List signature) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(signature);
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        header: (pw.Context context) => pw.Column(
          children: [
            pw.Text('Workflow Report',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text(formattedDate),
            pw.Divider(),
          ],
        ),
        footer: (pw.Context context) => pw.Column(
          children: [
            pw.Divider(),
            _buildSignatureSection(image),
          ],
        ),
        build: (pw.Context context) => [
          ..._buildWorkflowSections(allData),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildSignatureSection(pw.ImageProvider image) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Approval Signature:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Container(
          height: 80,
          width: 200,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Image(
            image,
            fit: pw.BoxFit.contain,
            dpi: 300, // Increase resolution
          ),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.only(
            top: 10,
          ),
          child: pw.Text("Yassine Kadri "),
        )
      ],
    );
  }

  List<pw.Widget> _buildWorkflowSections(
      List<Map<String, Map<int, int>>> allData) {
    return _workflows.asMap().entries.map((entry) {
      final index = entry.key;
      final workflow = entry.value;
      final data = allData[index];

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Workflow ${index + 1}: ${workflow.name ?? 'Unnamed'}',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildPdfSection('Process Status', data['process']!),
          _buildPdfSection('Sub-Process Status', data['subProcess']!),
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 20),
        ],
      );
    }).toList();
  }

  pw.Widget _buildPdfSection(String title, Map<int, int> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              children: [
                pw.Padding(
                    child: pw.Text('Status'),
                    padding: const pw.EdgeInsets.all(4)),
                pw.Padding(
                    child: pw.Text('Count'),
                    padding: const pw.EdgeInsets.all(4)),
              ],
            ),
            ...data.entries.map((entry) => pw.TableRow(
                  children: [
                    pw.Padding(
                      child: pw.Text(_getStatusLabelPdf(entry.key)),
                      padding: const pw.EdgeInsets.all(4),
                    ),
                    pw.Padding(
                      child: pw.Text(entry.value.toString()),
                      padding: const pw.EdgeInsets.all(4),
                    ),
                  ],
                )),
          ],
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }

  String _getStatusLabelPdf(int status) {
    switch (status) {
      case 1:
        return 'Created';
      case 2:
        return 'Started';
      case 3:
        return 'Finished';
      default:
        return 'Unknown';
    }
  }

  Widget _buildPieChart(
      Map<int, int> statusCounts, String title, BuildContext context) {
    final hasData = statusCounts.values.any((v) => v > 0);
    final sections = statusCounts.entries.map((entry) {
      return PieChartSectionData(
        color: _getStatusColor(entry.key),
        value: entry.value.toDouble(),
        title: hasData ? '${entry.value}' : '',
        radius: 30,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: hasData
              ? PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 0,
                    startDegreeOffset: 180,
                  ),
                )
              : Center(child: Text(AppLocalizations.of(context)!.error)),
        ),
      ],
    );
  }

  Widget _buildBarChart(
      Map<int, int> statusCounts, String title, BuildContext context) {
    // Create separate bars for each status
    final List<BarChartGroupData> barGroups = [
      BarChartGroupData(
        x: 0,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: statusCounts[1]?.toDouble() ?? 0,
            color: _getStatusColor(1),
            width: 20,
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: statusCounts.values
                  .fold(0, (a, b) => a > b ? a : b)
                  .toDouble(),
              color: Colors.grey[200],
            ),
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: statusCounts[2]?.toDouble() ?? 0,
            color: _getStatusColor(2),
            width: 20,
          ),
        ],
      ),
      BarChartGroupData(
        x: 2,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: statusCounts[3]?.toDouble() ?? 0,
            color: _getStatusColor(3),
            width: 20,
          ),
        ],
      ),
    ];

    return Column(
      children: [
        Text(title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            )),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: statusCounts.values
                  .fold(0, (a, b) => a > b ? a : b)
                  .toDouble(),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final status = value.toInt() + 1;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          _getStatusLabel(status, context),
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildValueLabels(statusCounts, context),
      ],
    );
  }

  Widget _buildValueLabels(Map<int, int> counts, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [1, 2, 3].map((status) {
        final value = counts[status] ?? 0;
        return Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getStatusLabel(status, context),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildWorkflowCharts(Workflow workflow, BuildContext context) {
    final intl = AppLocalizations.of(context)!;

    return FutureBuilder(
      future: _loadWorkflowData(workflow),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text(intl.error);
        }

        // Get the pre-calculated counts from the future
        final processCounts = snapshot.data?['process'] ?? {};
        final subProcessCounts = snapshot.data?['subProcess'] ?? {};
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(workflow.name ?? '',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child:
                          _buildChart(processCounts, intl.processes, context),
                    ),
                    Expanded(
                      child: _buildChart(
                          subProcessCounts, intl.subProcesses, context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [1, 2, 3]
                      .map((status) => Row(
                            children: [
                              Container(
                                  width: 12,
                                  height: 12,
                                  color: _getStatusColor(status)),
                              const SizedBox(width: 4),
                              Text(_getStatusLabel(status, context)),
                            ],
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final intl = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF78A190),
        title: Padding(
            padding: EdgeInsets.only(left: 118),
            child: Text(
              intl.dashboard,
              style: const TextStyle(
                  color: Color(0xFF28445C),
                  fontFamily: 'BrandonGrotesque',
                  fontWeight: FontWeight.bold),
            )),
        actions: [
          IconButton(
            color: Color(0xFF28445C).withOpacity(.40),
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _showSignatureDialog,
          ),
          IconButton(
            icon: Icon(_isPieChart ? Icons.bar_chart : Icons.pie_chart),
            onPressed: _toggleChartType,
            color: Color(0xFF28445C).withOpacity(.40),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _workflows.isEmpty
                  ? Center(child: Text(intl.noWorkflows))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _workflows.length,
                      itemBuilder: (context, index) =>
                          _buildWorkflowCharts(_workflows[index], context),
                    ),
            ),
    );
  }
}

const _dialogShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(20.0)),
);

const _headerStyle = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w600,
  color: Color(0xFF28445C),
  fontFamily: 'BrandonGrotesque',
);

const _inputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)),
  borderSide: BorderSide(color: Color(0xFF78A190)),
);

final _buttonStyle = ElevatedButton.styleFrom(
  backgroundColor: Color(0xFF78A190),
  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);
