import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/medicine_model.dart';
import '../models/medicine_log_model.dart';
import '../../objectbox.g.dart';

/// ObjectBox service for database management
class ObjectBoxService {
  late final Store _store;
  late final Box<MedicineModel> _medicineBox;
  late final Box<MedicineLogModel> _medicineLogBox;

  Store get store => _store;
  Box<MedicineModel> get medicineBox => _medicineBox;
  Box<MedicineLogModel> get medicineLogBox => _medicineLogBox;

  /// Initialize ObjectBox
  Future<void> init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final storePath = p.join(docsDir.path, 'medify-db');

    _store = await openStore(directory: storePath);
    _medicineBox = Box<MedicineModel>(_store);
    _medicineLogBox = Box<MedicineLogModel>(_store);
  }

  /// Close the store
  void close() {
    _store.close();
  }

  /// Clear all data (for testing/debugging)
  Future<void> clearAll() async {
    await _medicineBox.removeAllAsync();
    await _medicineLogBox.removeAllAsync();
  }
}
