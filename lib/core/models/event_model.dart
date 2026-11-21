import 'firestore_converters.dart';

/// Lebenszyklus eines Spieltermins (A-06): planned → active → completed.
enum EventStatus {
  planned,
  active,
  completed;

  static EventStatus fromName(String? name) => EventStatus.values.firstWhere(
    (s) => s.name == name,
    orElse: () => EventStatus.planned,
  );

  /// Erlaubt sind nur Schritte vorwärts um genau eine Stufe.
  bool canTransitionTo(EventStatus next) => next.index == index + 1;
}

/// Spieltermin, gespeichert unter `/events/{eventId}`.
class EventModel {
  const EventModel({
    required this.id,
    required this.date,
    required this.hostId,
    required this.hostName,
    required this.address,
    this.status = EventStatus.planned,
    this.createdAt,
    this.votingDeadline,
    this.foodVotingDeadline,
    this.selectedFoodCategory,
  });

  final String id;
  final DateTime date;
  final String hostId;
  final String hostName;

  /// Kopie der Host-Adresse zum Anlegezeitpunkt (A-03).
  final String address;
  final EventStatus status;
  final DateTime? createdAt;

  /// Ende des Spiele-Votings (US-04).
  final DateTime? votingDeadline;

  /// Frist der Essensabstimmung (A-13, US-07, US-08). Standard: 48 h vor
  /// dem Termin. Die Erinnerung (A-14) liegt 24 h davor und wird daraus
  /// berechnet, nicht gespeichert.
  final DateTime? foodVotingDeadline;

  /// Ergebnis des Essens-Votings (A-13).
  final String? selectedFoodCategory;

  factory EventModel.fromMap(String id, Map<String, dynamic> map) {
    return EventModel(
      id: id,
      date:
          dateFromFirestore(map['date']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      hostId: map['hostId'] as String? ?? '',
      hostName: map['hostName'] as String? ?? '',
      address: map['address'] as String? ?? '',
      status: EventStatus.fromName(map['status'] as String?),
      createdAt: dateFromFirestore(map['createdAt']),
      votingDeadline: dateFromFirestore(map['votingDeadline']),
      foodVotingDeadline: dateFromFirestore(map['foodVotingDeadline']),
      selectedFoodCategory: map['selectedFoodCategory'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': dateToFirestore(date),
      'hostId': hostId,
      'hostName': hostName,
      'address': address,
      'status': status.name,
      if (createdAt != null) 'createdAt': dateToFirestore(createdAt),
      if (votingDeadline != null)
        'votingDeadline': dateToFirestore(votingDeadline),
      if (foodVotingDeadline != null)
        'foodVotingDeadline': dateToFirestore(foodVotingDeadline),
      if (selectedFoodCategory != null)
        'selectedFoodCategory': selectedFoodCategory,
    };
  }

  EventModel copyWith({
    DateTime? date,
    String? hostId,
    String? hostName,
    String? address,
    EventStatus? status,
    DateTime? createdAt,
    DateTime? votingDeadline,
    DateTime? foodVotingDeadline,
    String? selectedFoodCategory,
  }) {
    return EventModel(
      id: id,
      date: date ?? this.date,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      address: address ?? this.address,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      votingDeadline: votingDeadline ?? this.votingDeadline,
      foodVotingDeadline: foodVotingDeadline ?? this.foodVotingDeadline,
      selectedFoodCategory: selectedFoodCategory ?? this.selectedFoodCategory,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EventModel &&
      other.id == id &&
      other.date == date &&
      other.hostId == hostId &&
      other.hostName == hostName &&
      other.address == address &&
      other.status == status &&
      other.createdAt == createdAt &&
      other.votingDeadline == votingDeadline &&
      other.foodVotingDeadline == foodVotingDeadline &&
      other.selectedFoodCategory == selectedFoodCategory;

  @override
  int get hashCode => Object.hash(
    id,
    date,
    hostId,
    hostName,
    address,
    status,
    createdAt,
    votingDeadline,
    foodVotingDeadline,
    selectedFoodCategory,
  );
}
