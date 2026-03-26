import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/general_provider.dart';
import '../utils/constants.dart';

class ticketsScreen extends StatefulWidget {
  @override
  State<ticketsScreen> createState() => _ticketsScreenState();
}

class _ticketsScreenState extends State<ticketsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = Provider.of<GeneralProvider>(context, listen: false);
      provider.fetchTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GeneralProvider>(context);
    final formatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text("Historique Tickets"),
        backgroundColor: AppConstants.secondaryColor,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading
          ? Center(child: CircularProgressIndicator())
          : provider.tickets.isEmpty
              ? Center(child: Text("Aucun ticket trouvé"))
              : ListView.builder(
                  padding: EdgeInsets.all(15),
                  itemCount: provider.tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = provider.tickets[index];

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text("Ticket #${ticket.id}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Contribuable: ${ticket.contribuableNom ?? 'N/A'}"),
                            Text("Taxe: ${ticket.taxeNom ?? 'N/A'}"),
                            Text("Expiration: ${formatter.format(ticket.dateExpiration)}"),
                          ],
                        ),
                        trailing: Text(
                          ticket.statut.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}