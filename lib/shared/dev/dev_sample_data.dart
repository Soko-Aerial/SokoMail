// =============================================================================
// DEVELOPMENT FIXTURES ONLY.
//
// Invented sample content used to demonstrate the UI before the SokoMail Go
// API exists. These are NOT real mailboxes, people or messages: names and
// subjects mirror the approved design references, and every address uses
// the reserved example.com domain (RFC 2606).
//
// Only `DevMock*` repositories (through DevMailStore) may use this file, and
// they are only selected when `AppConfig.developmentToolsCompiledIn` is true,
// so the compiler removes this data from release builds.
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:sokomail/shared/models/attachment.dart';
import 'package:sokomail/shared/models/email_address.dart';
import 'package:sokomail/shared/models/mail_folder.dart';

/// A sample message record. Mutable copies live in `DevMailStore`.
@immutable
class DevSampleMessage {
  const DevSampleMessage({
    required this.id,
    required this.mailboxId,
    required this.folder,
    required this.from,
    required this.to,
    required this.subject,
    required this.body,
    required this.sentAt,
    this.cc = const [],
    this.bcc = const [],
    this.isRead = false,
    this.isStarred = false,
    this.attachments = const [],
  });

  final String id;
  final String mailboxId;
  final MailFolder folder;
  final EmailAddress from;
  final List<EmailAddress> to;
  final List<EmailAddress> cc;
  final List<EmailAddress> bcc;
  final String subject;
  final String body;
  final DateTime sentAt;
  final bool isRead;
  final bool isStarred;
  final List<Attachment> attachments;

  DevSampleMessage copyWith({
    MailFolder? folder,
    List<EmailAddress>? to,
    List<EmailAddress>? cc,
    List<EmailAddress>? bcc,
    String? subject,
    String? body,
    DateTime? sentAt,
    bool? isRead,
    bool? isStarred,
    List<Attachment>? attachments,
  }) {
    return DevSampleMessage(
      id: id,
      mailboxId: mailboxId,
      folder: folder ?? this.folder,
      from: from,
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      attachments: attachments ?? this.attachments,
    );
  }
}

/// A sample mailbox record.
@immutable
class DevSampleMailbox {
  const DevSampleMailbox({
    required this.id,
    required this.address,
    required this.displayName,
    required this.isShared,
  });

  final String id;
  final String address;
  final String displayName;
  final bool isShared;

  EmailAddress get emailAddress =>
      EmailAddress(address, displayName: displayName);
}

abstract final class DevSampleData {
  static const personalMailboxId = 'dev-personal';
  static const sharedMailboxId = 'dev-shared';
  static const engineeringMailboxId = 'dev-engineering';
  static const leadershipMailboxId = 'dev-leadership';

  static const mailboxes = <DevSampleMailbox>[
    DevSampleMailbox(
      id: personalMailboxId,
      address: 'dev.employee@example.com',
      displayName: 'Development Employee',
      isShared: false,
    ),
    DevSampleMailbox(
      id: sharedMailboxId,
      address: 'operations@example.com',
      displayName: 'Operations',
      isShared: true,
    ),
    DevSampleMailbox(
      id: engineeringMailboxId,
      address: 'engineering@example.com',
      displayName: 'Engineering',
      isShared: true,
    ),
    DevSampleMailbox(
      id: leadershipMailboxId,
      address: 'leadership@example.com',
      displayName: 'Leadership',
      isShared: true,
    ),
  ];

  static const _me = EmailAddress(
    'dev.employee@example.com',
    displayName: 'Development Employee',
  );
  static const _operations = EmailAddress(
    'operations@example.com',
    displayName: 'Operations',
  );
  static const _engineering = EmailAddress(
    'engineering@example.com',
    displayName: 'Engineering',
  );
  static const _leadership = EmailAddress(
    'leadership@example.com',
    displayName: 'Leadership',
  );
  static const _david = EmailAddress(
    'david.njoroge@example.com',
    displayName: 'David Njoroge',
  );
  static const _regina = EmailAddress(
    'regina.kibwana@example.com',
    displayName: 'Regina Kibwana',
  );
  static const _flightOps = EmailAddress(
    'flight-ops@example.com',
    displayName: 'Operations Team',
  );
  static const _mary = EmailAddress(
    'mary.mwangi@example.com',
    displayName: 'Mary Mwangi',
  );
  static const _security = EmailAddress(
    'security@example.com',
    displayName: 'Security & Compliance',
  );
  static const _elijah = EmailAddress(
    'elijah.kamau@example.com',
    displayName: 'Elijah Kamau',
  );
  static const _hr = EmailAddress('hr@example.com', displayName: 'HR Team');
  static const _pmo = EmailAddress(
    'pmo@example.com',
    displayName: 'Project Management',
  );
  static const _itSupport = EmailAddress(
    'it-support@example.com',
    displayName: 'IT Support',
  );
  static const _procurement = EmailAddress(
    'procurement@example.com',
    displayName: 'Procurement',
  );
  static const _promo = EmailAddress(
    'offers@example.net',
    displayName: 'Prize Notifications',
  );

  static Attachment _file(String id, String name, String mime, double mb) =>
      Attachment(
        id: id,
        fileName: name,
        mimeType: mime,
        sizeBytes: (mb * 1024 * 1024).round(),
      );

  static const _pdf = 'application/pdf';
  static const _xlsx =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  static const _docx =
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

  /// Sample messages, timestamped relative to [now] so lists show realistic
  /// "today / yesterday / weekday" times.
  static List<DevSampleMessage> messages(DateTime now) {
    DateTime ago({int days = 0, int hours = 0, int minutes = 0}) =>
        now.subtract(Duration(days: days, hours: hours, minutes: minutes));

    return [
      // ------------------------------------------------------------ Inbox
      DevSampleMessage(
        id: 'dev-msg-001',
        mailboxId: personalMailboxId,
        folder: MailFolder.inbox,
        from: _david,
        to: const [_operations, _engineering, _leadership],
        subject: 'Drone Field Test – Project Update',
        body:
            'Good morning team,\n\n'
            "I'm pleased to share a brief update on the recent drone field "
            'test conducted at the Kajiado test range yesterday.\n\n'
            'Key outcomes:\n'
            '• Flight stability and control systems performed as expected.\n'
            '• Improved telemetry link with no data loss during the test.\n'
            '• Battery endurance increased by ~12% compared to the previous '
            'build.\n'
            '• No critical issues were recorded.\n\n'
            'The full test report, including flight data and observations, is '
            'attached for your review. Please share any feedback or follow-up '
            'actions by end of week so we can plan the next test cycle.\n\n'
            'Regards,\nDavid Njoroge\nOperations Lead\nSokoAerial Robotics',
        sentAt: ago(minutes: 25),
        attachments: [
          _file('dev-att-001', 'Field_Test_Report.pdf', _pdf, 2.8),
          _file('dev-att-002', 'Flight_Data_Summary.xlsx', _xlsx, 1.1),
        ],
      ),
      DevSampleMessage(
        id: 'dev-msg-002',
        mailboxId: personalMailboxId,
        folder: MailFolder.inbox,
        from: _regina,
        to: const [_engineering],
        cc: const [_me],
        subject: 'Engineering Sync – This Friday',
        body:
            'Please find the agenda for our engineering sync on Friday at '
            '14:00.\n\n'
            'Agenda:\n'
            '• Autonomy stack review\n'
            '• Telemetry link improvements\n'
            '• Hardware procurement status\n\n'
            'Add any topics before Thursday.\n\n'
            'Regina',
        sentAt: ago(hours: 1, minutes: 10),
      ),
      DevSampleMessage(
        id: 'dev-msg-003',
        mailboxId: personalMailboxId,
        folder: MailFolder.inbox,
        from: _flightOps,
        to: const [_operations],
        cc: const [_me],
        subject: 'Flight Schedule – Next Week',
        body:
            'The flight schedule for next week has been finalised. Crews are '
            'assigned to the morning windows; afternoon slots remain '
            'available for re-tests.',
        sentAt: ago(hours: 2, minutes: 40),
      ),
      DevSampleMessage(
        id: 'dev-msg-004',
        mailboxId: personalMailboxId,
        folder: MailFolder.inbox,
        from: _mary,
        to: const [_me],
        subject: 'Supplier Delivery Update',
        body:
            'We have a confirmation from our supplier that the rotor '
            'assemblies will arrive on Wednesday. The delivery schedule is '
            'attached.',
        sentAt: ago(days: 1, hours: 1),
        isRead: true,
        isStarred: true,
        attachments: [_file('dev-att-003', 'Delivery_Schedule.pdf', _pdf, 0.4)],
      ),
      DevSampleMessage(
        id: 'dev-msg-005',
        mailboxId: personalMailboxId,
        folder: MailFolder.inbox,
        from: _security,
        to: const [_me],
        subject: 'Policy Reminder: Data Handling',
        body:
            'A quick reminder on our data handling policy: flight logs and '
            'customer imagery must stay on approved company storage.',
        sentAt: ago(days: 1, hours: 4),
        isRead: true,
      ),
      DevSampleMessage(
        id: 'dev-msg-006',
        mailboxId: personalMailboxId,
        folder: MailFolder.inbox,
        from: _elijah,
        to: const [_me],
        subject: 'UAV Integration – Review Notes',
        body:
            "Here are the review notes from today's UAV integration session. "
            'Two follow-up items are assigned to the avionics team.',
        sentAt: ago(days: 3),
        isRead: true,
        attachments: [
          _file('dev-att-004', 'Integration_Review_Notes.docx', _docx, 0.2),
        ],
      ),
      DevSampleMessage(
        id: 'dev-msg-007',
        mailboxId: personalMailboxId,
        folder: MailFolder.inbox,
        from: _hr,
        to: const [_me],
        subject: 'Monthly Team Briefing',
        body:
            'Please join the monthly team briefing on Friday at 09:00 in the '
            'main hangar.',
        sentAt: ago(days: 4),
        isRead: true,
      ),
      DevSampleMessage(
        id: 'dev-msg-008',
        mailboxId: personalMailboxId,
        folder: MailFolder.inbox,
        from: _pmo,
        to: const [_me],
        subject: 'Q1 Milestones – Status Report',
        body: 'Attached is the latest Q1 milestones report for your review.',
        sentAt: ago(days: 5),
        isRead: true,
        attachments: [_file('dev-att-005', 'Q1_Status_Report.pdf', _pdf, 1.6)],
      ),
      DevSampleMessage(
        id: 'dev-msg-009',
        mailboxId: personalMailboxId,
        folder: MailFolder.inbox,
        from: _itSupport,
        to: const [_me],
        subject: 'Scheduled maintenance this weekend',
        body:
            'Internal systems will be unavailable on Saturday from 22:00 to '
            '02:00 while network equipment is upgraded.',
        sentAt: ago(days: 9),
        isRead: true,
      ),
      DevSampleMessage(
        id: 'dev-msg-010',
        mailboxId: personalMailboxId,
        folder: MailFolder.inbox,
        from: _procurement,
        to: const [_me],
        subject: 'Battery supplier quote received',
        body:
            'The quote for the next batch of flight batteries has arrived. '
            'Please confirm the quantities by the end of the month.',
        sentAt: ago(days: 12),
        isRead: true,
        isStarred: true,
        attachments: [_file('dev-att-006', 'Battery_Quote.pdf', _pdf, 0.8)],
      ),
      // ------------------------------------------------------------- Sent
      DevSampleMessage(
        id: 'dev-msg-101',
        mailboxId: personalMailboxId,
        folder: MailFolder.sent,
        from: _me,
        to: const [_david],
        subject: 'Re: Drone Field Test – Project Update',
        body: 'Thanks David, I will review the report before Friday.',
        sentAt: ago(minutes: 10),
        isRead: true,
      ),
      DevSampleMessage(
        id: 'dev-msg-102',
        mailboxId: personalMailboxId,
        folder: MailFolder.sent,
        from: _me,
        to: const [_procurement],
        bcc: const [_operations],
        subject: 'Purchase request: telemetry modules',
        body: 'Please raise a purchase order for six telemetry modules.',
        sentAt: ago(days: 4),
        isRead: true,
      ),
      // ----------------------------------------------------------- Drafts
      DevSampleMessage(
        id: 'dev-msg-201',
        mailboxId: personalMailboxId,
        folder: MailFolder.drafts,
        from: _me,
        to: const [_flightOps],
        subject: 'Field test feedback',
        body: "Initial thoughts on this week's field tests:",
        sentAt: ago(hours: 3),
        isRead: true,
      ),
      DevSampleMessage(
        id: 'dev-msg-202',
        mailboxId: personalMailboxId,
        folder: MailFolder.drafts,
        from: _me,
        to: const [_hr],
        subject: 'Training schedule request',
        body: 'Hi, could you share the training schedule for next quarter?',
        sentAt: ago(days: 2),
        isRead: true,
      ),
      DevSampleMessage(
        id: 'dev-msg-203',
        mailboxId: personalMailboxId,
        folder: MailFolder.drafts,
        from: _me,
        to: const [],
        subject: 'Notes for the autonomy review',
        body: 'Agenda items to raise:',
        sentAt: ago(days: 6),
        isRead: true,
      ),
      // ------------------------------------------------------------- Spam
      DevSampleMessage(
        id: 'dev-msg-301',
        mailboxId: personalMailboxId,
        folder: MailFolder.spam,
        from: _promo,
        to: const [_me],
        subject: 'You have been selected for a free drone',
        body: 'Sample spam message. Do not click links in messages like this.',
        sentAt: ago(days: 2, hours: 6),
      ),
      // ------------------------------------------------------------ Trash
      DevSampleMessage(
        id: 'dev-msg-401',
        mailboxId: personalMailboxId,
        folder: MailFolder.trash,
        from: _hr,
        to: const [_me],
        subject: 'Meeting room booking cancelled',
        body: 'Your booking for meeting room B has been cancelled.',
        sentAt: ago(days: 8),
        isRead: true,
      ),
      // ------------------------------------------- Operations (shared)
      DevSampleMessage(
        id: 'dev-msg-501',
        mailboxId: sharedMailboxId,
        folder: MailFolder.inbox,
        from: _flightOps,
        to: const [_operations],
        subject: 'Site access request – Kajiado range',
        body:
            'This message is in the shared Operations mailbox, showing how '
            'employees switch between mailboxes they have been granted.',
        sentAt: ago(hours: 2),
      ),
      DevSampleMessage(
        id: 'dev-msg-502',
        mailboxId: sharedMailboxId,
        folder: MailFolder.inbox,
        from: _mary,
        to: const [_operations],
        subject: 'Ground crew roster',
        body: 'The ground crew roster for next week is confirmed.',
        sentAt: ago(hours: 6),
      ),
      DevSampleMessage(
        id: 'dev-msg-503',
        mailboxId: sharedMailboxId,
        folder: MailFolder.inbox,
        from: _procurement,
        to: const [_operations],
        subject: 'Delivery schedule for spare rotors',
        body: 'The spare rotors will arrive on Wednesday morning.',
        sentAt: ago(days: 1),
        isRead: true,
      ),
      // ------------------------------------------ Engineering (shared)
      DevSampleMessage(
        id: 'dev-msg-601',
        mailboxId: engineeringMailboxId,
        folder: MailFolder.inbox,
        from: _elijah,
        to: const [_engineering],
        subject: 'Firmware build 4.2 ready for testing',
        body: 'Build 4.2 is on the test bench. Release notes to follow.',
        sentAt: ago(hours: 1),
      ),
      DevSampleMessage(
        id: 'dev-msg-602',
        mailboxId: engineeringMailboxId,
        folder: MailFolder.inbox,
        from: _regina,
        to: const [_engineering],
        subject: 'Sensor calibration results',
        body: 'Calibration results for the new IMU batch are within spec.',
        sentAt: ago(hours: 5),
      ),
      DevSampleMessage(
        id: 'dev-msg-603',
        mailboxId: engineeringMailboxId,
        folder: MailFolder.inbox,
        from: _david,
        to: const [_engineering],
        subject: 'Code review: obstacle avoidance',
        body: 'Please review the obstacle avoidance changes before Thursday.',
        sentAt: ago(days: 1, hours: 2),
      ),
      // ------------------------------------------- Leadership (shared)
      DevSampleMessage(
        id: 'dev-msg-701',
        mailboxId: leadershipMailboxId,
        folder: MailFolder.inbox,
        from: _pmo,
        to: const [_leadership],
        subject: 'Quarterly review preparation',
        body: 'Slides for the quarterly review are due on Monday.',
        sentAt: ago(hours: 4),
      ),
    ];
  }
}
