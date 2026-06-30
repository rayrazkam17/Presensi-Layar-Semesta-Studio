import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/attendance_service.dart';
import 'admin_employee_detail_page.dart';

class AdminEmployeeRecapPage extends StatefulWidget {
  const AdminEmployeeRecapPage({super.key});

  @override
  State<AdminEmployeeRecapPage> createState() =>
      _AdminEmployeeRecapPageState();
}

class _AdminEmployeeRecapPageState
    extends State<AdminEmployeeRecapPage> {
  final AttendanceService attendanceService = AttendanceService();

  final TextEditingController searchController = TextEditingController();

  late Future<List<Map<String, dynamic>>> recapFuture;

  String searchText = '';

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  final List<String> months = const [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  List<int> get years {
    final currentYear = DateTime.now().year;

    return List.generate(
      5,
      (index) => currentYear - 2 + index,
    );
  }

  @override
  void initState() {
    super.initState();

    loadRecap();

    searchController.addListener(() {
      setState(() {
        searchText = searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void loadRecap() {
    recapFuture = attendanceService.getMonthlyEmployeeRecap(
      month: selectedMonth,
      year: selectedYear,
    );
  }

  void refreshData() {
    setState(() {
      loadRecap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthTitle = DateFormat(
      'MMMM yyyy',
      'id_ID',
    ).format(
      DateTime(selectedYear, selectedMonth),
    ).toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Presensi Pegawai'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshData,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: recapFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Gagal memuat rekap:\n${snapshot.error}',
                ),
              ),
            );
          }

          final allData = snapshot.data ?? [];

          final filteredData = allData.where((item) {
            final nama = item['nama']?.toString().toLowerCase() ?? '';

            return nama.contains(searchText);
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              refreshData();
              await recapFuture;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama pegawai',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: selectedMonth,
                        decoration: const InputDecoration(
                          labelText: 'Bulan',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(12, (index) {
                          return DropdownMenuItem<int>(
                            value: index + 1,
                            child: Text(months[index]),
                          );
                        }),
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            selectedMonth = value;
                            loadRecap();
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'Tahun',
                          border: OutlineInputBorder(),
                        ),
                        items: years.map((year) {
                          return DropdownMenuItem<int>(
                            value: year,
                            child: Text('$year'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            selectedYear = value;
                            loadRecap();
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  monthTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                if (filteredData.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        'Belum ada data presensi pada periode ini',
                      ),
                    ),
                  )
                else
                  Card(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  'Nama',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Hadir',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Lembur',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(height: 1),

                        ...filteredData.map((item) {
                          final nama =
                              item['nama']?.toString() ?? 'Pegawai';

                          final hadir = item['hadir'] ?? 0;
                          final lembur = item['lembur'] ?? 0;

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminEmployeeDetailPage(
                                    userId: item['user_id'].toString(),
                                    nama: nama,
                                    role: item['role']?.toString() ?? '-',
                                    month: selectedMonth,
                                    year: selectedYear,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nama,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          item['role']?.toString() ?? '-',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '$hadir Hari',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '$lembur Hari',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}