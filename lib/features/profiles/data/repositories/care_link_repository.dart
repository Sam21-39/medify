import 'package:medify/core/database/objectbox_service.dart';
import 'package:medify/features/profiles/data/models/care_link_model.dart';
import 'package:medify/objectbox.g.dart';

class CareLinkRepository {
  CareLinkRepository(this._store);

  final ObjectBoxService _store;

  bool canActFor({required int caregiverId, required int patientId}) {
    if (caregiverId == patientId) return true;
    final query = _store.store
        .box<CareLinkModel>()
        .query(
          CareLinkModel_.caregiverProfileId.equals(caregiverId) &
              CareLinkModel_.patientProfileId.equals(patientId),
        )
        .build();
    final found = query.findFirst() != null;
    query.close();
    return found;
  }

  void link({required int caregiverId, required int patientId}) {
    if (canActFor(caregiverId: caregiverId, patientId: patientId)) return;
    _store.store.box<CareLinkModel>().put(
      CareLinkModel(
        caregiverProfileId: caregiverId,
        patientProfileId: patientId,
      ),
    );
  }
}
