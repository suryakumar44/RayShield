import 'dart:typed_data';
import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  // JosKart Theme Palette
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color.fromARGB(255, 40, 255, 223);
  static const Color fieldColor = Color(0xFF0D0D0D);

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController imageController = TextEditingController(); // kept for your reference
  final TextEditingController descController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Web Image Variables
  PlatformFile? _pickedFile;
  Uint8List? _webImage;

  // Dropdown Selection Variables
  String? _selectedCategory;
  String? _selectedHeat;
  String? _selectedSkintype;
  String? _selectedLevel;

  // Data Lists
  List<Map<String, dynamic>> _Category = [];
  List<Map<String, dynamic>> _HeatAbsourption = [];
  List<Map<String, dynamic>> _skintype = [];
  List<Map<String, dynamic>> _level = [];
  List<Map<String, dynamic>> _products = []; // Added to show in table

  @override
  void initState() {
    super.initState();
    fetchCategory();
    fetchSkinType();
    fetchHeatAbsourption();
    fetchLevel();
    fetchProducts(); // Added to refresh table
  }

  // --- Image Picker Logic ---
 Future<void> _pickImage() async {
    try {
      // Use FilePicker.platform instead of FilePicker
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // This is mandatory for Web
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
          _webImage = _pickedFile!.bytes;
        });
      }
    } catch (e) {
      debugPrint("Picker Error: $e");
    }
  }
  // --- Fetch Functions ---
  Future<void> fetchCategory() async {
    try {
      final response = await supabase.from('tbl_category').select();
      setState(() => _Category = response);
    } catch (e) {
      debugPrint("Category Fetch Error: $e");
    }
  }

  Future<void> fetchSkinType() async {
    try {
      final response = await supabase.from('tbl_type').select();
      setState(() => _skintype = response);
    } catch (e) {
      debugPrint("Skin Fetch Error: $e");
    }
  }

  Future<void> fetchHeatAbsourption() async {
    try {
      final response = await supabase.from('tbl_heatabsourption').select();
      setState(() => _HeatAbsourption = response);
    } catch (e) {
      debugPrint("Heat Absorption Fetch Error: $e");
    }
  }

  Future<void> fetchLevel() async {
    try {
      final response = await supabase.from('tbl_level').select();
      setState(() => _level = response);
    } catch (e) {
      debugPrint("Level Fetch Error: $e");
    }
  }

  Future<void> fetchProducts() async {
    try {
      final response = await supabase.from('tbl_product').select();
      setState(() => _products = response);
    } catch (e) {
      debugPrint("Product Fetch Error: $e");
    }
  }

  // --- Insert Logic ---
  Future<void> insert() async {
    try {
      if (_webImage == null) {
        _showSnackBar('Please select an image');
        return;
      }

      // 1. Upload Image to Storage
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.name}';
      await supabase.storage.from('product').uploadBinary(
            'product_photos/$fileName',
            _webImage!,
          );
      final String publicUrl = supabase.storage.from('product').getPublicUrl('product_photos/$fileName');

      // 2. Insert into DB
      await supabase.from('tbl_product').insert({
        'product_name': nameController.text,
        'product_description': descController.text,
        'product_price': priceController.text,
        'product_photo': publicUrl,
        'level_id': _selectedLevel,
        'heatabsourption_id': _selectedHeat,
        'type_id':_selectedSkintype,
        'category_id': _selectedCategory,
      });

      _showSnackBar('Product Added Successfully');
      clearData();
      fetchProducts();
    } catch (e) {
      debugPrint("Error $e");
      _showSnackBar('Error adding product');
    }
  }

  void clearData() {
    setState(() {
      nameController.clear();
      descController.clear();
      priceController.clear();
      _pickedFile = null;
      _webImage = null;
      _selectedCategory = null;
      _selectedHeat = null;
      _selectedSkintype = null;
      _selectedLevel = null;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: accentColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1250),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildInputForm(),
                  const SizedBox(height: 40),
                  const Text(
                    "Product Inventory",
                    style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _buildDataTable(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Product Management",
          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        ),
        Text(
          "Add and manage items in the JosKart catalog",
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildInputForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Picker Section
          Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    color: fieldColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _webImage == null ? Colors.white10 : accentColor),
                  ),
                  child: _webImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: Colors.white38, size: 40),
                            SizedBox(height: 10),
                            Text("Pick Image", style: TextStyle(color: Colors.white38)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.memory(_webImage!, fit: BoxFit.cover),
                        ),
                ),
              ),
              if (_webImage != null)
                TextButton(onPressed: _pickImage, child: const Text("Change Photo", style: TextStyle(color: accentColor))),
            ],
          ),
          const SizedBox(width: 30),
          // Fields Section
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildTextField(nameController, "Product Name", Icons.shopping_bag_outlined)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildTextField(priceController, "Price", Icons.payments_outlined, isNumber: true)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildDropdown("Category", _selectedCategory, _Category, 'category_id', 'category_name', (v) => setState(() => _selectedCategory = v))),
                    const SizedBox(width: 20),
                    Expanded(child: _buildDropdown("Skin Type", _selectedSkintype, _skintype, 'type_id', 'type_name', (v) => setState(() => _selectedSkintype = v))),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildDropdown("Heat Absorption", _selectedHeat, _HeatAbsourption, 'heatabsourption_id', 'heatabsourption_name', (v) => setState(() => _selectedHeat = v))),
                    const SizedBox(width: 20),
                    Expanded(child: _buildDropdown("Level", _selectedLevel, _level, 'level_id', 'level_name', (v) => setState(() => _selectedLevel = v))),
                  ],
                ),
                const SizedBox(height: 30),
                _buildTextField(descController, "Description", Icons.description_outlined, maxLines: 2),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: clearData, child: const Text("CLEAR ALL", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: insert,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("SAVE PRODUCT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: accentColor, size: 20),
        filled: true,
        fillColor: fieldColor,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: accentColor, width: 1)),
      ),
    );
  }

  Widget _buildDropdown(String hint, String? value, List<Map<String, dynamic>> items, String idKey, String nameKey, Function(String?) onChanged) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: fieldColor, borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.white38, fontSize: 14)),
          dropdownColor: cardColor,
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: accentColor,
          isExpanded: true,
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem(value: item[idKey].toString(), child: Text(item[nameKey].toString()));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.white10),
        child: DataTable(
          dataRowMaxHeight: 80,
          columns: const [
            DataColumn(label: Text("SL NO", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("NAME", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("PHOTO", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("PRICE", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("ACTION", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
          ],
          rows: _products.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final product = entry.value;
            return DataRow(cells: [
              DataCell(Text("$index", style: const TextStyle(color: Colors.white70))),
              DataCell(Text(product['product_name'] ?? "", style: const TextStyle(color: Colors.white))),
              DataCell(ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(product['product_photo'] ?? "", width: 40, height: 40, fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white24)),
              )),
              DataCell(Text("₹${product['product_price']}", style: const TextStyle(color: Colors.white70))),
              DataCell(Row(
                children: [
                  IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), 
                    onPressed: () async {
                      await supabase.from('tbl_product').delete().eq('product_id', product['product_id']);
                      fetchProducts();
                    }),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}