import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await DatabaseHelper.instance.database;
  runApp(FinanceApp());
}

class FinanceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: ChatFinancePage(),
    );
  }
}

class ChatFinancePage extends StatefulWidget {
  @override
  _ChatFinancePageState createState() => _ChatFinancePageState();
}

class _ChatFinancePageState extends State<ChatFinancePage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  int balanceCash = 0;
  int balanceAtm = 0;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _recalcBalances();
  }

  Future<void> _loadMessages() async {
    final rows = await DatabaseHelper.instance.getAllMessages();
    setState(() {
      messages = rows;
    });
  }

  Future<void> _recalcBalances() async {
    final res = await DatabaseHelper.instance.getBalances();
    setState(() {
      balanceCash = res['cash'] ?? 0;
      balanceAtm = res['atm'] ?? 0;
    });
  }

  String _formatRupiah(int v){
    final f = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return f.format(v);
  }

  Future<void> _handleSend(String text) async {
    text = text.trim().toLowerCase();
    if (text.isEmpty) return;
    final time = DateTime.now().toIso8601String();
    String display = text;

    final masukKeluar = RegExp(r'^(masuk|keluar)\s+(\d+)\s+(cash|atm)\$');
    final saldoCmd = RegExp(r'^saldo\$');

    if (masukKeluar.hasMatch(text)) {
      final m = masukKeluar.firstMatch(text)!;
      final type = m.group(1)!; // masuk/keluar
      final amount = int.parse(m.group(2)!);
      final account = m.group(3)!; // cash/atm
      await DatabaseHelper.instance.insertMessage({
        'type': type,
        'amount': amount,
        'account': account,
        'text': text,
        'time': time
      });
      display = text;
      await _loadMessages();
      await _recalcBalances();
    } else if (saldoCmd.hasMatch(text)) {
      final total = balanceCash + balanceAtm;
      final reply = 'Saldo — Cash: ' + _formatRupiah(balanceCash) + ', ATM: ' + _formatRupiah(balanceAtm) + ', Total: ' + _formatRupiah(total);
      await DatabaseHelper.instance.insertMessage({
        'type': 'info',
        'amount': 0,
        'account': 'none',
        'text': reply,
        'time': time
      });
      await _loadMessages();
    } else {
      // Unknown command: store as note
      await DatabaseHelper.instance.insertMessage({
        'type': 'note',
        'amount': 0,
        'account': 'none',
        'text': text,
        'time': time
      });
      await _loadMessages();
    }
    _controller.clear();
    setState((){});
  }

  Widget _buildPinnedBalances(){
    final total = balanceCash + balanceAtm;
    return Container(
      padding: EdgeInsets.symmetric(vertical:12, horizontal:16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _balanceCard('Cash', balanceCash),
          _balanceCard('ATM', balanceAtm),
          _balanceCard('Total', total),
        ],
      ),
    );
  }

  Widget _balanceCard(String title, int amount){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize:12, color:Colors.grey[700])),
        SizedBox(height:6),
        Text(_formatRupiah(amount), style: TextStyle(fontSize:16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMessage(Map<String,dynamic> msg){
    final String text = msg['text'] ?? '';
    final String type = msg['type'] ?? 'note';
    final bool isOutgoing = (type=='masuk' || type=='keluar' || type=='note');
    final align = isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isOutgoing ? Colors.green[50] : Colors.grey[200];
    return Container(
      margin: EdgeInsets.symmetric(vertical:6, horizontal:12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width*0.75),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(text, style: TextStyle(fontSize:16)),
          ),
          SizedBox(height:4),
          Text(
            DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(msg['time'])),
            style: TextStyle(fontSize:11, color:Colors.grey[600]),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
        AppBar(
          title: Row(children:[
            Image.asset('assets/icon.png', width:36, height:36),
            SizedBox(width:8),
            Text('Finance')
          ]),
        ),
      body: Column(
        children: [
          _buildPinnedBalances(),
          Divider(height:1),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.only(top:12, bottom:12),
              itemCount: messages.length,
              itemBuilder: (context, index){
                // messages stored oldest -> newest; reverse show newest at bottom
                final msg = messages.reversed.toList()[index];
                return _buildMessage(msg);
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal:8, vertical:6),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ketik perintah, mis: masuk 50000 cash, keluar 20000 atm, saldo',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: EdgeInsets.symmetric(horizontal:16, vertical:12),
                      ),
                      onSubmitted: _handleSend,
                    ),
                  ),
                  SizedBox(width:8),
                  ElevatedButton(
                    onPressed: () => _handleSend(_controller.text),
                    child: Icon(Icons.send),
                    style: ElevatedButton.styleFrom(shape: CircleBorder(), padding: EdgeInsets.all(12)),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

/* Simple local database using sqflite */
class DatabaseHelper {
  static final _dbName = 'finance_db.db';
  static final _dbVersion = 1;
  static final table = 'messages';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database!=null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final docs = await getApplicationDocumentsDirectory();
    final path = join(docs.path, _dbName);
    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT,
        amount INTEGER,
        account TEXT,
        text TEXT,
        time TEXT
      )
    ''');
  }

  Future<int> insertMessage(Map<String, dynamic> row) async {
    final db = await database;
    final id = await db.insert(table, row);
    // adjust balances if needed: for incoming/outgoing we just store and derive balances later
    return id;
  }

  Future<List<Map<String, dynamic>>> getAllMessages() async {
    final db = await database;
    final rows = await db.query(table, orderBy: 'id ASC');
    return rows;
  }

  Future<Map<String,int>> getBalances() async {
    final db = await database;
    final inCash = Sqflite.firstIntValue(await db.rawQuery("SELECT SUM(amount) FROM $table WHERE type='masuk' AND account='cash'")) ?? 0;
    final outCash = Sqflite.firstIntValue(await db.rawQuery("SELECT SUM(amount) FROM $table WHERE type='keluar' AND account='cash'")) ?? 0;
    final inAtm = Sqflite.firstIntValue(await db.rawQuery("SELECT SUM(amount) FROM $table WHERE type='masuk' AND account='atm'")) ?? 0;
    final outAtm = Sqflite.firstIntValue(await db.rawQuery("SELECT SUM(amount) FROM $table WHERE type='keluar' AND account='atm'")) ?? 0;
    return {
      'cash': (inCash - outCash),
      'atm': (inAtm - outAtm),
    };
  }
}
