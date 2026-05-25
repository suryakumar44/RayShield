import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class Heatabsourption extends StatefulWidget {
  const Heatabsourption({super.key});

  @override
  State<Heatabsourption> createState() => _HeatabsourptionState();
}

class _HeatabsourptionState extends State<Heatabsourption> {
  TextEditingController heatController = TextEditingController();
  List<Map<String, dynamic>> _heat = [];

  // Theme Palette
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color.fromARGB(255, 40, 255, 223);

  Future<void> fetchheat() async {
    try {
      final response = await supabase.from('tbl_heatabsourption').select();
      setState(() {
        _heat = response;
      });
    } catch (e) {
      debugPrint("Error $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchheat();
  }

  Future<void> insert() async {
    if (heatController.text.isEmpty) return;
    try {
      final heat = heatController.text;
      await supabase.from('tbl_heatabsourption').insert({
        'heatabsourption_name': heat,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Heat Absorption Rate Inserted"),
            backgroundColor: accentColor,
          ),
        );
      }
      heatController.clear();
      await fetchheat();
    } catch (e) {
      debugPrint("Error $e");
    }
  }

  void showEditDialog(Map<String, dynamic> heatData) {
    TextEditingController editController = TextEditingController(
      text: heatData['heatabsourption_name'],
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Edit Heat Absorption',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: editController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: accentColor),
              ),
              labelText: 'Absorption Rate',
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              onPressed: () async {
                final updatedType = editController.text;
                await supabase
                    .from('tbl_heatabsourption')
                    .update({'heatabsourption_name': updatedType})
                    .eq('heatabsourption_id', heatData['heatabsourption_id']);

                if (mounted) Navigator.pop(context);
                await fetchheat();
              },
              child: const Text(
                'Update',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: const Text(
          "Heat Absorption Levels",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // INPUT CARD
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: heatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.3),
                      hintText: "Enter heat absorption rate",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(
                        Icons.thermostat_outlined,
                        color: accentColor,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: accentColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: insert,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'SUBMIT RATE',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // TABLE SECTION
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        Colors.white.withOpacity(0.02),
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'SL.NO',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'ABSORPTION RATE',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'ACTIONS',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      rows: _heat.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final heat = entry.value;
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                index.toString(),
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                            DataCell(
                              Text(
                                heat['heatabsourption_name'] ?? '',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => showEditDialog(heat),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.blueAccent,
                                      size: 20,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      await supabase
                                          .from('tbl_heatabsourption')
                                          .delete()
                                          .eq(
                                            'heatabsourption_id',
                                            heat['heatabsourption_id'],
                                          );
                                      await fetchheat();
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                      size: 20,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
