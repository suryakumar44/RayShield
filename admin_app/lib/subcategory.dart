import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class Subcategory extends StatefulWidget {
  const Subcategory({super.key});

  @override
  State<Subcategory> createState() => _SubcategoryState();
}

class _SubcategoryState extends State<Subcategory> {
  TextEditingController subcategoryController = TextEditingController();

  String? _selectedValue;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subcategories = [];

  // Theme Colors
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color.fromARGB(255, 40, 255, 223);

  Future<void> fetchCategories() async {
    final response = await supabase.from('tbl_category').select();
    setState(() {
      _categories = response;
      _selectedValue = _categories.isNotEmpty
          ? _categories.first['category_id'].toString()
          : null;
    });
  }

  Future<void> fetchSubcategories() async {
    final response = await supabase
        .from('tbl_subcategory')
        .select(
          'subcategory_id, subcategory_name, category_id, tbl_category!inner(category_name)',
        );

    setState(() {
      _subcategories = response;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchSubcategories();
  }

  Future<void> insert() async {
    if (subcategoryController.text.isEmpty || _selectedValue == null) return;
    try {
      final subcategory = subcategoryController.text;
      await supabase.from('tbl_subcategory').insert({
        'subcategory_name': subcategory,
        'category_id': int.parse(_selectedValue!),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subcategory Added Successfully'),
            backgroundColor: accentColor,
          ),
        );
      }
      subcategoryController.clear();
      await fetchSubcategories();
    } catch (e) {
      debugPrint("Error $e");
    }
  }

  void showEditDialog(Map<String, dynamic> subcategorydata) {
    TextEditingController editController = TextEditingController(
      text: subcategorydata['subcategory_name'],
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Edit Subcategory',
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
              labelText: 'Subcategory Name',
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
                    .from('tbl_subcategory')
                    .update({'subcategory_name': updatedType})
                    .eq('subcategory_id', subcategorydata['subcategory_id']);

                if (mounted) Navigator.pop(context);
                await fetchSubcategories();
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
          "Manage Subcategories",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // INPUT FORM CARD
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  // Dropdown for Category
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: cardColor,
                        value: _selectedValue,
                        isExpanded: true,
                        hint: const Text(
                          "Select Category",
                          style: TextStyle(color: Colors.white38),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        onChanged: (v) => setState(() => _selectedValue = v),
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['category_id'].toString(),
                            child: Text(category['category_name'].toString()),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Textfield for Subcategory
                  TextFormField(
                    controller: subcategoryController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.3),
                      hintText: "Enter subcategory name",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(
                        Icons.account_tree_outlined,
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
                  const SizedBox(height: 24),
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
                        'SUBMIT SUB-CATEGORY',
                        style: TextStyle(
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
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        Colors.white.withOpacity(0.02),
                      ),
                      columns: const <DataColumn>[
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
                            'CATEGORY',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'SUB-CATEGORY',
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
                      rows: _subcategories.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final subcategory = entry.value;
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
                                subcategory['tbl_category']['category_name'] ??
                                    '',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            DataCell(
                              Text(
                                subcategory['subcategory_name'] ?? '',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        showEditDialog(subcategory),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.blueAccent,
                                      size: 20,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      await supabase
                                          .from('tbl_subcategory')
                                          .delete()
                                          .eq(
                                            'subcategory_id',
                                            subcategory['subcategory_id'],
                                          );
                                      await fetchSubcategories();
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
