import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/general_provider.dart';
import '../providers/auth_provider.dart';
import '../models/contribuable.dart';
import '../models/others.dart';
import '../utils/constants.dart';

class ContribuableScreen extends StatefulWidget {
  @override
  _ContribuableScreenState createState() => _ContribuableScreenState();
}

class _ContribuableScreenState extends State<ContribuableScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final general = Provider.of<GeneralProvider>(context, listen: false);
      general.fetchContribuables();
      general.fetchCommunes();
    });
  }

  void _showAddDialog({Contribuable? contribuable}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddContribuableForm(contribuable: contribuable),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GeneralProvider>(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text('Gestion des Contribuables'),
        backgroundColor: AppConstants.secondaryColor,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading && provider.contribuables.isEmpty
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.fetchContribuables(),
              child: ListView.builder(
                padding: EdgeInsets.all(15),
                itemCount: provider.contribuables.length,
                itemBuilder: (context, index) {
                  final item = provider.contribuables[index];
                  return _buildContribuableCard(item);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppConstants.primaryColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContribuableCard(Contribuable item) {
    return Card(
      margin: EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: EdgeInsets.all(15),
        title: Text(
          item.nom,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: AppConstants.textSecondary),
                SizedBox(width: 5),
                Text(item.telephone),
              ],
            ),
            SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.fingerprint, size: 14, color: AppConstants.textSecondary),
                SizedBox(width: 5),
                Text(item.numeroIdentifiant ?? 'N/A'),
              ],
            ),
            if (item.communeName != null)
              Text(
                'Commune: ${item.communeName}',
                style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.w600),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.type,
                style: TextStyle(color: AppConstants.primaryColor, fontSize: 12),
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: AppConstants.primaryColor),
              onPressed: () => _showAddDialog(contribuable: item),
            ),
          ],
        ),
      ),
    );
  }
}

class AddContribuableForm extends StatefulWidget {
  final Contribuable? contribuable;

  AddContribuableForm({this.contribuable});

  @override
  _AddContribuableFormState createState() => _AddContribuableFormState();
}

class _AddContribuableFormState extends State<AddContribuableForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _telController;
  late TextEditingController _idController;
  late TextEditingController _adresseController;
  
  int? _selectedCommune;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.contribuable?.nom ?? '');
    _telController = TextEditingController(text: widget.contribuable?.telephone ?? '');
    _idController = TextEditingController(text: widget.contribuable?.numeroIdentifiant ?? '');
    _adresseController = TextEditingController(text: widget.contribuable?.adresse ?? '');
    _selectedCommune = widget.contribuable?.communeId;
    
    // Normaliser le type pour le dropdown (casse minuscule pour correspondre à la DB)
    String type = widget.contribuable?.type.toLowerCase() ?? 'particulier';
    if (!['particulier', 'entreprise', 'marchand'].contains(type)) {
      type = 'particulier';
    }
    _selectedType = type;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _telController.dispose();
    _idController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GeneralProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajouter un contribuable',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<int>(
                value: _selectedCommune,
                decoration: InputDecoration(
                  labelText: 'Commune',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                isExpanded: true,
                items: provider.communes.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.nom, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (val) {
                  print('Commune sélectionnée: $val');
                  setState(() => _selectedCommune = val);
                },
                validator: (val) => val == null ? 'Champ obligatoire' : null,
              ),
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(labelText: 'Nom Complet'),
                validator: (val) => val!.isEmpty ? 'Champ obligatoire' : null,
              ),
              TextFormField(
                controller: _telController,
                decoration: InputDecoration(labelText: 'Téléphone'),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? 'Champ obligatoire' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(labelText: 'Type'),
                items: [
                  DropdownMenuItem(value: 'particulier', child: Text('Particulier')),
                  DropdownMenuItem(value: 'entreprise', child: Text('Entreprise')),
                  DropdownMenuItem(value: 'marchand', child: Text('Marchand')),
                ],
                onChanged: (val) => setState(() => _selectedType = val),
              ),
              TextFormField(
                controller: _idController,
                decoration: InputDecoration(labelText: 'Numéro Identifiant (Optionnel)'),
              ),
              TextFormField(
                controller: _adresseController,
                decoration: InputDecoration(labelText: 'Adresse (Optionnel)'),
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      final contrib = Contribuable(
                        id: widget.contribuable?.id,
                        agentId: widget.contribuable?.agentId ?? auth.user?.id,
                        communeId: _selectedCommune!,
                        nom: _nomController.text,
                        telephone: _telController.text,
                        type: _selectedType!,
                        numeroIdentifiant: _idController.text.isEmpty ? null : _idController.text,
                        adresse: _adresseController.text.isEmpty ? null : _adresseController.text,
                      );

                      bool success;
                      if (widget.contribuable == null) {
                        success = await provider.createContribuable(contrib, agentId: auth.user?.id);
                      } else {
                        success = await provider.updateContribuable(contrib);
                      }

                      if (success) {
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(provider.error ?? 'Erreur lors de l\'enregistrement')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
                  child: provider.isLoading 
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(widget.contribuable == null ? 'Enregistrer' : 'Mettre à jour', 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
