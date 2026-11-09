import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const ArkCalculatorApp());
}

// --- DATENMODELL ---
class CraftingItem {
  final String name;
  final String category;
  final Map<String, int> baseRecipe; // Rohstoff -> Menge für 1 Stück (Primitive)

  CraftingItem({
    required this.name,
    required this.category,
    required this.baseRecipe,
  });
}

// --- VORGEFERTIGTE ASA-DATENBANK ---
final List<CraftingItem> arkDatabase = [
  CraftingItem(
    name: 'Deinotherium Saddle',
    category: 'Sättel',
    baseRecipe: {'Metal Ingot': 450, 'Hide': 250, 'Cementing Paste': 120, 'Fiber': 200},
  ),
  CraftingItem(
    name: 'Rex Saddle',
    category: 'Sättel',
    baseRecipe: {'Metal Ingot': 350, 'Hide': 180, 'Cementing Paste': 80, 'Fiber': 150},
  ),
  CraftingItem(
    name: 'Heavy Auto Turret',
    category: 'Strukturen',
    baseRecipe: {'Metal Ingot': 500, 'Polymer': 150, 'Electronics': 100, 'Cementing Paste': 100},
  ),
  CraftingItem(
    name: 'Metal Wall',
    category: 'Strukturen',
    baseRecipe: {'Metal Ingot': 25},
  ),
  CraftingItem(
    name: 'Advanced Rifle Ammo',
    category: 'Munition',
    baseRecipe: {'Metal Ingot': 2, 'Gunpowder': 6},
  ),
  CraftingItem(
    name: 'Industrial Forge',
    category: 'Strukturen',
    baseRecipe: {'Metal Ingot': 2500, 'Polymer': 600, 'Crystal': 400, 'Oil': 400},
  ),
];

class ArkCalculatorApp extends StatelessWidget {
  const ArkCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARK ASA Crafting Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF00FFCC),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FFCC),
          secondary: Color(0xFF00FFCC),
          surface: Color(0xFF1E1E1E),
        ),
        fontFamily: 'Roboto',
      ),
      home: const CalculatorHomePage(),
    );
  }
}

class CalculatorHomePage extends StatefulWidget {
  const CalculatorHomePage({super.key});

  @override
  State<CalculatorHomePage> createState() => _CalculatorHomePageState();
}

class _CalculatorHomePageState extends State<CalculatorHomePage> {
  // Auswahl- und Eingabefelder
  CraftingItem? selectedItem;
  int quantity = 1;
  double qualityMultiplier = 1.0; // 1.0 = Primitive, 2.5 = Ascendant etc.
  String selectedCategory = 'Alle';

  final TextEditingController qtyController = TextEditingController(text: '1');
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void dispose() {
    qtyController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // Berechnet die Gesamtrohstoffe inkl. Stückzahl und Qualitätsfaktor
  Map<String, int> calculateTotalResources() {
    if (selectedItem == null) return {};
    Map<String, int> totals = {};

    selectedItem!.baseRecipe.forEach((resource, baseAmount) {
      int calculated = (baseAmount * quantity * qualityMultiplier).round();
      totals[resource] = calculated;
    });

    return totals;
  }

  // Generiert einen Text für den Discord- / Tribe-Chat
  String generateShareText(Map<String, int> totals) {
    if (selectedItem == null) return '';
    String text = '🛠️ **Crafting-Bedarf: $quantity.x ${selectedItem!.name}** (Faktor: ${qualityMultiplier.toStringAsFixed(1)}x)\n';
    totals.forEach((res, amount) {
      text += '- $res: **$amount**\n';
    });
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['Alle', 'Sättel', 'Strukturen', 'Munition'];
    
    // Gefilterte Item-Liste nach Suche & Kategorie
    final filteredItems = arkDatabase.where((item) {
      final matchesCategory = selectedCategory == 'Alle' || item.category == selectedCategory;
      final matchesSearch = item.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    final totals = calculateTotalResources();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ARK ASA Resource Calculator', style: TextStyle(color: Color(0xFF00FFCC), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SUCHLEISTE ---
            TextField(
              controller: searchController,
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Item suchen (z.B. Deinotherium)...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00FFCC)),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // --- KATEGORIEN-FILTER ---
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: categories.map((cat) {
                  bool isSelected = selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: const Color(0xFF00FFCC),
                      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                      backgroundColor: const Color(0xFF1E1E1E),
                      onSelected: (bool selected) {
                        setState(() => selectedCategory = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // --- ITEM-AUSWAHL DROPDOWN ---
            DropdownButtonFormField<CraftingItem>(
              value: selectedItem,
              hint: const Text('Wähle ein Item aus...'),
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1E1E),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              items: filteredItems.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text('${item.name} (${item.category})', style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (CraftingItem? newItem) {
                setState(() => selectedItem = newItem);
              },
            ),
            const SizedBox(height: 12),

            // --- MENGE & QUALITÄT ---
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stückzahl',
                      filled: true,
                      fillColor: Color(0xFF1E1E1E),
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                    onChanged: (val) {
                      setState(() {
                        quantity = int.tryParse(val) ?? 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Blueprint Qualität: ${qualityMultiplier.toStringAsFixed(1)}x', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Slider(
                        value: qualityMultiplier,
                        min: 1.0,
                        max: 5.0,
                        divisions: 40,
                        activeColor: const Color(0xFF00FFCC),
                        onChanged: (val) {
                          setState(() => qualityMultiplier = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30, color: Colors.grey),

            // --- ERGEBNIS / EINKAUFSLISTE ---
            const Text('Einkaufsliste (Gesamtbedarf):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00FFCC))),
            const SizedBox(height: 8),
            
            Expanded(
              child: selectedItem == null
                  ? const Center(child: Text('Bitte wähle oben ein Item aus.', style: TextStyle(color: Colors.grey)))
                  : ListView(
                      children: totals.entries.map((entry) {
                        return Card(
                          color: const Color(0xFF1E1E1E),
                          child: ListTile(
                            title: Text(entry.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            trailing: Text('${entry.value}', style: const TextStyle(color: Color(0xFF00FFCC), fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        );
                      }).toList(),
                    ),
            ),

            // --- KOPIEREN-BUTTON ---
            if (selectedItem != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFCC),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.copy),
                  label: const Text('Liste für Discord kopieren', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final text = generateShareText(totals);
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('In die Zwischenablage kopiert!')),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
