import '../models.dart';

/// Fake Firestore content for building the screens before the backend.
///
/// The maps have exactly the shape the pipeline writes (`cases/{id}`,
/// `verdicts/{id}`) and are read through the real `fromFirestore` code.
/// "Red Light at 130" is the real example of data-model/example-case.json;
/// the other cases are invented and their ECLI and links do not exist.
abstract final class FakeData {
  static const redLightId = 'ECLI:NL:RBNHO:2026:13327';
  static const deathAtTheWheelId = 'ECLI:NL:FAKE:2026:1';
  static const shoplifterId = 'ECLI:NL:FAKE:2026:2';
  static const insiderTraderId = 'ECLI:NL:FAKE:2026:3';
  static const whistleblowerId = 'ECLI:NL:FAKE:2026:4';
  static const healingWeekendId = 'ECLI:NL:FAKE:2026:5';
  static const silentWitnessId = 'ECLI:NL:FAKE:2026:6';
  static const scootersId = 'ECLI:NL:FAKE:2026:7';
  static const fakeInvoicesId = 'ECLI:NL:FAKE:2026:8';

  static final newPlayer = PlayerProfile(
    uid: 'fake-isabella',
    name: 'Isabella',
    username: 'isabella',
    countryCode: 'NL',
    createdAt: DateTime.utc(2026, 10, 19),
  );

  static const countries = <String, Map<String, dynamic>>{
    'NL': {'name': 'Netherlands', 'publishedCases': 9},
    'OM': {'name': 'Oman', 'publishedCases': 0},
    'PT': {'name': 'Portugal', 'publishedCases': 0},
  };

  static Map<String, dynamic> _case({
    required String id,
    required String category,
    required String title,
    required String court,
    required String decisionDate,
    required List<String> charges,
    required String summaryShort,
    required String summaryLong,
    required List<(String, String)> arguments,
    List<String> contentWarnings = const [],
    required String addedAt,
  }) =>
      {
        'status': 'published',
        'country': 'NL',
        'countryName': 'Netherlands',
        'year': int.parse(decisionDate.substring(0, 4)),
        'decisionDate': decisionDate,
        'legalArea': 'criminal',
        'category': category,
        'title': title,
        'court': court,
        'charges': charges,
        'summaryShort': summaryShort,
        'summaryLong': summaryLong,
        'arguments': [for (final (side, text) in arguments) {'side': side, 'text': text}],
        'contentWarnings': contentWarnings,
        'sourceUrl': 'https://deeplink.rechtspraak.nl/uitspraak?id=$id',
        'addedAt': addedAt,
      };

  static Map<String, dynamic> _verdict({
    required List<String> courtRuled,
    double? prisonMonths,
    double? prisonSuspendedMonths,
    double? fineEur,
    int? communityServiceHours,
    int? probationMonths,
    List<(String, String)> otherMeasures = const [],
    required String actualSentence,
    required String courtReasoning,
  }) =>
      {
        'courtRuled': courtRuled,
        'sentence': {
          'prisonMonths': prisonMonths,
          'prisonSuspendedMonths': prisonSuspendedMonths,
          'fineEur': fineEur,
          'communityServiceHours': communityServiceHours,
          'probationMonths': probationMonths,
        },
        'otherMeasures': [for (final (type, label) in otherMeasures) {'type': type, 'label': label}],
        'actualSentence': actualSentence,
        'courtReasoning': courtReasoning,
      };

  static final cases = <String, Map<String, dynamic>>{
    redLightId: _case(
      id: redLightId,
      category: 'traffic',
      title: 'Red Light at 130',
      court: 'District Court of North Holland',
      decisionDate: '2026-09-03',
      charges: [
        'Reckless driving causing a crash with serious injury',
        'Driving with a blood alcohol level above the legal limit',
      ],
      summaryShort: 'A driver who had been drinking sped through a red light at a rural crossroads and hit '
          'another car. The other driver was badly injured.',
      summaryLong: 'On a summer evening, a man drove his car at 128 to 138 km/h on a road limited to 50 km/h. '
          'His blood alcohol level was 0.71 mg/ml, above the 0.5 legal limit. His partner and her two-year-old '
          'daughter were in the car. He drove through a traffic light that had been red for at least 8.9 seconds '
          'and crashed into another car crossing the junction. The other driver suffered a broken leg and bruised '
          'ribs and is still in psychological treatment. The defendant\'s partner fractured her spine and a hand. '
          'He says he believed the light was green and that he was rushing because his son was ill.',
      arguments: [
        ('prosecution', 'He drove at about 130 km/h in a 50 km/h zone and ran a light that had been red for almost 9 seconds.'),
        ('prosecution', 'His blood alcohol level was 0.71 mg/ml, above the 0.5 legal limit, with a two-year-old child in the car.'),
        ('prosecution', 'He had an earlier conviction for speeding, with his licence suspended for 56 days.'),
        ('defence', 'He believed the light was green and was rushing because his son was ill.'),
        ('defence', 'After his licence was seized he lost his job and his rented home.'),
        ('context', 'The injured driver broke a leg and ribs and is still in psychological treatment.'),
      ],
      contentWarnings: ['violence', 'minors'],
      addedAt: '2026-10-01T09:00:00Z',
    ),
    deathAtTheWheelId: _case(
      id: deathAtTheWheelId,
      category: 'traffic',
      title: 'Death at the Wheel',
      court: 'District Court of Gelderland',
      decisionDate: '2026-06-12',
      charges: ['Causing a fatal road accident through careless driving'],
      summaryShort: 'A delivery driver looking at his phone hit a cyclist on a country road. The cyclist died at the scene.',
      summaryLong: 'A 34-year-old delivery driver was driving a van on a straight country road in daylight. Phone '
          'records show he was reading messages in the seconds before the crash. He hit a 67-year-old cyclist from '
          'behind; she died at the scene. He stopped, called the emergency services and tried to help. He has no '
          'criminal record and says he cannot forgive himself. Her family says the loss has broken them.',
      arguments: [
        ('prosecution', 'Phone records show he was reading messages in the seconds before the crash.'),
        ('prosecution', 'The road was straight, dry and well lit: the cyclist was visible from far away.'),
        ('defence', 'He stopped at once, called for help and tried to save her.'),
        ('defence', 'He has no criminal record and has been in therapy since the accident.'),
        ('context', 'The victim\'s husband and children described the loss in court.'),
      ],
      contentWarnings: ['death'],
      addedAt: '2026-10-02T09:00:00Z',
    ),
    shoplifterId: _case(
      id: shoplifterId,
      category: 'theft',
      title: 'The Shoplifter\'s Dilemma',
      court: 'District Court of Rotterdam',
      decisionDate: '2026-05-20',
      charges: ['Theft of baby formula from a supermarket'],
      summaryShort: 'A single mother was caught leaving a supermarket with six tins of baby formula she had not paid for.',
      summaryLong: 'A 23-year-old single mother of a baby was stopped by a security guard with six tins of baby '
          'formula worth about EUR 90 in her bag. She had lost her job two months earlier and her benefits had '
          'not started yet. She admitted the theft at once and later paid the supermarket back. She has no '
          'criminal record. The supermarket says theft of baby formula has become a serious problem.',
      arguments: [
        ('prosecution', 'She took six tins worth about EUR 90 and hid them in her bag.'),
        ('prosecution', 'The supermarket says formula theft has become frequent and costly.'),
        ('defence', 'She had no income while waiting for her benefits and her baby needed food.'),
        ('defence', 'She admitted it at once, has no record and paid the shop back.'),
      ],
      addedAt: '2026-10-03T09:00:00Z',
    ),
    insiderTraderId: _case(
      id: insiderTraderId,
      category: 'financial',
      title: 'The Insider Trader',
      court: 'District Court of Amsterdam',
      decisionDate: '2026-04-08',
      charges: ['Insider trading', 'Passing on inside information'],
      summaryShort: 'A finance manager bought shares in a company days before his employer announced it would buy it.',
      summaryLong: 'A finance manager working on a confidential takeover bought shares in the target company for '
          'EUR 60,000 a week before the deal was announced. He also told his brother, who bought shares too. When '
          'the takeover was announced, the shares rose by 40%. He says he had been following the company for years '
          'and would have bought anyway. He lost his job and has paid back the profit.',
      arguments: [
        ('prosecution', 'He bought EUR 60,000 of shares one week before a takeover he was working on.'),
        ('prosecution', 'He told his brother, who also bought shares before the announcement.'),
        ('defence', 'He says he had followed the company for years and planned to invest anyway.'),
        ('defence', 'He lost his job and has paid back the profit he made.'),
        ('context', 'Insider trading undermines trust in the stock market, the regulator says.'),
      ],
      addedAt: '2026-10-04T09:00:00Z',
    ),
    whistleblowerId: _case(
      id: whistleblowerId,
      category: 'cybercrime',
      title: 'The Whistleblower Hacker',
      court: 'District Court of The Hague',
      decisionDate: '2026-03-17',
      charges: ['Unauthorised computer access', 'Criminal conspiracy'],
      summaryShort: 'A computer science graduate hacked a private prison company and leaked documents showing it '
          'had falsified violence records.',
      summaryLong: 'A 26-year-old computer science graduate broke into the network of a company running detention '
          'centres. He copied internal reports showing that violent incidents had been left out of official '
          'figures to keep government contracts. He gave the files to a journalist and identified himself publicly '
          'the next day. He accessed no personal data and caused no disruption. A parliamentary inquiry followed.',
      arguments: [
        ('prosecution', 'He broke into a private network on purpose and copied internal documents.'),
        ('prosecution', 'He planned the intrusion with a friend over several weeks.'),
        ('defence', 'The documents revealed falsified violence records and led to a parliamentary inquiry.'),
        ('defence', 'He accessed no personal data, caused no damage and turned himself in.'),
        ('context', 'He has no criminal record and now works for a cybersecurity firm.'),
      ],
      addedAt: '2026-10-05T09:00:00Z',
    ),
    healingWeekendId: _case(
      id: healingWeekendId,
      category: 'homicide',
      title: 'The Healing Weekend',
      court: 'District Court of Overijssel',
      decisionDate: '2026-02-11',
      charges: ['Death by negligence', 'Selling a prohibited substance'],
      summaryShort: 'A participant died during a weekend retreat where the organiser served a psychedelic brew.',
      summaryLong: 'A woman organised paid "healing weekends" on a farm, where participants drank a brew '
          'containing DMT. A 41-year-old man with a heart condition became unwell during the night. The organiser '
          'waited several hours before calling an ambulance, and he died. She says she did not know about his heart '
          'condition and thought he was having a normal reaction. She had no medical training.',
      arguments: [
        ('prosecution', 'She served a prohibited substance to paying guests with no medical screening.'),
        ('prosecution', 'She waited several hours before calling an ambulance.'),
        ('defence', 'She says she did not know about his heart condition.'),
        ('defence', 'Participants signed a form saying they took part at their own risk.'),
        ('context', 'The man\'s family says he joined the retreat to cope with depression.'),
      ],
      contentWarnings: ['death', 'drugs'],
      addedAt: '2026-10-06T09:00:00Z',
    ),
    silentWitnessId: _case(
      id: silentWitnessId,
      category: 'homicide',
      title: 'The Silent Witness',
      court: 'District Court of Limburg',
      decisionDate: '2026-01-29',
      charges: ['Manslaughter'],
      summaryShort: 'A man was found dead after a fight outside a bar. His former friend was charged, but nobody saw the blow.',
      summaryLong: 'Two former friends argued inside a bar and left together around 2 a.m. Twenty minutes later, '
          'one of them was found dead in a side street with a head injury. The other man had blood on his jacket. '
          'He says they fought briefly, that his friend was alive when he walked away, and that the blood came from '
          'the fight. No camera covered the street and no witness saw what happened.',
      arguments: [
        ('prosecution', 'He was the last person seen with the victim and had blood on his jacket.'),
        ('prosecution', 'The two men had argued loudly inside the bar.'),
        ('defence', 'He says his friend was alive and standing when he left.'),
        ('defence', 'No witness or camera saw the fatal blow.'),
        ('context', 'The pathologist could not say whether the injury came from a blow or a fall.'),
      ],
      contentWarnings: ['violence', 'death'],
      addedAt: '2026-10-07T09:00:00Z',
    ),
    scootersId: _case(
      id: scootersId,
      category: 'fraud',
      title: 'Seven Mobility Scooters',
      court: 'District Court of Zeeland-West Brabant',
      decisionDate: '2025-12-04',
      charges: ['Fraud through online sales'],
      summaryShort: 'A man sold mobility scooters online to seven elderly buyers but never delivered them.',
      summaryLong: 'Over four months, a 29-year-old man posted adverts for second-hand mobility scooters on a '
          'marketplace website. Seven buyers, most of them over 70, paid between EUR 400 and EUR 900 each. None '
          'received a scooter. He says he planned to deliver but his supplier let him down, and that he spent the '
          'money on debts. He has one earlier conviction for a similar online fraud.',
      arguments: [
        ('prosecution', 'Seven buyers, mostly over 70, paid for scooters that never arrived.'),
        ('prosecution', 'He has an earlier conviction for a similar online fraud.'),
        ('defence', 'He says his supplier let him down and he meant to deliver.'),
        ('defence', 'He has started paying some of the buyers back.'),
      ],
      addedAt: '2026-10-08T09:00:00Z',
    ),
    fakeInvoicesId: _case(
      id: fakeInvoicesId,
      category: 'fraud',
      title: 'The Fake Invoices',
      court: 'District Court of Central Netherlands',
      decisionDate: '2025-11-13',
      charges: ['Forgery of documents', 'Fraud'],
      summaryShort: 'An office manager paid fake invoices from her own shell company for three years.',
      summaryLong: 'The office manager of a small engineering firm set up a company in her mother\'s name. For three '
          'years, she created invoices for cleaning services that were never provided and approved them herself. '
          'The firm paid EUR 186,000 in total. The fraud came to light when a new accountant noticed the cleaning '
          'costs. She says she was in debt and meant to pay the money back.',
      arguments: [
        ('prosecution', 'She paid EUR 186,000 of fake invoices to a company she controlled.'),
        ('prosecution', 'The fraud lasted three years and abused her employer\'s trust.'),
        ('defence', 'She was in serious debt and says she meant to pay it back.'),
        ('defence', 'She confessed as soon as she was questioned.'),
        ('context', 'The small firm had to lay off two employees after the losses.'),
      ],
      addedAt: '2026-10-09T09:00:00Z',
    ),
  };

  static final verdicts = <String, Map<String, dynamic>>{
    redLightId: _verdict(
      courtRuled: ['prison', 'probation'],
      prisonMonths: 8,
      prisonSuspendedMonths: 4,
      probationMonths: 24,
      otherMeasures: [
        ('driving_ban', '3-year driving ban, 1 year suspended'),
        ('compensation', 'EUR 10,500 to the injured driver'),
      ],
      actualSentence: '8 months in prison, 4 of them suspended with 2 years of probation, a 3-year driving ban '
          '(1 suspended) and EUR 10,500 compensation to the injured driver.',
      courtReasoning: 'The court found the driving reckless: extreme speed, a red light and alcohol together created '
          'a serious and foreseeable danger. National sentencing guidelines set 8 months in prison and a 3-year ban '
          'for this level of culpability. His earlier speeding conviction weighed against him. His own injuries, the '
          'loss of his job and home, and his remorse were taken into account, but the court saw no reason to replace '
          'prison with community service and followed the prosecutor\'s demand.',
    ),
    deathAtTheWheelId: _verdict(
      courtRuled: ['community_service', 'probation'],
      prisonMonths: 3,
      prisonSuspendedMonths: 3,
      communityServiceHours: 240,
      probationMonths: 24,
      otherMeasures: [('driving_ban', '18-month driving ban')],
      actualSentence: '240 hours of community service, 3 months in prison fully suspended with 2 years of '
          'probation, and an 18-month driving ban.',
      courtReasoning: 'Using a phone while driving is a serious breach of care, and it cost a life. The court '
          'weighed this against his clean record, his immediate help at the scene and his deep remorse. A prison '
          'term to be served would add little; the maximum community service with a suspended sentence and a '
          'driving ban punishes him while keeping a check on his future driving.',
    ),
    shoplifterId: _verdict(
      courtRuled: ['case_dismissed'],
      actualSentence: 'Found guilty, but no penalty imposed.',
      courtReasoning: 'The theft was proven. However, the court considered her desperate situation, the small '
          'value, her immediate confession, the repayment and her clean record. Any penalty would hit her child as '
          'much as her. The court therefore found her guilty without imposing a penalty.',
    ),
    insiderTraderId: _verdict(
      courtRuled: ['fine', 'probation'],
      prisonMonths: 6,
      prisonSuspendedMonths: 6,
      fineEur: 45000,
      probationMonths: 24,
      otherMeasures: [('confiscation', 'Confiscation of EUR 24,000 profit')],
      actualSentence: 'A EUR 45,000 fine and 6 months in prison fully suspended with 2 years of probation; '
          'the profit is confiscated.',
      courtReasoning: 'The court did not believe the purchase was a coincidence: the timing and the tip to his '
          'brother showed he used inside information. Insider trading damages trust in the market, so a heavy fine '
          'is needed. Because he lost his career and repaid the profit, the court suspended the prison sentence.',
    ),
    whistleblowerId: _verdict(
      courtRuled: ['community_service'],
      communityServiceHours: 80,
      actualSentence: '80 hours of unpaid community work.',
      courtReasoning: 'Breaking into a computer network is a crime even for a good cause, and other legal routes '
          'were open to him. But the court gave weight to the public interest of what he revealed, the absence of '
          'damage or personal data, and his decision to identify himself. A short community service order was '
          'enough.',
    ),
    healingWeekendId: _verdict(
      courtRuled: ['prison', 'probation'],
      prisonMonths: 18,
      prisonSuspendedMonths: 6,
      probationMonths: 36,
      otherMeasures: [('behavioural_order', 'Ban on organising retreats for 3 years')],
      actualSentence: '18 months in prison, 6 of them suspended with 3 years of probation, and a 3-year ban '
          'on organising retreats.',
      courtReasoning: 'She gave a dangerous substance to paying guests without any medical check and waited far '
          'too long to call for help. The court found that her negligence caused his death. The waiver form did not '
          'change her duty of care. Part of the sentence is suspended to keep her from organising such events again.',
    ),
    silentWitnessId: _verdict(
      courtRuled: ['acquitted'],
      actualSentence: 'Acquitted of manslaughter.',
      courtReasoning: 'The evidence showed that the two men fought, but not that the defendant caused the fatal '
          'injury. The pathologist could not exclude a fall, and no witness saw what happened after he left. Doubt '
          'must benefit the defendant, so the court acquitted him.',
    ),
    scootersId: _verdict(
      courtRuled: ['community_service', 'probation'],
      prisonMonths: 2,
      prisonSuspendedMonths: 2,
      communityServiceHours: 120,
      probationMonths: 24,
      otherMeasures: [('compensation', 'EUR 4,350 to the seven buyers')],
      actualSentence: '120 hours of community service, 2 months in prison fully suspended with 2 years of '
          'probation, and EUR 4,350 compensation to the buyers.',
      courtReasoning: 'He deliberately targeted elderly buyers and repeated an earlier fraud. The court chose '
          'community service so he can keep working and repay the victims, with a suspended prison term as a '
          'warning against doing it again.',
    ),
    fakeInvoicesId: _verdict(
      courtRuled: ['prison'],
      prisonMonths: 12,
      prisonSuspendedMonths: 0,
      otherMeasures: [('compensation', 'EUR 186,000 to her former employer')],
      actualSentence: '12 months in prison and EUR 186,000 compensation to her former employer.',
      courtReasoning: 'She abused her position for three years and caused losses that cost two colleagues their '
          'jobs. Sentencing guidelines for fraud above EUR 100,000 point to a prison term. Her confession and debts '
          'did not outweigh the length and scale of the fraud.',
    ),
  };
}
