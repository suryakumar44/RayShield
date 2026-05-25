import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DermaList extends StatefulWidget {
  const DermaList({super.key});

  @override
  State<DermaList> createState() => _DermaListState();
}

class _DermaListState extends State<DermaList> {
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color.fromARGB(255, 27, 233, 192);

  List<Map<String, dynamic>> _dermatologists = [];
  bool _isLoading = true;
  
  get proofUrl => null;

  @override
  void initState() {
    super.initState();
    fetchDermatologists();
  }

  Future<void> fetchDermatologists() async {
    try {
      final response = await supabase.from('tbl_dermatologist').select();
      setState(() {
        _dermatologists = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> updateStatus(dynamic id, String status) async {
    await supabase
        .from('tbl_dermatologist')
        .update({'dermatologist_status': status})
        .eq('dermatologist_id', id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked as ${status.toUpperCase()}'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    }
    fetchDermatologists();
  }

  @override
  Widget build(BuildContext context) {
    final pendingList = _dermatologists
        .where(
          (d) =>
              d['dermatologist_status'] == null ||
              d['dermatologist_status'] == 'pending',
        )
        .toList();
    final approvedList = _dermatologists
        .where((d) => d['dermatologist_status'] == 'approved')
        .toList();
    final rejectedList = _dermatologists
        .where((d) => d['dermatologist_status'] == 'rejected')
        .toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(50, 50, 50, 0),
              child: _buildHeader(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: TabBar(
                isScrollable: true,
                indicatorColor: accentColor,
                labelColor: accentColor,
                unselectedLabelColor: Colors.white38,
                tabs: const [
                  Tab(text: "PENDING"),
                  Tab(text: "APPROVED"),
                  Tab(text: "REJECTED"),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: accentColor),
                    )
                  : TabBarView(
                      children: [
                        _buildTableContainer(pendingList, "pending"),
                        _buildTableContainer(approvedList, "approved"),
                        _buildTableContainer(rejectedList, "rejected"),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableContainer(List<Map<String, dynamic>> data, String type) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          "No $type records.",
          style: const TextStyle(color: Colors.white24),
        ),
      );
    }
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(50),
        child: _buildDataTable(data),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 15),
        const Text(
          "Dermatologist Directory",
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      // Launch URL in external browser which handles automatic asset downloading
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not open file link: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildDataTable(List<Map<String, dynamic>> list) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Colors.white.withOpacity(0.03),
          ),
          dataRowMaxHeight: 70,
          columns: const [
            DataColumn(
              label: Text(
                "SL.NO",
                style: TextStyle(color: accentColor, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                "PHOTO",
                style: TextStyle(color: accentColor, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                "NAME",
                style: TextStyle(color: accentColor, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                "EMAIL",
                style: TextStyle(color: accentColor, fontSize: 12),
              ),
            ), // New Column
            DataColumn(
              label: Text(
                "EXPERIENCE",
                style: TextStyle(color: accentColor, fontSize: 12),
              ),
            ), // New Column
            DataColumn(
              label: Text(
                "SPECIALIZATION",
                style: TextStyle(color: accentColor, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                "PROOF",
                style: TextStyle(color: accentColor, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                "ACTIONS",
                style: TextStyle(color: accentColor, fontSize: 12),
              ),
            ),
          ],
          rows: list.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final derma = entry.value;
            final currentStatus = derma['dermatologist_status'];  
            final bool hasProof = proofUrl != null && proofUrl.isNotEmpty;

            return DataRow(
              cells: [
                DataCell(
                  Text("$index", style: const TextStyle(color: Colors.white54)),
                ),
                DataCell(
                  CircleAvatar(
                    backgroundImage:
                        (derma['dermatologist_photo'] != null &&
                            derma['dermatologist_photo'] != '')
                        ? NetworkImage(derma['dermatologist_photo'])
                        : null,
                  ),
                ),
                DataCell(
                  Text(
                    derma['dermatologist_name'] ?? 'N/A',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                // New Data Cell: Email
                DataCell(
                  Text(
                    derma['dermatologist_email'] ?? 'N/A',
                    style: const TextStyle(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // New Data Cell: Experience
                DataCell(
                  Text(
                    "${derma['dermatologist_experience'] ?? '0'} Years",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                DataCell(
                  Text(
                    derma['dermatologist_specialization'] ?? 'N/A',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
               DataCell(
  // 1. Access the URL directly from the current 'derma' row map
  (derma['dermatologist_proof'] != null && derma['dermatologist_proof'].toString().isNotEmpty)
      ? InkWell(
          onTap: () => _launchURL(derma['dermatologist_proof']), // Launch the specific URL
          borderRadius: BorderRadius.circular(4),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download, size: 16, color: Colors.blueAccent),
                SizedBox(width: 6),
                Text(
                  "View Document",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        )
      : const Text("No Document", style: TextStyle(color: Colors.white24)),
),
                DataCell(
                  Row(
                    children: [
                      if (currentStatus != 'approved')
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.greenAccent,
                            size: 20,
                          ),
                          onPressed: () => updateStatus(
                            derma['dermatologist_id'],
                            'approved',
                          ),
                        ),
                      if (currentStatus != 'rejected')
                        IconButton(
                          icon: const Icon(
                            Icons.highlight_off,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: () => updateStatus(
                            derma['dermatologist_id'],
                            'rejected',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
