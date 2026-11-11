import 'package:flutter_test/flutter_test.dart';
import 'package:medify/features/medicines/domain/entities/medicine.dart';
import 'package:medify/features/medicines/domain/voice/medicine_draft_parser.dart';

void main() {
  group('MedicineDraftParser', () {
    test('parses the A6 fixture fully', () {
      const transcript = 'Paracetamol 500 mg twice a day after food for 5 days';
      final draft = MedicineDraftParser.parse(transcript);

      expect(draft.name, 'Paracetamol');
      expect(draft.dosageAmount, 500);
      expect(draft.unit, 'mg');
      expect(draft.reminderTimes, [8 * 3600, 20 * 3600]);
      expect(draft.intakeTiming, MedicineIntakeTiming.afterFood);
      expect(draft.durationDays, 5);
      expect(draft.notes, transcript);
      expect(draft.medicineType, isNull, reason: 'not stated, never guessed');
    });

    test('parses type, timing before food and digit frequency', () {
      final draft = MedicineDraftParser.parse(
        'Amoxicillin capsule 250 mg 3 times a day before food for 2 weeks',
      );

      expect(draft.name, 'Amoxicillin');
      expect(draft.medicineType, MedicineType.capsule);
      expect(draft.reminderTimes, [8 * 3600, 14 * 3600, 20 * 3600]);
      expect(draft.intakeTiming, MedicineIntakeTiming.beforeFood);
      expect(draft.durationDays, 14);
    });

    test(
      'single daily dose defaults to 08:00 and leaves unstated fields null',
      () {
        final draft = MedicineDraftParser.parse('Vitamin D once a day');

        expect(draft.name, 'Vitamin D');
        expect(draft.dosageAmount, isNull, reason: 'no number, so no dosage');
        expect(draft.reminderTimes, [8 * 3600]);
        expect(draft.intakeTiming, isNull);
        expect(draft.durationDays, isNull);
        expect(draft.medicineType, isNull);
      },
    );

    test('empty or blank transcript yields an empty draft', () {
      for (final input in ['', '   ']) {
        final draft = MedicineDraftParser.parse(input);
        expect(draft.name, isNull);
        expect(draft.dosageAmount, isNull);
        expect(draft.reminderTimes, isNull);
        expect(draft.notes, isNull);
      }
    });

    test('unrecognised frequency stays null', () {
      final draft = MedicineDraftParser.parse('Ibuprofen 200 mg when needed');

      expect(draft.name, 'Ibuprofen');
      expect(draft.dosageAmount, 200);
      expect(draft.reminderTimes, isNull);
    });

    group('dose is never guessed', () {
      test('a number after "for" is not a dose', () {
        final draft = MedicineDraftParser.parse(
          'Paracetamol twice a day for 5 days',
        );

        expect(draft.dosageAmount, isNull);
        expect(draft.unit, isNull);
        expect(draft.durationDays, 5);
        expect(draft.reminderTimes, [8 * 3600, 20 * 3600]);
      });
    });

    group('name', () {
      test('strips leading "I need to take" and "take"', () {
        expect(
          MedicineDraftParser.parse(
            'I need to take Paracetamol 500 mg once daily',
          ).name,
          'Paracetamol',
        );
        expect(
          MedicineDraftParser.parse('Take Paracetamol 500 mg').name,
          'Paracetamol',
        );
        expect(
          MedicineDraftParser.parse('I take Paracetamol 500 mg').name,
          'Paracetamol',
        );
      });

      test('strips leading "add"', () {
        expect(
          MedicineDraftParser.parse('Add Vitamin D every day').name,
          'Vitamin D',
        );
      });

      test('accepts an optional comma before the dose', () {
        final draft = MedicineDraftParser.parse(
          'Paracetamol, 500 mg twice a day',
        );

        expect(draft.name, 'Paracetamol');
        expect(draft.dosageAmount, 500);
      });

      test('keeps digits inside a name and rejects a glued dose', () {
        final draft = MedicineDraftParser.parse(
          'Vitamin D3 1000 IU once daily',
        );

        expect(draft.name, 'Vitamin D3');
        expect(draft.dosageAmount, 1000);
        expect(draft.unit, 'iu');

        final glued = MedicineDraftParser.parse('Vitamin D3 once daily');
        expect(glued.name, 'Vitamin D3');
        expect(glued.dosageAmount, isNull, reason: 'the 3 is part of the name');
      });

      test('keeps unicode letters', () {
        final draft = MedicineDraftParser.parse('Ibuprofène 200 mg once a day');

        expect(draft.name, 'Ibuprofène');
        expect(draft.dosageAmount, 200);
      });

      test('drops a trailing form word', () {
        expect(
          MedicineDraftParser.parse('Take Ibuprofen tablets 400 mg').name,
          'Ibuprofen',
        );
      });

      test('more than three words is unsure, so null', () {
        final draft = MedicineDraftParser.parse(
          'Extra strong cold relief 500 mg',
        );

        expect(draft.name, isNull);
        expect(draft.dosageAmount, isNull);
      });

      test('a leading stopword leaves no name', () {
        final draft = MedicineDraftParser.parse('it after food');

        expect(draft.name, isNull);
      });
    });

    group('units', () {
      test('plural and long forms normalise', () {
        expect(MedicineDraftParser.parse('Paracetamol 5 mgs').unit, 'mg');
        expect(
          MedicineDraftParser.parse('Paracetamol 2 milligrams').unit,
          'mg',
        );
        expect(
          MedicineDraftParser.parse('Amoxicillin 5 milliliters').unit,
          'ml',
        );
        expect(MedicineDraftParser.parse('Amoxicillin 5 mls').unit, 'ml');
      });

      test('decimal dose keeps its value', () {
        final draft = MedicineDraftParser.parse('Paracetamol 2.5 mg');

        expect(draft.dosageAmount, 2.5);
        expect(draft.unit, 'mg');
      });
    });

    group('frequency', () {
      test('daily forms mean once a day', () {
        for (final input in [
          'Vitamin D daily',
          'Vitamin D every day',
          'Vitamin D once daily',
        ]) {
          expect(MedicineDraftParser.parse(input).reminderTimes, [
            8 * 3600,
          ], reason: input);
        }
      });

      test('"twice daily" and "three times daily" count doses', () {
        expect(
          MedicineDraftParser.parse('Vitamin C twice daily').reminderTimes,
          [8 * 3600, 20 * 3600],
        );
        expect(
          MedicineDraftParser.parse('Ibuprofen three times daily')
              .reminderTimes,
          [8 * 3600, 14 * 3600, 20 * 3600],
        );
      });

      test('word numbers for frequency', () {
        expect(
          MedicineDraftParser.parse('Cetirizine 10 mg two times a day')
              .reminderTimes,
          [8 * 3600, 20 * 3600],
        );
        expect(
          MedicineDraftParser.parse('Cetirizine six times a day').reminderTimes,
          hasLength(6),
        );
      });

      test('boundaries: zero and eight or more doses stay null', () {
        for (final input in [
          'Paracetamol 500 mg 0 times a day',
          'Paracetamol 500 mg 7 times a day',
          'Paracetamol 500 mg eight times a day',
          'Paracetamol 500 mg 10 times a day',
        ]) {
          expect(
            MedicineDraftParser.parse(input).reminderTimes,
            isNull,
            reason: input,
          );
        }
      });
    });

    group('duration', () {
      test('word numbers for duration', () {
        expect(
          MedicineDraftParser.parse('Amoxicillin for two weeks').durationDays,
          14,
        );
        expect(
          MedicineDraftParser.parse('Amoxicillin for one week').durationDays,
          7,
        );
      });

      test('zero days stays null', () {
        expect(
          MedicineDraftParser.parse('Amoxicillin for 0 days').durationDays,
          isNull,
        );
      });
    });

    group('intake timing', () {
      test('conflicting timings are ambiguous, so null', () {
        final draft = MedicineDraftParser.parse(
          'Paracetamol 500 mg twice a day after food at bedtime',
        );

        expect(draft.intakeTiming, isNull);
        expect(draft.reminderTimes, [8 * 3600, 20 * 3600]);
      });

      test('a single timing is kept', () {
        expect(
          MedicineDraftParser.parse('Paracetamol 500 mg at bedtime')
              .intakeTiming,
          MedicineIntakeTiming.beforeSleep,
        );
      });
    });
  });
}
