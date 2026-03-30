import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/general_provider.dart';
import '../utils/constants.dart';
import 'contribuable_screen.dart';
import 'taxe_screen.dart';
import 'payment_screen.dart';
import 'ticketsScreen.dart';
import 'quartier_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      Provider.of<GeneralProvider>(context, listen: false).fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<GeneralProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Tableau de bord',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppConstants.secondaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              provider.fetchDashboardStats();
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, user),
      body: provider.isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.fetchDashboardStats(),
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenue, ${user?.name ?? 'Utilisateur'}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    SizedBox(height: 25),
                    _buildQuickActions(context),
                    SizedBox(height: 30),
                    Text(
                      'Statistiques Rapides',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    SizedBox(height: 15),
                    _buildStatsGrid(provider),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDrawer(BuildContext context, user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: AppConstants.secondaryColor),
            accountName: Text(user?.name ?? 'Utilisateur'),
            accountEmail: Text(user?.email ?? 'email@mairie.tg'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppConstants.primaryColor,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Tableau de bord'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Contribuables'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ContribuableScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.assignment),
            title: Text('Taxes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => TaxeScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.payment),
            title: Text('Paiements'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => PaymentScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.receipt_long),
            title: Text('Tickets'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ticketsScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.map),
            title: Text('Quartiers'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => QuartierScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _buildActionCard(
          context,
          'Ajouter Contribuable',
          Icons.person_add,
          Colors.blue,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => ContribuableScreen())),
        ),
        _buildActionCard(
          context,
          'Nouvelle Taxe',
          Icons.add_task,
          Colors.orange,
          () => Navigator.push(
              context, MaterialPageRoute(builder: (context) => TaxeScreen())),
        ),
        _buildActionCard(
          context,
          'Nouveau Paiement',
          Icons.account_balance_wallet,
          Colors.green,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => PaymentScreen())),
        ),
        _buildActionCard(
          context,
          'Historique Tickets',
          Icons.receipt_long,
          Colors.purple,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => ticketsScreen())),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(GeneralProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Recouvrement',
          '${provider.tauxRecouvrement}%',
          Icons.trending_up,
          Colors.green,
        ),
        _buildStatCard(
          'Total Payé',
          '${provider.totalPaye.toStringAsFixed(0)} FCFA',
          Icons.attach_money,
          Colors.blue,
        ),
        _buildStatCard(
          'Agents Actifs',
          '${provider.agentsActifs}',
          Icons.groups,
          Colors.orange,
        ),
        _buildStatCard(
          'Tickets émis',
          '${provider.totalTickets}',
          Icons.confirmation_number,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}